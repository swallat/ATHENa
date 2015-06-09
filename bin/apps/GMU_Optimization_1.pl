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
# APPLICATION: GMU_optimization_1
#####################################################################

my $APPLICATION_NAME = "GMU_Optimization_1";


my $bestStrat = "";
my $FAIL_COUNT = 0;
my $MAX_CONSECUTIVE_FAILURE = 3;
#####################################################################
# application function
#####################################################################
sub application{
	printOut("\nRunning application : GMU OPTIMIZATION 1\n");
	printLocalProgress("Application : GMU OPTIMIZATION 1\n");
	my ($VENDOR, $FAMILY, $DEVICE);

	$VENDOR = uc($DEV_OBJ->getVendor());
	$FAMILY = uc($DEV_OBJ->getFamily());
	$DEVICE = uc($DEV_OBJ->getDevice());

	#===== Variables for the runs
	
	my (@DIRECTORY_LIST);
	my $RUNNO = 1;
	my $ClkNet = &get_ClkName();
	my $CONFIG_FILE = "$CONFIG_DIR/GMU_optimization_1.txt";
	my @investigated_strategies = ("area", "speed", "balanced");
	if( $VENDOR =~ /xilinx/i ) {
		my ($Improvement, $CurrentFreq, $NextReqFreq, $ReqFreq);
		
		#===== Open file and load data
		my @OriginalReqFreqSteps = @{&get_RequestedFreqSteps($CONFIG_FILE)};
		my @COSTTABLE_VALUES = @{&get_CostTable($VENDOR, $CONFIG_FILE)};	
		
		#=== Get Clock Net name
		
		
		$DEV_OBJ->setDispatchType($DISPATCH_TYPE_NONE);
		$DEV_OBJ->setLocalApplication("single_run");

		#==============================================================================
		#===== loop through each investigated strategies
		
		foreach $strat (@investigated_strategies) {		
			my $maxFreq = 0.0;
			
			$DEV_OBJ->setOptimizationStrategy($strat);					
			my @ReqFreqSteps = @OriginalReqFreqSteps;
			$Improvement = shift(@ReqFreqSteps); #shift @ReqFreqSteps; <== keep the first value for future loop			
			$ReqFreq = "";
			
			my $loop = 1;
			my $state = "NORMAL_SEARCH"; # HIGH_EFFORT_SEARCH, #HIGH_EFFORT_WITH_PLACEMENT_SEARCH
			my @placement_locations = @COSTTABLE_VALUES;
			my $placement_location;	
			my $LOOP_OBJ = dclone($DEV_OBJ);
			while($loop == 1){
				
				# Dispatch new run
				my $NEWDEV_OBJ = dclone($LOOP_OBJ);
				$NEWDEV_OBJ->setRunNo($RUNNO); $RUNNO++;			
				$NEWDEV_OBJ->setRequestedFreqs($ReqFreq, $ReqFreq);				
				if ( $state =~ m/^HIGH_EFFORT_WITH_PLACEMENT_SEARCH$/i ) {
					$NEWDEV_OBJ->setPlacementLocation( $placement_location );
				}				
				my $deviceDir = dispatchDevice(\$NEWDEV_OBJ);
				push(@DIRECTORY_LIST,$deviceDir);
				
			
				printOut("Requested frequency ".$ReqFreq."\n");
				
				# Execute
				printOut("\nExecuting $Improvement % request run...\n");
				my %RunHash = (
					vendor => "$VENDOR",
					title => "GMU_Xilinx_Optimization_1 - $Improvement % improvement",
					directories => \@DIRECTORY_LIST,
					requested_frequency => 0,
					run_all_options => "yes",
					max_runs => $maxSimultaneousRuns,
				);
				&ExecuteScripts(\%RunHash);
				
				# Gather Reqults
				($CurrentFreq, $maxFreq) = &compareFreq($maxFreq, shift @DIRECTORY_LIST, $VENDOR, $ClkNet);
				if ( $CurrentFreq <= 0 ) { # invalid result
					$FAIL_COUNT++;
					if ( $FAIL_COUNT > $MAX_CONSECUTIVE_FAILURE ) {					
						printOut("Exceed iteration limit ( $MAX_CONSECUTIVE_FAILURE ). Too many consecutive failure, program terminating.");
						last;
					}
				} else {
					$FAIL_COUNT = 0;
				}				
				printOut("Achieved freq ".$CurrentFreq."\n");
				
				if($CurrentFreq >= $ReqFreq) {	#pass
					
					$NextReqFreq = ($Improvement/100) * $maxFreq + $maxFreq;
					$ReqFreq = $NextReqFreq;
					printOut("PASS\n");
					printOut("NextReqFreq \t $NextReqFreq \n");
					if ( $state =~ m/^HIGH_EFFORT_WITH_PLACEMENT_SEARCH$/i ) {
						#restart the placement location over again
						@placement_locations = @COSTTABLE_VALUES;
						$placement_location = shift(@placement_locations);
					}
				} else { #fail	
					# Performs normal search with low effort until no improvement can be reached
					# then change to high effort. If no improvement cannot be reached with high effort,
					# try all the possible placement locations. If it still doesn't help then 
					if ( $state =~ m/NORMAL_SEARCH/i ) {
						$state = "HIGH_EFFORT_SEARCH";
						$LOOP_OBJ->deleteToolOpt($VENDOR, "PAR", "ol");
						$LOOP_OBJ->addOpt($VENDOR, "PAR", "ol", "high");
					} elsif ( $state =~ m/^HIGH_EFFORT_SEARCH$/i ) {
						$state = "HIGH_EFFORT_WITH_PLACEMENT_SEARCH";
						$placement_location = shift(@placement_locations);
					} elsif ( $state =~ m/^HIGH_EFFORT_WITH_PLACEMENT_SEARCH$/i ) {
						if ( $#ReqFreqSteps < 0 and $#placement_locations < 0) { # nothing left to loop
							$loop = 0;
						} else {		
							if ( $#placement_locations < 0 ) { #run out of placement, request smaller improvement step
								$Improvement = shift(@ReqFreqSteps); 
								@placement_locations = @COSTTABLE_VALUES;
								$placement_location = shift(@placement_locations);	
								$NextReqFreq = ($Improvement/100) * $maxFreq + $maxFreq;
								$ReqFreq = $NextReqFreq;							
							} else {
								$placement_location = shift(@placement_locations);						
							}
						}
					}
					printOut("FAIL\n");
				}
			}		
		}
	} elsif( $VENDOR =~ /altera/i ) {
		foreach $strat (@investigated_strategies) {		
			$DEV_OBJ->setOptimizationStrategy($strat);
			($temp,$RUNNO) = &placement_search($RUNNO, $CONFIG_FILE);
		}
	} else {
		printOut("Invalid Family for application: GMU_optimization_1. Program terminated.\n");
		exit;
	}
}










1;