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
# Loads the design configuration to the global variables specified
# This function is shared among the mail and dispatches scripts
#####################################################################
sub read_DesignConfig {
	printOut("Reading design configuration...");	
	
	printOut("DESIGN_CONFIGURATION_FILE		$DESIGN_CONFIGURATION_FILE\n");
	
	open(DESIGNOPTS, "$DESIGN_CONFIGURATION_FILE") || printErrorToScreen("\n\n\n Main - Support: Could not acquire design configuration file!\n\n\n", 1);
	@tooldata = <DESIGNOPTS>;
	close(DESIGNOPTS);
	@tooldata = @{remove_comments(\@tooldata)};
	
	#default value
	$WORK_DIR = "ATHENa_workspace";
	
    $DB_CRITERIA = "throughput_area";
    $DB_QUERY_MODE = "off";
        
	my %generics;
	my $size = @tooldata;
	my $i = 0;
	for($i=0;$i<$size;$i++){	
		#print $i;
		#skip all the # signs in the options
		# my $substring = substr $tooldata[$i], 0, 1;
		# next if($substring =~ /#/);
			
		if($tooldata[$i] =~ m/WORK_DIR\s*=\s*${REGEX_PATH_IDENTIFIER}/gi){
			$WORK_DIR = &trim_spaces($1);			
			#print "WORK_DIR				 $WORK_DIR\n";
		}
		if($tooldata[$i] =~ m/SOURCE_DIR\s*=\s*${REGEX_PATH_IDENTIFIER}/gi){
			$SOURCE_DIR = &trim_spaces($1);		
			#print "SOURCE_DIR				 $SOURCE_DIR\n";
		}
		if($tooldata[$i] =~ m/SOURCE_LIST_FILE\s*=\s*${REGEX_PATH_IDENTIFIER}/gi){
			$SOURCE_LIST_FILE = &trim_spaces($1);
			#print "SOURCE_LIST_FILE				 $SOURCE_LIST_FILE\n";
		}
		# =========== Verification
		if($tooldata[$i] =~ m/VERIFICATION_DIR\s*=\s*${REGEX_PATH_IDENTIFIER}/gi){
			$VERIFICATION_DIR = &trim_spaces($1);
			#print "VERIFICATION_DIR				 $VERIFICATION_DIR\n";
		}
		if($tooldata[$i] =~ m/VERIFICATION_LIST_FILE\s*=\s*${REGEX_PATH_IDENTIFIER}/gi){
			$VERIFICATION_LIST_FILE = &trim_spaces($1);
			#print "VERIFICATION_LIST_FILE				 $VERIFICATION_LIST_FILE\n";		
		}
		if($tooldata[$i] =~ m/VERIFICATION_ONLY\s*=\s*${REGEX_PATH_IDENTIFIER}/gi){
			my $temp = $1; $temp =~ s/<|>//g;
			$VERIFICATION_ONLY = $temp;
			# force default value if unspecified
			if ( $VERIFICATION_ONLY eq "" ) { $VERIFICATION_ONLY = $DEFAULT_VERIFICATION_ONLY;	}
			#print "VERIFICATION_ONLY				 $VERIFICATION_ONLY\n";
		}
		if($tooldata[$i] =~ m/TB_TOP_LEVEL_ENTITY\s*=\s*${REGEX_PATH_IDENTIFIER}/gi){
			my $temp = $1; $temp =~ s/<|>//g;
			$TB_TOP_LEVEL_ENTITY = $temp;
			#print "TB_TOP_LEVEL_ENTITY				 $TB_TOP_LEVEL_ENTITY\n";
		}
		if($tooldata[$i] =~ m/TB_TOP_LEVEL_ARCH\s*=\s*${REGEX_PATH_IDENTIFIER}/gi){
			my $temp = $1; $temp =~ s/<|>//g;
			$TB_TOP_LEVEL_ARCH = $temp;
			#print "TB_TOP_LEVEL_ARCH				 $TB_TOP_LEVEL_ARCH\n";
		}
		if($tooldata[$i] =~ m/MAX_TIME_FUNCTIONAL_VERIFICATION\s*=\s*${REGEX_PATH_IDENTIFIER}/gi){
			my $temp = $1; $temp =~ s/<|>//g;
			$MAX_TIME_FUNCTIONAL_VERIFICATION = $temp;
			#print "MAX_TIME_FUNCTIONAL_VERIFICATION				 $MAX_TIME_FUNCTIONAL_VERIFICATION\n";
		}
		if($tooldata[$i] =~ m/FUNCTIONAL_VERIFICATION_MODE\s*=\s*${REGEX_PATH_IDENTIFIER}/gi){
			my $temp = $1; $temp =~ s/<|>//g;
			$FUNCTIONAL_VERIFICATION_MODE = $temp;
			# force default value if unspecified
			if ( $FUNCTIONAL_VERIFICATION_MODE eq "" ) { $FUNCTIONAL_VERIFICATION_MODE = $DEFAULT_FUNCTIONAL_VERFICATION_MODE;	}
			#print "FUNCTIONAL_VERIFICATION_MODE				 $FUNCTIONAL_VERIFICATION_MODE\n";
		}		
		# ============ End of verification
		if($tooldata[$i] =~ m/PROJECT_NAME\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
			$PROJECT_NAME = $1;
			#print "PROJECT_NAME				 $PROJECT_NAME\n";
		}
		if($tooldata[$i] =~ m/TOP_LEVEL_ENTITY\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
			$TOP_LEVEL_ENTITY = $1;
			#print "TOP_LEVEL_ENTITY			 $TOP_LEVEL_ENTITY\n";
		}
		if($tooldata[$i] =~ m/TOP_LEVEL_ARCH\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
			$TOP_LEVEL_ARCH = $1;
			#print "TOP_LEVEL_ARCH				 $TOP_LEVEL_ARCH\n";
		}
		if($tooldata[$i] =~ m/CLOCK_NET\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
			$CLOCK_NET  = $1;
			#print "CLOCK_NET				 $CLOCK_NET \n";
		}
		if($tooldata[$i] =~ m/OPTIMIZATION_TARGET\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
			$OPTIMIZATION_TARGET  = $1;
			#print "OPTIMIZATION_TARGET			 $OPTIMIZATION_TARGET \n";
		}
		if($tooldata[$i] =~ m/OPTIONS\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
			$OPTIONS  = $1;
			#print "OPTIONS				 	$OPTIONS \n";
		}
		if($tooldata[$i] =~ m/LATENCY\s*=\s*${REGEX_CONFIG_FORMULA_IDENTIFIER}/gi){
			$LATENCY  = $1;
			#print "LATENCY			 $LATENCY \n";
		}
		if($tooldata[$i] =~ m/THROUGHPUT\s*=\s*${REGEX_CONFIG_FORMULA_IDENTIFIER}/gi){
			$THROUGHPUT  = $1;
			#print "THROUGHPUT				 	$THROUGHPUT \n";
		}
		
		if($tooldata[$i] =~ m/APPLICATION\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
			$APPLICATION  = $1;			
		}
		
		if($tooldata[$i] =~ m/TRIM_MODE\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
			$TRIM_MODE  = $1;			
		}
		
        if($tooldata[$i] =~ m/DB_QUERY_MODE\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
			$DB_QUERY_MODE  = $1;			
		}
        
        if($tooldata[$i] =~ m/DB_CRITERIA\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
			$DB_CRITERIA = $1;			
		}
        
        
		if($tooldata[$i] =~ m/GLOBAL_GENERICS_BEGIN/i) {
			$i++;		
			my $count = 1;
			while(1) {
				$tooldata[$i] =~ s/ //gi; # remove spaces for easier processing
				if ( $tooldata[$i] =~ m/([\w\d]+)\s*=\s*([\d\w,\s]+)/gi) {				# a = 1,2,3
					$generics{global}{$count}{name} = $1;
					my @values = split(/,/,join('',split(/ /,$2)));
					$generics{global}{$count}{values} = \@values;				
					$count++;
				} elsif ( $tooldata[$i] =~ m/\(([\w,\s\d]+)\)\s*=\s*([\(\)\d\w,\s]+)/gi) {	# (a,b,c) = (1,2,3) , (4,5,6);															
					my $name = $1;					
					my @array = ($2 =~ m/([\w\d,]+)/gi);
					my @values = ();
					foreach $val ( @array ) {
						if ( $val eq "," ) { next; } #remove any useless comma
						else { 
							push ( @values, $val);						
						}
					}					
					$generics{global}{$count}{name} = $name;	
					$generics{global}{$count}{values} = \@values;
					$count++;					
				} elsif ( $tooldata[$i] =~ m/GLOBAL_GENERICS_END/i) { 
					last;
				} 
				$i++;
			}					
		}
		
					
		while($tooldata[$i] =~ m/FPGA_VENDOR\s*=\s*(\w+)/gi){
            
            
			my $vendor = &trim_spaces($1);
			$done = 0; #0 = false, 1=true
			while ($done == 0){
				$i++;
				my $substring = substr $tooldata[$i], 0, 1;
				if(($tooldata[$i] =~ /END[\s^\w]*VENDOR/i)){
					$done = 1;
				}
				elsif( $tooldata[$i] =~ m/FPGA_FAMILY\s*=\s*([\w_ -]+)/gi) { 
                    
						my $family = &trim_spaces(lc($1));
						my $device_string;
						
						my $REQ_SYN_FREQ = 0;
						my $REQ_IMP_FREQ = 0;
						my $SYN_CONSTRAINT_FILE = "default";
						my $IMP_CONSTRAINT_FILE = "default";
						
						my %UTIL_FACTORS = ();
						my @DEVICE_ITEMS = @{$VENDOR_DEVICE_ITEMS{lc($vendor)}};
						my @UTIL_DEFAULTS = @{$VENDOR_DEVICE_UTIL_DEFAULTS{lc($vendor)}};
						
						#print join(" ", @DEVICE_ITEMS)."\n\n";
						#print join(" ", @UTIL_DEFAULTS)."\n\n";
						
						$done1 = 0; #0 = false, 1=true
						while ($done1 == 0){
							$i++;
							my $substring = substr $tooldata[$i], 0, 1;
							if(($tooldata[$i] =~ /END[\s^\w]*FAMILY/i)){
								$done1 = 1;
							}
							elsif($substring =~ /[\s\\\\-_\/#]+/){}
							else{
								if($tooldata[$i] =~ m/FPGA_DEVICES\s*=\s*([\w,-_ ]+)/gi){
									$device_string = $1;
									#print $device_string;
								}
								
								#not efficient way to load
								#load utilization factors
								foreach my $P (0..$#DEVICE_ITEMS){
									my $ITEM = $DEVICE_ITEMS[$P];
									my $lookupstring = "MAX_".$ITEM."_UTILIZATION";
									#print "Searching for string $lookupstring\n";
									if ($tooldata[$i] =~ m/${lookupstring}\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
										$UTIL_FACTORS{$ITEM} = $1;
										#print "Found $lookupstring : $1\n";
									}
								}
								
								if($tooldata[$i] =~ m/REQ_SYN_FREQ\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
									$REQ_SYN_FREQ = $1;
									#print $REQ_SYN_FREQ;
								}
								if($tooldata[$i] =~ m/SYN_REQ_FREQ\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
									$REQ_SYN_FREQ = $1;
									#print $REQ_SYN_FREQ;
								}
								
								if($tooldata[$i] =~ m/REQ_IMP_FREQ\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
									$REQ_IMP_FREQ = $1;
									#print $REQ_IMP_FREQ;
								}
								if($tooldata[$i] =~ m/IMP_REQ_FREQ\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
									$REQ_IMP_FREQ = $1;
									#print $REQ_IMP_FREQ;
								}
								
								if($tooldata[$i] =~ m/SYN_CONSTRAINT_FILE\s*=\s*${REGEX_PATH_IDENTIFIER}/gi){
									$SYN_CONSTRAINT_FILE = &trim_spaces($1);									
								}
								if($tooldata[$i] =~ m/IMP_CONSTRAINT_FILE\s*=\s*${REGEX_PATH_IDENTIFIER}/gi){
									$IMP_CONSTRAINT_FILE = &trim_spaces($1);
								}
								if($tooldata[$i] =~ m/GENERICS_BEGIN/i) {
									$i++;		
									my $count = 1;
									while(1) {
										if ( $tooldata[$i] =~ m/([\w\d]+)\s*=\s*([\d\w,\s]+)/) {				# a = 1,2,3
											$generics{$vendor}{$family}{$count}{name} = $1;
											my @values = split(/,/,join('',split(/ /,$2)));
											$generics{$vendor}{$family}{$count}{values} = \@values;											
											$count++;
										} elsif ( $tooldata[$i] =~ m/\(([\w,\s\d]+)\)\s*=\s*([\(\)\d\w,\&\s]+)/) {	# (a,b,c) = (1,2,3) & (4,5,6);					
											my $name = $1;					
											my @array = ($2 =~ m/([\w\d,]+)/gi);
											my @values = ();
											foreach $val ( @array ) {
												if ( $val eq "," ) { next; } #remove any useless comma
												else { 
													push ( @values, $val);
												}
											}
											$generics{$vendor}{$family}{$count}{name} = $name;	
											$generics{$vendor}{$family}{$count}{values} = \@values;
											$count++;			
										} elsif ( $tooldata[$i] =~ m/GENERICS_END/i) { 
											last;
										} 
										$i++;
									}		
								}
							}
						}
						
						#assign default values to the utilization factors
						foreach my $i (0..$#DEVICE_ITEMS){
							my $ITEM = $DEVICE_ITEMS[$i];
							#printOut($ITEM." - ".$UTIL_FACTORS{$ITEM}."\n");
							#$UTIL_FACTORS{$ITEM} = $UTIL_DEFAULTS[$i] unless($UTIL_FACTORS{$ITEM} > 0);
							$UTIL_FACTORS{$ITEM} = $UTIL_DEFAULTS[$i] if($UTIL_FACTORS{$ITEM} eq "");
							#printOut($ITEM." - ".$UTIL_FACTORS{$ITEM}."\n");
						}
						
						#could be multiple devices seperated by a comma
						my @devices = split(/[, ]+/, $device_string);
						#keep track of devices in the global hash 'requested_devices'
						foreach $dev (@devices){
							chomp($dev);
							my $Device = new Device();
							$Device->setVendor(lc($vendor));
							$Device->setFamily($family);
							$Device->setDevice(lc($dev));
							$Device->setRequestedFreqs($REQ_SYN_FREQ, $REQ_IMP_FREQ);
							$Device->setConstraintFile($SYN_CONSTRAINT_FILE, $IMP_CONSTRAINT_FILE);
							$Device->setUtilizationFactors(\%UTIL_FACTORS);							
							push(@{$requested_devices{lc($vendor)}}, $Device);							
						}
                }
				
			}
		}
	}

	$WORK_DIR =~ s/<|>//g;
	$WORK_DIR = processRelativePath($WORK_DIR, "");
	$SOURCE_DIR =~ s/<|>//g;
	$SOURCE_DIR = processRelativePath($SOURCE_DIR, "");
	$SOURCE_LIST_FILE =~ s/<|>//g;
	$SOURCE_LIST_FILE = processRelativePath($SOURCE_LIST_FILE, "source_dir");
	$VERIFICATION_DIR =~ s/<|>//g;
	$VERIFICATION_DIR = processRelativePath($VERIFICATION_DIR, "");
	$VERIFICATION_LIST_FILE =~ s/<|>//g;
	$VERIFICATION_LIST_FILE = processRelativePath($VERIFICATION_LIST_FILE, "$VERIFICATION_DIR");
	$SYN_CONSTRAINT_FILE = processRelativePath($SYN_CONSTRAINT_FILE, "source_dir") unless($SYN_CONSTRAINT_FILE =~ m/default|none/gi);
	$IMP_CONSTRAINT_FILE = processRelativePath($IMP_CONSTRAINT_FILE, "source_dir") unless($IMP_CONSTRAINT_FILE =~ m/default|none/gi);;	
	printOut("done\n");
	
	return ( \%generics );
}

#####################################################################
# Create project folder
#####################################################################
sub configureWorkspace{
	
	#create workspace directory
	create_dir("$WORK_DIR");
	
	#Temporary error checks
	#check if work directory is present
	printError("CRITICAL ERROR: The workspace directory provided in the design configuration file doesnot exist!\n\n", 1) unless(-d "$WORK_DIR");
	
	#create the app folder
	create_dir("$WORK_DIR/$APPLICATION");
	
	#determine the workspace folder
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);	
	$year = 1900 + $year;
	$mon = 1 + $mon;
	if($mon < 10) { $mon = "0".$mon; }
	if($mday < 10) { $mday = "0".$mday; }
	my $RunNo = 1;
	$WORKSPACE = "$WORK_DIR/$APPLICATION/".$year."_".$mon."_".$mday."_".$PROJECT_NAME."_".$RunNo;
	#print "Config project --> $RunNo\n";
	#While the directories exist keep counting up!
	while(-d $WORKSPACE){
	#	print "\tincrementing -> $RunNo\n";
		$RunNo++;
		$WORKSPACE = "$WORK_DIR/$APPLICATION/".$year."_".$mon."_".$mday."_".$PROJECT_NAME."_".$RunNo;
	}
	
	$RunNo++;
	&create_dir($WORKSPACE);
	
	$TEMP_DIR = "$WORKSPACE/temp";
	&create_dir($TEMP_DIR);
}


#####################################################################
# Loads the tool information according to the environmental variables
# Check constants.pl for more info
# 
# We need tools for both synthesis and implementation
# so ISE and Quartus can do both
# synplify can do synthesis
# 
# we could make this function generic, by providing a mapping function to match tools to vendors
# Unnecessary work for little payoff
#####################################################################
sub tool_config{
	my @vendors = @_;
	my @retvals = ();
	
	my $Synplifydone = 0;
	
	foreach $vendor (@vendors){
		if(lc($vendor) eq "xilinx"){
			my $retval = 0;
			unless ($Synplifydone == 1){
				&configureSynplify();
				$Synplifydone = 1;
			}
			$retval = configureISE();
			push(@retvals, $retval);
		}
		elsif(lc($vendor) eq "altera"){
			my $retval = 0;
			unless ($Synplifydone == 1){
				&configureSynplify();
				$Synplifydone = 1;
			}
			$retval = configureQuartus();
			push(@retvals, $retval);
		}
		elsif(lc($vendor) eq "actel"){
			printError("Error: Tool configuration - Vendor not supported!\n",0);
			push(@retvals, 1);
		}
		else{
			printError("Error: Tool configuration - Vendor not found!\n",0);
			push(@retvals, 1);
		}
	}
	return @retvals;
}

#####################################################################
# Configure Xilinx ISE
#####################################################################
sub configureISE{
	my $retval = 0;
	
	#$ISE_ENV_VAR = "XILINX";
	#$ISE_INSTALL_FOLDER = $ENV{$ISE_ENV_VAR};

	if($ISE_INSTALL_FOLDER eq "") {
		printError("ERROR: Tool configuration - cannot acquire ISE installation directoy\n", 0);
		return 1;
	}
	
	$ISE_INSTALL_FOLDER =~ s/\\/\//gi;
	$ISE_INSTALL_FOLDER .= "\/" unless($ISE_INSTALL_FOLDER =~ m/\/$/gi);
	$XST = $ISE_INSTALL_FOLDER."xst.exe";
	$XNGDBUILD = $ISE_INSTALL_FOLDER."ngdbuild.exe";
	$XMAP = $ISE_INSTALL_FOLDER."map.exe";
	$XPAR = $ISE_INSTALL_FOLDER."par.exe";
	$XTRACE = $ISE_INSTALL_FOLDER."trce.exe";
	$XPARTGEN = $ISE_INSTALL_FOLDER."partgen.exe";
	
	$XXDL = $ISE_INSTALL_FOLDER."xdl.exe"; #___ add xdl support
	$XNETGEN = $ISE_INSTALL_FOLDER."netgen.exe"; #___ add netgen support
	
	return 0;
}

#####################################################################
# Configure Altera Quartus
#####################################################################
sub configureQuartus{
	#$ALTERA_ENV_VAR = "QUARTUS_ROOTDIR";
	#$ALTERA_INSTALL_FOLDER = $ENV{$ALTERA_ENV_VAR};

	if($ALTERA_INSTALL_FOLDER eq "") {
		printError("ERROR: Tool configuration - cannot acquire Altera Quartus installation directoy\n",0);
		return 1;
	}
	
	$ALTERA_INSTALL_FOLDER =~ s/\\/\//gi;
	$ALTERA_INSTALL_FOLDER .= "\/" unless($ALTERA_INSTALL_FOLDER =~ m/\/$/gi);
	$QMAP = $ALTERA_INSTALL_FOLDER."quartus_map.exe";
	$QFIT = $ALTERA_INSTALL_FOLDER."quartus_fit.exe";
	$QASM = $ALTERA_INSTALL_FOLDER."quartus_asm.exe";
	$QTAN = $ALTERA_INSTALL_FOLDER."quartus_tan.exe";
	$QSTA = $ALTERA_INSTALL_FOLDER."quartus_sta.exe";
	$QPOW = $ALTERA_INSTALL_FOLDER."quartus_pow.exe";
	
	return 0;
}


#####################################################################
# Configure Synplify
#####################################################################
sub configureSynplify{
	return 1;
}

#####################################################################
# Print Generics Data
#####################################################################
sub printGenerics{
	my %generics = %{shift()};
	
	foreach $vendor ( keys %generics ){
		if ( $vendor =~ m/global/i ) {
			print "Global --> \n";
			foreach $count ( keys %{$generics{$vendor}} ) {
				print "\t$generics{$vendor}{$count}{name} ->\n";
				foreach $val (@{$generics{$vendor}{$count}{values}}) {
					print "\t\t$val\n";
				}
				print "\n";
			}
			print "\n\n";			
		} else {
			foreach $family ( keys %{$generics{$vendor}} ){		
				print "$vendor - $family --> \n";
				foreach $count ( keys %{$generics{$vendor}{$family}} ) {
					print "\t$generics{$vendor}{$family}{$count}{name} ->\n ";
					foreach $val (@{$generics{$vendor}{$family}{$count}{values}}) {
						print "\t\t$val\n";
					}				
					print "\n";
				}
				print "\n";
			}
		}
	}
}

#####################################################################
# Print Generics Data
#####################################################################
sub getGenericsInfo{
	my ( $gen_ref, $vendor, $family ) = @_;
	my %generics = %{$gen_ref};

	my %combo;
	## Overwriting generics from global with family and form a new hash
	foreach $count ( keys %{$generics{global}} ) {		
		my $generic_name = $generics{global}{$count}{name};	
		$combo{$generic_name} = \@{$generics{global}{$count}{values}};	
	}
	foreach $count ( keys %{$generics{$vendor}{$family}} ) {
		my $generic_name = $generics{$vendor}{$family}{$count}{name};		
		if ( exists $combo{$generic_name} ) { delete $combo{$generic_name}; }
		$combo{$generic_name} = \@{$generics{$vendor}{$family}{$count}{values}};
	}
	
	## from the new hash, generate combination using loops	
	return ( \@{&formCombinations(\%combo)} );	
}

#####################################################################
# Form generic combinations
#####################################################################
sub formCombinations {
	my %combo = %{shift()};
	my @combo_array = ();
	my @names = sort keys %combo ;
	
	# recursive calling
	my	$generic_name = shift(@names);
	#my $generic_name = $names[0];
	my @generic_values = @{$combo{$generic_name}};
	delete $combo{$generic_name};
	my @combinations = ();
	if ( $#names >= 0 ) {
		@combinations = @{&formCombinations(\%combo)};
	}
	
	# form strings
	my @strings = ();
	foreach $generic_value (@generic_values ) {
		my @temp_names = ( $generic_name =~ m/([\d\w]+)/gi );		
		if ( $#temp_names >= 0 ) {
			my @temp_values = ( $generic_value =~ m/([\d\w]+)/gi );
			
			#check for errors
			my $combo_count = ($#temp_values+1)/($#temp_names+1); 
			if ( $combo_count =~ m/[.]+/i ) { 					
				print "Error! invalid combination between values and names in generic ($combo_count)\n";
				print "Please check your design configuration.\n";
				system( pause ); exit;
			}
			my $temp_str; 
			for ( $name_id = 0; $name_id < $combo_count; $name_id++ ) {
				for( $i = 0; $i < $#temp_names+1; $i ++ ) {
					my $addr = $name_id*$#name_id+$i;
					$temp_str .= "$temp_names[$i]=$temp_values[$addr]";
					if ( $i != $#temp_names ) { $temp_str .= ","; }
				}				
				push ( @strings, $temp_str );
				$temp_str = "";
			}
		}
	}
	
	#combine strings to each combination
	foreach $str ( @strings ) {	
		$str =~ s/,/ /gi;
		if ( $#combinations >= 0 ) {
			foreach $combo (@combinations) {
				my $new_combo = "$combo $str";
				push ( @combo_array, $new_combo );
			}
		} else {
			push (@combo_array, $str );
		}
	}
	
	
	return \@combo_array;
}

1; #return 1 when including this file along with other scripts.