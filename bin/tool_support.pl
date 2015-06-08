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

#=========================================================================================
#	SUPPORT FUNCTIONS for Tool related stuff
#	DATA_FILE (tool_data.txt) General Format::
#	REGEX_TOOL_DATA:
		# 	$1 	 [ $2 			] [ $3     ] [ $4           ] [ $5   ] [ $6(TYPE) ][ $7?       ]
		# VENDOR [ SYN/IMP/SIM  ] [ NUMBER ] [ VERSION_NAME ] [ PATH ] [ FREE/SUB ][ SELECTED? ]
# 	REGEX_CORE_DATA :
		# CORE [ MAX_USAGE ][ AVAILABLE ]		
#=========================================================================================

use Storable qw(dclone);
use Config;


#####################################################################
# list all the directories in a folder
#####################################################################
sub getdirs{
  my $dir = shift;
  my $curdir = getcwd;
  
  opendir(DIR,$dir) or die "Can't open the current directory: $!\n";
  my @names = readdir(DIR);
  closedir(DIR);
  my @return = ();
  chdir($dir);
  foreach $name (@names) {
    next if (($name eq ".") or ($name eq ".."));
    if (-d $name){
      push(@return, $name);
    }
  }
  chdir($curdir);

  return @return;
}


#####################################################################
# return different version type based on version input
#####################################################################
sub switch_version {
	my $vendor = shift();
	my $version = shift();
	
	if ($vendor =~ m/xilinx/i) {
		if ( $version =~ m/webpack/i) {
			return "designsuite";
		} else {
			return "webpack";
		}
	} elsif ($vendor =~ m/altera/i) {
		if ( $version =~ m/web_edition/i ) {
			return "subscription_edition";
		} else {
			return "web_edition";
		}
	}
	print "Error{switch_version}!!\n\nUNSUPPORTED VENDOR!!! Program terminating.\n"; system( pause );
	exit;	
}
#####################################################################
# Flags when no tool is detected
#####################################################################
sub any_tool_install_detect {
	
		my $string = shift();
		my $pat = "Not detected";
		my $tool_flag =0;
        while ($string =~m/$pat/g) {
         $tool_flag++;
        }
		return $tool_flag ;
		}


