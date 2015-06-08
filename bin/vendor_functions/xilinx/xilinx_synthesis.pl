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
# Xilinx_synthesis
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
sub xilinx_synthesis{
	#$DEV_OBJ is a global object
	my $DEVICE_NAME = $DEV_OBJ->getDevice();
	
	printOut("pre Performing synthesis...");
	read_SynthesisOptions();
	set_SynthesisFilenames();
	printOut("[ok]\n");
	
	if(lc($SYNTHESIS_TOOL) eq "xst"){
		printOut("Performing synthesis...");
		&processSynConstraints();
		
		# ISE functions
		&create_scr($SCRIPT_FILE, $DEVICE_NAME);
		&create_prj($PROJECT_FILE);
		&copy_non_compilation_files();

		my $SYNTHESIS_FLAGS = prepare_SynthesisFlags();
		printOut("Executing: $XST $SYNTHESIS_FLAGS\n");
		my $xs = system("\"$XST\" $SYNTHESIS_FLAGS");
		if($xs == 0){ printOut("[ok]\n"); return 0; }
		else{return $xs;}
	}
	else{ #sinplify pro
		printOut("Xilinx Synthesis - tool support error!\n");
	}
}

#####################################################################
# copy non compilation file
#####################################################################
sub copy_non_compilation_files {	
	use File::Copy;
	foreach $file (  @SOURCE_FILES ) {
		if ( $file !~ /.txt$|.v$|.vhd$|.vhdl$/i ) {
			$srcfile = "$SOURCE_DIR/$file";			
			copy("$srcfile","$file");
		}
	}
}

#####################################################################
# prepare the flags for xst tool
#####################################################################
sub read_SynthesisOptions{
	@SYNTHESIS_TOOL_FLAGS = ();
	
	my ($xil, $alt, $act) = $DEV_OBJ->getSynthesisTool('detailed');
	$SYNTHESIS_TOOL = $xil;
	printOut("SYNTHESIS_TOOL \t\t $SYNTHESIS_TOOL\n");
	
	my %OPT_HASH = $DEV_OBJ->getToolOpts('xilinx', $SYNTHESIS_TOOL);
	
	my @OPTS = keys %OPT_HASH;
	foreach my $OPT (@OPTS){
		push(@SYNTHESIS_TOOL_FLAGS, "-".$OPT." ".$OPT_HASH{$OPT});
	}
	#print join(", ", @SYNTHESIS_TOOL_FLAGS)."\n";
}

#####################################################################
# Sets file names based on global vars
#####################################################################
sub set_SynthesisFilenames{
	$SCRIPT_FILE = $PROJECT_NAME.".scr";
	$PROJECT_FILE = $PROJECT_NAME.".prj";
	$NGC_FILE = "$TOP_LEVEL_ENTITY.ngc";
	$NGD_FILE = "$TOP_LEVEL_ENTITY.ngd";
	$PCF_FILE = "$TOP_LEVEL_ENTITY.pcf";
	$NCD_FILE = "map.ncd";
	$PAR_FILE = "$TOP_LEVEL_ENTITY.ncd";
	$TWR_FILE = "$TOP_LEVEL_ENTITY.twr";
}

#####################################################################
# create script file
# if there is an xcf or ucf file it will add it to the script
#####################################################################
sub create_scr{
	my $FILENAME = $_[0];
	my $DEVICE = $_[1];
	my $output = "";
	
	$output .= "-p $DEVICE\n";
	$output .= "-ifn ".$PROJECT_NAME.".prj\n";
	$output .= "-ofn $NGC_FILE\n";
	$output .= "-ofmt NGC\n";
	
	#handle verilog files
	my $NoOfVFiles = grep /.v$/, @SOURCE_FILES;
	if($NoOfVFiles > 0){
		$output .= "-ifmt mixed\n";
		$output .= "-top $TOP_LEVEL_ENTITY\n";
	}
	else{
		$output .= "-ifmt vhdl\n";
		$output .= "-ent $TOP_LEVEL_ENTITY\n";
		$output .= "-arch " . lc($TOP_LEVEL_ARCH) . "\n"; # force top level arch to be lower case
	}
	
	# insert the fool flags from the options file
	foreach $line (@SYNTHESIS_TOOL_FLAGS){
		next if($line eq "");
		my $substring = substr $line, 0, 1;
		$line = "-$line" unless($substring =~ /[-]+/);
		$output .= $line."\n";
	}
	
	#detect ucf or xcf file
	my ($constraint, $constraint_file) = find_constraints("xcf");
	if($constraint == 1){
		$output .= "-uc $constraint_file";
	}
	
	#write script file
	open(WRTFILE, ">$FILENAME") || die("Cannot create scr file"); 
	print WRTFILE "run\n";
	print WRTFILE "$output";
	close(WRTFILE);
}

