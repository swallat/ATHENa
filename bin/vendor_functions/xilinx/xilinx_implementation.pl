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
# Xilinx_implementation
# Version: 0.1
# 
# performs the implementation, once, based on the options file.
# ISE - ngdbuild, map, par, trace
#####################################################################

#####################################################################
# Vars
#####################################################################
$SYNTHESIS_TOOL = "";
%IMPLEMENTATION_FLAGS = ();

my $PrintCosttableToLog = "yes";
#####################################################################
# implementation
# Arguements: none
# All the information is provided to the through a global struct
#####################################################################
sub xilinx_implementation{
	#$DEV_OBJ is a global object
	my $DEVICE_NAME = $DEV_OBJ->getDevice();
	
	printOut("pre Performing implementation...");
	read_ImplementationOptions();
	set_ImplementationFilenames();
	printOut("[ok]\n");
	
	if(lc($SYNTHESIS_TOOL) eq "xst"){
		&processImpConstraints();
		
		printOut("building ngd...");
		my $NGDBUILD_FLAGS = prepare_NgdbuildFlags($DEVICE_NAME);
		printOut("Executing: $XNGDBUILD $NGDBUILD_FLAGS\n");
		$ng = system("\"$XNGDBUILD\" $NGDBUILD_FLAGS");
		if ($ng == 0){ printOut("[ok]\n");}
		else {return $ng;}
		
		
		### delete -cm option for spartan6 and virtex6
		if($DEV_OBJ->getFamily() =~ m/virtex6|spartan6|artix7|kintex7|virtex7/i) {
			$DEV_OBJ->deleteToolOpt("xilinx", "MAP", "cm");
		}
	
		printOut("mapping...");
		my $MAP_FLAGS = prepare_MapFlags($DEVICE_NAME);
		printOut("Executing: $XMAP $MAP_FLAGS\n");
		$ma = system("\"$XMAP\" $MAP_FLAGS");
		if ($ma == 0){ printOut("[ok]\n");}
		else {return $ma;}
		
		printOut("Performing place and route...");
		my $PAR_FLAGS = prepare_ParFlags();
		printOut("Executing: $XPAR $PAR_FLAGS\n");
		$pa = system("\"$XPAR\" $PAR_FLAGS");
		if ($pa == 0){ printOut("[ok]\n");}
		else {return $pa;}
		
		printOut("Performing trace...");
		my $TRACE_FLAGS = prepare_TraceFlags();
		printOut("Executing: $XTRACE $TRACE_FLAGS\n");
		$tr = system("\"$XTRACE\" $TRACE_FLAGS");
		if ($tr == 0){ printOut("[ok]\n");}
		else {return $tr;}
		
		#___ added xdl generation support
		printOut("Performing xdl extraction...");
		my $XDL_FLAGS = prepare_XdlFlags();
		#printOut("Generating xdl file\n");
		printOut("Executing: $XXDL $XDL_FLAGS\n");
		$tr = system("\"$XXDL\" $XDL_FLAGS");
		if ($tr == 0){ printOut("[ok]\n");}
		else {return $tr;}
		
		#___ added netgen generation support
		printOut("Performing vhd macro generation...");
		my $VHD_FLAGS = prepare_NetgenFlags();
		#printOut("Generating vhdl macro file\n");
		printOut("Executing: $XNETGEN $VHD_FLAGS\n");
		$tr = system("\"$XNETGEN\" $VHD_FLAGS");
		if ($tr == 0){ printOut("[ok]\n");}
		else {return $tr;}

		#___ added bitgen generation support
        printOut("Performing bitgen generation...");
        my $BITGEN_FLAGS = prepare_BitgenFlags();
        #printOut("Generating bitstream\n");
        printOut("Executing: $XBITGEN $BITGEN_FLAGS\n");
        $tr = system("\"$XBITGEN\" $BITGEN_FLAGS");
        if ($tr == 0){ printOut("[ok]\n");}
        else {return $tr;}
			
	}
	else{ #sinplify pro
		printOut("Xilinx Implementation - tool support error!\n");
	}
	
	#handle cost table;
	&printToLog($OPTION_LOG_FILE_NAME, "COST_TABLE = 1") if (lc($PrintCosttableToLog) eq "yes");
	
	return 0;
}

