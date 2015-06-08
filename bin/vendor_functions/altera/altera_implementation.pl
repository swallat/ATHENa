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
# Altera_implementation
# Version: 0.1
# 
# performs the implementation, once, based on the options file.
# 
#####################################################################

#####################################################################
# Vars
#####################################################################
$SYNTHESIS_TOOL = "";
%IMPLEMENTATION_FLAGS = ();

#####################################################################
# implementation
# Arguements: none
# All the information is provided to the through a global struct
#####################################################################
sub altera_implementation{
	my $VENDOR = "altera";
	my $FAMILY = $DEV_OBJ->getFamily();
	my $DEVICE = $DEV_OBJ->getDevice();
	
	printOut("Reading Options...\n");
	read_ImplementationOptions();
	
	printOut("FIT running...");
	my $QFIT_FLAGS = prepare_fit_flags($PROJECT_NAME);
	printOut("Executing: $QFIT $QFIT_FLAGS\n");
	$qf = system("\"$QFIT\" $QFIT_FLAGS");
	if ($qf eq 0 ){ printOut("[ok]\n");}
	else {return $qf; }
	
	printOut("ASM running...");
	my $QASM_FLAGS = prepare_asm_flags($PROJECT_NAME);
	printOut("Executing: $QASM $QASM_FLAGS\n");
	$qf = system("\"$QASM\" $QASM_FLAGS");
	if ($qf eq 0 ){ printOut("[ok]\n");}
	else {return $qf;}
	
	printOut("STA running...");

	my $QSTA_FLAGS = prepare_sta_flags($PROJECT_NAME);
	printOut("Executing: $QSTA $QSTA_FLAGS\n");
	$qf = system("\"$QSTA\" $QSTA_FLAGS");

	if ($qf eq 0 ){ printOut("[ok]\n");}
	else {return $qf;}
	
	return 0;
}

#####################################################################
# prepare the flags for the tools
#####################################################################
sub read_ImplementationOptions{
	my ($xil, $alt, $act) = $DEV_OBJ->getSynthesisTool('detailed');
	$SYNTHESIS_TOOL = $alt;
	
	#printOut("SYNTHESIS_TOOL				 $SYNTHESIS_TOOL\n");
	
	#foreach my $TOOL (@ALTERA_QUATRUS_IMPLEMENTATION_TOOLS){
	#	my %OPT_HASH = $DEV_OBJ->getToolOpts('xilinx', lc($TOOL));
	#	my @OPTS = keys %OPT_HASH;
	#	foreach my $OPT (@OPTS){
	#		push(@{$IMPLEMENTATION_FLAGS{$TOOL}}, "-".$OPT." ".$OPT_HASH{$OPT});
	#	}
	#}
}


#####################################################################
# Prepare FIT flags
#####################################################################
sub prepare_fit_flags{
	my $FLAGS = "";
	my $PROJECT_NAME = $_[0];
	my $RFREQ = "";

	my ($REQ_SYN_FREQ, $REQ_IMP_FREQ) = $DEV_OBJ->getRequestedFreqs();
	my ($SYN_CONSTRAINT_FILE, $IMP_CONSTRAINT_FILE) = $DEV_OBJ->getConstraintFiles();
	my ($ucffile, $requested_frequency, $requested_delay);

	$requested_frequency = 0; $requested_delay = 0;
	$requested_frequency = $REQ_IMP_FREQ;
	$requested_delay = (1/$requested_frequency) * 1000 unless ($requested_frequency == 0);
	&printToLog($OPTION_LOG_FILE_NAME, "REQ_IMPLEMENTATION_FREQ = $requested_frequency\nREQ_IMPLEMENTATION_TCLK = $requested_delay");
	
	if ($REQ_IMP_FREQ > 0){
		$RFREQ = "--fmax=$REQ_IMP_FREQ";
		$RFREQ.="Mhz";
	}
	else{
		my $RFREQ="";
	}
	
	my $OPTIONS_FILE_FLAGS = get_OptionFlags("QUARTUS_FIT");	
	$OPTIONS_FILE_FLAGS.=$RFREQ;	
	&printToLog($OPTION_LOG_FILE_NAME, "IMP_OPTS = $OPTIONS_FILE_FLAGS");	
	
	if($OPTIONS_FILE_FLAGS =~ m/--seed=([\d]+)/gi){
		&printToLog($OPTION_LOG_FILE_NAME, "SEED = $1");
	}
	else{
		&printToLog($OPTION_LOG_FILE_NAME, "SEED = 1");
	}
	
	$FLAGS = "--read_settings_files=on --write_settings_files=off $OPTIONS_FILE_FLAGS $PROJECT_NAME -c $PROJECT_NAME  >> fit.log";
	return $FLAGS;
}


#####################################################################
# Prepare ASM flags
#####################################################################
sub prepare_asm_flags{
	my $FLAGS = "";
	my $PROJECT_NAME = $_[0];
	
	$FLAGS = "--read_settings_files=on --write_settings_files=off $PROJECT_NAME -c $PROJECT_NAME >> asm.log";
	
	return $FLAGS;
}

#####################################################################
# Prepare tan flags
#####################################################################
sub prepare_tan_flags{
	my $FLAGS = "";
	my $PROJECT_NAME = $_[0];
	
	$FLAGS = "--read_settings_files=on --write_settings_files=off $PROJECT_NAME -c $PROJECT_NAME  >> tan.log";
	
	return $FLAGS;
}

#####################################################################
# Prepare sta flags
#####################################################################
sub prepare_sta_flags{
	my $FLAGS = "";
	my $PROJECT_NAME = $_[0];	
	$FLAGS = "$PROJECT_NAME --do_report_timing >> tan.log";	
	return $FLAGS;
}


#####################################################################
# Returs the flags from the options file
#####################################################################
sub get_OptionFlags{
	my $TOOL = $_[0];
	# insert the tool flags from the options file
	my $OPTIONS_FILE_FLAGS = "";
	
	my %OPT_HASH = $DEV_OBJ->getToolOpts('altera', $TOOL);
	my @OPTS = keys %OPT_HASH;
	foreach my $OPT (@OPTS){
		$OPTIONS_FILE_FLAGS .= "--".$OPT."=".$OPT_HASH{$OPT}." ";
	}
	return $OPTIONS_FILE_FLAGS;
}














1; #return 1 when including this file along with other scripts.