#####################################################################
# create project file
#####################################################################
sub create_prj{
	my $FILENAME = $_[0];
	
	my $output = "";
	
	my $vhdl_syntax = "vhdl ";



	if($DEV_OBJ->getFamily() =~ m/virtex6|spartan6|artix7|kintex7|virtex7/i) {	$vhdl_syntax = ""; }
	







	foreach my $file (@SOURCE_FILES) {
		if ($file =~ m/.v$/i ) {
			my $dest_dir_text = "verilog work \"$SOURCE_DIR/";
			$output .= "$dest_dir_text$file\"\n";	
		} elsif ($file =~ m/.vhdl$|.vhd$/i ) {
			my $dest_dir_text = "${vhdl_syntax}work \"$SOURCE_DIR/";
			$output .= "$dest_dir_text$file\"\n";
		}
	}
	
	open(WRTFILE, ">$FILENAME") || die("Cannot create project file"); 
	print WRTFILE $output;
	close(WRTFILE);
}

#####################################################################
# Prepare synthesis flags
#####################################################################
sub prepare_SynthesisFlags{
	my $FLAGS = "";
	
	$OPTIONS_FILE_FLAGS = join(" ", @SYNTHESIS_TOOL_FLAGS);
	#printOut("$OPTIONS_FILE_FLAGS\n");
	&printToLog($OPTION_LOG_FILE_NAME, "SYN_OPTS = $OPTIONS_FILE_FLAGS");
	
	$FLAGS = "-ifn $SCRIPT_FILE > $XILINX_SYNTHESIS_REPORT";
	return $FLAGS;
}

#####################################################################
# Find constraints file
#####################################################################
sub find_constraints{
	my $FILE_TYPE = $_[0];

	#read files in directory 
	opendir(DIR, ".") || die("Cannot open directory"); 
	my @files = readdir(DIR);
	closedir(DIR);
	my @usedfiles = grep(/\.$FILE_TYPE$/,@files);
	
	#printOut("CONSTRAINT FILES: ".join("  ",@usedfiles)."\n");
	
	my $length = @usedfiles;
	if($length > 0){
		return (1, $usedfiles[0]);
	}
	return (0, 0);
}

#####################################################################
# Create XCF
#####################################################################
sub processSynConstraints{
	printOut("\n");
	my ($xcffile, $requested_frequency, $requested_delay);
	$xcffile = $XILINX_SYNTHESIS_CONSTRAINTS_FILE_NAME;
	$requested_frequency = 0; $requested_delay=0;
	
	my ($REQ_SYN_FREQ, $REQ_IMP_FREQ) = $DEV_OBJ->getRequestedFreqs();
	my ($SYN_CONSTRAINT_FILE, $IMP_CONSTRAINT_FILE) = $DEV_OBJ->getConstraintFiles();
	
	my $OUTPUT = "";
	my $write_output = 0;
	if((lc($SYN_CONSTRAINT_FILE) ne "default") & (length($SYN_CONSTRAINT_FILE) > 0)){
		$write_output = 1;
		
		printOut("processing Synthesis constraints at $SYN_CONSTRAINT_FILE\n");
		open(SYNC, $SYN_CONSTRAINT_FILE);
		$OUTPUT = join("", <SYNC>);
		close(SYNC);
	}
	$OUTPUT .= "\n";
	#if (($CLOCK_NET ne "" ) oe ($CLOCK_NET !~ m/^NONE$/i ) and ($CLOCK_NET !~ m/^N\\A$/i)) {
	if (($CLOCK_NET !~ m/^$|^N\\A$|NONE$/i)) {
		#printLocalProgress("clock_net --> <$CLOCK_NET>\n");
		if($REQ_SYN_FREQ > 0){
			$write_output = 1;
			
			printOut("Requesting synthesis frequency: $REQ_SYN_FREQ\n");
			$requested_frequency = $REQ_SYN_FREQ;
			$requested_delay = (1/$requested_frequency) * 1000;
			
			$OUTPUT .= "NET \"$CLOCK_NET\" TNM_NET = \"$CLOCK_NET\";\n";
			$OUTPUT .= "TIMESPEC \"TS_clock\" = PERIOD \"$CLOCK_NET\" $requested_delay ns HIGH 50 %;";
		}
		$OUTPUT .= "\n";
	} 
	
	if($write_output == 1){
		open(WRTFILE, ">$xcffile") || die("Cannot create xcf file");
		print WRTFILE $OUTPUT;
		close(WRTFILE);
	}
	
	&printToLog($OPTION_LOG_FILE_NAME, "REQ_SYNTHESIS_FREQ = $requested_frequency\nREQ_SYNTHESIS_TCLK = $requested_delay");
}











1; #return 1 when including this file along with other scripts.
