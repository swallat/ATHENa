# =============================================
# ATHENA - Automated Tool for Hardware EvaluatioN.
# Copyright � 2009 - 2014 CERG at George Mason University <cryptography.gmu.edu>.
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
use File::Copy;
use Storable;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Path qw(remove_tree rmtree);


# FIND the current working directory
# use Cwd;
# my $dir = getcwd;

#####################################################################
# athena exit routine
#####################################################################
sub exit_athena{
	if ( $NOPAUSE =~ /off/i ) {
		system( pause );
	}
	exit;
}

#####################################################################
# Create a directory
#####################################################################
sub create_dir{
	my $dirname = $_[0];
	mkdir "$dirname", 0777 unless -d "$dirname";
}

#####################################################################
# Copies files from a directory recursively
# &copy_recursively("testdir1", "testdir2");
#####################################################################
sub copy_recursively{
    my ($from_dir, $to_dir, $exception) = @_;
    opendir my($dh), $from_dir or printError("\n\nCould not open dir '$fromdir': $!",1);
    for my $entry (readdir $dh) {
		next if ($entry eq ".");
		next if ($entry eq "..");
		next if (lc($entry) eq lc(CVS));
		next if ($entry eq $exception);
		next if ($entry =~ m/^_/gi);
        my $source = "$from_dir/$entry";
        my $destination = "$to_dir/$entry";
        if (-d $source) {
            mkdir $destination or printError("mkdir '$destination' failed: $!",1) if not -e $destination;
            copy_recursively($source, $destination, $regex);
        } else {
            copy($source, $destination) or die "copy failed: $!";
        }
    }
    closedir $dh;
    return;
}

#####################################################################
# Returns the option file
#####################################################################
sub get_OptionFile{
	return "options.".$OPTIONS."_".$OPTIMIZATION_TARGET.".txt";
}

