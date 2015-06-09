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
# Dispatch script
# Version: 0.7
# 
# -This script is dispatched by the main script
#####################################################################
use Cwd;
use Storable qw(retrieve dclone);
#use warnings;

#$ATHENA_VERSION = x.x.x;
$CONTEXT = "child";
$TITLE = "";

# Device structure to keep track of data;
$DEV_OBJ = ();

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

#####################################################################
# Global Vars for dispatch run
#####################################################################

$DISPATCH_TYPE = "";
$LOCAL_APPLICATION = "";
$OPTIONS_FILE = "";

$VENDOR = "";
$FAMILY = "";
$DEVICE = "";

$maxSimultaneousRuns = 1;

#####################################################################
# Global Vars for output
#####################################################################
$PREV_OUTPUT = "";
$DELAY = 5;
$LAST_REFRESH = 0;

#####################################################################
# Initialization
#####################################################################
sub init(){
	use Structs;
	use Device;
	
	my $ref = retrieve('device.obj');
	$DEV_OBJ = ${$ref};

	read_LocalConfig();
	$CONFIG_DIR = "$WORKSPACE/$CONFIG_DIR_NAME";
	$BIN_DIR = "$ROOT_DIR/$BIN_DIR_NAME";
	$TEMP_DIR = "$WORKSPACE/$TEMP_DIR_NAME";
	
	require "$BIN_DIR/regex.pl";	
	require "$BIN_DIR/support.pl";
	require "$BIN_DIR/print_support.pl";
	
	require "$BIN_DIR/report_extract.pl";
	require "$BIN_DIR/constants.pl";
	require "$BIN_DIR/globals.pl";
	require "$BIN_DIR/config.pl";
	require "$BIN_DIR/device_lib.pl";
	require "$BIN_DIR/option_lib.pl";
	require "$BIN_DIR/run_support.pl";
	require "$BIN_DIR/extract.pl";
	require "$BIN_DIR/extract_old.pl";
	require "$APPLICATION_DIR/api.pl";	
	require "$APPLICATION_DIR/api_support.pl";
	require "$APPLICATION_DIR/api_text_support.pl";	
}

#####################################################################
# Read the local config file
#####################################################################
sub read_LocalConfig(){
	$ROOT_DIR = $DEV_OBJ->getRootDir();
	$WORKSPACE = $DEV_OBJ->getWorkspaceDir();
	$DISPATCH_TYPE = $DEV_OBJ->getDispatchType();
	$LOCAL_APPLICATION = $DEV_OBJ->getLocalApplication();
	$VENDOR = $DEV_OBJ->getVendor();
	$FAMILY = $DEV_OBJ->getFamily();
	$DEVICE = $DEV_OBJ->getDevice();
	
	$maxSimultaneousRuns = $DEV_OBJ->getMaxRuns();
	#printOut("Number of processor cores to use : $maxSimultaneousRuns\n");

	#printOut(" $VENDOR - $FAMILY - $DEVICE \n");
	$TITLE = $DEVICE;
}

