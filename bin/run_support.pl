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
# Run support script
# Version: 0.1
# 
# Provides an framework for multicore operation
#####################################################################

use Thread;
#####################################################################
# Run function - thread function of operation
#####################################################################
sub executeRun{
	my ($directory) = @_;
	#print "directory = $directory\n\n";
	$directory =~ s/\\/\//gi;
	$directory .= "\/" unless($directory =~ m/\/$/gi);
	#print "directory = $directory\n\n";
	my $script = $directory."run.sh";
	#my $script = $directory."dispatch.pl"; #<== wont work because it doesnot change the CWD, so devobject is not found.
	#print "\nscript== $script\n";
	#print "\n starting script run.sh\n";
	system ("chmod +x '$script'");
	if (system("\"$script\"") == 0)
	{
		#print "Called script..\n";
	}
	else
	{
		print"Could Not Execute run.sh..\n";

		}
}

#####################################################################
# Execute scripts - Dispatching multiple threads is handled here.
#####################################################################
sub ExecuteScripts{
	preserveProgress();
	
	my ($hash_ref) = @_;
	my (%arguments, $run_title, @temp, @directories, $requested_frequency, $run_all_options, $maxSimultaneousRuns, $SimultaneousRuns, $numOfRuns, %thread_hash);
	my ($TotalRuns);
	
	%arguments = %{$hash_ref};
	$run_title = $arguments{title};
	@runDirs = @{$arguments{directories}};
	@directories = @runDirs; #<== this is so we dont edit the array in the argument
	$requested_frequency = $arguments{requested_frequency};
	$run_all_options = $arguments{run_all_options};
	$maxSimultaneousRuns = $arguments{max_runs}; #<== Maximum simultaneous runs
	$maxSimultaneousRuns = 1 if ($maxSimultaneousRuns < 1); 
	
	#printOut "LIST OF DIRECTORIES FROM RUN_SUPPORT.pl ".join("\n",@directories)."\n";
	%thread_hash = (); #<==  $thread_hash{tid} = directory;	
	$numOfRuns = $#runDirs + 1;
	$TotalRuns = $#runDirs + 1;
	my $running = 0; #<== no of running threads
	my $runNo = 0; #<== run number - progress
	my @threads = (); #<== currently running threads
	
	$SimultaneousRuns = 0; #<== doesnt necessarly refelect actual runs, but only the SimultaneousRuns in this function
	my $Achieved_requested_frequency = $NO; #<== flag to stop executing new runs when the present one achieved the runs.
	my $maxDelay = 6; #<== minimum delay between checks
	
	printOut("============================================\n");
	printOut("Title: $run_title\n");
	printOut("Requested Stop Frequency: $requested_frequency\n") if($requested_frequency > 0);
	printOut("Run All Options: $run_all_options\n");
	printOut("Total number of runs : $TotalRuns\n");
	printOut("Max Simultaneous Runs : $maxSimultaneousRuns\n");
	printOut("============================================\n");
	
	printLocalProgress("\bTotal number of runs in the present context : $TotalRuns\n");
	
	while($numOfRuns > 0 or $#threads >= 0){				
		last if(($#threads < 0) and ($Achieved_requested_frequency == $YES));
		while(($running < $maxSimultaneousRuns) and ($numOfRuns > 0) and ($Achieved_requested_frequency == $NO)){
			$running++;
			$numOfRuns--;
			$runNo++;
			my $directory = shift @directories;
			my $t = threads->new(\&executeRun, $directory);
			my $tid = $t->tid;
			$thread_hash{$tid} = $directory;
			push(@threads, $t);
			
			my $file = "$directory/device.obj";
			my $ref = retrieve($file);
			my $dev = ${$ref};
			my $Nruns = $dev->getMaxRuns();
			$SimultaneousRuns += $Nruns;
		}
		
		# sleep for some time
		&GatherProgress(@runDirs);
		if (lc($CONTEXT) eq "parent"){					
			sleep($DELAY);				
			&DisplayProgress();
		} else {
			sleep(5);
		}				
		#printOut("Maximum sleep time allowed : $maxDelay secs\n") unless (lc($CONTEXT) eq "parent");
		
		# Display Progress
		
		
		# check thread progress
		my @running_threads = ();
		foreach my $thread (@threads){
			my $tid = $thread->tid;
			if($thread->is_joinable() eq 1){
				# Adjust necessary variables and join thread
				print "joining $tid\n";

				$thread->join();
				$running--;
				$SimultaneousRuns--;
				
				# Delete the thread information
				my $Directory = $thread_hash{$tid};
				delete $thread_hash{$tid};
				
				# Extract Log from directory
				&ReportLog($Directory);
				
				# Passively Nofity parent thread that the data is ready for screen update
				
				# Extract performance information when required
				if(lc($run_all_options) eq "no"){
					
					my ($FREQ, $PERIOD) = extract_perf_results($DEV_OBJ->getVendor(), "", "", $Directory);
					if($FREQ >= $requested_frequency){
						$Achieved_requested_frequency = $YES;
						printOut("Achieved the requested frequency $FREQ > $requested_frequency.\n");
						printLocalProgress("$run_title - Achieved the requested frequency ($FREQ) in this context. Stopping execution.\n");
					}
					else{
						printOut("DIDNOT achieve the requested frequency of $requested_frequency. Achieved = $FREQ \n");
					}
				}
				
				#run - post processing
				# checks
				# error logs
				# other info
				
				# we could do it here or at the end of dispatch.pl
			}
			else{
				push(@running_threads, $thread);
			}
		}
		@threads = @running_threads;
		
		# Assign cores (if all runs are executing and currently executing runs are smaller than the max allowed)
		if ((lc($CONTEXT) ne "parent") and (($#directories+1) > 0)){
			printOut("RUNS left to be executed ". ($#directories+1) ."\n");
			printOut("Currently executing runs : $running \n");
			printOut("Current Simultaneous Runs : $SimultaneousRuns \n");
		}

		if(($#directories+1 == 0) and ($SimultaneousRuns < $maxSimultaneousRuns) and ($running > 0)){
			
			printOut("\n");
			my $str = localtime;
			printOut($str."\n");
			printOut("Directories left to be executed ". ($#directories+1) ."\n");
			printOut("Currently executing runs : $running \n");
			printOut("Current Simultaneous Runs : $SimultaneousRuns \n");
			printOut("No of allowed cores : $maxSimultaneousRuns \n");
			printOut("\n");
			
			my $unusedCores = $maxSimultaneousRuns - $running;
			printOut("No of unused cores : $unusedCores\n");
			
			my @maxRuns = getMaxRunVals($#threads+1, $unusedCores);
			printOut("Maxruns : ".join(" - ", @maxRuns));
		
			foreach my $thread (@threads){
				my $tid = $thread->tid;
				my $Directory = $thread_hash{$tid};
				printOut("Assigning core to $Directory\n");
				my $runs = shift @maxRuns;
				$SimultaneousRuns += $runs;
				
				my $Aruns = getCoreUsageDir($Directory);
				&setCoreUsage($Directory, $runs+$Aruns);
			}
		}
		
		# Core Info
		my $Tcores = getCoreUsage();
		if($Tcores > $maxSimultaneousRuns){
			$maxSimultaneousRuns = $Tcores;
			printOut("Newly assigned cores $Tcores\n");
			printOut("Setting the maxSimultaneousRuns to $maxSimultaneousRuns\n");
		}
	}
	&GatherProgress(@runDirs);
	&DisplayProgress(1) if(lc($CONTEXT) eq "parent");
}

#####################################################################
# Displays the progress from different directories
#####################################################################
sub DisplayProgress{
	my $force = shift();
	open LOG, $PROGRESS_LOG_FILE;# or printOut("\nError reading global progress log file\n");
	my $output = join("", <LOG>);
	close LOG;
	
	my $elapsed_time = &elapsed_time($start_time);
	
	if (( $PREV_OUTPUT ne $output ) or ( $LAST_REFRESH > 120 ) or ($force == 1)){
		$PREV_OUTPUT = $output;		
		system(clear);
		print "\n Athena Progress : \t";				
		print "(Elapsed time : $elapsed_time)\n";		
		print "\tGathering Information \n\tPlease wait...\n" if (length($output) < 1);
		my @lines = split(/\n/,$output);
		my $new_delay = int($#lines/10);
		if ( $new_delay > $DELAY ) { $DELAY = $new_delay; }
		print $output;
		$LAST_REFRESH = 0;
	} else {
		$LAST_REFRESH = $LAST_REFRESH + $DELAY;
	}
}

#####################################################################
# Gathers the progress from the directories to write 
#####################################################################
sub GatherProgress{
	my (@Directories) = @_;
	my $output = "";

	foreach my $directory (@Directories){
		$output .= "\n"; map($output .= "=",(0..length($directory))); $output .= "\n";
		$output .= "$directory\n";
		
		my $logfile = "$directory/$LOCAL_TEMP_PROGRESS_LOG_FILE_NAME";
		open LOG, $logfile;
		my $out = join("\t",<LOG>);
		$output .= "\t$out" if(length($out) > 0);
		close LOG;
		
		$logfile = "$directory/$LOCAL_PROGRESS_LOG_FILE_NAME";
		open LOG, $logfile;
		$output .= "\t".join("\t", <LOG>);
		close LOG;
	}
	if (lc($CONTEXT) eq "parent"){
		printToLog($PROGRESS_LOG_FILE, $output, $OVERWRITE);
	}
	else{
		printToLog($LOCAL_PROGRESS_LOG_FILE_NAME, $output, $OVERWRITE);
	}
}

#####################################################################
# Grab the Report Log from the run directory
#####################################################################
sub ReportLog{
	my ($Directory) = @_;
	my $output = "";
	
	$output .= "\n"; map($output .= "=",(0..length($Directory))); $output .= "\n";
	$output .= "Acquiring the log from \n $Directory\n\n";

	my $logfile = "$Directory/$LOCAL_CMD_LOG_FILE_NAME";
	open LOG, $logfile;
	$output .= "\t".join("\t", <LOG>);
	close LOG;
	
	$output .= "\n"; map($output .= "=",(0..length($Directory))); $output .= "\n";
	
	if (lc($CONTEXT) eq "parent"){
		printToLog($CMD_LOG_FILE, $output, $APPEND);
	}
	else{
		printToLog($LOCAL_CMD_LOG_FILE_NAME, $output, $APPEND);
	}
}

#####################################################################
# Saves the assigned core info into a certain directory
#####################################################################
sub setCoreUsage{
	my ($directory, $cores) = @_;
	my $output = "";
	$output .= "CORES=$cores\n";
	my $logfile = "$directory/$LOCAL_RUN_INFO_FILE_NAME";
	printToLog($logfile, $output, $OVERWRITE);
}

#####################################################################
# Retrieves the assigned core info into a certain directory
#####################################################################
sub getCoreUsage{
	my $cores = -1;
	open LOG, $LOCAL_RUN_INFO_FILE_NAME; # or printOut("Warning: Cannot read the core usage file\n");
	my $input = join("", <LOG>);
	close LOG;
	
	if($input =~ m/CORES=([\d]+)/gi){
		$cores = $1;
	}
	return $cores;
	
	printToLog($LOCAL_RUN_INFO_FILE_NAME, "", $OVERWRITE);
}

#####################################################################
# Retrieves the assigned core info of a certain directory
#####################################################################
sub getCoreUsageDir{
	my ($directory) = @_;
	my $cores = -1;
	my $logfile = "$directory/$LOCAL_RUN_INFO_FILE_NAME";
	open LOG, $logfile; # or printOut("Warning: Cannot read the core usage file\n");
	my $input = join("", <LOG>);
	close LOG;
	
	if($input =~ m/CORES=([\d]+)/gi){
		$cores = $1;
	}
	
	my $file = "$directory/device.obj";
	my $ref = retrieve($file);
	my $dev = ${$ref};
	my $Ncores = $dev->getMaxRuns();
	
	return $cores if($cores > $Ncores);
	return $Ncores if($cores <= $Ncores);
}

#####################################################################
# Retrieves the assigned core info of a certain directory
#####################################################################
sub preserveProgress{
	# append the LOCAL_PROGRESS_LOG_FILE_NAME to LOCAL_TEMP_PROGRESS_LOG_FILE_NAME
	my $output = "";
	
	open LOG, $LOCAL_PROGRESS_LOG_FILE_NAME;
	$output = join("", <LOG>);
	close LOG;
	
	if(length($output)>0){
		printToLog($LOCAL_TEMP_PROGRESS_LOG_FILE_NAME, $output, $APPEND);
	}
}





1;