#####################################################################
# Returns the current working directory
#####################################################################
sub get_CurrentDir{
	my $dir = getcwd;
	my @dirs = split(/[\/\\]+/,$dir);
	my $CURRENT_DIRECTORY = @dirs[$#dirs];
	return $CURRENT_DIRECTORY;
}

#####################################################################
# Returns the current working directory
#####################################################################
sub get_ParentDirPath{
	my $dir = getcwd;
	my @dirs = split(/[\/\\]+/,$dir);
	my $CURRENT_DIRECTORY = @dirs[$#dirs];
	my $PARTENT_DIR = $dir;
	$PARTENT_DIR =~ s/$CURRENT_DIRECTORY$//g;
	$PARTENT_DIR =~ s/\/$//g;
	return $PARTENT_DIR;
}

#####################################################################
# Remove comments from array
#####################################################################
sub remove_comments{
	my @data = @{shift()};
	my $debug = shift();
	my @newdata;
	
	if ($debug == 1 ) {
		print "helo\n";
		my $bef = join ("",@data);
		print "\n\nBefore -----------\n$bef\n\n"; system( pause );
	}
		
	for ( my $i = 0; $i < scalar@data; $i ++ ) {
		chomp($data[$i]);
		# remove anything that begins with #
		if ($data[$i] =~ m/$REGEX_COMMENT_IDENTIFIER/i) { 
			if ($debug == 1 ) {
				my $substring = substr $data[$i], 0, 1;
				if ($substring !~ /#/) { print "\nMATCH!! $data[$i]\n"; }
			}
			$data[$i] = $1;
		}
		# remove tabs
		$data[$i] =~ s/[\t]+//gi;
		push ( @newdata, $data[$i] ) unless ($data[$i] eq "");
	}
	if ($debug == 1 ) {
		my $aft = join ("\n",@newdata);
		print "\n\nAFTER -----------\n$aft\n\n"; system(pause );	
	}
	
	my $line = "================================================================\n";
	#printToLog("log.txt",$line.join("\n",@newdata)."\n",$APPEND) unless (lc($CONTEXT) eq "parent");
	
	return (\@newdata);
}		
		
		
#####################################################################
# Acquires the sources from the file
#####################################################################
sub acquire_sources{
	my $retval = 0;
	my $type = shift();
	my $list_file = shift();
	my @files;
	if ( -e $list_file ) {
		open(SFILE, "$list_file");
		my @DATA = <SFILE>;
		close(SFILE);
	
		@DATA = @{&remove_comments(\@DATA)};
		
		foreach my $file(@DATA){
			next if ($file eq "");
		
			if ( $type =~ m/^sources/i ) { 
				if ( $file =~ m/$REGEX_SOURCE_IDENTIFIER/i ) {
					push(@SOURCE_FILES, $file); 
				} else {
					$retval = 1;
					my $str = ".".join(" .",@SOURCE_FILE_TYPES);
					printOut("Invalid file extension: $file. Supported file extension are {$str}\n");
				}
			} else { 
				if ( $file =~ m/$REGEX_SOURCE_IDENTIFIER/i ) {
					push(@VERIFICATION_FILES, &trim_spaces($file));
				} else {
					push(@TEST_VECTORS_FILES, &trim_spaces($file));
				}
			}
		}	
	} else {
		printError("Source list cannot be read from $list_file\n", 0);
	}
	
	return $retval;
}

#####################################################################
# Matches the sources provided in design config 
# to the ones in the source folder
#####################################################################
sub identify_sources{

	my $retval = 0;
	my $type = shift();				
	my $dir = shift();
	my $list_file = shift();	
	
	$retval = acquire_sources($type, $list_file);
	#read files in directory 
	opendir(DIR, $dir) || ($retval = 1);
	my @ALLfiles = readdir(DIR);
	closedir(DIR);
	
	my @files;
	if ( $type =~ m/^sources/i ) { @files = @SOURCE_FILES; }
	else { @files = (@VERIFICATION_FILES, @TEST_VECTORS_FILES); }

	foreach my $file(@files){				
        $retval = 1 unless(grep(/^$file/, @ALLfiles));
		printOut("Cannot find source file: $file. please check your source list.\n") unless(grep(/^$file/, @ALLfiles));
	}
	return $retval;
}

#####################################################################
# Dispatches the files from different directories
#####################################################################
sub dispatch_files{
	my($to_dir, @FILE_LIST) = @_;
	#printOut("FILE LIST: ".join("\n\t", @FILE_LIST)."\n");
	foreach my $dispatch_item (@FILE_LIST){
		my @items = split(/[\\\/]+/, $dispatch_item);
		my $item = @items[$#items];
		#printOut("Copying: $item\n");
		copy($dispatch_item, "$to_dir/$item") or printOut("An error has occured while copying $item to $to_dir \n\n");
	}
}

#####################################################################
# Make a batch script to call perl file
#####################################################################
sub create_BatchScript{
	my $directory = $_[0];
	#printOut("creating batch scripts at $directory\n");
	
	#damn you windows... get ur slashes right! 
	#$directory =~ s/\//\\/gi;
	
	my @ary = split(/:/, $directory);
	my $driveletter = $ary[0];

	#printOut("driveletter = $driveletter\n");
	my $file = "$directory/run.sh";
	
	#write script file
	open(WRTFILE, ">$file") || printError("Support.pl: Cannot create bat file",1); 
	print WRTFILE "echo off\n";
	print WRTFILE "set XIL_TIMING_ALLOW_IMPOSSIBLE=1\n";	
	print WRTFILE "cd \"$directory\"\n";
	print WRTFILE "perl $DISPATCH_SCRIPT_NAME\n";	
	close(WRTFILE);
}

#####################################################################
# Dispatch a device
#####################################################################
sub dispatchDevice{
	my $devStruct_ref = $_[0];
	my $devStruct = ${$devStruct_ref};
	
	#printOut("START printing device info ===================================================\n");
	#printOut($devStruct->print() . "\n");
	#printOut($devStruct->printOpts() . "\n");
	#printOut("END printing device info ===================================================\n\n\n");
	
	#perform error checks here
	#check vendor, family, dispatch type, application, other info
	
	# retrieve all the information
	my $workspaceDir = $devStruct->getWorkspaceDir();
	my $vendor = $devStruct->getVendor();
	my $family = $devStruct->getFamily();
	my $device = $devStruct->getDevice();	
	my $generic_id = $devStruct->getGenericID();

	
	my $vendorDir = "$workspaceDir/$vendor";
	create_dir($vendorDir);
	my $familyDir = "$vendorDir/$family\_$generic_id";
	create_dir($familyDir);
	my $deviceDir = "$familyDir/$device";
	&create_dir($deviceDir);
	if ( $CONTEXT =~ /parent/i ) {
		my $generics = $devStruct->getGenericValue();
		my $generic_file = "$vendorDir/$family\_$generic_id/generics.txt";
		open(WRTFILE, "> $generic_file") || printError("Cannot create generics.txt",1); 	
		print WRTFILE "$generics";
		close(WRTFILE);		
	}
	my $RunDir = "";
	my $localApplication = $devStruct->getLocalApplication();
	my $DispatchType = $devStruct->getDispatchType();
	my $RunNo = $devStruct->getRunNo();
	
	#printOut("\n\n APPLICATION \t $APPLICATION \n DispatchType \t $DispatchType \n localApplication \t $localApplication \n";
	
	if($DispatchType eq $DISPATCH_TYPE_NONE){
		if((lc($APPLICATION) ne "single_run") and (lc($localApplication) eq "single_run")){
			$RunDir = "$deviceDir/run_".$RunNo;
		}
		elsif((lc($APPLICATION) eq "single_run") and (lc($localApplication) eq "single_run")){
			$RunDir = "$deviceDir/run_1";
		}
		else{
			$RunDir = "$deviceDir";
		}
	}
	else{
		$RunDir = "$deviceDir";
	}
	&create_dir($RunDir);
	
	#printOut("Dispatching device to $RunDir\n");
	
	$devStruct->setRunDir($RunDir);
	my $objFile = "$RunDir/device.obj";
	#printOut("object file: $objFile\n");
	store(\$devStruct, $objFile);
	
	#copy the necessary files in to the device folder
	if(lc($vendor) eq "xilinx"){
		push(@DISPATCH_LIST, $XILINX_SYNTHESIS_SCRIPT);
		push(@DISPATCH_LIST, $XILINX_IMPLEMENTATION_SCRIPT);
	}
	elsif(lc($vendor) eq "altera"){
		push(@DISPATCH_LIST, $ALTERA_SYNTHESIS_SCRIPT);
		push(@DISPATCH_LIST, $ALTERA_IMPLEMENTATION_SCRIPT);
	}
	elsif(lc($vendor) eq "actel"){
		push(@DISPATCH_LIST, $ACTEL_SYNTHESIS_SCRIPT);
		push(@DISPATCH_LIST, $ACTEL_IMPLEMENTATION_SCRIPT);
	}
	my $APPLICATION_SCRIPT = "$APPLICATION_DIR/$APPLICATION.pl";
	push(@DISPATCH_LIST, $APPLICATION_SCRIPT);
	
	&dispatch_files($RunDir, @DISPATCH_LIST);
	
	#create a batch script to execute the perl scripts
	&create_BatchScript($RunDir);
	
	return $RunDir;
}

#####################################################################
# Read options from option files
# 
# VENDOR, TOOL name = uppercase
# ALTERA needs options uppercase, XILINX needs them lowercase <== call it a pain in the A55
# Option , flag = lower if xilinx, upper if altera
#####################################################################
sub readOpts{
	my %OPT_HASH = ();
	my %SYNTHESIS_TOOL = ();
	
	my $OPTIONS_FILE = "$CONFIG_DIR/".get_OptionFile();
print "OPTION --> \n\t$OPTIONS_FILE\n\n============\n";	
	open(DESIGNOPTS, "$OPTIONS_FILE") || printError("Could not acquire options file!", 1);
	
	

	my @optdata = <DESIGNOPTS>;
	close(DESIGNOPTS);
	@optdata = @{remove_comments(\@optdata)};
	
	my $size = $#optdata;
	#printOut("$size\n");
	my $i = 0;
	for($i=0;$i<$size;$i++)
	{
		#skip all the # signs in the options
		my $substring = substr $optdata[$i], 0, 1;
		next if($substring =~ /#/);
		
		foreach my $VENDOR (@VENDORS){
			$VENDOR = uc($VENDOR);
			my @TOOLS = ();
			if(lc($VENDOR) eq "xilinx"){ @TOOLS = @ALL_XILINX_TOOLS; }
			elsif(lc($VENDOR) eq "altera"){ @TOOLS = @ALL_ALTERA_TOOLS; }
			elsif(lc($VENDOR) eq "actel"){ @TOOLS = @ALL_ACTEL_TOOLS; }
			
			my $SYN_TOOL_VAR = $VENDOR."_SYNTHESIS_TOOL";
			if($optdata[$i] =~ m/${SYN_TOOL_VAR}\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
				#printOut("SYNTHESIS_TOOL				 $1\n");
				$SYNTHESIS_TOOL{$VENDOR} = $1;
			}
			
			foreach my $TOOL (@TOOLS){
				$TOOL = uc($TOOL);
				my $TOOL_STR = $VENDOR."_".$TOOL."_OPT";
				if($optdata[$i] =~ m/${TOOL_STR}\s*=/gi){
					my $toolDone = 0;
					while ($toolDone == 0){
						$i++;

						if(($optdata[$i] =~ /END[\s^\w]*OPT/i)){
							$toolDone = 1;																	
						}else{
							next if ( $optdata[$i] =~ m/^\s*$/i ); #empty line							
							chomp($optdata[$i]);
							$optdata[$i] =~ s/^\t*\s*//gi; # remove preceding tabs and spaces
							$optdata[$i] =~ s/\t*\s*$//gi; # remove following tabs and spaces
													
							#printOut("$VENDOR - $TOOL - $optdata[$i]\n");
							$optdata[$i] =~ s/-//gi;							
						
							my @splitdata = split(/[= ]+/,$optdata[$i]);

							#ALTERA needs options uppercase, XILINX needs them lowercase <== call it a pain in the A55
							$OPT_HASH{$TOOL}{lc($splitdata[0])} = lc($splitdata[1]."") if(lc($VENDOR) eq "xilinx");
							$OPT_HASH{$TOOL}{uc($splitdata[0])} = uc($splitdata[1]."") if(lc($VENDOR) eq "altera");
							
							#Option translations happens here
						}
					}
				}
			}
		}
	}
	return \%OPT_HASH, \%SYNTHESIS_TOOL;
}

#####################################################################
# Handle Zero Utilization factors
#
# If one of the Device specific items has utilization of 0, 
# we set an option to the appropriate tool not to use these items (dsp, bram, mult ... blah)
#####################################################################
sub checkZeroUtilizationFactors{
	# Modify Options - If utilization is set to 0, then modify the options so the tool will know.
	my ($UTIL_FACTORS_REF, %UTIL_FACTORS, @DEVICE_ITEMS, %ZERO_UTIL_OPTS, %Family_hash, @FAMILIES, @TOOLS);
	my ($VENDOR, $FAMILY, $DEVICE);
	$VENDOR = $DEV_OBJ->getVendor();
	$FAMILY = $DEV_OBJ->getFamily();
	$DEVICE = $DEV_OBJ->getDevice();
	
	$UTIL_FACTORS_REF = $DEV_OBJ->getUtilizationFactors();
	%UTIL_FACTORS = %{$UTIL_FACTORS_REF};
	@DEVICE_ITEMS = keys %UTIL_FACTORS;
	#printOut("UTIL FACTOR KEYS " . join(" , ", @DEVICE_ITEMS)."\n");
	
	%Family_hash = %{$VENDOR_ZERO_UTIL_OPTS{lc($VENDOR)}};
	@FAMILIES = keys %Family_hash;
	#printOut("FAMILIES with zero util options " . join(" , ", @FAMILIES)."\n");
	%ZERO_UTIL_OPTS = %{$Family_hash{lc($FAMILY)}};
	@TOOLS = keys %ZERO_UTIL_OPTS;
	#printOut("TOOLS with zero util options " . join(" , ", @TOOLS)."\n");
	
	foreach my $ITEM (@DEVICE_ITEMS){
		next if($UTIL_FACTORS{$ITEM} > 0);
		foreach my $TOOL (@TOOLS){
			my @OPTIONS = @{$ZERO_UTIL_OPTS{$TOOL}{$ITEM}};
			#printOut("$ITEM, $TOOL, @OPTIONS \n");
			unless($#OPTIONS eq -1){
				map{ 
					$DEV_OBJ->deleteToolOpt($VENDOR, $TOOL, $_);
					$DEV_OBJ->addOpt($VENDOR, $TOOL, $_, "0");
				}@OPTIONS;
			}
			if (( $ITEM =~ m/bram/i) and ($TOOL =~ m/xst/i)) {
				$DEV_OBJ->deleteToolOpt($VENDOR, $TOOL, "ram_style"); # delete ram_style, if any
				$DEV_OBJ->addOpt($VENDOR, $TOOL, "ram_style", "distributed");
			}
		}
	}
	
	#printOut($DEV_OBJ->print());
	#printOut($DEV_OBJ->printOpts());
}

#####################################################################
# Calculates the elapsed time since the execution of the script
#####################################################################
sub elapsed_time{
	my ($start_time) = @_;
	my $present_time = time();
	
	# print "START   --> $start_time\n";
	# print "CURRENT --> $present_time\n";
	
	my $elapsed = $present_time - $start_time;
	#@parts = gmtime($elapsed);
	#printf ("Days:%4d Hours:%4d Mins:%4d Secs:%4d\n",@parts[7,2,1,0]);
	my $days = int($elapsed/(24*60*60));
	my $hours = ($elapsed/(60*60))%24;
	my $mins = ($elapsed/60)%60;
	my $secs = $elapsed%60;
	return $days."d ".$hours."h:".$mins."m:".$secs."s";
}

#####################################################################
# Returns current time in yyyy\mm\dd - hh:mm:ss format
#####################################################################
sub currentTime{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = localtime();
	$year += 1900;
	$sec = "0".$sec if( $sec < 10);
	$min = "0".$min if( $min < 10);
	$hour = "0".$hour if( $hour < 10);
	$mday = "0".$mday if( $mday < 10);
	$mon = "0".$mon if( $mon < 10);

	return "$year\\$mon\\$mday - $hour:$min:$sec";
}

#####################################################################
# Modify dir paths to work with altera
#####################################################################
sub adjust_dir{
	my ($DIR) = @_;
	$DIR =~ s/\\/\//gi; 
	return $DIR;
}

#####################################################################
# Replaces characters in a text file.
# Handles both text and Ascii files
#####################################################################
sub replace_chars{
	my ($INPUT, $REPLACE_THIS, $WITH_THIS, $TYPE) = @_;
	
	my $TEMP = $INPUT;
	$TEMP =~ s/$REPLACE_THIS/$WITH_THIS/gi;
	return $TEMP if(lc($TYPE) eq "text");
	
	return unless(-e $INPUT);
	
	open(LOG, $INPUT);
	my $DATA = join("", <LOG>);
	close (LOG);
	
	#print $DATA;
	$DATA =~ s/$REPLACE_THIS/$WITH_THIS/g;
	#print $DATA;
	open(LOG, ">", $INPUT) || printError($!,1);
	print LOG $DATA;
	close (LOG);
}

#####################################################################
# Returns the processed data from a text file. 
# used to read configuration/option files
# @data = @{getProcessedText($file , "label in case of error")};
#####################################################################
sub getProcessedText{
	my ($CONFIG_FILE, $label) = @_;
	open(DESIGNOPTS, "$CONFIG_FILE") || printError("Could not acquire $label configuration file!", 0);
	my @CONFIG_DATA = <DESIGNOPTS>;
	close(DESIGNOPTS);
	
	printOut("Number of lines in config file - Pre comment removal : $#CONFIG_DATA\n");
	@CONFIG_DATA = @{remove_comments(\@CONFIG_DATA)};
	printOut("Nunmber of lines in config file - Post comment removal : $#CONFIG_DATA\n");
	
	#printToLog("processed_data.txt", join("\n",@CONFIG_DATA), $APPEND) unless (lc($CONTEXT) eq "parent");
	return \@CONFIG_DATA;
}

#####################################################################
# process relative paths
# stupid code - redundant (not idiot proof)
#####################################################################
sub processRelativePath{
	my ($INPUT_PATH, $DEFAULT_DIR) = @_;
	
	#replace all \ blackward slashes with / forward slashes (suitable for linux and altera)
	$INPUT_PATH =~ s/[\\]+/\//gi;
	$INPUT_PATH =~ s/[\/]+/\//gi;
	
	#process default dir
	if($DEFAULT_DIR eq ""){ 
		$DEFAULT_DIR = $ROOT_DIR; 
	}
	elsif($DEFAULT_DIR =~ m/source(?: |_|)dir/gi){ 
		$DEFAULT_DIR = $ROOT_DIR;
		$DEFAULT_DIR = $SOURCE_DIR if($SOURCE_DIR ne "");
	}
	elsif($DEFAULT_DIR =~ m/work(?: |_|)dir/gi){
		$DEFAULT_DIR = $ROOT_DIR;
		$DEFAULT_DIR = $WORK_DIR if($WORK_DIR ne "");
	}
	elsif($DEFAULT_DIR =~ m/config(?: |_|)dir/gi){
		$DEFAULT_DIR = $ROOT_DIR;
		$DEFAULT_DIR = $CONFIG_DIR if($CONFIG_DIR ne "");
	}
	#printOut("default directory : \t\t $DEFAULT_DIR\n\n");
	
	# parse input path
	my $RELATIVE_DIR = "";
	if($INPUT_PATH =~ m/\$([\w-_ ]+)([\/.]+)/gi){
		$RELATIVE_DIR = $1;
		$INPUT_PATH =~ s/\$$1\///i if($2 eq "/../");
		$INPUT_PATH =~ s/\$$1//i if($2 eq "../");
		$INPUT_PATH =~ s/\$$1\///i if($2 eq "/"); # "\$source_dir/strategies" split to 'source_dir' , 'strategies'
	}
	
	if($RELATIVE_DIR eq ""){
		$RELATIVE_DIR = $DEFAULT_DIR; 
	}
	elsif($RELATIVE_DIR =~ m/source(?: |_|)dir/gi){ 
		$RELATIVE_DIR = $DEFAULT_DIR; 
		$RELATIVE_DIR = $SOURCE_DIR if($SOURCE_DIR ne "");
	}
	elsif($RELATIVE_DIR =~ m/work(?: |_|)dir/gi){
		$RELATIVE_DIR = $DEFAULT_DIR;
		$RELATIVE_DIR = $WORK_DIR if($WORK_DIR ne "");
	}
	elsif($RELATIVE_DIR =~ m/config(?: |_|)dir/gi){
		$RELATIVE_DIR = $DEFAULT_DIR;
		$RELATIVE_DIR = $CONFIG_DIR if($CONFIG_DIR ne "");
	}
	my @SPLIT = split(/[\/]+/,$INPUT_PATH);
	
	my $RES_DIR = $RELATIVE_DIR;
	
	#if there is no split
	if($#SPLIT < 1){
		#printOut("no split\n");
		$RES_DIR = "$RES_DIR/$INPUT_PATH";
		return $RES_DIR;
	}
	# determine if path is relative
	elsif(($SPLIT[0] eq ".") or ($SPLIT[0] eq "..") or ($SPLIT[0] eq "") or (length($SPLIT[0]) > 2)){
		foreach my $path (@SPLIT){
			next if(($path eq "."));
			if(length($path) > 2){
				$RES_DIR = "$RES_DIR/$path";
			}
			elsif($path eq ""){
				my $dir = getcwd;
				my @ary = split(/:/, $dir);
				my $driveletter = $ary[0] if(length($ary[0]) == 1);
				$RES_DIR = "$driveletter:\"\b";
			}
			elsif($path eq ".."){
				#move one dir up
				my @dirs = split(/[\/\\]+/,$RES_DIR);
				$RES_DIR =~ s/$dirs[$#dirs]//g;
				$RES_DIR =~ s/\/$//g;
			}
			else{
				#append the dir
				$RES_DIR = "$RES_DIR/$path";
			}
		}
		return $RES_DIR;
	}
	return $INPUT_PATH;
}

#####################################################################
# Find files with a certain extension in the directory
#####################################################################
sub get_file_type{
  my $dir = shift; my $filetype = shift;
  opendir(DIR, $dir);# || die("Cannot open directory");
  my @files = readdir(DIR);
  closedir(DIR);
  my @file = grep(/\.$filetype$/,@files);
  return @file;
}

#####################################################################
# Returns the list of Parallel Runs per a single run
#####################################################################
sub getMaxRunVals{
	my ($total_runs, $maxSimultaneousRuns) = @_;
	#printOut("Support.pl - getmaxrunvals - Total runs = $total_runs, Max Parallel runs = $maxSimultaneousRuns\n");
	my @retvals = ();
	my @array = 0..$total_runs-1;
	
	if($maxSimultaneousRuns <= $total_runs){ #<== return 1 for total runs;
		@retvals = map{ 1; } @array;
	}
	else{ #<== split the available runs into appropriate "runs";
		my $min = int($maxSimultaneousRuns/$total_runs);		
		my $total = $min * $total_runs;
		my $left = $maxSimultaneousRuns - $total;
		
		@retvals = map{ $min; } @array;
		@retvals = map{ if($left>0){$left--; $_ + 1;} else {$_;} } @retvals;
	}
	return @retvals;
}

#####################################################################
# Check devices
#####################################################################
sub checkDeviceSupport {
	my ($VENDOR, $FAMILY, $DEVICE) = @_;
	
	if($VENDOR =~ m/xilinx/i){
        my @families = getFamilies("xilinx");
		my $fam_check = grep{lc($FAMILY) eq lc($_)} @families;
		if($fam_check == 0){ return 0 };
		
		return 1 if(lc($DEVICE) eq lc($DISPATCH_TYPE_BEST_MATCH) or lc($DEVICE) eq lc($DISPATCH_TYPE_ALL));
		
		return checkLibDevice($VENDOR, $FAMILY, $DEVICE);
        
        #=========== Deprecated ==========
		# my @families = getFamilies("xilinx");
				
        # # foreach $fam (@families) {
            # # print "$fam\n";
        # # }
		# my $fam_check = grep{lc($FAMILY) eq lc($_)} @families;
		# if($fam_check == 0){ return 0 };
		
		# if ($DEVICE =~ m/$DISPATCH_TYPE_BEST_MATCH|$DISPATCH_TYPE_ALL/i ) {
			# return 1;
		# } 
		
        # print("$XPARTGEN -v $DEVICE -nopkgfile\n");
        # `echo HAHA`;
		# system("$XPARTGEN -v $DEVICE -nopkgfile >run.txt");
		# open(FILE, "run.txt");
		# my $INPUT = join("", <FILE>);
		# close (FILE);
        # print "INPUT:\n$INPUT\n";
        

		# #Loading device for application Rf_Device from file '3s50.nph' in environment
		# if($INPUT =~ m/Loading device/gi){
			# map(unlink($_), grep(/\.pkg$|partlist\.xct$|partlist\.xml$|run\.txt$/,<*>));
			# return 1;
		# }
		# else{
			# map(unlink($_), grep(/\.pkg$|partlist\.xct$|partlist\.xml$|run\.txt$/,<*>));
			# return 0;
		# }
	}
	elsif($VENDOR =~ m/altera/i){
		my @families = getFamilies("altera");
		my $fam_check = grep{lc($FAMILY) eq lc($_)} @families;
		if($fam_check == 0){ return 0 };
		
		return 1 if(lc($DEVICE) eq lc($DISPATCH_TYPE_BEST_MATCH) or lc($DEVICE) eq lc($DISPATCH_TYPE_ALL));
		
		return checkLibDevice($VENDOR, $FAMILY, $DEVICE);
	}
}

#####################################################################
# Error checks
#####################################################################
sub ErrCheck{

	printOut("Performing error checks...");
	
	my (@ERR_LIST, $STOP_SCRIPT);
	$STOP_SCRIPT = "no";
	
=pod
	The process of error checks:
		Check the list of tools available
			display warning and verify if the user wants to continue, if tools are not present for requested vendor
			yes - remove the affected families
			no - quit
		
		Check if devices valid
			display warning and verify if the user wants to continue, if tools are not present for requested vendor
			yes - remove the affected families
			no - quit
			
		generate a list of files that are required based on the vendors/tools supported
		add these to the list of scripts we already check (application scripts).
		Check if all the files are present...
		
		source directory
		sources
		
		check
			-- globals
			projectname
			toplevel entity
			toplevel architecture (based on source file type)
			
			-- verification
			
			-- synthesis and implementation
			clk net
			latency
			throughput
			optimization target
			OPTIONS
		
			
			
		option files
		option file format
		
=cut 
	
	my @vendor_list = (keys %requested_devices);
	
	if ( $#vendor_list+1 == 0 ) {
		print "\n\nError! Athena detected that you have not specified any devices in design configuration.\n";
		print "Please refer to design configuration for more details\n\n";
		&exit_athena();
	}
	
	#===================================================================================================================================#
	# Check Tools and remove vendors with unsupported tools
	#Configure tools and findout list of failed vendors
	my @vendor_list = (keys %requested_devices);
	my @failed_vendors = map{
		my $vendor = $_;
		my @result = tool_config($vendor); 
		if($result[0] == 1){$vendor;}else{} 
	} @vendor_list;
	
	#skip the userinput if no ignored devices;
	goto DeviceCheck if($#failed_vendors < 0);
	
	my $failed_output = "";
	map{ 
		my $vendor = $_;
		my @device_list = @{$requested_devices{$vendor}};
		map{$devStruct = $_; $failed_output .= $devStruct->getVendor()." - ".$devStruct->getFamily()." - ".$devStruct->getDevice()."\n";} @device_list;
	} @failed_vendors;
		
	printLogToScreen("\n\n#####################################################################\n");
	printLogToScreen("Tools required for the following vendor(s) is/are not present on this system:\n");
	printLogToScreen("$failed_output");
	printLogToScreen("#####################################################################\n");
    while (1) {
		my $input;
        printLogToScreen("Would you like to continue the execution by ignoring the(se) vendor(s)? Y/N : ");
        chomp( $input = <STDIN> );
        #$input = 'y' if $input eq '';
		if(lc($input) eq "y"){
			map(delete $requested_devices{$_}, @failed_vendors);
			printOut("Yes\n");
			last;
		}
		elsif(lc($input) eq "n"){
			printLogToScreen("\nStopping execution\n\n");
			&exit_athena();
		}
		else{
			printLogToScreen("\nERROR: Answer must be y or n.\n\n");
		}
    }
	
	DeviceCheck: #device check label
	
	
	#===================================================================================================================================#
	# Check given families against library (assuming library has loaded with no errors)
	# and remove the devices/families that are not supported
	my @vendor_list = (keys %requested_devices);
	my @failed_devices = ();
	foreach $vendor ( @vendor_list ) {
		my @passed_devices = ();
		my @device_list = @{$requested_devices{$vendor}};
		foreach $devStruct ( @device_list ){
			my $family = lc($devStruct->getFamily());
			my $device = lc($devStruct->getDevice());
								
			#deal with best_match case
			unless(&checkDeviceSupport($vendor, $family, $device) == 1){
				push(@failed_devices, $devStruct);
				next;
			}
			push(@passed_devices, $devStruct);
		}
		$requested_devices{$vendor} = \@passed_devices;
	}
	
	#skip the userinput if all devices have passed;
	goto ErrorCheckLabel1 if($#failed_devices < 0);	
	#printOut("No of faied devices" . $#failed_devices+1 . "\n");	
	my $failed_output = "";
	map{$devStruct = $_; $failed_output .= $devStruct->getVendor()." - ".$devStruct->getFamily()." - ".$devStruct->getDevice()."\n";} @failed_devices;
	
	printLogToScreen("\n\n#####################################################################\n");
	printLogToScreen("The following device(s)/familie(s) did not pass the device check. \nEither the device/family is not supported by vendor tools, its not present in our library or the names have been misspelled.\n");
	printLogToScreen("$failed_output");
	printLogToScreen("#####################################################################\n");
    while (1) {
		my $input;
		printLogToScreen("Would you like to continue the execution by ignoring the(se) device(s)? Y/N : ");
        chomp( $input = <STDIN> );
        #$input = 'y' if $input eq '';
		if(lc($input) eq "y"){
			printOut("Yes\n");
			#already removed the devices
			last;
		}
		elsif(lc($input) eq "n"){
			printLogToScreen("\nStopping execution\n\n");
			&exit_athena();
		}
		else{
			printLogToScreen("\nERROR: Answer must be y or n.\n\n");
		}
    }
	
	ErrorCheckLabel1: #general files and scripts
	#===================================================================================================================================#
	#generate a list of files needed
	my @vendor_list = (keys %requested_devices);
	
	my (@applications, @application_scripts, %supported_files, @required_files, @required_list, @missing_files);
	
	#applications	
	my $app_script = $APPLICATION_DIR."/".$APPLICATION.".pl";
	unless ( -e $app_script ) {
		push(@ERR_LIST, "ERROR: main - Application $APPLICATION does not exist! ==> check design configuration!\n");
		$STOP_SCRIPT = "yes";
	}
	
	#supported files
	%supported_files = (
		xilinx 			=> [ $DEFAULT_XILINX_DEVICE_LIBRARY_FILE, $XILINX_SYNTHESIS_SCRIPT, $XILINX_IMPLEMENTATION_SCRIPT ], #$XILINX_OPTION_LIBRARY_FILE
		altera 			=> [ $DEFAULT_ALTERA_DEVICE_LIBRARY_FILE, $ALTERA_SYNTHESIS_SCRIPT, $ALTERA_IMPLEMENTATION_SCRIPT ], #$ALTERA_OPTION_LIBRARY_FILE
		actel  			=> [ $DEFAULT_ACTEL_DEVICE_LIBRARY_FILE, $ACTEL_SYNTHESIS_SCRIPT, $ACTEL_IMPLEMENTATION_SCRIPT ], #$XILINX_OPTION_LIBRARY_FILE
		other 			=> [$REPORT_SCRIPT, $DISPATCH_SCRIPT, $GLOBAL_SYNTHESIS_SCRIPT, $GLOBAL_IMPLEMENTATION_SCRIPT, $RESULT_EXTRACTION_SCRIPT],
		applications 	=> \@APPLICATION_SCRIPTS,
	);
	
	@required_list = (@vendor_list, other, applications);
	map{ push(@required_files, @{$supported_files{$_}}); }@required_list;
	
	#check if all files are present
	@missing_files = map{
		unless(-e $_){
			push(@ERR_LIST, "ERROR: $_ missing!\n");
			$STOP_SCRIPT = "yes";
			$_;
		}
		else{}
	}@required_files;
		
	ErrorCheckLabel2: #source directory and source files
	#===================================================================================================================================#
	#check if source files in the source folder match the ones provided
	
	if(-d $SOURCE_DIR){ 
		if (-s $SOURCE_LIST_FILE) {
			unless(identify_sources("sources", $SOURCE_DIR, $SOURCE_LIST_FILE) == 0){
				push(@ERR_LIST, "ERROR: main - Source file mismatch! ==> Please check the sources!\n");
				$STOP_SCRIPT = "yes";						
			}
		} else {
			print "SOURCE LIST FILE\n";
			push(@ERR_LIST, "ERROR: main - Source list file not exist! ==> check design configuration!\n");
			push(@ERR_LIST, "SOURCE_LIST_FILE : $SOURCE_LIST_FILE\n");
			$STOP_SCRIPT = "yes";
		}
	}
	else{
		push(@ERR_LIST, "ERROR: main - Source directory does not exist! ==> check design configuration!\n");
		push(@ERR_LIST, "SOURCE DIRECTORY : $SOURCE_DIR\n");
		$STOP_SCRIPT = "yes";
	}
	
	
	ErrorCheckLabel3: #Other options from design config
	#===================================================================================================================================#
=pod
	PROJECT_NAME
	TOP_LEVEL_ENTITY
	TOP_LEVEL_ARCH (not needed if design is mixed/verilog, otherwise needed)
	CLOCK_NET
	OPTIMIZATION_TARGET
	OPTIONS
	EXHAUSTIVE_SEARCH_STRATEGY
	APPLICATION (already checked)
	LATENCY
	THROUGHPUT
=cut
	
	my (@option_checks);
	
	#if verilog no need to specify TOP_LEVEL_ARCH
	my $arch_needed = "no";
	$arch_needed = "yes" if(grep /.v$/, @SOURCE_FILES);
	
	#option check format = Variable, description, default vaule, stop script
	@option_checks = (
		[ \$PROJECT_NAME, 			"Project Name",				"project1",		"no" ], #<== default value needs to be changed in the main_support.pl
		[ \$TOP_LEVEL_ENTITY, 		"Top Level Entity",			"",			 	"yes"],
		[ \$TOP_LEVEL_ARCH, 		"Top Level Architecture",	"",			 	$arch_needed],
		[ \$CLOCK_NET,				"Clock net",				"",				"no"],
		[ \$OPTIMIZATION_TARGET,	"Optimization Target",		"speed",		"no"],
		[ \$OPTIONS,				"Option type",				"default",		"no"],
		[ \$LATENCY,				"Latency Formula",			"",				"no"],
		[ \$THROUGHPUT,				"Throughput Formula",		"",				"no"],
	);

	#printOut("\n\n\n");
	foreach my $option_ary_ref (@option_checks){
		my @option_ary = @{$option_ary_ref};
		my ($variable_ref, $description, $defaultvalue, $stopscript) = @option_ary;
		my $variable = $$variable_ref;
		#printOut("($variable,\t\t\t$description,\t\t\t$defaultvalue,\t\t\t$stopscript)\n");

		#printOut("length \t\t\t ". length($variable) . "\n");
		$variable =~ s/[ \s]+//gi;
		if(length($variable) < 1){
			if(lc($stopscript) eq "yes"){
				push(@ERR_LIST, "ERROR: main - $description is missing.\n");
				$STOP_SCRIPT = "yes";
			}
			else{
				if(length($defaultvalue) > 0){
					push(@ERR_LIST, "Warning: main - Default value ($defaultvalue) is chosen for $description.\n");
					$$variable_ref = $defaultvalue;
				}
				else{
					push(@ERR_LIST, "Warning: main - $description is missing. No default value present!\n");
				}
			}
		}
	}
	

	ErrorCheckLabel4: #option files and their format
	#===================================================================================================================================#
	
	my $OPTIONS_FILE = "$CONFIG_DIR/".get_OptionFile();
	unless(-e $OPTIONS_FILE){
		push(@ERR_LIST, "Error: main - Default options file is missing! \nPlease check the 'OPTIMIZATION_TARGET' and 'OPTIONS' settings in the design config. \nOptions file: $OPTIONS_FILE	\n");
		$STOP_SCRIPT = "yes";
	}
	my @option_files = (), my @missing_opt_files = ();
	
	if($APPLICATION =~ m/^exhaustive_search$/i){
		$OPTIONS_FILE = "$CONFIG_DIR/exhaustive_search.txt";
		push(@option_files, $OPTIONS_FILE);
	}
	elsif($APPLICATION =~ m/^placement_search$/i){
		$OPTIONS_FILE = "$CONFIG_DIR/placement_search.txt";
		push(@option_files, $OPTIONS_FILE);
	}
	elsif($APPLICATION =~ m/^strategy_search$/i){
		$OPTIONS_FILE = "$CONFIG_DIR/strategy_search.txt";
		push(@option_files, $OPTIONS_FILE);
	}
	elsif($APPLICATION =~ m/^batch_elimination$/i){
		$OPTIONS_FILE = "$CONFIG_DIR/batch.$EXHAUSTIVE_SEARCH_STRATEGY.txt";
		push(@option_files, $OPTIONS_FILE);
	}
	elsif($APPLICATION =~ m/^frequency_search$/i){
		$OPTIONS_FILE = "$CONFIG_DIR/frequency_search.txt";
		push(@option_files, $OPTIONS_FILE);
	}
	elsif($APPLICATION =~ m/^GMU_Xilinx_optimization_1$/i){
		$OPTIONS_FILE = "$CONFIG_DIR/GMU_Xilinx_optimization_1.txt";
		push(@option_files, $OPTIONS_FILE);
	}
	elsif($APPLICATION eq "GMU_Optimization_1"){
		$OPTIONS_FILE = "$CONFIG_DIR/GMU_Optimization_1.txt";
		push(@option_files, $OPTIONS_FILE);
	}




	else{	
		goto ErrorCheckVerification;
	}
	
	@missing_opt_files = map{
		unless(-e $_){
			push(@ERR_LIST, "ERROR: main - Application ($APPLICATION) option files are missing! \nOptions File: $_\n");
			$STOP_SCRIPT = "yes";
			$_;
		}
		else{}
	}@option_files;	
	
	
	ErrorCheckVerification: 	#testbench directory and testbench files
=pod
	check - FUNCTIONAL_VERIFICATION_MODE syntax
	if ( FUNCTIONAL_VERIFICATION_MODE is on ) {
		check - Directory and its testbench file
		check - TB_TOP_LEVEL_ENTITY
		check - TB_TOP_LEVEL_ARCH
	}
	
	
	MAX_TIME_FUNCTIONAL_VERIFICATION -- uncheck	
=cut

	if ( $TRIM_MODE eq "" ) { $TRIM_MODE = "off"; }
	if ( $TRIM_MODE !~ m/off|zip|delete/i ) { 				
		push(@ERR_LIST, "ERROR: Invalid option for TRIM_MODE! ==> check design configuration!\n");
		push(@ERR_LIST, "TRIM_MODE = <$TRIM_MODE>\n");
		$STOP_SCRIPT = "yes";
	}
			
	#===================================================================================================================================#
	# FUNCTIONAL VERIFICATION OPTIONS CHECK
	#check if source files in the source folder match the ones provided
	if(($FUNCTIONAL_VERIFICATION_MODE !~ m/on/i) and ($FUNCTIONAL_VERIFICATION_MODE !~ m/off/i) and ($FUNCTIONAL_VERIFICATION_MODE ne "")){	
		push(@ERR_LIST, "ERROR: Invalid option for FUNCTIONAL_VERIFICATION_MODE! ==> check design configuration!\n");
		push(@ERR_LIST, "FUNCTIONAL_VERIFICATION_MODE = <$FUNCTIONAL_VERIFICATION_MODE>\n");
		$STOP_SCRIPT = "yes";
	}
	
	# check for verification only parameter
	if(($VERIFICATION_ONLY !~ m/on/i) and ($VERIFICATION_ONLY !~ m/off/i) and ($VERIFICATION_ONLY ne "")){	
		push(@ERR_LIST, "ERROR: Invalid option for VERIFICATION_ONLY! ==> check design configuration!\n");
		push(@ERR_LIST, "VERIFICATION_ONLY = <$VERIFICATION_ONLY>\n");
		$STOP_SCRIPT = "yes";
	}
	if (( $VERIFICATION_ONLY =~ m/on/i) and ($FUNCTIONAL_VERIFICATION_MODE !~ m/on/i)) {
		push(@ERR_LIST, "ERROR: You've turned VERIFICATION_ONLY on without turning on FUNCTIONAL_VERIFICATION_MODE ==> check design configuration!\n");	
		$STOP_SCRIPT = "yes";
	}
	
	
	# check if verification is on
	if($FUNCTIONAL_VERIFICATION_MODE =~ m/on/i) {
		#check if source files in the source folder match the ones provided
		if(-d $VERIFICATION_DIR){
			unless(identify_sources("tb_sources", $VERIFICATION_DIR, $VERIFICATION_LIST_FILE) == 0){
				push(@ERR_LIST, "ERROR: main - Testbench files mismatch! ==> Please check the file $VERIFICATION_LIST_FILE\n");
				$STOP_SCRIPT = "yes"; 
			}
		}
		else{
			push(@ERR_LIST, "ERROR: main - Testbench directory does not exist! ==> check design configuration!\n");
			push(@ERR_LIST, "VERIFICATION DIRECTORY : $VERIFICATION_DIR\n");
			$STOP_SCRIPT = "yes";
		}			
			
		# check for unspecified top_level_entity
		if ($TB_TOP_LEVEL_ENTITY eq "" ) {
			push(@ERR_LIST, "ERROR: Unspecified top level entity name of testbench. This value should exists when any VERIFICATION_MODE is on. ==> check design configuration!\n");
			$STOP_SCRIPT = "yes"; 
		}

		# check for unspecified top_level_architecture
		if ($TB_TOP_LEVEL_ARCH eq "" ) {
			push(@ERR_LIST, "ERROR: Unspecified top level entity architecture of testbench. This value should exists when any VERIFICATION_MODE is on. ==> check design configuration!\n");
			$STOP_SCRIPT = "yes";
		}
		
		#check for maximum functional simulation time parameter
		#	if no unit is specified, default unit is 'ns'	
		
		my @units = qw{ps ns us ms}; 
		if ( $MAX_TIME_FUNCTIONAL_VERIFICATION eq "" ) { $MAX_TIME_FUNCTIONAL_VERIFICATION = "-all"; goto ErrorCheckFinal; } 
		if ( $MAX_TIME_FUNCTIONAL_VERIFICATION =~ /^([\d.]+)\s*(\w*)/i ) {
			my $step = $1;	my $unit = $2;
			
			#check step
			if ($step =~ /^(\d*)(.?)(\d*)$/) {
				my $num = $1;	if ($num eq "") {$num = 0;}
				my $digit = $3;
				if ( $2 eq "." ) {
					if ($digit eq "") {$digit = 0;}	
				}
				$step = "$num$2$digit";				
			} else { 
				push(@ERR_LIST, "ERROR: Invalid MAX_TIME_FUNCTIONAL_VERIFICATION step, `$step`. ==> check design configuration!\n");
				$STOP_SCRIPT = "yes";			
			}		
			
			if ( $step <= 0 || $step > 9999999999999999) {
				push(@ERR_LIST, "ERROR: Invalid MAX_TIME_FUNCTIONAL_VERIFICATION step, `$step`. ==> check design configuration!\n");
				$STOP_SCRIPT = "yes";
			}
			
			#check unit
			if ( $unit eq "" ) { $unit = "ns"; goto endmaxtime; }
			foreach $u (@units) {
				if ( lc($unit) eq lc($u) ) {
					goto endmaxtime;
				}
			}			
			push(@ERR_LIST, "ERROR: Invalid MAX_TIME_FUNCTIONAL_VERIFICATION unit, `$unit`. ==> check design configuration!\n");
			$STOP_SCRIPT = "yes";
			
			endmaxtime:
			$MAX_TIME_FUNCTIONAL_VERIFICATION = "$step $unit";
		} else {
			push(@ERR_LIST, "ERROR: Invalid MAX_TIME_FUNCTIONAL_VERIFICATION parameter. ==> check design configuration!\n");
			$STOP_SCRIPT = "yes";
		}
	}

    #===================================================================================================================================#
	# DB REPORT OPTIONS
	#
	if(($DB_CRITERIA !~ m/^THROUGHPUT$/i) and ($DB_CRITERIA !~ m/^THROUGHPUT_AREA$/i) and ($DB_CRITERIA !~ m/^AREA$/i) 
        and ($DB_CRITERIA !~ m/^LATENCY$/i) and ($DB_CRITERIA !~ m/^LATENCY_AERA$/i)){	 
		push(@ERR_LIST, "ERROR: Invalid option for DB_CRITERIA! ==> check design configuration!\n");
		$STOP_SCRIPT = "yes";
	}
    
    if(($DB_QUERY_MODE !~ m/^Overall$/i) and ($DB_QUERY_MODE !~ m/^Generic$/i) and ($DB_QUERY_MODE !~ m/^Device$/i) and ($DB_QUERY_MODE !~ m/^off$/i)) { 
		push(@ERR_LIST, "ERROR: Invalid option for DB_QUERY_MODE! ==> check design configuration!\n");
		$STOP_SCRIPT = "yes";
	}

	ErrorCheckFinal: #Report list of errors and ask user for input  

	#===================================================================================================================================#
	#print the list of errors
	if($#ERR_LIST+1 > 0){
		printErrorToScreen("\n");
		printErrorToScreen("#####################################################################\n");
		printErrorToScreen("# ERROR LOG \n");
		printErrorToScreen("#####################################################################\n");	 
		my $str .= join("", @ERR_LIST)."\n";;
		printErrorToScreen($str."\n");
		
		
		if(lc($STOP_SCRIPT) eq "yes"){
			printErrorToScreen("Critical errors detected! \n", 0);
			printErrorToScreen("Refer to the error log for details\n", 1);
			&exit_athena();
		}
		else{
			while (1) {
				system( cls );
				printErrorToScreen("$str\n");
				my $input;
				printErrorToScreen("Would you like to continue the execution? [y/n] : ");
				chomp( $input = <STDIN> );
				#$input = 'y' if $input eq '';	printError("$input\n");
				if(lc($input) eq "y"){
					last;
				}
				elsif(lc($input) eq "n"){
					printErrorToScreen("\nStopping execution\n\n");
					&exit_athena();
				}
				else{
					printErrorToScreen("\nERROR: Answer must be Y or N.\n\n");
				}
			}
		}
	}
	else{
		printOut("done\n");
	}
}

#####################################################################
# ResultCheck
# Checks the results of current run and reports errors
#####################################################################
sub ResultCheck{
	my ($VENDOR) = @_;

=pod
Generalized error checking
	get log files
	look for strings like "errors found" and report errors
	
Xilinx
	XST
		Number of errors   :    0 (   0 filtered)
		Number of warnings :    0 (   0 filtered)
		Number of infos    :    1 (   0 filtered)
	
	NGDBuild
		Number of errors:     0
		Number of warnings:   0
	
	Map
		Number of errors:      0
		Number of warnings:    0
	
	Par
		Placement: Completed - No errors found.
		Routing: Completed - No errors found.
		Timing: Completed - 33 errors found.

		Number of error messages: 0
		Number of warning messages: 1
		Number of info messages: 0
	
	
Altera
	Info: Quartus II Classic Timing Analyzer was successful. 0 errors, 2 warnings - main.tan.rpt
	Info: Quartus II Fitter was successful. 0 errors, 5 warnings - main.fit.rpt
	Info: Quartus II Analysis & Synthesis was successful. 0 errors, 1 warning - main.map.rpt
	
	
=cut
	
	# use Hashing. 
	# foreach vendor 
	# 	for each tool - get errors
	#		(store error regex vars in hash - $errorRegex{vendor}{tool}{REGEX} = $regex
	
	# Report Names ==========================================================
	# for Xilinx
	$REGEX_VENDOR_ERROR{lc(XILINX)}{XST}{REPORT} = $XILINX_SYNTHESIS_REPORT;
	$REGEX_VENDOR_ERROR{lc(XILINX)}{NGDBUILD}{REPORT} = $XILINX_NGDBUILD_REPORT;
	$REGEX_VENDOR_ERROR{lc(XILINX)}{MAP}{REPORT} = $XILINX_MAP_REPORT;
	$REGEX_VENDOR_ERROR{lc(XILINX)}{PAR}{REPORT} = $XILINX_PAR_REPORT;
	
	# for Altera
	my @file = get_file_type(getcwd, "$ALTERA_SYNTHESIS_REPORT_SUFFIX");
	$REGEX_VENDOR_ERROR{lc(ALTERA)}{QUARTUS_MAP}{REPORT} = $file[0];
	my @file = get_file_type(getcwd, "$ALTERA_IMPLEMENTATION_REPORT_SUFFIX");
	$REGEX_VENDOR_ERROR{lc(ALTERA)}{QUARTUS_FIT}{REPORT} = $file[0];
	@file = get_file_type(getcwd, "$ALTERA_TIMING_REPORT_1_SUFFIX");
	if ( $file[0] eq "" ) { @file = get_file_type(getcwd, "$ALTERA_TIMING_REPORT_2_SUFFIX"); }
	$REGEX_VENDOR_ERROR{lc(ALTERA)}{QUARTUS_TAN}{REPORT} = $file[0];
	
	# Perform the checks
	printOut("The following is a list of errors/warnings/infos generated by the tools.\n");
	my @TOOLS = @{$VENDOR_TOOLS{lc($VENDOR)}};
	foreach my $TOOL (@TOOLS){
		#print "========================\nprocessing $TOOL \n";
		my (@ERRORS, @INFOS, $REPORT, $REPORT_DATA, $REGEX_REF, @REGEX_ARRAY, $INFO_REF, @INFO_ARRAY);
		
		$REPORT = $REGEX_VENDOR_ERROR{lc($VENDOR)}{$TOOL}{REPORT};
		open REPORT, $REPORT;
		$REPORT_DATA = join("", <REPORT>);
		close REPORT;
		#print "Length of report :".length($REPORT_DATA)."\n";
		
		$REGEX_REF = $REGEX_VENDOR_ERROR{lc($VENDOR)}{$TOOL}{REGEX};
		$INFO_REF = $REGEX_VENDOR_ERROR{lc($VENDOR)}{$TOOL}{INFO};
		@REGEX_ARRAY = @{$REGEX_REF};
		@INFO_ARRAY = @{$INFO_REF};
		#print "No of regex vars :".$#REGEX_ARRAY."\n";		
		foreach my $i (0..$#REGEX_ARRAY){
			my $REGEX = $REGEX_ARRAY[$i];
			my $INFO = $INFO_ARRAY[$i];
			#print "REGEX -- $REGEX\n";
			#print "INFO -- $INFO\n";
			if($REPORT_DATA =~ m/$REGEX/gi){
				#print "\t\t\t\tDETECTED  --  $1 $INFO\n";
				push(@ERRORS, $1);
				push(@INFOS, $INFO);
			}
		}
		printOut("TOOL - $TOOL\n");
		foreach my $i (0..$#ERRORS){
			printOut("\t".$ERRORS[$i] ." ". $INFOS[$i]."\n");
			#printProgress("\t".$ERRORS[$i] ." ". $INFOS[$i]."\n") if($ERRORS[$i] > 0);
		}
	}	
}

###################################
## match extension, used by TRIM ##
###################################
sub match_extension {
	my ($value, $ignore_regex_ref) = @_;
	my @ignores = @{$ignore_regex_ref};
	
	foreach $ignore ( @ignores ) {
		my $ignore_regex = qr/\.$ignore$/i;
		if ($value =~ m/$ignore_regex/ ) {
			return 1;
		}	
	}
	return 0;	
}

##########
## Trim FILE ##
##########
sub trim {
	my ($directory, $mode, $zipped_name) = @_;
	### form ignore expressions
    #my @ignore_list = qw{txt twr log rpt zip bat scr prj xcf ucf qsf ncd};
    my @ignore_list = qw{ncd vhd xdl bit call}; #___
    #my @exclude_list = qw{obj pm pl};
    my @exclude_list = qw{obj pm pl txt}; #___
	$directory =~ s/\\\\/\//i; 
	
	opendir ( DIR, $directory ) or die "Can't open the current directory: $!\n"; 
		my @files = readdir(DIR);
	closedir(DIR);	

	if ( $mode !~ m/delete|off|zip$|tiny_zip$/i ) { 
		print "Invalid mode :: $mode\nProgram terminating!\n"; 
		system ( pause ); exit; 
	}

	if ($zipped_name eq "" ) {
		$zipped_name = "$directory/zipped.zip";
	} else {
		$zipped_name = "$directory/$zipped_name.zip";
	}

	### Add to zip
	my $current_dir = cwd;
	chdir($directory);
	if ( $mode =~ m/off/i ) {
		exit;
	} elsif ( $mode =~ m/zip/i ) {
		my $zip = Archive::Zip->new();
		foreach $file (@files) {
			if (($file =~ /^\.$|^\.\.$/i) or (&match_extension($file,\@ignore_list)) ) {
				next;
			} else { 
				if ( -d $file ) {
					if ( $mode !~ m/tiny_zip/i ) {
					$zip->addTree( ".\${file}", "${file}");
					}
				} elsif (not (&match_extension($file,\@exclude_list))) {
					$zip->addFile( $file, $file, 9 );
				}
			}
		}
		die 'write error.' if ( $zip->writeToFileNamed($zipped_name) != AZ_OK );
	}
	chdir($current_dir);





	foreach $file (@files) {
		if (($file =~ /^\.$|^\.\.$/i) or (&match_extension($file,\@ignore_list)) ) {
			next;
		} else { 
			$name = "$directory/$file";		
			if ( -d $name ) {
				&rmtree($name);			
			} elsif ( -f $name ) {
				unlink $name;
			}
		}
	}
    
    #___ delete _map.ncd since we do only need {_par.ncd}
    foreach $file (@files) {
        if ($file =~ /.*\_map.ncd/) {
            $name = "$directory\\$file";
            unlink $name;
        }
    }
    
    #___ create result directory if not given
    my $db = "$ROOT_DIR/db";
    my $design_name = "$db/$PROJECT_NAME";
    my $design_rtl = "$design_name/design_rtl";
    my $fpga_family = "$design_name/$FAMILY";
	my $fpga_device_package = "$fpga_family/$DEVICE";
    my $fpga_opt_target = "$fpga_device_package/$OPTIMIZATION_TARGET";
    
    printf "$db\n";
    printf "$design_name\n";
    printf "$design_rtl\n";
    printf "$fpga_family\n";
    printf "$fpga_device_package\n";
    printf "$fpga_opt_target\n";
    
    mkdir $db;
    mkdir $design_name;
    mkdir $design_rtl;
    mkdir $fpga_family;
    mkdir $fpga_device_package;
    mkdir $fpga_opt_target;
    
    #${PROJECT_NAME}_${FAMILY}_${DEVICE}_${OPTIMIZATION_TARGET}.ncd"
	   
    #___ copy results to directory
    foreach $file (@files) {
        if (($file =~ /.*.ncd/) or ($file =~ /.*.xdl/) or ($file =~ /.*.vhd/) or ($file =~ /.*.bit/) or ($file =~ /.*.call/)) {
            if (!($file =~ /.*_map.ncd/)) {
                my $src_file_path = "$directory\/$file";
                my $dst_file_path = "";
                
                if($file =~ /.*.ncd/){
                    $dst_file_path = "$fpga_opt_target\/$file";
                }
                elsif($file =~ /.*.xdl/){
                    $dst_file_path = "$fpga_opt_target\/$file";
                }
                elsif($file =~ /.*.vhd/){
                    $dst_file_path = "$fpga_opt_target\/$file";	
                }
                elsif($file =~ /.*.bit/){
                    $dst_file_path = "$fpga_opt_target\/$file";	
                }
                elsif($file =~ /.*.call/){
                    $dst_file_path = "$fpga_opt_target\/$file";	
                }
                
                
                warn "source = $src_file_path\n";
                warn "dest = $dst_file_path";
                copy($src_file_path, $dst_file_path) or warn "copy failed: $!";		
            } 
        }
    }

}

sub trim_spaces {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}









1; #return 1 when including this file along with other scripts.