#####################################################################
# Main function
#####################################################################
sub run{
	#local variables: List of dispatched folders
	local( @vendor_list = () );
	
	#read design config
	read_DesignConfig();
	
	#determine list of vendors
	@vendor_list = (keys %requested_devices);
	
	#tool configuration - this could be done by the individual scripts
	my @tool_config_results = tool_config($VENDOR);
	printError("ERROR: An error occured during tool configuration. Refer to the error log for details. \nStopping the execution.\n\n", 1) unless ($tool_config_results[0] == 0);
	
	#load device library
	&loadDevLib($VENDOR);
	
	#check if source files in the source folder match the ones provided
	printError("ERROR: Dispatch - Source file mismatch! \n Please check the sources!\n", 1) unless(identify_sources("sources", $SOURCE_DIR, $SOURCE_LIST_FILE) == 0);
	
	my $db = "$ROOT_DIR/db";
    my $design_name = "$db/$PROJECT_NAME";
    my $design_rtl = "$design_name/design_rtl";

    printf "$db\n";
    printf "$design_name\n";
    printf "$design_rtl\n";

    mkdir $db;
    mkdir $design_name;
    mkdir $design_rtl;

    foreach $file (  @SOURCE_FILES ) {
		if ( $file =~ /.txt$|.v$|.vhd$|.vhdl$/i ) {
			$srcfile = "$SOURCE_DIR/$file";		
			$dstfile = "$design_rtl/$file";	
			printf "Copy file $srcfile to $dstfile\n";
			copy("$srcfile","$dstfile");
		}
	}
	$srcfile = "$SOURCE_LIST_FILE";
	$dstfile = "$design_rtl/source_list.txt";
	printf "Copy file $srcfile to $dstfile\n";
	copy("$srcfile","$dstfile");

	my $req1 = lc($VENDOR)."_synthesis.pl";
	my $req2 = lc($VENDOR)."_implementation.pl";
	my $req3 = "$LOCAL_APPLICATION.pl";
	require $GLOBAL_SYNTHESIS_SCRIPT_NAME;
	require $GLOBAL_IMPLEMENTATION_SCRIPT_NAME;
	require $SINGLE_RUN_SCRIPT;
	require $req1;
	require $req2;
	require $req3;
	
	my $print_once = 1;
	# Modify Options - If utilization is set to 0, then modify the options so the tool will know.
	&checkZeroUtilizationFactors();
	
	
	#printOut($DEV_OBJ->print()."\n");
	#printOut($DEV_OBJ->printOpts()."\n");
	
	if(($DISPATCH_TYPE eq $DISPATCH_TYPE_BEST_MATCH) or ($DISPATCH_TYPE eq $DISPATCH_TYPE_ALL)){
		printLocalProgress("Executing all devices that fit utilization factor requirements...\n") if ($DISPATCH_TYPE eq $DISPATCH_TYPE_ALL);
		printLocalProgress("Looking for a best fit device...\n") if ($DISPATCH_TYPE eq $DISPATCH_TYPE_BEST_MATCH);
		
		local(@DIRECTORY_LIST=(), @DEVICE_LIST=());
		
		#######################################
		### XILINX ############################
		#######################################
		if(lc($VENDOR) eq "xilinx"){
			#largest device
			my $tempDEV = getLargestDev($VENDOR, $FAMILY);
			
			#if device not returned, we assume family doesnt exist.
			if($tempDEV eq "none"){printOut("CRITICAL ERROR: Could not acquire xilinx device\n"); goto ERRCHECK;}
			my $INIT_DEV = $tempDEV->getDevice();
			printOut("current device = $INIT_DEV\n");
			
			# set the device info
			$DEV_OBJ->setDevice($INIT_DEV);
			
			my ($synresult, $impresult);
			my ($UTIL_RESULTS_REF, %UTIL_RESULTS);
			my ($UTIL_FACTORS_REF);
			$UTIL_FACTORS_REF = $DEV_OBJ->getUtilizationFactors();
			
			$synresult = synthesis($VENDOR, $FAMILY, $INIT_DEV);
			printOut("Synthesis result returned - $synresult\n");
			if ($synresult ne 0){ 
				printOut("CRITICAL ERROR: Synthesis has failed for the current device.\n"); 
				printLocalProgress("ERROR: Synthesis Failed for current device with result - $synresult\n");
				goto ERRCHECK; 
			}
			
			$UTIL_RESULTS_REF = extract_util_results($VENDOR, $FAMILY, $XILINX_SYNTHESIS_REPORT, "", "", 1);

			
			# get appropriate devices
			if($DISPATCH_TYPE eq $DISPATCH_TYPE_BEST_MATCH){
				my $dev = findBestDev($VENDOR, $FAMILY, $UTIL_RESULTS_REF, $UTIL_FACTORS_REF);
				if($dev eq "none"){
					printOut("Cannot fit this design on $FAMILY Family\n");
					printLocalProgress("Cannot fit this design on $FAMILY Family\n");
					goto ERRCHECK;
				}
				else{
					push(@DEVICE_LIST, $dev);
					my $var = "BEST_MATCH = ".$dev->getDevice();
					&printToLog($OPTION_LOG_FILE_NAME, $var);
				}
			}
			elsif($DISPATCH_TYPE eq $DISPATCH_TYPE_ALL){
				@DEVICE_LIST = findAllDev($VENDOR, $FAMILY, $UTIL_RESULTS_REF, $UTIL_FACTORS_REF);
				if(@DEVICE_LIST[0] eq "none"){
					printOut("Cannot fit this design on $FAMILY Family\n");
					printLocalProgress("Cannot fit this design on $FAMILY Family\n");
					goto ERRCHECK;
				}
			}
		}
		#######################################
		### ALTERA ############################
		#######################################
		elsif(lc($VENDOR) eq "altera"){
			my @ignoredDevices = ();
			#for altera iterate through devices in descending order, to find the correct device
			my @AlteraDevices = findAllDev(lc($VENDOR), lc($FAMILY));
			printLocalProgress("Looping through device library");
			
			foreach my $DeviceNum (0..$#AlteraDevices){
				my $devID = $#AlteraDevices - $DeviceNum;
				my $AlteraDevice = $AlteraDevices[$devID];
				my $tempDEV = $AlteraDevice;
				if($tempDEV eq "none"){
					printOut("Cannot fit the design on $FAMILY Family\n\n"); 
					printLocalProgress("Cannot fit the design on $FAMILY Family\n");
					goto ERRCHECK;
				}
				my $INIT_DEV = $tempDEV->getDevice();
				printOut("current device = $INIT_DEV\n");
				
				# set the device info
				$DEV_OBJ->setDevice($INIT_DEV);
				
				my ($synresult, $impresult);
				my ($UTIL_RESULTS_REF, %UTIL_RESULTS);
				my ($UTIL_FACTORS_REF, %UTIL_FACTORS);
				$UTIL_FACTORS_REF = $DEV_OBJ->getUtilizationFactors();
							
				$synresult = synthesis($VENDOR, $FAMILY, $INIT_DEV);
				my $devname = $DEV_OBJ->getDevice();
				printOut("Checking device -> $devname");		
				printLocalProgress("Checking device -> $devname");
				
				if ($synresult ne 0){
					printOut("CRITICAL ERROR: Synthesis has failed for the current device.\n");	
					printLocalProgress("ERROR: Synthesis Failed for current device with result - $synresult\n");					
					push(@ignoredDevices, $INIT_DEV);
					next;
				}
				else{
					$impresult = implementation($VENDOR, $FAMILY, $INIT_DEV);
					if ($impresult ne 0){
						printOut("CRITICAL ERROR: Implementation has failed for the current device.\n");
						printLocalProgress("ERROR: Implementation Failed for current device with result - $impresult\n");
						goto ERRCHECK;
					}
				}
							
				# extract results
				$UTIL_RESULTS_REF = extract_util_results($VENDOR, $FAMILY, "$TOP_LEVEL_ENTITY.$ALTERA_IMPLEMENTATION_REPORT_SUFFIX", "");						
				
				# get appropriate devices/directories
				if($DISPATCH_TYPE eq $DISPATCH_TYPE_BEST_MATCH){
					my $dev = findBestDev($VENDOR, $FAMILY, $UTIL_RESULTS_REF, $UTIL_FACTORS_REF);					
					if($dev eq "none"){
						printOut("Cannot fit this design on $FAMILY Family\n");
						printLocalProgress("Cannot fit this design on $FAMILY Family\n");
						goto ERRCHECK;
					}
					else{
						push(@DEVICE_LIST, $dev);
						my $var = "BEST_MATCH = ".$dev->getDevice();
						&printToLog($OPTION_LOG_FILE_NAME, $var);
					}
				}
				elsif($DISPATCH_TYPE eq $DISPATCH_TYPE_ALL){
					@DEVICE_LIST = findAllDev($VENDOR, $FAMILY, $UTIL_RESULTS_REF, $UTIL_FACTORS_REF);
					if(@DEVICE_LIST[0] eq "none"){
						printOut("Cannot fit this design on $FAMILY Family\n");
						printLocalProgress("Cannot fit this design on $FAMILY Family\n");
						goto ERRCHECK;
					}
				}
				
				#remove the devices that have resulted in a failure 
				my @NEW_DEVICE_LIST;
				foreach my $device (@DEVICE_LIST){
					my $ignore = 0;
					foreach my $ignore_name (@ignoredDevices){
						if ($device->getDevice() =~ /$ignore_name/i ) {
							$ignore = 1;
						}
					}
					if ( $ignore == 0 ) {
						push(@NEW_DEVICE_LIST, $device);
					}
				}
				@DEVICE_LIST = @NEW_DEVICE_LIST;
				last;
			}
			ALTERADONE: printOut("altera is done\n\n");
		}
		#######################################
		### ACTEL #############################
		#######################################
		elsif(lc($VENDOR) eq "actel"){
			#none for now
		}
	
		#===========================================
		# Check to see if all the devices have failed.
		ERRCHECK: if($#DEVICE_LIST < 0){
			my $rundir = $DEV_OBJ->getRunDir();
			if ($DEV_OBJ->getVendor() =~ m/xilinx/i ) {
				if($DISPATCH_TYPE ne $DISPATCH_TYPE_BEST_MATCH){
					my $file = "$rundir/$XILINX_SYNTHESIS_REPORT";
					printOut("Please check synthesis report file : $file");
					printLocalProgress("Please check synthesis report file for more info :\n\t$file");								
				}
			} elsif ($DEV_OBJ->getVendor() =~ m/altera/i) {				
				if($DISPATCH_TYPE ne $DISPATCH_TYPE_BEST_MATCH){
					printOut("Please check synthesis report file : $rundir/*.rpt");	
					printLocalProgress("Please check report files for more info :\n\t$rundir/*.rpt");	
				}
			} else {
				# unsupported vendor
			}							
			my $var = "NOT_PASS = YES";
			&printToLog($OPTION_LOG_FILE_NAME, $var);
			goto ERROR;
		}
		#===========================================
		
		# printOut the current list of devices ready to be dispatched
		my $output = "";
		$output .= "DEVICES being dispatched : ";
		foreach $dev (@DEVICE_LIST){
			$NEWDEVICE = $dev->getDevice();
			$output .= "$NEWDEVICE, ";
		}
		$output .= "\n";
		printOut($output);
		printLocalProgress($output);
		
		
		#######################################
		### DISPATCH ##########################
		#######################################
		my @maxRuns = getMaxRunVals($#DEVICE_LIST+1, $maxSimultaneousRuns);
		printOut("dispatch : ". $#DEVICE_LIST+1 .", $maxSimultaneousRuns \n");
		printOut("Maxruns : ".join(" - ", @maxRuns));
		
		foreach my $LIB_DEV (@DEVICE_LIST){
			#printOut("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~begin dispatch loop \n\n\n");
			
			#clone to get a new device with same information
			my $NEWDEV_OBJ = dclone($DEV_OBJ);
			
			#get the dispatched device name
			my $NEWDEVICE_NAME = $LIB_DEV->getDevice();
			printOut("dispatched device: $NEWDEVICE_NAME\n");
			
			#check if the device already exists
			my $PARENT_DIR = get_ParentDirPath();
			my $NEWDEVICE_DIRECTORY = "$PARTENT_DIR/$NEWDEVICE_NAME";
			if (-d $NEWDEVICE_DIRECTORY) {
				printOut("The device is already present in the list.\n");
				printLocalProgress("The device is already present in the list.\n");
				next;
			}
			
			#set the new device parameters
			$NEWDEV_OBJ->setDevice($NEWDEVICE_NAME);
			$NEWDEV_OBJ->setDispatchType($DISPATCH_TYPE_NONE);
			$NEWDEV_OBJ->setMaxRuns(shift @maxRuns);
			
			#dispatch device
			my $deviceDir = dispatchDevice(\$NEWDEV_OBJ);
			push(@DIRECTORY_LIST,$deviceDir);
			
			#printOut("\n\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~end dispatch loop \n");
		}
		
		#EXECUTE the scripts
		printOut("\nExecuting dispatched scripts...\n");
		%RunHash = (
			title => "Athena - Dispatch",
			directories => \@DIRECTORY_LIST,
			requested_frequency => 0,
			run_all_options => "yes",
			max_runs => $maxSimultaneousRuns,
		);	
		&ExecuteScripts(\%RunHash);

	}
	else{
		if($LOCAL_APPLICATION eq "single_run"){			
			&single_run($VENDOR, $rundir);
		}
		else{
			&application($VENDOR);
		}
	}
	goto DONE;
	
	ERROR: printOut("An error has occured...\n\n");
	DONE: printOut("Done with current script...\n\n");
	#return 1;
}

#####################################################################
# Execution starts here
#####################################################################
my $start_time = time();

# Initialize 
&init();

# Note the log start time;
my $start = "Log started at ".currentTime()."\n";
my $output;
$output .= "\n"; map($output .= "=",(0..length($start))); $output .= "\n";
$output .= $start;
$output .= "\n"; map($output .= "=",(0..length($start))); $output .= "\n";
printOut($output);

#call main
&run();

#check results for errors/warnings
&ResultCheck($VENDOR);

my $elapsed_time = elapsed_time($start_time);
printOut("Elapsed time: $elapsed_time\n");
&printToLog($OPTION_LOG_FILE_NAME, "ELAPSED_TIME = $elapsed_time");
&printProgress("Elapsed time for current run : $elapsed_time\n");