#####################################################################
# prepare the flags for the tools
#####################################################################
sub read_ImplementationOptions{
	my ($xil, $alt, $act) = $DEV_OBJ->getSynthesisTool('detailed');
	$SYNTHESIS_TOOL = $xil;
	#printOut("SYNTHESIS_TOOL				 $SYNTHESIS_TOOL\n");
	
	#foreach my $TOOL (@XILINX_ISE_IMPLEMENTATION_TOOLS){
	#	my %OPT_HASH = $DEV_OBJ->getToolOpts('xilinx', lc($TOOL));
	#	my @OPTS = keys %OPT_HASH;
	#	foreach my $OPT (@OPTS){
	#		push(@{$IMPLEMENTATION_FLAGS{$TOOL}}, "-".$OPT." ".$OPT_HASH{$OPT});
	#	}
	#}
}


#####################################################################
# Sets file names based on global vars
#####################################################################
sub set_ImplementationFilenames{
	#$SCRIPT_FILE = $PROJECT_NAME.".scr";
	#$PROJECT_FILE = $PROJECT_NAME.".prj";
	$NGC_FILE = "$TOP_LEVEL_ENTITY.ngc";
	$NGD_FILE = "$TOP_LEVEL_ENTITY.ngd";
	$PCF_FILE = "$TOP_LEVEL_ENTITY.pcf";
	$NCD_FILE = "${TOP_LEVEL_ENTITY}_map.ncd";
	$PAR_FILE = "${PROJECT_NAME}_${FAMILY}_${DEVICE}_${OPTIMIZATION_TARGET}.ncd"; #___ 
	$XDL_FILE = "${PROJECT_NAME}_${FAMILY}_${DEVICE}_${OPTIMIZATION_TARGET}.xdl"; #___
	$VHD_FILE = "${PROJECT_NAME}_${FAMILY}_${DEVICE}_${OPTIMIZATION_TARGET}.vhd"; #___
	$BIT_FILE = "${PROJECT_NAME}_${FAMILY}_${DEVICE}_${OPTIMIZATION_TARGET}.bit"; #___
	
	$TWR_FILE = $XILINX_TRACE_REPORT;

}

#####################################################################
# Find constraints file
#####################################################################
#
#this functions is already loaded from sysnthesis file
#

#####################################################################
# Prepare NGDBUILD flags
#####################################################################
sub prepare_NgdbuildFlags{
	my $DEVICE_NAME = $_[0];
	my $FLAGS = "";
	my ($constraint, $constraint_file) = find_constraints("ucf");
	my $OPTIONS_FILE_FLAGS = get_OptionFlags("NGDBUILD");
	
	if($constraint == 1){
		$FLAGS = "-p $DEVICE_NAME $OPTIONS_FILE_FLAGS -uc $constraint_file $NGC_FILE $NGD_FILE > $XILINX_NGDBUILD_REPORT";
		&printToLog($OPTION_LOG_FILE_NAME, "NGD_OPTS = $OPTIONS_FILE_FLAGS -uc $constraint_file");
	}
	else{
		$FLAGS = "-p $DEVICE_NAME $OPTIONS_FILE_FLAGS $NGC_FILE $NGD_FILE > $XILINX_NGDBUILD_REPORT";
		&printToLog($OPTION_LOG_FILE_NAME, "NGD_OPTS = $OPTIONS_FILE_FLAGS");
	}

	return $FLAGS;
}

#####################################################################
# Prepare MAP flags
#####################################################################
sub prepare_MapFlags{
	my $DEVICE_NAME = $_[0];
	my $FLAGS = "";
	my $OPTIONS_FILE_FLAGS = get_OptionFlags("MAP");
	&printToLog($OPTION_LOG_FILE_NAME, "MAP_OPTS = $OPTIONS_FILE_FLAGS");
	
	if($OPTIONS_FILE_FLAGS =~ m/-t\s*(\d+)/gi){
		&printToLog($OPTION_LOG_FILE_NAME, "COST_TABLE = $1") if (lc($PrintCosttableToLog) eq "yes");
		$PrintCosttableToLog = "no";
	}
	
	$FLAGS = "-p $DEVICE_NAME $OPTIONS_FILE_FLAGS -o $NCD_FILE $NGD_FILE $PCF_FILE > $XILINX_MAP_REPORT";
	return $FLAGS;
}

#####################################################################
# Prepare PAR flags
#####################################################################
sub prepare_ParFlags{
	my $FLAGS = "";
	my $OPTIONS_FILE_FLAGS = get_OptionFlags("PAR");
	&printToLog($OPTION_LOG_FILE_NAME, "PAR_OPTS = $OPTIONS_FILE_FLAGS");
	
	if($OPTIONS_FILE_FLAGS =~ m/-t\s*(\d+)/gi){
		&printToLog($OPTION_LOG_FILE_NAME, "COST_TABLE = $1") if (lc($PrintCosttableToLog) eq "yes");
		$PrintCosttableToLog = "no";
	}
	
	$FLAGS = "$OPTIONS_FILE_FLAGS $NCD_FILE $PAR_FILE $PCF_FILE > $XILINX_PAR_REPORT";
	return $FLAGS;
}

