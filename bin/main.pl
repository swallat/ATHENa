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
# Main script
# Version: 0.7
# 
# -This script will generate other scripts based on user options
#####################################################################

use Cwd;
use File::Copy;
use Storable qw(retrieve dclone);
#use warnings;

#$ATHENA_VERSION = x.x.x;
$CONTEXT = "parent";
$TITLE = "ATHENA MAIN";

#####################################################################
# Folder names and other info
#####################################################################
$BIN_DIR_NAME = "bin";
$CONFIG_DIR_NAME = "config";
$TEMP_DIR_NAME = "temp";

$ROOT_DIR = "";
$BIN_DIR = "";
$WORKSPACE = "";
$CONFIG_DIR = "";
$TEMP_DIR = "";
$SIM_DIR = "";

#$DESIGN_CONFIGURATION_FILE = "";

#print "Number of processor cores to use : $maxSimultaneousRuns\n";
#No of processor cores to use for athena
	
#####################################################################
# Initialization
#####################################################################
sub init(){
	#acquire root dir
	$ROOT_DIR = getcwd;
	$ROOT_DIR =~ s/\/$BIN_DIR_NAME$//;
	
	$BIN_DIR = "$ROOT_DIR/$BIN_DIR_NAME";
	$CONFIG_DIR = "$ROOT_DIR/$CONFIG_DIR_NAME";
	
	#load necessary files
	require "$BIN_DIR/regex.pl";
	require "$BIN_DIR/support.pl";
	require "$BIN_DIR/print_support.pl";
	
	
	
	#load the rest of the files
	use Structs;
	use Device;
	require "$BIN_DIR/constants.pl";
	require "$BIN_DIR/globals.pl";
	require "$BIN_DIR/config.pl";
	require "$BIN_DIR/device_lib.pl";
	require "$BIN_DIR/option_lib.pl";
	require "$BIN_DIR/run_support.pl";
	
	require "$BIN_DIR/tool_support.pl";
	require "$BIN_DIR/verification_functions/verification.pl";	
	require "$BIN_DIR/verification_functions/modelsim.pl";	
	require "$BIN_DIR/verification_functions/aldec.pl";	
	
	$maxSimultaneousRuns = get_coreinfo_from_data_file("max_usage");
}

