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
# Support functions for API
#####################################################################

#####################################################################
# Acquires Requested frequency improvement step
#####################################################################
sub get_RequestedFreqSteps{
	my $CONFIG_FILE = shift();
	printOut("CONFIG_FILE		$CONFIG_FILE\n");
	my @ConfigData = @{getProcessedText($CONFIG_FILE , "frequency_search.txt")};
	my $DATA = join("\n", @ConfigData);	
	
	if($DATA =~ m/REQUESTED_FREQ_IMPROVEMENT_STEPS\s*=\s*([\d ,%]+)/gi){
		#print "$1\n";
		my $var = $1;
		$var =~ s/%//gi;
		my @split = split(/[, ]+/,$var);
		@ReqFreqSteps = @split;
	}
	return \@ReqFreqSteps;
}

#####################################################################
# Acquires Costtable Values
#####################################################################
sub get_CostTable{
	my ($VENDOR, $CONFIG_FILE) = @_;
	my @ConfigData = @{getProcessedText($CONFIG_FILE , "placement_search")};
	my $ConfigDataStr = join("\n", @ConfigData);	
	my @RETURN_VALS = ();
	my $REGEX_STR = "";
	if (lc($VENDOR) eq "xilinx"){
		$REGEX_STR = "XILINX_COST_TABLE_VALUES";
	}
	elsif (lc($VENDOR) eq "altera"){
		$REGEX_STR = "ALTERA_SEED_VALUES";
	}
	
	if($ConfigDataStr =~ m/${REGEX_STR}\s*=\s*([\s\d;:]+)/i){
		@RETURN_VALS = @{&parse_CostTable($1)};		
	}
	
	while($#RETURN_VALS < 0){		

		print "NOTE:\n\n
		Please enter the COST TABLE / SEED  values for the experiment.\n
		USAGE: Seperate each set by semicolon. You can specify single numbers or sets\n
		\tSet format => beginning number : step : end number\n
		\tFor Xilinx the range is 1 - 100\n
		\tEXAMPLE: \n
		\t\tEntering 2; 4:4:40; 5; 65:11:99 \n
		\t\treturn 2,4,8,12,16,20,24,28,32,36,40,5,65,76,87,98 \n\n	
		\nIncorrectly formated items will be ignored!\n::";
		my $input = <STDIN>;
		@RETURN_VALS = @{&parse_CostTable($input)};		
	}
	
	printOut("Placement search values = ". join(" - ",@RETURN_VALS));
	return \@RETURN_VALS;
}

#####################################################################
# parses Costtable Values
#####################################################################
sub parse_CostTable{
	my $data = $_[0];
	my @RETURN_VALS = ();
	
	my @mainlist = split(/[\s;,]+/,$data);
	foreach $item (@mainlist){
		my @sublist = split(/[\s:]+/,$item);
		if($#sublist < 2){
			push(@RETURN_VALS, $item);
		}
		next if($#sublist != 2);
		next if($sublist[0] < $sublist[0]);
		my $start = $sublist[0];
		my $step = $sublist[1];
		my $end = $sublist[2];
		while($start <= $end){
			push(@RETURN_VALS, $start);
			$start += $step;
		}
	}
	return \@RETURN_VALS;
}

#####################################################################
# get clk net name
#####################################################################
sub get_ClkName {
	my $CONFIG_FILE = "$CONFIG_DIR/$DESIGN_CONFIGURATION_FILE_NAME";
	my @ConfigData = @{getProcessedText($CONFIG_FILE , $DESIGN_CONFIGURATION_FILE_NAME)};
	my $DATA = join("\n", @ConfigData);
	my $ClkNet;
	if($DATA =~ /$REGEX_CLOCK_NET_EXTRACT/){
		#print "$1\n";
		$ClkNet = $1;
	} else { 
		print "Clock net name not found. Program terminated\n"; 
		exit;
	}
	return $ClkNet;
}

1;