#####################################################################
# Prepare TRACE flags
#####################################################################
sub prepare_TraceFlags{
	my $FLAGS = "";
	my $OPTIONS_FILE_FLAGS = get_OptionFlags("TRACE");
	&printToLog($OPTION_LOG_FILE_NAME, "TRACE_OPTS = $OPTIONS_FILE_FLAGS");
	$FLAGS = "-intstyle silent $OPTIONS_FILE_FLAGS $PAR_FILE $PCF_FILE -o $TWR_FILE";
	return $FLAGS;
}

#___ 
#####################################################################
# Prepare xdl flags
#####################################################################
sub prepare_XdlFlags{
	my $FLAGS = "-ncd2xdl $PAR_FILE $XDL_FILE";
	return $FLAGS;
}

#___ 
#####################################################################
# Prepare netgen flags
#####################################################################
sub prepare_NetgenFlags{
	my $FLAGS = "-ofmt vhdl $PAR_FILE $VHD_FILE";
	return $FLAGS;
}

#___
#####################################################################
# Prepare bitgen flags
#####################################################################
sub prepare_BitgenFlags{
    my $FLAGS = "-intstyle ise $PAR_FILE";
    
	return $FLAGS;
}

#####################################################################
# Returs the flags from the options file
#####################################################################
sub get_OptionFlags{
	my $TOOL = $_[0];
	# insert the fool flags from the options file
	my $OPTIONS_FILE_FLAGS = "";
	
	my %OPT_HASH = $DEV_OBJ->getToolOpts('xilinx', $TOOL);
	my @OPTS = keys %OPT_HASH;
	foreach my $OPT (@OPTS){
		$OPTIONS_FILE_FLAGS .= "-".$OPT." ".$OPT_HASH{$OPT}." ";
	}
	return $OPTIONS_FILE_FLAGS;
}

#####################################################################
# Create UCF
#####################################################################
sub processImpConstraints{
	printOut("\n");
	my ($ucffile, $requested_frequency, $requested_delay);
	$ucffile = $XILINX_IMPLEMENTATION_CONSTRAINTS_FILE_NAME;
	$requested_frequency = 0; $requested_delay = 0;	
	
	my ($REQ_SYN_FREQ, $REQ_IMP_FREQ) = $DEV_OBJ->getRequestedFreqs();
	my ($SYN_CONSTRAINT_FILE, $IMP_CONSTRAINT_FILE) = $DEV_OBJ->getConstraintFiles();
	
	my $OUTPUT = "";
	my $write_output = 0;
	
	if((lc($IMP_CONSTRAINT_FILE) ne "default") & (length($IMP_CONSTRAINT_FILE) > 0)){
		$write_output = 1;
		
		printOut("processing Implementation constraints at $IMP_CONSTRAINT_FILE\n");
		open(IMPC, $IMP_CONSTRAINT_FILE);
		$OUTPUT = join("", <IMPC>);
		close(IMPC);
	}
	$OUTPUT .= "\n";
	if (($CLOCK_NET !~ m/^$|^N\\A$|NONE$/i)) {
		if($REQ_IMP_FREQ > 0){
			$write_output = 1;
			
			printOut("Requesting implementation frequency: $REQ_IMP_FREQ\n");
			$requested_frequency = $REQ_IMP_FREQ;
			$requested_delay = (1/$requested_frequency) * 1000;
			
			$OUTPUT .= "NET \"$CLOCK_NET\" TNM_NET = \"$CLOCK_NET\";\n";
			$OUTPUT .= "TIMESPEC \"TS_clock\" = PERIOD \"$CLOCK_NET\" $requested_delay ns HIGH 50 %;";
		}
		$OUTPUT .= "\n";
	}
	
	if($write_output == 1){
		open(WRTFILE, ">$ucffile") || die("Cannot create ucf file");
		print WRTFILE $OUTPUT;
		close(WRTFILE);
	}
	
	&printToLog($OPTION_LOG_FILE_NAME, "REQ_IMPLEMENTATION_FREQ = $requested_frequency\nREQ_IMPLEMENTATION_TCLK = $requested_delay");
}















1; #return 1 when including this file along with other scripts.