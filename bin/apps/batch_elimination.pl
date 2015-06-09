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
# APPLICATION: batch_elimination
# Version: 0.1
# - General Implementation under the assumption that the user has entered everything correctly.
# - No "idiot checks"
#
# 
# Benjamin Brewster (GMU) explains:
# The BE algorithm instead of simply investigating an on/off state will need to check
# options that have up to three states. The baseline will be initialized with the highest 
# optimization level set for all options. Each iteration of the algorithm will change 
# a single option through each option level. If any lower level for an option yields the 
# same performance as the higher level, the lower level option will be utilized. 
# The adapted algorithm also analyzes performance not in program execution time, 
# but other metrics such as throughput, area, and throughput/area ratio.
#
# For more details about the algorithm please refer to the documentation
#####################################################################

#####################################################################
# application function
#####################################################################
sub application{
	printOut("\nRunning application : BATCH ELIMINATION\n");
	printLocalProgress("Application : BATCH ELIMINATION\n");
	my ($VENDOR, $FAMILY, $DEVICE);
	
	$VENDOR = uc($DEV_OBJ->getVendor());
	$FAMILY = uc($DEV_OBJ->getFamily());
	$DEVICE = uc($DEV_OBJ->getDevice());
	
	#read config files
	my ($BaselineOption_HASHREF, $GeneralOption_HASHREF, $SynthesisTool_HASHREF) = readBEConfig($VENDOR, $FAMILY);	
	my %BaselineOptions = %{$BaselineOption_HASHREF};
	my %GeneralOptions = %{$GeneralOption_HASHREF};
	
	# prepare the options hash{tool}{opt} = @flags  <== @flags should be $flag. only one flag
	my @TOOLS = keys %BaselineOptions;
	foreach my $TOOL (@TOOLS){
		my %OPTION_HASH = %{$BaselineOptions{$TOOL}};
		my @OPTIONS = keys %OPTION_HASH;
		foreach my $OPTION (@OPTIONS){
			my @FLAGS = @{$OPTION_HASH{$OPTION}};
			my $var = shift @FLAGS;
			$ModifiedBaselineOptions{$TOOL}{$OPTION} = $var;
			$ProcessedBaselineOptions{$TOOL}{$OPTION} = $var;
		}
	}
	printHash(\%ModifiedBaselineOptions);
	
	#=== Get Clock Net name
	my $ClkNet;
	my $CONFIG_FILE = "$CONFIG_DIR/$DESIGN_CONFIGURATION_FILE_NAME";
	@ConfigData = @{getProcessedText($CONFIG_FILE , $DESIGN_CONFIGURATION_FILE_NAME)};
	my $DATA = join("\n", @ConfigData);
	if($DATA =~ /$REGEX_CLOCK_NET_EXTRACT/){
		#print "$1\n";
		$ClkNet = $1;
	}
	
	#===== Variables for the runs
	my (@DIRECTORY_LIST);
	my $RUNNO = 1;
	
	#===== Baseline run
	# Prepare run
	my $NEWDEV_OBJ = dclone($DEV_OBJ);
	$NEWDEV_OBJ->setRunNo($RUNNO);
	$RUNNO++;
	$NEWDEV_OBJ->setDispatchType($DISPATCH_TYPE_NONE);
	$NEWDEV_OBJ->setLocalApplication("single_run");
	&modify_options(\$NEWDEV_OBJ, \%ModifiedBaselineOptions);
	$NEWDEV_OBJ->setSynthesisTool($SynthesisTool_HASHREF);
	
	# Dispatch run/device
	my $deviceDir = dispatchDevice(\$NEWDEV_OBJ);
	push(@DIRECTORY_LIST,$deviceDir);
	
	# Execute
	printOut("\nExecuting baseline run...\n");
	my %RunHash = (
		vendor => "$VENDOR",
		title => "BatchElimination - Baseline",
		directories => \@DIRECTORY_LIST,
		requested_frequency => 0,
		run_all_options => "yes",
		max_runs => $maxSimultaneousRuns,
    );
	&ExecuteScripts(\%RunHash);
	
	#Gather Results (for now only performance results)
	my @BASELINE_RESULTS = extract_perf_results($VENDOR, "", "", shift @DIRECTORY_LIST, $ClkNet);
	printOut("BASELINE_RESULTS \t \t \t @BASELINE_RESULTS\n");
	
	#===== Rest of the runs
	my @TOOLS = keys %GeneralOptions;
	
#	my @permutations = permutations(@TOOLS);
#	foreach $permutation_ref (@permutations){
#		my @PermutedTools = @{$permutation_ref};
#		printOut("Current permutation - ".join(", ",@PermutedTools)."\n");
#		foreach my $TOOL (@PermutedTools){
		
		printOut("Current order - ".join(", ",@TOOLS)."\n");
		foreach my $TOOL (@TOOLS){
			my %OPTION_HASH = %{$GeneralOptions{$TOOL}};
			my @OPTIONS = keys %OPTION_HASH;
			foreach my $OPTION (@OPTIONS){
				my @FLAGS = @{$OPTION_HASH{$OPTION}};
				#printOut("Currently processing $TOOL $OPTION @FLAGS====================================================\n");
				
				#===== form combinations
				my @COMBINATIONS = @{formCombinations(\%ModifiedBaselineOptions, $TOOL, $OPTION, @FLAGS)};
				#printOut("Combinations ".($#COMBINATIONS+1)."\n");
				
				#===== dispatch
				@DIRECTORY_LIST = ();
				my %CombinationTracking = ();
				foreach my $COMBINATION_HASHREF (@COMBINATIONS){
					
					# Track the combination
					$CombinationTracking{$RUNNO} = $COMBINATION_HASHREF;
					
					# Prepare run
					my $NEWDEV_OBJ = dclone($DEV_OBJ);
					$NEWDEV_OBJ->setRunNo($RUNNO);
					$RUNNO++;
					$NEWDEV_OBJ->setDispatchType($DISPATCH_TYPE_NONE);
					$NEWDEV_OBJ->setLocalApplication("single_run");
					&modify_options(\$NEWDEV_OBJ, $COMBINATION_HASHREF);
					$NEWDEV_OBJ->setSynthesisTool($SynthesisTool_HASHREF);
					
					# Dispatch run/device
					my $deviceDir = dispatchDevice(\$NEWDEV_OBJ);
					push(@DIRECTORY_LIST,$deviceDir);
				}
				
				#===== Execute
				printOut("\nExecuting post baseline run...\n");
				my %RunHash = (
					title => "BatchElimination - Post-Baseline",
					directories => \@DIRECTORY_LIST,
					requested_frequency => 0,
					run_all_options => "yes",
					max_runs => $maxSimultaneousRuns,
				);
				&ExecuteScripts(\%RunHash);
				
				#===== getResults
				my %ResultTracking = ();
				foreach my $DIRECTORY (@DIRECTORY_LIST){
					my @RESULTS = extract_perf_results($VENDOR, "", "", $DIRECTORY, $ClkNet);
					
					my @split = split(/[\/]+/,$DIRECTORY);
					my $RunNo = $split[$#split];
					$RunNo =~ s/run_//gi;
					
					$ResultTracking{$RunNo} = \@RESULTS;
				}
				$CombinationTracking{1} = \%ProcessedBaselineOptions;
				$ResultTracking{1} = \@BASELINE_RESULTS;
				
				printHash(\%CombinationTracking);
				printHash(\%ResultTracking);
				
				#===== sort results by performence/area/other metric including the baseline run.
				my @SortedRuns = sort{ @{$ResultTracking{$b}}[0] <=> @{$ResultTracking{$a}}[0]} (keys %ResultTracking);
				printOut("Sorted runs - ".join(", ",@SortedRuns)."\n");
				
				#===== choose the best result and modify the ModifiedBaselineOptions with the appropriate flag.
				my $BestCombination_HASHREF = $CombinationTracking{shift @SortedRuns};
				my %BestCombination = %{$BestCombination_HASHREF};
				my $BestFlag = $BestCombination{$TOOL}{$OPTION};
				#printOut("$TOOL, $OPTION, $BestFlag\n");
				$ModifiedBaselineOptions{$TOOL}{$OPTION} = $BestFlag;
			}
		}
		printOut("/n/nPRINTING FINAL OPTIONS per current permutation\n");
		printHash(\%ModifiedBaselineOptions);
#	}
}

#####################################################################
# Read the config file
# NOTE: publish the BE config file format
#
# * place the options in ascending order based on performance/area/other order
# * ex: par effort high med low
# 
# This function returns
# Baseline hash (contains the baseline options - one set of  options)
# Regular hash (contains the rest of options)
#####################################################################
sub readBEConfig{
	my ($VENDOR, $FAMILY) = @_;
	
	if(lc($VENDOR) eq "xilinx"){
		@SYNTHESIS_TOOLS = @XILINX_SYNTHESIS_TOOLS;
		@IMPLEMENTATION_TOOLS = @XILINX_IMPLEMENTATION_TOOLS;
	}
	elsif(lc($VENDOR) eq "altera"){
		@SYNTHESIS_TOOLS = @ALTERA_SYNTHESIS_TOOLS;
		@IMPLEMENTATION_TOOLS = @ALTERA_IMPLEMENTATION_TOOLS;
	}
	elsif(lc($VENDOR) eq "actel"){
		@SYNTHESIS_TOOLS = @ACTEL_SYNTHESIS_TOOLS;
		@IMPLEMENTATION_TOOLS = @ACTEL_IMPLEMENTATION_TOOLS;
	}
	# All tools var is set based on the synthesis tool form the config files
	#@ALLTOOLS = (@SYNTHESIS_TOOLS, @IMPLEMENTATION_TOOLS);
	
	#open file and load data
	my $CONFIG_FILE = "$CONFIG_DIR/batch.$EXHAUSTIVE_SEARCH_STRATEGY.txt";
	printOut("CONFIG_FILE		$CONFIG_FILE\n");
	@ConfigData = @{getProcessedText($CONFIG_FILE , "batch_elimination")};
	my $DATA = join("\n", @ConfigData);	
	
	#======= get the order of elimination based on tools
	if($DATA =~ m/$VENDOR    _RUN_ORDER\s*=\s*([(),\s\d\w.]+)/gi){
		print "$1\n";
	}
	# Get the performance margin
	if($DATA =~ m/PERFORMANCE_MARGIN\s*=\s*([(),\s\d\w.]+)/gi){
		print "$1\n";
	}
	
	my ($NoOfRuns, $BaselineOption_HASHREF, $GeneralOption_HASHREF, $SynthesisTool_HASHREF) = loadOpts($VENDOR, $FAMILY, @ConfigData);
	
	printOut("==================================================\n");
	printOut("No of runs : (baseline run) + [for each tool (# of flags - 1)] \n");
	printOut("No of runs : $NoOfRuns\n");
	printOut("==================================================\n");
	
	printLocalProgress("Number of Runs (formula) : (baseline run) + [for each tool (# of flags - 1)] \n");
	printLocalProgress("TOTAL NUMBER OF RUNS : $NoOfRuns\n");
	
	print("TOTAL NUMBER OF RUNS : $NoOfRuns\n");
	return $BaselineOption_HASHREF, $GeneralOption_HASHREF, $SynthesisTool_HASHREF;
}

#####################################################################
# Parses the options for the data
#####################################################################
sub loadOpts{
	my ($VENDOR, $FAMILY, @optdata) = @_;
	my %GENERAL_OPT_HASH = ();
	my %BASELINE_OPT_HASH = ();
	my %SYNTHESIS_TOOL_HASH = ();
	my $NoOfRuns = 1;
	
	my $size = $#optdata;
	my $i = 0;
	for($i=0;$i<$size;$i++){
		
		#skip all the # signs in the options
		my $substring = substr $optdata[$i], 0, 1;
		next if($substring =~ /#/);
		
		my $VENDOR_START_STR = $VENDOR."_OPTIONS_BEGIN";
		my $VENDOR_END_STR = $VENDOR."_OPTIONS_END";
		
		if($optdata[$i] =~ m/${VENDOR_START_STR}/gi){
			my $VendorDone = 0; #0 = false, 1=true
			while ($VendorDone == 0){
				$i++;
				my $substring = substr $optdata[$i], 0, 1;
				if($optdata[$i] =~ m/${VENDOR_END_STR}/gi){
					$VendorDone = 1;
				}
				elsif($substring =~ /[\s\\\\-_\/#]+/){}
				else{
					#============== READ options for the level,vendor ==============#
					my $TOOL = $VENDOR."_SYNTHESIS_TOOL";
					if($optdata[$i] =~ m/${TOOL}\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
						my $SYNTHESIS_TOOL = $1;
						#printOut("SYNTHESIS_TOOL				 $SYNTHESIS_TOOL\n");
						$SYNTHESIS_TOOL_HASH{$VENDOR} = $SYNTHESIS_TOOL;
						
						#remove the other synthesis tools from @ALLTOOLS
						@ALLTOOLS = ($SYNTHESIS_TOOL, @IMPLEMENTATION_TOOLS);
					}
					
					foreach my $T (@ALLTOOLS){
						my $TOOL = $T;
						$TOOL = uc($TOOL);
						my %TOOL_HASH = ();
						my $TOOL_STR = $VENDOR."_".$TOOL."_OPT";
						if($optdata[$i] =~ m/${TOOL_STR}\s*=/gi){
							my $toolDone = 0;
							while ($toolDone == 0){
								$i++;
								my $substring = substr $optdata[$i], 0, 1;
								if(($optdata[$i] =~ /END[\s^\w]*OPT/i)){
									$toolDone = 1;
								}
								elsif($substring =~ /[\s\\\\-_\/#]+/){}
								else{
									my ($OPTION, @FLAGS, @OPTS);
									
									#======= ignore - symbols
									$optdata[$i] =~ s/[-]+//;
									@OPTS = split(/[\s-=,]+/,$optdata[$i]);
									
									#======= Get the option and flags
									$OPTION = shift(@OPTS);
									@FLAGS = (@OPTS);
									#printOut("TOOL: $TOOL		OPTION: $OPTION		FLAGS: ".join("-",@FLAGS)."\n");
									
									
									#======= HANDLE VIRTEX5, SPARTAN6 and VIRTEX6
									$TOOL = "MAP" if((lc($TOOL) eq "par") and (lc($FAMILY) eq "virtex5") and ($LEVEL == 2));
									
									#======= you can check for specific options here.
									if(lc($OPTION) eq "xilinx_costtable_values"){
										$OPTION = "t";
										my @CTV = parse_CostTableVals(join("",@OPTS));
										@FLAGS = (@CTV);
										#printOut join("-",@FLAGS)."\n");
									}
									elsif(lc($OPTION) eq "altera_seed_values"){
										$OPTION = "SEED";
										my @CTV = parse_CostTableVals(join("",@OPTS));
										@FLAGS = (@CTV);
										#printOut join("-",@FLAGS)."\n");
									}
									else{
										#($$OPTION, @FLAGS) = translateOptions($VENDOR, $FAMILY, $TOOL, $OPTION, @GUI_FLAGS);
									}
									
									#keep track of no of options
									$NoOfRuns += ($#FLAGS); # technically $flags - 1, but perl arrays have -1 start value
									#print "$TOOL, $OPTION, $#FLAGS \n";
									
									# Case conversion for flags
									if(lc($VENDOR) eq "xilinx"){
										$OPTION = lc($OPTION);
										@FLAGS = map(lc($_),@FLAGS);
									}
									elsif(lc($VENDOR) eq "altera"){
										$OPTION = uc($OPTION);
										@FLAGS = map(uc($_),@FLAGS);
									}
									elsif(lc($VENDOR) eq "actel"){
										print "EXHAUSTIVE - VENDOR not supported";
									}
									
									#Push the flags
									#$OPT_HASH{$TOOL}{$OPTION} = \@FLAGS;
									my @FLAG = shift @FLAGS;
									$BASELINE_OPT_HASH {$TOOL}{$OPTION} = \@FLAG;
									$GENERAL_OPT_HASH {$TOOL}{$OPTION} = \@FLAGS;
								}
							}
						}
					}								
				}
			}
		}
	}
	return $NoOfRuns, \%BASELINE_OPT_HASH, \%GENERAL_OPT_HASH, \%SYNTHESIS_TOOL_HASH;
}


#####################################################################
# parces CosttableValues
#####################################################################
sub parse_CostTableVals{
	my $data = $_[0];
		
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
	@RETURN_VALS = sort{$a <=> $b} @RETURN_VALS;
	
	return @RETURN_VALS;
}

#####################################################################
# Creates Combinations for the flags
#####################################################################
sub formCombinations{
	my ($ModifiedBaseline_HASHREF, $TOOL, $OPTION, @FLAGS) = @_;
	my @COMBINATIONS;
	
	foreach my $FLAG (@FLAGS){
		my $NewBaseline_HASHREF = dclone($ModifiedBaseline_HASHREF);
		my %NewBaseline = %{$NewBaseline_HASHREF};
		
		$NewBaseline{$TOOL}{$OPTION} = $FLAG;
		#printHash(\%NewBaseline);
		push (@COMBINATIONS, \%NewBaseline);
	}
	return \@COMBINATIONS;
}

#####################################################################
# Modifies the options
#####################################################################
sub modify_options{
	my ($DEV_REF, $HASH_REF) = @_;
	my $DEVICE = $$DEV_REF;
	my %COMBO_HASH = %{$HASH_REF};
	my $VENDOR = $DEVICE->getVendor();
	
	#print("\nmodify_options ======================================BEGIN \n");
	#$DEVICE->printOpts();
	foreach my $TOOL (@ALLTOOLS){
		my %TOOL_HASH = %{$COMBO_HASH{$TOOL}};
		my @OPTLIST = (keys %TOOL_HASH);
		foreach $OPT (@OPTLIST){
			my $FLAG = $TOOL_HASH{$OPT};
			$DEVICE->deleteToolOpt($VENDOR, $TOOL, $OPT);
			$DEVICE->addOpt($VENDOR, $TOOL, $OPT, $FLAG);
		}
	}
	#printOut($DEVICE->printOpts());
	#print("modify_options ======================================END \n\n");
}

#####################################################################
# Permutations
#####################################################################
sub permutations {
    return !@_ ? [] : map{
        my $next = $_;
        map{
            [ $_[ $next ], @$_ ]
        } permutations( @_[ 0 .. $_-1, $_+1 .. $#_ ] );
    } 0 .. $#_;
}


































1;