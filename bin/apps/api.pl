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
# API
#
# api takes RUNNO as input
# DEV_OBJ is the core data
#####################################################################

#####################################################################
# placement search
#####################################################################
sub placement_search {
	my ($RUNNO, $option_file) = @_;
	my $VENDOR = uc($DEV_OBJ->getVendor());	
	my @DIRECTORY_LIST = ();		
	my @COSTTABLE_VALUES = ();
	
	@COSTTABLE_VALUES = @{&get_CostTable($VENDOR, $option_file)};

	printOut("PROCESSING COST TABLE/SEED VALUES: ".join(", ",@COSTTABLE_VALUES)."\n\n");
	printLocalProgress("PROCESSING COST TABLE/SEED VALUES: ".join(", ",@COSTTABLE_VALUES)."\n");
	
	foreach $CTV (@COSTTABLE_VALUES){
		
		#clone to get a new device with same information
		my $NEWDEV_OBJ = dclone($DEV_OBJ);
		
		#set Run Number
		$NEWDEV_OBJ->setRunNo($RUNNO);
		$RUNNO++;
		
		#MODIFY the cost table value
		$NEWDEV_OBJ->setPlacementLocation($CTV);
		
		#set the new device parameters
		$NEWDEV_OBJ->setDispatchType($DISPATCH_TYPE_NONE);
		$NEWDEV_OBJ->setLocalApplication("single_run");
		
		#dispatch device
		my $deviceDir = dispatchDevice(\$NEWDEV_OBJ);
		push(@DIRECTORY_LIST,$deviceDir);
	}
	
	#EXECUTE the scripts
	my %RunHash = (
		vendor => "$VENDOR",
		title => "Athena - Placement Search",
		directories => \@DIRECTORY_LIST,
		requested_frequency => 0,
		run_all_options => "yes",
		max_runs => $maxSimultaneousRuns,
    );
	&ExecuteScripts(\%RunHash);	
	return( \@DIRECTORY_LIST, $RUNNO);
}

#####################################################################
# frequency search
#####################################################################
sub frequency_search {
	my ($RUNNO, $option_file) = @_;

	#===== Variables for the runs
	my $VENDOR = uc($DEV_OBJ->getVendor());
	my ($Improvement, $maxFreq, $CurrentFreq, $NextReqFreq, $ReqFreq, $ClkNet);
	my (@DIRECTORY_LIST);
	my (@dir_list); #all the directories used in the search
	#===== Open file and load data	
	my @ReqFreqSteps = @{&get_RequestedFreqSteps($option_file)};	

	#=== Get Clock Net name
	$ClkNet = &get_ClkName();
	
	#===== Perform a single run --> options and freq specified in design config.
	my $NEWDEV_OBJ = dclone($DEV_OBJ);
	$NEWDEV_OBJ->setRunNo($RUNNO);
	$RUNNO++;
	$NEWDEV_OBJ->setDispatchType($DISPATCH_TYPE_NONE);
	$NEWDEV_OBJ->setLocalApplication("single_run");
	my $deviceDir = dispatchDevice(\$NEWDEV_OBJ);
	push(@DIRECTORY_LIST,$deviceDir);
	push(@dir_list,$device_dir);
	# Execute
	printOut("\nExecuting baseline run...\n");
	my %RunHash = (
		vendor => "$VENDOR",
		title => "Frequency Search - Baseline",
		directories => \@DIRECTORY_LIST,
		requested_frequency => 0,
		run_all_options => "yes",
		max_runs => $maxSimultaneousRuns,
    );
	&ExecuteScripts(\%RunHash);
		
	# Read the achieved freq	
	($CurrentFreq, $maxFreq) = &compareFreq(0.0, shift @DIRECTORY_LIST, $VENDOR, $ClkNet);
	printOut("Achieved freq ".$CurrentFreq."\n");
	
	foreach my $Improvement (@ReqFreqSteps){
		printOut("\n\nCurrently processing Improvement \t $Improvement % \n");
		
		$CurrentFreq = $maxFreq;
		$NextReqFreq = ($Improvement/100) * $maxFreq + $maxFreq;
		printOut("NextReqFreq \t $NextReqFreq \n");
		$ReqFreq = $NextReqFreq;
				
		my $pass = "true";
		
		while($pass eq "true"){
			printOut("Requested frequency ".$ReqFreq."\n");
			
			# Dispatch new run
			my $NEWDEV_OBJ = dclone($DEV_OBJ);
			$NEWDEV_OBJ->setRunNo($RUNNO);
			$RUNNO++;
			$NEWDEV_OBJ->setDispatchType($DISPATCH_TYPE_NONE);
			$NEWDEV_OBJ->setLocalApplication("single_run");
			$NEWDEV_OBJ->setRequestedFreqs($ReqFreq, $ReqFreq);
			my $deviceDir = dispatchDevice(\$NEWDEV_OBJ);
			push(@DIRECTORY_LIST,$deviceDir);
			push(@dir_list,$device_dir);
			
			# Execute
			printOut("\nExecuting $Improvement % request run...\n");
			my %RunHash = (
				vendor => "$VENDOR",
				title => "Frequency Search - $Improvement % improvement",
				directories => \@DIRECTORY_LIST,
				requested_frequency => 0,
				run_all_options => "yes",
				max_runs => $maxSimultaneousRuns,
			);
			&ExecuteScripts(\%RunHash);
			
			# Gather Reqults
			($CurrentFreq, $maxFreq) = &compareFreq($maxFreq, shift @DIRECTORY_LIST, $VENDOR, $ClkNet);
			printOut("Achieved freq ".$CurrentFreq."\n");
			
			if($CurrentFreq >= $ReqFreq)
			{
				#pass
				printOut("PASS\n");
				$NextReqFreq = ($Improvement/100) * $CurrentFreq + $CurrentFreq;
				printOut("NextReqFreq \t $NextReqFreq \n");
				$ReqFreq = $NextReqFreq;
			}
			else
			{
				#fail
				printOut("FAIL\n");
				$pass = "false";
			}
		}
	}

	printOut("\n\nCurrently Achieved maximum frequency : $maxFreq \n\n");
	return ( \@dir_list, $RUNNO);
}
1;