#####################################################################
# Main function
# Do not change the order of functions in the script
#####################################################################
sub run{
	#local variables: List of dispatched folders
	local( @DIRECTORY_LIST = (), @vendor_list = () );
	
	# read design config
	my %generics = %{read_DesignConfig()};	
	############################
	#determine workspace folder
	configureWorkspace();	
	# Note the log start time;
	$CMD_LOG_FILE = "$WORKSPACE/$CMD_LOG_FILE_NAME";
	$PROGRESS_LOG_FILE = "$WORKSPACE/$PROGRESS_LOG_FILE_NAME";
	my $output;
		$output .= "\n"; map($output .= "=",(0..length($start))); $output .= "\n";
		$output .= "Log started at ".currentTime()."\n";
		$output .= "\n"; map($output .= "=",(0..length($start))); $output .= "\n";
		printOut($output);
	
	#config folder
	$OLDCONFIG_DIR = "$ROOT_DIR/$CONFIG_DIR_NAME";
	$NEWCONFIG_DIR = "$WORKSPACE/$CONFIG_DIR_NAME";
	$CONFIG_DIR = $NEWCONFIG_DIR;
	#copy the config files to local config folder
	&create_dir($NEWCONFIG_DIR);
	&copy_recursively("$OLDCONFIG_DIR", "$NEWCONFIG_DIR");
	############################
	# determine list of vendors
	@vendor_list = (keys %requested_devices);
	# load device library files based on tool version and installation type
	# this copies the appripriate libs to the workspace config directory
	&ConfigureDevLib(@vendor_list);
	#load device library (for error checking)
	&loadDevLib(@vendor_list);
	# Design config error check	
	&ErrCheck();

	#########################
	# Functional simulation #
	#########################
	my $str; my $test_result;	
	if ( $FUNCTIONAL_VERIFICATION_MODE =~ m/on/i ) {	
		# Create directory
			my $tempcurdir = cwd;		
			$SIM_DIR = "$WORKSPACE/sim";
			&create_dir($SIM_DIR);
		# move to created directory
			chdir($SIM_DIR);
		# Copy test vector files to verification workspace ($SIM_DIR)
			my @DEST_FILES = ();
			if ( $TEST_VECTORS_LIST_FILE ne "" ) {		
				for ( my $i = 0; $i < scalar@TEST_VECTORS_FILES; $i++ ) {
					my $destfile = $SIM_DIR."\/".$TEST_VECTORS_FILES[$i]; 
					my $file = $VERIFICATION_DIR."\/".$TEST_VECTORS_FILES[$i]; 				
					if ( $^O =~ m/$REGEX_OS_WINDOWS/i ) { #windows
						$destfile =~ s/\//\\/g; $file =~ s/\//\\/g; 					
						system( "copy \"$file\" \"$destfile\"");
					}
					push(@DEST_FILES, $destfile);
				}			
			}
		# Performing simulation
			$str = "Performing functional simulation...";		
			$test_result = verify($vendor_list[0], "functional");
		# delete copied test vectors
			foreach my $file ( @DEST_FILES ) {
				if ( $^O =~ m/$REGEX_OS_WINDOWS/i ) { #windows
					$file =~ s/\//\\/g; 
					system( "del \"$file\"" );
				}
			}
		# move back to original dir
			chdir($tempcurdir);				
		# pass or fail?
		if ($test_result == 0 ) { 
			$str .= "[PASS]\n"; printOut("$str"); 
		} else { 
			$str .= "[Fail]\n"; printOut("$str"); 
			$VERIFICATION_ONLY = "on"; #force verification only to turn on as verification failed
		}		
	}	

	# End the program if verification only
	if ( $VERIFICATION_ONLY =~ m/on/i ) { 
		if ( $test_result eq 0) { printLogToScreen( "\n\tYour design is functionally well!\n"); }
		else { 
			printLogToScreen( "\n\tFunctional verification [FAIL]."); 

			printLogToScreen( "\n\tFunctional verification can fail due to the following reasons :");
			printLogToScreen( "\n\tno verification output file, unspecified stop point, not enough run time, or");
			printLogToScreen( "\n\tyour simulator license doesn't support batch mode.");
			printLogToScreen( "\n\tPlease refer to the generated \'transcript\' or \'waveform\' located in ==>\n\t$SIM_DIR\n");
		}
		exit; 		
	} 
	
	
	
	
	# read options
	my ($hashref, $synthesisToolref) = readOpts();
	

	
	#############################################
	#### dispatch scipts                      ###
	#############################################
	my $total_runs = 0;
	foreach $vendor ( @vendor_list ) {
		my @device_list = @{$requested_devices{$vendor}};
		foreach $devStruct ( @device_list ){			
			my @combinations = @{&getGenericsInfo(\%generics, $devStruct->getVendor(), $devStruct->getFamily() )};
			if ($#combinations >= 0 ) {
				$total_runs = $total_runs + ($#combinations + 1);
			} else {
				$total_runs = $total_runs + 1;
			}
		}
	}
	
	print "Total number of runs : $total_runs \nMaximum simultaneous runs allowed: $maxSimultaneousRuns\n";
	my @maxRuns = getMaxRunVals($total_runs, $maxSimultaneousRuns) if($total_runs > 0);
	
	printOut("\nDispatching devices...\n");
	foreach $vendor ( @vendor_list ) {
		my @device_list = @{$requested_devices{$vendor}};
		foreach $devStruct ( @device_list ){
			my $device = $devStruct->getDevice();
			my $family = $devStruct->getFamily();
			
			printOut("Processing : ". $devStruct->getVendor()." - ".$family." - ".$device ."\n");
			
			$devStruct->setRootDir($ROOT_DIR);
			$devStruct->setWorkspaceDir($WORKSPACE);
			$devStruct->setMaxRuns(shift @maxRuns);
			
			
			$dispatch_type = $device;
			$dispatch_type = $DISPATCH_TYPE_NONE unless (($device eq $DISPATCH_TYPE_BEST_MATCH) or ($device eq $DISPATCH_TYPE_ALL));
			
			$devStruct->setDispatchType($dispatch_type);			
			$devStruct->setLocalApplication($APPLICATION);			
			$devStruct->setAllOpts($vendor,$hashref);
			$devStruct->setSynthesisTool($synthesisToolref);
			$devStruct->setTrimMode($TRIM_MODE);
			
			#&printGenerics( \%generics );
			my @combinations = @{&getGenericsInfo(\%generics, $vendor, $family )};
			
			my $generic_id = 1;
			if ($#combinations >= 0 ) {
				foreach $generic ( @combinations ) {					
					my $newdevice = dclone($devStruct);
					$newdevice->setGenericID($generic_id);				
					$newdevice->setGenericValue($generic);		
					$generic_id++;
					my $deviceDir = dispatchDevice(\$newdevice);
					push(@DIRECTORY_LIST,$deviceDir);
				} 			
            } else {
				$devStruct->setGenericID($generic_id);
				$devStruct->setGenericValue("default");
				my $deviceDir = dispatchDevice(\$devStruct);
				push(@DIRECTORY_LIST,$deviceDir);
			}		
		}
	}

	#EXECUTE the scripts
	printOut("\nExecuting dispatched scripts...\n");
	my %RunHash = (
		title => "Athena - Main",
		directories => \@DIRECTORY_LIST,
		requested_frequency => 0,
		run_all_options => "yes",
		max_runs => $maxSimultaneousRuns,
	);
	&ExecuteScripts(\%RunHash);
		
	#Generate reports
	REPORT_GEN:
	printOut ("\n\nGENERATING REPORT ...\n");
	#printOut ("\"$REPORT_SCRIPT\" \"$WORKSPACE\" display\n");
	system("\"$REPORT_SCRIPT\" \"$WORKSPACE\" both");
    
    if ( $DB_QUERY_MODE !~ /^off$/i ) {
        chdir ( $ROOT_DIR );
        system("\"$DB_REPORT_GENERATOR\" \"$WORKSPACE\" $DB_QUERY_MODE $DB_CRITERIA");
    }
}

#####################################################################
# Execution starts here
#####################################################################
$start_time = time();
#$NOPAUSE = "off";
#if (@ARGV[0] =~ /nopause/i ) {
#	$NOPAUSE = "on";
#}

# Initialize 
&init();

# Call main script
&run();

my $elapsed_time = elapsed_time($start_time);
printOut("Elapsed time: $elapsed_time\n");

#if ( $NOPAUSE =~ /off/i ) {
#	system( pause );
#}