#####################################################################
# Loads the device library
#####################################################################
sub configure_library{
	print("Generating Library Files...\t");
	my %data = %{shift()};
	
	foreach my $vendor (@VENDOR_LIST){	
		if ( not exists $data{$vendor}{imp}{selected_choice} ) { next; }
		
		my ($lib_string, $lib_ver);
		my ($old_lib_file, $new_lib_file);
		my ($final_lib_file);
		
		#detect tool versions
		my $version_type = lc($data{$vendor}{imp}{choice_list}{$data{$vendor}{imp}{selected_choice}}{version_type});
		if (lc($vendor) eq "xilinx"){
			$lib_string = lc($vendor)."_device_lib_".$version_type;			
			$lib_ver = $data{$vendor}{imp}{choice_list}{$data{$vendor}{imp}{selected_choice}}{version_name};			
			$final_lib_file = $xilinx_device_library_file;
		}
		elsif(lc($vendor) eq "altera"){			
			$lib_string = lc($vendor)."_device_lib_quartus_".$version_type;
			$lib_ver = lc($data{$vendor}{imp}{choice_list}{$data{$vendor}{imp}{selected_choice}}{version_name});					
			$final_lib_file = $altera_device_library_file;
		}		
		$lib_ver =~ s/ [\d\w.\W]+$//i; # remove anything after spaces	
		
		#detect libraries
		my $vendorlibdir = $ROOT_DIR."/".$DEVICE_LIB_DIR."/_".$lib_string."/";
		# print "vendorlibdir \t\t $vendorlibdir\n";		
		my $lib_file = $ROOT_DIR."/".$DEVICE_LIB_DIR."/_".$lib_string."/".$lib_string."_".$lib_ver.".txt";
		# print "old_file: $lib_file\n";		
		my $new_lib_file = $ROOT_DIR."/".$DEVICE_LIB_DIR."/".lc($vendor)."_device_lib.txt";
		# print "new_file: $new_lib_file\n";

		#if correct lib is found use it
		if(-e $lib_file){
			#print("library found - ". replace_chars($lib_file, $vendorlibdir, "", "text") ."\n");			
			copy($lib_file, $new_lib_file) or goto filecopyerr;
			replace_chars($new_lib_file, $vendorlibdir, "", "text");
		} else {
			goto userinput;
			
			filecopyerr:
			printerror("error copying library files! looking for alternative files...\n", 0);
					
			userinput:
			#otherwise ask the user
			opendir(dir, "$vendorlibdir");
			my @temp_files = readdir(dir);
			my @lib_files;
			foreach my $t (@temp_files) {
				if ( $t =~ m/.txt/i ) {	push (@lib_files, $t); }				
			}
						
			#@lib_files = map{my $string = $_; $string =~ s/$vendorlibdir//gi; $string;} @lib_files;
			my $total_files = $#lib_files + 2;
			
			while( 1 ){
				my $input;
				while ( 1 ) {
					system( clear );
					print "\n\n";
					print "================================================================================\n";
					print "'$vendor' library version '$lib_ver' is missing from device_lib folder.\n";
					print "This file should be located in =>\n";
					print "$lib_file\n\n";
					print "If another type of vendor library exists, you may want to manually update your\n";
					print "version\\library by navigate to <Manual => Implementation Setup => $vendor>\n\n";
					print "Note : You can browse the device_lib folder of your installation to see\n";
					print "avaiailable libraries.\n\n";
					print "For a temporary fix, you will need to select one of the following choices.\n";
					print "Please be aware that if you decide to skip, most of ATHENa's features will\n";
					print "not function properly\n";
					print "================================================================================\n\n";
					foreach $count (0..$#lib_files){
						print "\t".($count+1).". $lib_files[$count]\n";
					}					
					print "\t".($#lib_files+2).". Skip (Warning: ATHENa may not be functioning correctly)\n\n";
					print "Your choice :: ";
					$input = <stdin>;
					chop ($input);
					if ( $input < 1 || $input > $total_files ) {
						print "Invalid input. Please try again.\n\n";
					} else { last;	}					
				}
				
				if ($input == $total_files) { last; }
				#print "input \t\t $input\n";
				my $lib_file = $vendorlibdir.$lib_files[$input-1];
				#print "lib_file \t\t $lib_file\n";
				if (-e $lib_file) {					
					copy($lib_file, $new_lib_file);
					last;
				} else {
					printerror("error copying library files! please select another file...\n\n", 0);
				}
			}
		}
		
		vendordone:		
		#replace tab characters, otherwise loading the library will fail
		replace_chars($final_lib_file, "\t", "");
	}
	print "[DONE]\n";

}


#####################################################################
# print current data, use for debugging
#####################################################################
sub print_data {
	my %data = %{shift()};
	my $display_type = shift();

	my @types;	
	if ( $display_type =~ m/all/i ) { 
		@types = ( "sim", "imp", "syn" );
	} else {
		@types = $display_type;
	}
	
	foreach $type ( @types ) {
		my $word;
		if ( $type =~ m/sim/i ) { $word = "Simulators"; };
		if ( $type =~ m/imp/i ) { $word = "Implementation\\Fit Tools"; };
		if ( $type =~ m/syn/i ) { $word = "Synthesis Tools"; };
		print "\n\nPrinting --> $word\n";
		foreach $vendor ( keys %data ) {
			print "$vendor: selected<$data{$vendor}{$type}{selected_choice}>\n";
			my $count = 0;
			foreach $num ( keys %{$data{$vendor}{$type}{choice_list}} ) {
				$count++;
				print "\t$num -> $data{$vendor}{$type}{choice_list}{$num}{version_name}\t: $data{$vendor}{$type}{choice_list}{$num}{root_dir}\t: $data{$vendor}{$type}{choice_list}{$num}{version_type}\n";
			}
			print "\tTotal tools = $count\n";
		}
	}
	system( pause );
}

#####################################################################
# Populating data if "tool_config.txt" not exists in config folder
#####################################################################
$TOOL_DATA_FILE = "tool_config.txt";
$DATA_FILE = "$ROOT_DIR/$CONFIG_DIR_NAME/$TOOL_DATA_FILE";
	# General Format :
	# VENDOR [ TYPE ][ NUMBER ] [ VERSION_NAME ] [ ROOT_DIR ] [VERSION_TYPE] [ SELECTED? ]
$REGEX_TOOL_INFO = qr/([\w]*)\[([\w\s]*)]\[(\d*)\]\[([\w\d.\s-]*)\]\[([\s\:\d\w.\\\/ ()-]*)\]\[([\w\d.]*)\]\[(\w*)\]/i;
	# CORE [ MAX_USAGE ][ AVAILABLE ]
$REGEX_CORE_INFO = qr/CORE\[(\d*)\]\[(\d*)\]/;
	# OS_INFO [ OS ][ SYSTEM ARCHITECTURE ]
$REGEX_OS_INFO = qr/OS_INFO\[(\w*)\]\[(\d*)\]/;

sub load_tool_data {
	my %data;
	if ( -e "$DATA_FILE" ) {
		print " \n Populating data from previous settings ... \n";
		%data = %{&get_info_from_data_file()};				
	} else {		#FIRST RUN
		print " \n Populating data from environmental variables \n ";
		%data = %{&get_toolinfo_from_env()};	
		%data = %{&get_toolinfo_from_possible_locations(\%data)};
		$data{core}{available} = &get_coreinfo_from_env();
		$data{core}{max_usage} = $data{core}{available};
		my %os_data = &get_os_info();#raj
		$data{'os'} = $os_data{'os'};#raj
		$data{'os_arch'} = $os_data{'os_arch'};#raj
		my %new_data = %{ dclone(\%data) };

		&set_latest_tool_settings(\%new_data);
		my $str = get_current_settings(\%new_data);
		
		#my $tool_check = any_tool_install_detect($str);
		#print "Tool check == $tool_check\n";


		while ( 1 ) {
			system ( clear );
			print "\n\n\tWelcome to Automated Tool for Hardware EvaluatioN (ATHENa)!\n\n";
			print " \n\tIt seems that this is your first time in running ATHENa.\n";
			print "\tATHENa has Automatically selected the following settings for you :\n\n$str\n";
			print "\tWould you like to use current settings?\n\n";
			print "Your choice [y/n] :: ";
			
			my $choice = <STDIN>; chop($choice);
			if ( $choice =~ m/y/i ) {					
				 &save( \%new_data ); exit;
			} elsif ( $choice =~ m/n/i ) {
				my $location = "ATHENa Setup";
				&set_manual($location, \%data, 1);
			} else {
				print "Invalid input, please try again\n";
			}

		



			
	    }
	}

	return (\%data);
}
#####################################################################
# Get option list from data file "tool_config.pl"
#####################################################################
sub get_coreinfo_from_data_file {
	my $infotype = shift();
	my %core;	
	
	open ("inf","< $DATA_FILE") || die "could'nt open $DATA_FILE\n";
		while ( $record = <inf> ) {
			if ( $record =~ /$REGEX_CORE_INFO/) {
				# CORE[$max_usage][$avilable]
				$core{max_usage} = $1;
				$core{available} = $2;				
			}	
			
		}
	close ("inf");
	
	if ( $infotype =~ m/max_usage/i ) {
		return $core{max_usage};
	} elsif ( $infotype =~ m/available/i ) {
		return $core{avilable};
	} else {
		print "tool_support.pl : Error!! Invalid Logical Processor info type `$infotype`\n"; exit;
	}	
}

#####################################################################
# Get option list from data file "tool_config.pl"
#####################################################################
sub get_info_from_data_file {
	my %data;
	
	open ("inf","< $DATA_FILE") || die "could'nt open tool.txt\n";
		while ( $record = <inf> ) {
			if ( $record =~ /$REGEX_TOOL_INFO/) {		
				$data{$1}{$2}{choice_list}{$3}{version_name} = $4;
				$data{$1}{$2}{choice_list}{$3}{root_dir} = $5;
				$data{$1}{$2}{choice_list}{$3}{version_type} = $6;
				if ( $7 eq "selected" ) { 
					$data{$1}{$2}{selected_choice} = $3;
				}				
			}
			if ( $record =~ /$REGEX_CORE_INFO/) {
				# CORE[$max_usage][$avilable]
				$data{core}{max_usage} = $1;
				$data{core}{available} = $2;				
			}
			if ( $record =~ /$REGEX_OS_INFO/) {
				# OS_INFO[OS][OS_ARCH]
				$data{'os'} = $1;
				$data{'os_arch'} = $2;				
			}	
		}
	close ("inf");
	return ( \%data );
}


#####################################################################
# Get coreinfo from ENV
#####################################################################
sub get_coreinfo_from_env {
	#my $core = $ENV{"NUMBER_OF_PROCESSORS"};
	 my $core = &no_of_processors();
	if ( $core < 1 ) { 
		print "\tError!!! Unable to detect the number of your Logical Processors\n\n";
		print "\tWindows User:\n\tPlease check if the environmental variable \"NUMBER_OF_PROCESSORS\" is set.\n";
		print "\tThis value should be bigger than 0. You can check the variable by typing \"echo %NUMBER_OF_PROCESSORS%\"\n";
		print "\tin command prompt.\n\n";
		print "\tLinux User:Please check Number of Processors in your system by typing \"cat /proc/cpuinfo\"\n";
		print "\tin the terminal.\n";
		print "\tFor now, ATHENa will assume that your computer contains only single logical processor\n";
		system( pause );
		$core = 1;
	}
	return ($core);
}


#####################################################################
# Get toolinfo from ENV
#####################################################################
sub get_toolinfo_from_env {
	my %data;
	my @plist = (@PATH_LIST, $XILINX_ENV, $ALTERA_ENV);
	for (my $count = 0; $count < scalar@plist; $count++)
	{			
		print "$plist[$count]\n";
		#if ( $plist[$count] =~ /actel/i ) { print "$plist[$count]\n"; system( pause ); }
		my @t = &check_and_add_path("any", "any", $plist[$count], \%data);		
		%data = %{$t[1]};
	}

	return (\%data);
}

#####################################################################
# Get toolinfo from ENV
#####################################################################
sub get_toolinfo_from_possible_locations {
	my %data = %{shift()};
	
	# ------
	# Xilinx
	# ------
	my $static_path = "C:\\Xilinx";
		#check for subdirectory ( should contain version )
	#my @possible_xilinx_paths = ("\\ise\\bin", "\\ise_ds\\ise\\bin" );
	my @possible_xilinx_paths = ("/ise/bin", "/ise_ds/ise/bin" );
	if ( -d $static_path ) {
		@dirs = &getdirs( $static_path ); 
		foreach $dir ( @dirs ) {
			foreach $extension ( @possible_xilinx_paths ) {
				my $p = "${static_path}/${dir}$extension";	
				my @t = &check_and_add_path("any", "any", $p, \%data);		
				%data = %{$t[1]};
			}			
		}
	}
	return (\%data);
}
#####################################################################
# ROUTINE TO GET SYSTEM ARCHITECTURE--os info
#####################################################################
sub get_os_info {

#####################################################################
# OS Hash
#####################################################################
my  %os_hash =(os => "",os_arch => "",);
#####################################################################
$os_hash{'os'} = $Config{osname};
$os_hash{'os_arch'} = $Config{archname};
my $i=0;
my $len =0;
my @var = split("-", $os_hash{'os_arch'});
my $len = scalar(@var);
while($i < $len)
{		
	if ($var[$i] =~ /86_64/ ){
	$os_hash{'os_arch'} = 64;} elsif ($var[$i] =~ /86/ ){
	$os_hash{'os_arch'} = 32;}
	$i++;
		}

return %os_hash;
}
#####################################################################
# ROUTINE TO GET NUMBER OF PROCESSORS -USED IN LINUX AND CYGWIN
#####################################################################

sub no_of_processors {
        $no_of_proc = 0;
my $i=0;
my $len =0;
        @cpu_info = `cat /proc/cpuinfo`;
        $len = scalar(@cpu_info);
        while($i < $len)
        {
                if ($cpu_info[$i] =~ m/processor/ )
                        { $no_of_proc++;
                                }
                $i++;
                }
        return $no_of_proc;
}

#####################################################################
# Overwriting tool_data file
#####################################################################
sub get_selected_tool_info {
	my %data = %{shift()};
	my ($vendor, $type, $info ) = (shift(), shift(), shift());

	if ( not defined $data{$vendor}{$type}{selected_choice} ) {		
		return (1, "N/A");
	}
	my $choice = $data{$vendor}{$type}{selected_choice};
	
	return (0, $data{$vendor}{$type}{choice_list}{$choice}{$info});
}


#####################################################################
# Overwriting tool_data file
#####################################################################
sub update_tool_data_file {
	my %data = %{shift()};	
	
	print "Generating new $TOOL_DATA_FILE...\t";	
	
	open (outf, "> $DATA_FILE") || die "could'nt overwrite $DATA_FILE\n";
	foreach $vendor ( @VENDOR_LIST ) {	
		foreach $type ( keys ( %{$data{$vendor}} ) ) {
			foreach $i ( sort( keys %{$data{$vendor}{$type}{choice_list}} ) ) {
				print outf "$vendor\[$type\]\[$i\]";		# vendor [ type ] [ choice ]
				print outf "[$data{$vendor}{$type}{choice_list}{$i}{version_name}]"; 
				print outf "[$data{$vendor}{$type}{choice_list}{$i}{root_dir}]";
				print outf "[$data{$vendor}{$type}{choice_list}{$i}{version_type}]";
				
				if ( $i == $data{$vendor}{$type}{selected_choice} ) {
					print outf "[selected]\n";
				} else {
					print outf "[]\n";
				}
			}
		}
	}		
	print outf "CORE[$data{core}{max_usage}][$data{core}{available}]\n";
	print outf "OS_INFO[$data{os}][$data{os_arch}]\n";
	close (outf);
	print "[DONE]\n";
}

#####################################################################
# get path to data file
#####################################################################
sub set_latest_tool_settings {
	my %data = %{shift()};

    foreach my $vendor ( keys %data ) {
		#Use the latest version
		# syn & imp tool
		if ( scalar keys %{$data{$vendor}{imp}{choice_list}} >= 1 ) {
			my @sorted = sort { $data{$vendor}{imp}{choice_list}{$b}{version_name} <=> $data{$vendor}{imp}{choice_list}{$a}{version_name}}  keys %{$data{$vendor}{imp}{choice_list}};
			$data{$vendor}{imp}{selected_choice} = $sorted[0];
		}
		# sim tool
		foreach my $k ( keys %{$data{$vendor}{sim}{choice_list}} ) {
			if ( $data{$vendor}{sim}{choice_list}{$k}{version_name} =~ m/${DEFAULT_SIM_VENDOR}/i ) {
				$data{$vendor}{sim}{selected_choice} = $k;
				goto NEXT_SETTINGS;
			}		
		}
		NEXT_SETTINGS:
	}
	$data{core}{max_usage} = $data{core}{available};	
}


#####################################################################
# get path to data file
#####################################################################
sub get_new_path {
	my %data = %{shift()};
	my ($xilinx_rootdir, $xilinx_path, $altera_rootdir, $altera_path);
    
	my $path = "";
    foreach $vendor ( @VENDOR_LIST ) {			
        my $choice = $data{$vendor}{imp}{selected_choice};
        if ( $vendor =~ /xilinx/i ) {
            $xilinx_rootdir = $data{$vendor}{imp}{choice_list}{$choice}{root_dir};
			#$xilinx_rootdir = $xilinx_rootdir.$STR_ISE;
            $xilinx_path = $xilinx_rootdir;
			$xilinx_path1 = $xilinx_path;
			#print "path = $xilinx_path\n";
			if ( $xilinx_path =~ /(bin[\w\d\D\\\/]+)/i ) {
				print "Found - $1!\n";
				$temp = $1;
				$temp =~ s/\\/\\\\/g;
				#print "path1 = $temp\n";
				$xilinx_path1 =~ s/${temp}//i;
				#print "path1 = $xilinx_path1\n";
			}
            
			$path .= "export XILINX=\"$xilinx_path\"\n";
        } elsif ( $vendor =~ /altera/i ) {
            $altera_rootdir = $data{$vendor}{imp}{choice_list}{$choice}{root_dir};
            #$altera_rootdir = $altera_rootdir.$STR_QUARTUS;

            $altera_path = $altera_rootdir;
			$altera_path =~ s/\\bin//i;
            
			$path .= "export QUARTUS_ROOTDIR=\"$altera_path\"\n";
        }	
    }
    $xilinx_rootdir = $xilinx_rootdir.":";
	$altera_rootdir = $altera_rootdir.":";

	#$path .= "export PATH=\"/usr/local/bin:/usr/bin:/bin:$altera_rootdir:$xilinx_rootdir:$PATH_ENV\"\n";
	$path .= "export PATH=\"$altera_rootdir$xilinx_rootdir\$PATH\"\n";
	#$path .= "source ".$xilinx_path1."settings$data{'os_arch'}.sh\n";
	return $path;
}

#####################################################################
# overwrite and update the shell file
#####################################################################
sub update_bat_file {
	
	print "Generating new ATHENa.sh...\t";

	my %data = %{shift()};
	open ( shell_file , "> $ROOT_DIR/ATHENa.sh" )  || die "could'nt overwrite ATHENa.bat\n";
	
    my $path = &get_new_path ( \%data );
	
	#print batch_file "$path";
	#print batch_file "cd bin\n";
	#print batch_file "main.pl \%1 \n";
	#print batch_file "cd ..\n";
	#print batch_file "pause";
	
print shell_file <<SHELL;
#!/bin/bash
###########################
#Shell Script to Run ATHENa
###########################
#Function to Simulate 'Pause' as in Windows
pause()
{
	read -s -n 1 -p "ATHENa Execution Completed. Press any key to continue . . ."
	echo
	}
#Setting Path Variables
$path
#Starting ATHENa
cd bin
perl main.pl \$1
if [ "\$1" = "nopause" ] ; then #Req. for ATHENa Spooler
	echo done
	cd ..
else					         #ATHENa Execution Complete

	pause


	cd ..
fi
#EOF
SHELL

	
	close (shell_file);
	system ("chmod +x $ROOT_DIR/ATHENa.sh");
	print "[DONE]\n";				
}
#####################################################################
# update tool data and batch file
#####################################################################
sub save {
	my %data = %{shift()};
	#update tool_data.txt
	&update_tool_data_file(\%data);	
	#update start.sh
	&update_bat_file( \%data );	
	&configure_library( \%data );
}	
#####################################################################
# reorder any unexisting choice list
#####################################################################
sub update_choice_list {
	$vendor = shift;
	$type = shift;
	%data = %{shift()};

	# return if no data
	if ( scalar(keys %{$data{$vendor}{imp}{choice_list}}) == 0 ) { return; }
	
	my @list = sort { $a <=> $b } keys %{$data{$vendor}{$type}{choice_list}};
	for ( my $i = 1; $i <= scalar@list; $i++) {
		#print $list[$i-1];
		if ( $i == $list[$i-1] ) {
			#do nothing
		} else {
			%{$data{$vendor}{$type}{choice_list}{$i}} = (
				version_name => $data{$vendor}{$type}{choice_list}{$list[$i-1]}{version_name},
				root_dir => $data{$vendor}{$type}{choice_list}{$list[$i-1]}{root_dir},
				version_type => $data{$vendor}{$type}{choice_list}{$list[$i-1]}{version_type},
			);
			delete $data{$vendor}{$type}{choice_list}{$list[$i-1]};
		}		
	}
}


#####################################################################
# retrieve a string of current settings
#####################################################################
# ======== DISPLAY SIZE
sub get_current_settings{	
	my %data = %{shift()};
	
	my $str = "=========== FPGA Tools ===========\n\n";
	foreach $vendor ( @VENDOR_LIST ) {				
		$str .= sprintf("$vendor :\n");
		$str .= sprintf("   %s", "Syn & Imp Tool");
		if ( exists $data{$vendor}{imp}{selected_choice} ) {
			my $choice = $data{$vendor}{imp}{selected_choice};
			$str .= sprintf("\n\tVersion   : %s\n", $data{$vendor}{imp}{choice_list}{$choice}{version_name});
			$str .= sprintf("\tType      : %s\n", $data{$vendor}{imp}{choice_list}{$choice}{version_type});
			$str .= sprintf("\tLocation  : %s\n", $data{$vendor}{imp}{choice_list}{$choice}{root_dir} );
		} else {
			$str .= " : Not detected\n";
		}
		
		$str .=  sprintf("   %s", "Simulator");
		if ( exists $data{$vendor}{sim}{selected_choice} ) {
			my $choice = $data{$vendor}{sim}{selected_choice};	
			$str .= sprintf("\n\tVendor    : %s\n", $data{$vendor}{sim}{choice_list}{$choice}{version_name});
			$str .= sprintf("\tVersion   : %s\n", $data{$vendor}{sim}{choice_list}{$choice}{version_type});
			$str .= sprintf("\tLocation  : %s\n", $data{$vendor}{sim}{choice_list}{$choice}{root_dir} );
		} else {
			$str .= "      : Not detected\n";
		}		
	}	
	$str .= "\n====== Logical Processors ======\n\n";
	$str .= "Total number of Logical processors                : $data{core}{available}\n";
	$str .= "Number of Logical Processors to be used by ATHENa : $data{core}{max_usage}\n\n";
	$str .= "===================================\n";
	
	$str .= "\n====== Operating System Info ======\n\n";
	$str .= "Operating System    = $data{'os'}\n";
	$str .= "System Architecture = $data{'os_arch'} bit\n"; 
	$str .= "===================================\n";
	return $str;
}
return 1;