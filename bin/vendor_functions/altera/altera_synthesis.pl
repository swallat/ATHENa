# =============================================
# ATHENA - Automated Tool for Hardware EvaluatioN.
# Copyright © 2009 - 2014 CERG at George Mason University <cryptography.gmu.edu>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see http://www.gnu.org/licenses
# or write to the Free Software Foundation,Inc., 51 Franklin Street,
# Fifth Floor, Boston, MA 02110-1301  USA.
# =============================================

#! ./perl


#####################################################################
# Altera_synthesis
# Version: 0.1
# 
# Performs the synthesis, once, based on the options file.
#####################################################################

#####################################################################
# Vars
#####################################################################

$SYNTHESIS_TOOL = "";
@SYNTHESIS_TOOL_FLAGS = ();

#####################################################################
# Synthesis
# Arguements: none
# All the information is provided to the through a global struct
#####################################################################
sub altera_synthesis{
	# ALTERA PROBLEM (project names have to be toplevel entities)
	my $tempPrjname = $PROJECT_NAME;
	$PROJECT_NAME = $TOP_LEVEL_ENTITY;
	
	my $VENDOR = "altera";
	my $FAMILY = $DEV_OBJ->getFamily();
	my $DEVICE = $DEV_OBJ->getDevice();
	my $GENERIC = $DEV_OBJ->getGenericValue();
	
	printOut("performing pre-synthesis...");
	read_SynthesisOptions();
	set_SynthesisFilenames();
	printOut("[ok]\n");
	
	if(lc($SYNTHESIS_TOOL) eq "quartus_map"){
		printOut("performing synthesis...");
		
		&create_prj($PROJECT_FILE, $PROJECT_NAME, $FAMILY, $DEVICE, $GENERIC);
		my $SYNTHESIS_FLAGS = prepare_SynthesisFlags() . " $PROJECT_NAME -c $PROJECT_NAME >> syn.log";
		printOut("Executing: $QMAP $SYNTHESIS_FLAGS\n");
		$xs = system("\"$QMAP\" $SYNTHESIS_FLAGS");				
		if ($xs eq 0 ){ printOut("[ok]\n"); return 0;}
		else {return $xs;}
	}
	else{ #sinplify pro
	
	}
	
	# ALTERA PROBLEM (project names have to be toplevel entities)
	# assuming a modular design, we cant change the project name. (so reset it)
	$PROJECT_NAME = $tempPrjname;
}

#####################################################################
# prepare the flags for xst tool
#####################################################################
sub read_SynthesisOptions{
	@SYNTHESIS_TOOL_FLAGS = ();
	
	my ($xil, $alt, $act) = $DEV_OBJ->getSynthesisTool('detailed');
	$SYNTHESIS_TOOL = $alt;
	printOut("SYNTHESIS_TOOL \t\t $SYNTHESIS_TOOL\n");
	
	my %OPT_HASH = $DEV_OBJ->getToolOpts('altera', $SYNTHESIS_TOOL);
	
	my @OPTS = keys %OPT_HASH;
	foreach my $OPT (@OPTS){
		push(@SYNTHESIS_TOOL_FLAGS, "--".$OPT."=".$OPT_HASH{$OPT});
	}
	#print join(", ", @SYNTHESIS_TOOL_FLAGS)."\n";	
}

#####################################################################
# Sets file names based on global vars
#####################################################################
sub set_SynthesisFilenames{
	$PROJECT_FILE = $PROJECT_NAME.".qsf";
	
	$ALTERA_SYNTHESIS_REPORT = $PROJECT_NAME.".".$ALTERA_SYNTHESIS_REPORT_SUFFIX;
	$ALTERA_POWER_REPORT = $PROJECT_NAME.".".$ALTERA_POWER_REPORT_SUFFIX;
	$ALTERA_TIMING_REPORT_1 = $PROJECT_NAME.".".$ALTERA_TIMING_REPORT_1_SUFFIX;
	$ALTERA_TIMING_REPORT_2 = $PROJECT_NAME.".".$ALTERA_TIMING_REPORT_2_SUFFIX ;
	$ALTERA_IMPLEMENTATION_REPORT = $PROJECT_NAME.".".$ALTERA_IMPLEMENTATION_REPORT_SUFFIX;

}

