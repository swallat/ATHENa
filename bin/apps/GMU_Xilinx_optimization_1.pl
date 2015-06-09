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
# APPLICATION: GMU_Xilinx_optimization_1
# Version: 0.1
# - General Implementation under the assumption that the user has entered everything correctly.
# - No "idiot checks"
#
# 
# Frequency search - performs a basic run (with default or user specifed frequency), then we add our requests 
# The current version doesnot fully support multicore operation. 
# Currently this is only xilinx compatable.
#
# For more details about the algorithm please refer to the documentation
#####################################################################

my $APPLICATION_NAME = "GMU_Xilinx_optimization_1";

my $maxFreq = 0.0;
my $maxRatio = 0.0;
my $bestStrat = "";
my $max_cost_table;
#####################################################################
# application function
#####################################################################
sub application{
	printOut("\nRunning application : GMU XILINX OPTIMIZATION 1\n");
	printLocalProgress("Application : GMU XILINX OPTIMIZATION 1\n");
	my ($VENDOR, $FAMILY, $DEVICE);
	
	$VENDOR = uc($DEV_OBJ->getVendor());
	$FAMILY = uc($DEV_OBJ->getFamily());
	$DEVICE = uc($DEV_OBJ->getDevice());

	#===== Variables for the runs
	my (@ReqFreqSteps, $Improvement, $CurrentFreq, $NextReqFreq, $ReqFreq, $PlacementSteps, $ClkNet);
	@ReqFreqSteps = (5, 25, 2);
	$PlacementSteps = 5;
	my (@DIRECTORY_LIST);
	my $RUNNO = 1;
	
	#===== Open file and load data
	my $CONFIG_FILE = "$CONFIG_DIR/GMU_Xilinx_optimization_1.txt";
	printOut("CONFIG_FILE		$CONFIG_FILE\n");
	@ConfigData = @{getProcessedText($CONFIG_FILE , "GMU_Xilinx_optimization_1")};
	my $DATA = join("\n", @ConfigData);	
	
	if($DATA =~ m/REQUESTED_FREQ_IMPROVEMENT_STEPS\s*=\s*([\d ,%]+)/gi){
		#print "$1\n";
		my $var = $1;
		$var =~ s/%//gi;
		my @split = split(/[, ]+/,$var);
		@ReqFreqSteps = @split;
	}

	if($DATA =~ m/PLACEMENT_STEPS\s*=\s*([\d]+)/gi){
		#print "$1\n";
		$PlacementSteps = $1;
	}
	#===== calculate loop increment
	my $loop_inc;
	if(lc($VENDOR) eq "xilinx"){		
		$max_cost_table = 100;
		$loop_inc = int($max_cost_table/$PlacementSteps);
	} elsif (lc($VENDOR) eq "altera"){
		$max_cost_table = 2**32-1;
		$loop_inc = int($max_cost_table/$PlacementSteps);
	} else {
		print "This application is not supporting this vendor --> $VENDOR.\n";
		exit;
	}
	
	#=== Get Clock Net name
	my $CONFIG_FILE = "$CONFIG_DIR/$DESIGN_CONFIGURATION_FILE_NAME";
	@ConfigData = @{getProcessedText($CONFIG_FILE , $DESIGN_CONFIGURATION_FILE_NAME)};
	my $DATA = join("\n", @ConfigData);
	if($DATA =~ /$REGEX_CLOCK_NET_EXTRACT/){
		#print "$1\n";
		$ClkNet = $1;
	}
	
	#==============================================================================
	#===== Performs AREA optimized single run --> and get the best TP/A (AREA)
	my $NEWDEV_OBJ = dclone($DEV_OBJ);
	my $current_strat = "area";
	$NEWDEV_OBJ->setRunNo($RUNNO);
	$RUNNO++;
	$NEWDEV_OBJ->setDispatchType($DISPATCH_TYPE_NONE);
	$NEWDEV_OBJ->setLocalApplication("single_run");	
	$NEWDEV_OBJ->setOptimizationStrategy($current_strat);		
	my $deviceDir = dispatchDevice(\$NEWDEV_OBJ);
	push(@DIRECTORY_LIST,$deviceDir);

	# Execute
	printOut("\nExecuting baseline run...\n");
	my %RunHash = (
		vendor => "$VENDOR",
		title => "GMU_Xilinx_optimization_1 - AREA Optimized",
		directories => \@DIRECTORY_LIST,
		requested_frequency => 0,
		run_all_options => "yes",
		max_runs => $maxSimultaneousRuns,
    );
	&ExecuteScripts(\%RunHash);
	
	# Read the achieved freq
	my $dir = shift @DIRECTORY_LIST;
	my @DEFAULT_RESULTS = extract_perf_results($VENDOR, "", "",$dir, $ClkNet);
	my $freq = @DEFAULT_RESULTS[0];	
	# Read the achieved area
	my %hash_result = %{extract_util_results($VENDOR, "", "", $dir)};
	my $area = &getArea(\%hash_result, $VENDOR);	
	&maxRatio($freq,$area,$current_strat);	
	
	
	#==============================================================================
	#===== Performs SPEED optimized single run --> and get the best TP/A
	my $NEWDEV_OBJ = dclone($DEV_OBJ);
	my $current_strat = "speed";
	$NEWDEV_OBJ->setRunNo($RUNNO);
	$RUNNO++;
	$NEWDEV_OBJ->setDispatchType($DISPATCH_TYPE_NONE);
	$NEWDEV_OBJ->setLocalApplication("single_run");
	$NEWDEV_OBJ->setOptimizationStrategy($current_strat);	
	my $deviceDir = dispatchDevice(\$NEWDEV_OBJ);
	push(@DIRECTORY_LIST,$deviceDir);
	
	# Execute
	printOut("\nExecuting baseline run...\n");
	my %RunHash = (
		vendor => "$VENDOR",
		title => "GMU_Xilinx_optimization_1 - Speed Optimized",
		directories => \@DIRECTORY_LIST,
		requested_frequency => 0,
		run_all_options => "yes",
		max_runs => $maxSimultaneousRuns,
    );
	&ExecuteScripts(\%RunHash);
	
	# Read the achieved freq
	my $dir = shift @DIRECTORY_LIST;
	my @DEFAULT_RESULTS = extract_perf_results($VENDOR, "", "",$dir, $ClkNet);
	my $freq = @DEFAULT_RESULTS[0];	
	# Read the achieved area
	my %hash_result = %{extract_util_results($VENDOR, "", "", $dir)};
	my $area = &getArea(\%hash_result, $VENDOR);	
	&maxRatio($freq,$area,$current_strat);	
	#==============================================================================
	#===== Performs BALANCED optimized single run --> and get the best TP/A
	my $NEWDEV_OBJ = dclone($DEV_OBJ);
	my $current_strat = "balanced";
	$NEWDEV_OBJ->setRunNo($RUNNO);
	$RUNNO++;
	$NEWDEV_OBJ->setDispatchType($DISPATCH_TYPE_NONE);
	$NEWDEV_OBJ->setLocalApplication("single_run");
	$NEWDEV_OBJ->setOptimizationStrategy($current_strat);
	my $deviceDir = dispatchDevice(\$NEWDEV_OBJ);
	push(@DIRECTORY_LIST,$deviceDir);
	
	# Execute
	printOut("\nExecuting baseline run...\n");
	my %RunHash = (
		vendor => "$VENDOR",
		title => "GMU_Xilinx_optimization_1 - Balanced Optimized",
		directories => \@DIRECTORY_LIST,
		requested_frequency => 0,
		run_all_options => "yes",
		max_runs => $maxSimultaneousRuns,
    );
	&ExecuteScripts(\%RunHash);
	
	# Read the achieved freq
	my $dir = shift @DIRECTORY_LIST;
	my @DEFAULT_RESULTS = extract_perf_results($VENDOR, "", "",$dir, $ClkNet);
	my $freq = @DEFAULT_RESULTS[0];	
	# Read the achieved area
	my %hash_result = %{extract_util_results($VENDOR, "", "", $dir)};
	my $area = &getArea(\%hash_result, $VENDOR);	
	&maxRatio($freq,$area,$current_strat);	
	#==============================================================================	
	
	# Force the following steps to select the optimization strategy that gives the best ratio
	$DEV_OBJ->setOptimizationStrategy($bestStrat);
	
	
	# print "\n$bestStrat\n\n";
	# system( pause );
	
	# ================================== 
	# Req new freq (loop)
	# ================================== 
	
	$Improvement = $ReqFreqSteps[0]; #shift @ReqFreqSteps; <== keep the first value for future loop
	$CurrentFreq = $DEFAULT_RESULTS[0];
	printOut("CurrentFreq \t $CurrentFreq \n");
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
		
		# Execute
		printOut("\nExecuting $Improvement % request run...\n");
		my %RunHash = (
			vendor => "$VENDOR",
			title => "GMU_Xilinx_optimization_1 - $Improvement % improvement",
			directories => \@DIRECTORY_LIST,
			requested_frequency => 0,
			run_all_options => "yes",
			max_runs => $maxSimultaneousRuns,
		);
		&ExecuteScripts(\%RunHash);
		
		# Gather Reqults
		my @RESULTS = extract_perf_results($VENDOR, "", "", shift @DIRECTORY_LIST, $ClkNet);
		$CurrentFreq = $RESULTS[0];
		&maxFreq($CurrentFreq);
		printOut("Achieved freq ".$CurrentFreq."\n");
		
		if($CurrentFreq >= $ReqFreq)
		{
			#pass
			printOut("PASS\n");
			$NextReqFreq = ($Improvement/100) * $maxFreq + $maxFreq;
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

	# ================================== 
	# Req new freq (high effort) (only for xilinx?)
	# ================================== 
	if(lc($VENDOR) eq "xilinx"){
	
		my $NEWDEV_OBJ = dclone($DEV_OBJ);
		$NEWDEV_OBJ->setRunNo($RUNNO);
		$RUNNO++;
		$NEWDEV_OBJ->setDispatchType($DISPATCH_TYPE_NONE);
		$NEWDEV_OBJ->setLocalApplication("single_run");
		$NEWDEV_OBJ->setRequestedFreqs($ReqFreq, $ReqFreq);
		
		$NEWDEV_OBJ->deleteToolOpt($VENDOR, "PAR", "ol");
		$NEWDEV_OBJ->addOpt($VENDOR, "PAR", "ol", "high");
		
		my $deviceDir = dispatchDevice(\$NEWDEV_OBJ);
		push(@DIRECTORY_LIST,$deviceDir);
		
		# Execute
		printOut("\nExecuting $Improvement % request high effort run...\n");
		my %RunHash = (
			vendor => "$VENDOR",
			title => "GMU_Xilinx_optimization_1 - $Improvement % improvement high effort",
			directories => \@DIRECTORY_LIST,
			requested_frequency => 0,
			run_all_options => "yes",
			max_runs => $maxSimultaneousRuns,
		);
		&ExecuteScripts(\%RunHash);
		
		# Gather Reqults
		my @RESULTS = extract_perf_results($VENDOR, "", "", shift @DIRECTORY_LIST, $ClkNet);
		&maxFreq($RESULTS[0]);
		printOut("Achieved freq ".$CurrentFreq."\n");
		
		if($CurrentFreq >= $ReqFreq)
		{
			#pass
			printOut("PASS with high effort\n");
			$pass = "true";
			$NextReqFreq = ($Improvement/100) * $CurrentFreq + $CurrentFreq;
			printOut("NextReqFreq \t $NextReqFreq \n");
			$ReqFreq = $NextReqFreq;
		}
		else
		{
			#fail
			printOut("FAIL with high effort\n");
			$pass = "false";
		}
	}
	
	# ================================== 
	# Costtable iterations
	# ================================== 
	printOut("No of placement starting points \t $PlacementSteps \n");
	foreach my $Improvement (@ReqFreqSteps){
		printOut("\n\nCurrently processing Improvement \t $Improvement % \n");
		
		$CurrentFreq = $maxFreq;
		$NextReqFreq = ($Improvement/100) * $maxFreq + $maxFreq;
		printOut("NextReqFreq \t $NextReqFreq \n");
		$ReqFreq = $NextReqFreq;
		
		
		printOut("PlacementSteps = $PlacementSteps, loop increment = $loop_inc \n");
		
		while($pass eq "true"){
			printOut("outerloop - requesting $ReqFreq Mhz\n");
			
			# Take advantage of multicore
			@DIRECTORY_LIST = ();
			my $i = int($loop_inc/2);
			while($i<$max_cost_table){
				printOut("-----dispatching - $i\n");
				
				#dispatch device
				my $NEWDEV_OBJ = dclone($DEV_OBJ);
				$NEWDEV_OBJ->setRunNo($RUNNO);
				$RUNNO++;
				$NEWDEV_OBJ->setDispatchType($DISPATCH_TYPE_NONE);
				$NEWDEV_OBJ->setLocalApplication("single_run");
				$NEWDEV_OBJ->setRequestedFreqs($ReqFreq, $ReqFreq);
				if(lc($VENDOR) eq "xilinx"){
					$NEWDEV_OBJ->addOpt($VENDOR, "PAR", "ol", "high");
				}
				$NEWDEV_OBJ->setPlacementLocation( $i );				
				
				my $deviceDir = dispatchDevice(\$NEWDEV_OBJ);
				push(@DIRECTORY_LIST,$deviceDir);
				
				$i += $loop_inc;
			}
			
			# Execute
			printOut("\nExecuting $Improvement % request costtable runs...\n");
			my %RunHash = (
				vendor => "$VENDOR",
				title => "GMU_Xilinx_optimization_1 - $Improvement % improvement cost table",
				directories => \@DIRECTORY_LIST,
				requested_frequency => $ReqFreq,
				run_all_options => "no",
				max_runs => $maxSimultaneousRuns,
			);
			&ExecuteScripts(\%RunHash);
			
			# Extract Results and compare them
			foreach my $DIRECTORY (@DIRECTORY_LIST){
				my @RESULTS = extract_perf_results($VENDOR, "", "", $DIRECTORY, $ClkNet);
				printOut("\n $DIRECTORY \n Achieved freq ".$RESULTS[0]."\n");
				&maxFreq($RESULTS[0]);
				
				if($CurrentFreq >= $ReqFreq){
					printOut("pass");
					$pass = "true";
					last;
				}
				else{
					printOut("Fail");
					$pass = "false";
				}
			}
			
			if(lc($pass) eq "true"){
				$NextReqFreq = ($Improvement/100) * $maxFreq + $maxFreq;
				printOut("NextReqFreq \t $NextReqFreq \n");
				$ReqFreq = $NextReqFreq;
			}
		}
		
		# Consider the pass value from before the loop
		$pass = "true";
	}
	printOut("\n\nCurrently Achieved maximum frequency : $maxFreq \n\n");
}


#####################################################################
# Maintains the currently Achieved maximum frequency
#####################################################################
sub maxFreq{
	my $Freq = $_[0];
	if($Freq > $maxFreq){ $maxFreq = $Freq; }
}

#####################################################################
# Maintains the currently Achieved maximum ratio
#####################################################################
sub maxRatio{
	my ($freq,$area,$current_strat) = @_;
	my $Ratio = $freq/$area;	
	
	if($Ratio > $maxRatio){ 
		$maxRatio = $Ratio; $maxFreq = $freq;
		$bestStrat = $current_strat;
	}	
}

sub getArea{
	my %result = %{shift()};
	my $vendor = shift;
	my $area;
	if ( $vendor =~ /xilinx/i ) {
		$area = $result{$XILINX_DEVICE_ITEMS[0]}; #slice		
	} elsif ( $vendor =~ /altera/i ) {
		$area = $result{$ALTERA_DEVICE_ITEMS[0]}; # LE
		if ($area == 0 ) {
			$area = $result{$ALTERA_DEVICE_ITEMS[1]}; #COMBALUT
		}
	} else {
		print "Invalid vendor for getArea function!!\n";
		exit;
	}
	
	
	return $area;
}











1;