#####################################################################
# create project file
#####################################################################
sub create_prj{
	my $PRJ_FILE = $_[0];
	my $PRJ_NAME = $_[1];
	my $FAMILY = $_[2];
	my $DEVICE = $_[3];
	my $generics = $_[4];
	
	my $output = "";
	
	$output .= "set_global_assignment -name TOP_LEVEL_ENTITY $PRJ_NAME\n";	
	if ($FAMILY =~ /stratix iv/i ) { $FAMILY = "stratix iv"; }
	if ($FAMILY =~ /stratix v/i ) { $FAMILY = "stratix v"; }
	$output .= "set_global_assignment -name FAMILY \"$FAMILY\"\n";		
	$output .= "set_global_assignment -name DEVICE $DEVICE\n";
	
	my %req_utilization = %{$DEV_OBJ->getUtilizationFactors()};
	if (( $req_utilization{DSP} == 0 ) or ( $req_utilization{MULT} == 0 ))  {
		$output .= "set_global_assignment -name AUTO_DSP_RECOGNITION OFF\n";
	}
	if ( $req_utilization{MEMORY} == 0 ) {
		$output .= "set_global_assignment -name MAX_RAM_BLOCKS_M4K 0\n";
		$output .= "set_global_assignment -name MAX_RAM_BLOCKS_M512 0\n";
		$output .= "set_global_assignment -name MAX_RAM_BLOCKS_MRAM 0\n";
		$output .= "set_global_assignment -name AUTO_ROM_RECOGNITION OFF\n";
        $output .= "set_global_assignment -name AUTO_RAM_RECOGNITION OFF\n";
		$output .= "set_global_assignment -name AUTO_SHIFT_REGISTER_RECOGNITION OFF\n";
	}
	
	# source files	
	foreach $file(@SOURCE_FILES) {
		if ( $file =~ m/.v$/i ) {
			my $dest_dir_text = "set_global_assignment -name VERILOG_FILE \"$SOURCE_DIR/";		
			$output .= "$dest_dir_text$file\"\n";
		} elsif ( $file =~ m/.vhd|.vhdl/i ) {
			my $dest_dir_text = "set_global_assignment -name VHDL_FILE \"$SOURCE_DIR/";		
			$output .= "$dest_dir_text$file\"\n";
		} elsif ( $file =~ m/.tdf$/i ) {
			my $dest_dir_text = "set_global_assignment -name AHDL_FILE \"$SOURCE_DIR/";		
			$output .= "$dest_dir_text$file\"\n";
		} elsif ( $file =~ m/.gdf$/i ) {
			my $dest_dir_text = "set_global_assignment -name GDF_FILE \"$SOURCE_DIR/";		
			$output .= "$dest_dir_text$file\"\n";
		}
		
		
	}
	
	# generics
	my @gens = split(/ /g,$generics);
	foreach $genpair (@gens) {
		if ( $genpair =~ /^default$/i ) { next; }
		my ($name, $value) = split(/=/,$genpair);		
		$output .= "set_parameter -name $name \"$value\"\n";
	}
		
	open(WRTFILE, ">$PRJ_FILE") || die("Cannot create project file"); 
	print WRTFILE $output;
	close(WRTFILE);
}

#####################################################################
# Prepare synthesis flags
#####################################################################
sub prepare_SynthesisFlags{
	my $FLAGS = "--read_settings_files=on --write_settings_files=off ";
	#"--read_settings_files=on --write_settings_files=off $PROJECT_NAME -c $PROJECT_NAME >> syn.log";
	my $OPTIONS_FILE_FLAGS = join(" ", @SYNTHESIS_TOOL_FLAGS);
	#printOut("$OPTIONS_FILE_FLAGS\n");
	$FLAGS.=$OPTIONS_FILE_FLAGS;
	&printToLog($OPTION_LOG_FILE_NAME, "SYN_OPTS = $OPTIONS_FILE_FLAGS");
	#printOut("F: $FLAGS\n");
	#$FLAGS = "-ifn $SCRIPT_FILE -ofn $ALTERA_SYNTHESIS_REPORT -intstyle $RUNMODE > $ALTERA_SYNTHESIS_REPORT1";
	return $FLAGS;
}
















1; #return 1 when including this file along with other scripts.