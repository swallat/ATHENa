# =============================================
# ATHENA - Automated Tool for Hardware EvaluatioN.
# Copyright © 2009 CERG at George Mason University <cryptography.gmu.edu>.
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

##############################################
# Version Number 	: 0.3
# 0.3 :
#	Functional setting support
# 0.2 : 
#	Update version detection mechanism for xilinx and altera. Versions are now extracted from xflow and quartus_sh command for xilinx and altera, respectively.
#	Extraction of the choice list from environmental variables will operate only when tool_data.txt is not present at the beginning of the program.
#	Added reset settings capability
#	Added additional field to tool_data.txt called version_type. The type specifies whether the user want this to be a subscribe or free version.
#	Added supporting functions for switching version types.
##############################################

use Cwd;
use Storable qw(dclone);
use List::Util qw[min max];
use Config;

# Data structure of hashes use as a basic building block of this script ::
# $VENDOR { sim\imp } { choice_list } 		{ $NUMBER } { root_dir } 	{ $DIR }
# $VENDOR { sim\imp } { choice_list } 		{ $NUMBER } { vendor_name }	{ $NAME_OF_TOOL'SVENDOR }
# $VENDOR { sim\imp } { choice_list } 		{ $NUMBER } { version_name }{ version no }
# $VENDOR { sim\imp } { choice_list } 		{ $NUMBER } { version_type }{ $TYPE } (Free or subscription)
# $VENDOR { sim\imp } { selected_choice } 	{ $NUMBER }
$DEBUG_MODE = "on";
$BIN_DIR_NAME = "bin"; $CONFIG_DIR_NAME = "config";
$ROOT_DIR = cwd; $DEVICE_LIB_DIR = "device_lib";
$ROOT_DIR =~ s/\/$BIN_DIR_NAME//;

# ==============================
# GLOBAL CONSTANTS


$XILINX_ENV = $ENV{'XILINX'};
$ALTERA_ENV = $ENV{'QUARTUS_ROOTDIR'};
$PATH_ENV = $ENV{'PATH'};
@PATH_LIST = split(":", $PATH_ENV);

	# XILINX SPECIFIC CONSTANTS
$STR_ISE_PROG_NAME = "ise";
    # ALTERA SPECIFIC CONSTANTS
$STR_QUARTUS_PROG_NAME = "quartus";
	# MODELSIM
$STR_MODELSIM = "modelsim";	
	# ALDEC
$STR_ALDEC = "aldec";

@VENDOR_LIST = ("xilinx", "altera");	
# ==============================

require "$ROOT_DIR/$BIN_DIR_NAME/tool_core.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/tool_support.pl";
# -- For loading loadDevLibFiles function
require "$ROOT_DIR/$BIN_DIR_NAME/support.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/constants.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/device_lib.pl";
	
# ==============================

sub change_selected_tools_license {
	my %data = %{shift()};
	
	while(1) {
		system( clear );
		print get_current_settings(\%data);
		
		print "\n\tSelect below choices to switch license.\n\n";
		print "\t1) Switch Xilinx's license type\n";
		print "\t2) Switch Altera's license type\n\n";
		print "\tr) return\n";
		
		print "Your Choice :: ";
		my $choice = <STDIN>; chop($choice);
		if ( $choice == 1 ) {			
			$data{xilinx}{imp}{choice_list}{$data{xilinx}{imp}{selected_choice}}{version_type} = &switch_version(xilinx,$data{xilinx}{imp}{choice_list}{$data{xilinx}{imp}{selected_choice}}{version_type});
		} elsif  ( $choice == 2 ) {
			$data{altera}{imp}{choice_list}{$data{altera}{imp}{selected_choice}}{version_type} = &switch_version(altera,$data{altera}{imp}{choice_list}{$data{altera}{imp}{selected_choice}}{version_type});
		} elsif ( $choice =~ /r/i ) { 
			last;
		} else { print "Invalid choice, try again.\n"; }					
	}	
	return (\%data);
}
#####################################################################
# update version routine
#####################################################################
sub set_version_type {
	my $location = shift();
	my $vendor = shift();
	my %data = %{shift()};
	
	$location .= "\n\t=> Library update";
	my $last_choice = scalar(keys %{$data{$vendor}{imp}{choice_list}});	

	while (1) {
		system ( clear );
		print "$location\n\n\n\n";
		print "\n\tSelect below choices to switch between license type\n\n";
		## Printing choice list
		for ( my $i = 1; $i <= $last_choice; $i ++ ) {
			print "\t$i. $data{$vendor}{imp}{choice_list}{$i}{version_name} <$data{$vendor}{imp}{choice_list}{$i}{root_dir} :: $data{$vendor}{imp}{choice_list}{$i}{version_type}>\n";
		}	
		print "\n\t(r) Return     (s) Save     (e) Exit\n\n";
		
		# Asking for choice		
		while ( 1 ) {
			print "Your Choice :: ";
			my $choice = <STDIN>; chop($choice);
			
			if ( $choice >= 1 and $choice <= $last_choice ) {
				$data{$vendor}{imp}{choice_list}{$choice}{version_type} = &switch_version($vendor,$data{$vendor}{imp}{choice_list}{$choice}{version_type});
				last;
			} 
			elsif ( $choice =~ /r/i )  { return(\%data); }
			elsif ( $choice =~ /s/i )  { &save( \%data ); last; }
			elsif ( $choice =~ /e/i )  { exit; }
			else { print "Invalid choice, try again.\n"; }					
		}
	}
}

#####################################################################
# ROUTINE TO GET SYSTEM ARCHITECTURE -returns a hash
#####################################################################
sub get_os_info {

#####################################################################
# OS Hash-- Contains OS info-> {os-- os name; os_arch-- arch(32/64)}
#####################################################################
		my  %os_hash =(os => "",os_arch => "",);
#####################################################################
		$os_hash{'os'} = $Config{osname};
		$os_hash{'os_arch'} = $Config{archname};

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
# LVL 3 
# Manual => Synthesis and Implementation Tools Setup -> $Vendor
#####################################################################


sub set_vendor_tools {
	my $location = shift();		
	my $vendor = shift();
	my %data = %{shift()};
	my $type = shift();

	#print "Vendor :: $vendor\n";
	$location .= "\n\t=> $vendor";
	my $last_choice;
	my $updatetype, $ot, $del;
	START_VENDOR_TOOLS:	
	$last_choice = scalar(keys %{$data{$vendor}{$type}{choice_list}});	
	
	while (1) {		
		system( clear );
		print "$location\n\n\n\n";
		
		if ( $last_choice > 0 ) {
			print "\tATHENa has detected that the following versions of $vendor\n";
			print "\tare installed on your machine.\n";
			print "\tPlease indicate which of these versions you would like to use\n";
			print "\tin the following ATHENa runs.\n\n";

			## Printing choice list
			for ( my $i = 1; $i <= $last_choice; $i ++ ) {
				print "\t$i. $data{$vendor}{$type}{choice_list}{$i}{version_name} <$data{$vendor}{$type}{choice_list}{$i}{root_dir} :: $data{$vendor}{$type}{choice_list}{$i}{version_type}>";
				if ( defined $data{$vendor}{$type}{selected_choice} ) {
					if ( $data{$vendor}{$type}{selected_choice} == $i ) {
						print " <<<";
					}
				}
				print "\n";
			}		
		} else {
			print "\tNo tool found for $vendor\n";
			print "\tPlease make sure that you have installed a tool correctly.\n\n";
			print "\tTo do this, check whether your tool is recognized by operating\n";
			print "\tsystem by typing \"echo \%PATH\%\" in Konsole. If your tool is\n";
			print "\tinstalled correctly, you should be able to see your installed path\n";
			print "\tthere. Otherwise, you can manually add the path to the list used by\n";
			print "\tATHENa, using option 1 below.\n";
		}
		
		print "\n";
		
		if ( $type =~ m/imp/i ) {
			$updatetype = $last_choice + 1;		print "\t$updatetype. Update listed version\\library\n";
		} else { $updatetype = $last_choice; }
		$ot = $updatetype+1;				print "\t$ot. Add another version to the list\n";
		$del = $ot+1; 						print "\t$del. Delete a version from the list\n";
		print "\n\t(r) Return     (s) Save     (e) Exit\n\n";
		
		# Asking for choice
		while ( 1 ) {
			print "Your Choice :: ";
			my $choice = <STDIN>; chop($choice);

			if ( $choice >= 1 and $choice <= $last_choice ) {
				$data{$vendor}{$type}{selected_choice} = $choice;
				last;
			} elsif (($choice == $updatetype) and ($type =~ m/imp/i)) {
				if ( $last_choice == 0 ) {
					print "Nothing to edit.\n"; system( pause );					
				} else {
					&set_version_type($location, $vendor, \%data);
				}									
				last;
			} elsif ( $choice == $ot ) {
				#ask for root directory
				while ( 1 ) {			
					print "\n\tPlease enter the path to the program's executable.\n";
					print "\t\tFor Xilinx, locate 'ise'\n";
					print "\t\tFor Altera, locate 'quartus'\n";
					print "\tFor instance, if you're trying to insert \"opt/altera/91/quartus/bin/quartus\"\n";
					print "\tYou'll need to type \"opt/altera/91/quartus/bin\"\n\n"; 
					
					print "To return to menu, type \"ret\" or \"return\".\n=>";
					my $directory = <STDIN>; chop($directory);
                    # check for valid path
					if (( $directory eq "return" ) || ($directory eq "ret")) {	last; }
					my @t = &check_and_add_path($type, $vendor, $directory, \%data );					
					%data = %{$t[1]};
					if ($t[0] == 0 ) {		
						$last_choice++;
						$data{$vendor}{$type}{selected_choice} = $last_choice;
						goto START_VENDOR_TOOLS;
					} else {
						print "\tError:: Invalid path, please re-enter\n";						
					}
				}
				last;
			} elsif ( $choice == $del ) {				
				if ( $last_choice == 0 ) {
					print "\n\tNo $vendor tool listed. Please select other choice. \n";
				} else {
					while ( 1 ) {			
						print "\n\tPlease select the version you would like to delete \n";
						for ( my $i = 1; $i <= $last_choice; $i ++ ) {
							print "$i. $data{$vendor}{$type}{choice_list}{$i}{version_name} <$data{$vendor}{$type}{choice_list}{$i}{root_dir}>\n";
						}
						my $ch_ret = $last_choice + 1;
						print "$ch_ret. Return\n\nYour Choice[1-$ch_ret]:: ";
						
						$del_choice = <STDIN>; chop($del_choice);	
						
						if (($del_choice < 1) or ($del_choice > $ch_ret)) {
							print "Invalid choice, please try again.\n";
						} elsif ( $del_choice == $ch_ret ) {
							last;
						} else {
							while ( 1 ) {
								print "\nYou're deleting version $data{$vendor}{$type}{choice_list}{$del_choice}{version_name} <y/n>?:: ";
								my $result = <STDIN>; chop($result);
								if (($result eq "y") or ($result eq "Y")) {
									
									if ( $del_choice == $data{$vendor}{$type}{selected_choice} ) {
										delete $data{$vendor}{$type}{selected_choice};
									} elsif ( $data{$vendor}{$type}{selected_choice} > $del_choice ) {
										$data{$vendor}{$type}{selected_choice} = $data{$vendor}{$type}{selected_choice} - 1;
									}
									
									delete $data{$vendor}{$type}{choice_list}{$del_choice};
									&update_choice_list($vendor, $type, \%data );
									$last_choice = $last_choice - 1;
									
									last;
								} elsif (($result eq "n") or ($result eq "N")) {					
									last;
								} else {
									print "\tError: Invalid input.\n";
								}
							}
						}
					}
				}
				last;
			} 
			elsif ( $choice =~ /r/i )  { return(\%data); }
			elsif ( $choice =~ /s/i )  { &save( \%data ); last; }
			elsif ( $choice =~ /e/i )  { exit; }
			else { print "Invalid choice, try again.\n"; }			
		}
	}
}
#####################################################################
# LVL 2 
# Manual => Core Usage Setup
#####################################################################
sub set_core_usage {
	my $location = shift();
	my %data = %{shift()};
	my $type = shift();
	
	$location .= "\n\t=>  Logical Processor(s) Usage Setup";
	
	if ( $data{core}{available} == 1 ) {
		print "You cannot modify this value as you only have a single Logical Processor.\n";
		system( pause );
		return;
	}
	while (1) {	
		system( clear );
		print "$location\n\n\n\n";
		print "You have $data{core}{available} Logical Processor(s) available.\n";
		print "Please select the maximum number of Logical Processors to be used by ATHENa.\n";
		print "Your Choice [1-$data{core}{available}] :: "; 
		my $choice = <STDIN>; chop($choice);
		if ( $choice < 1 || $choice > $data{core}{available} ) {
			print "\nInvalid input. Please try again.\n\n"; system( pause );
		} else {
			$data{core}{max_usage} = $choice;
			return;
		}
	}
}
	
#####################################################################
# LVL 2 
# Manual => Synthesis and Implementation Tools Setup 
#####################################################################

sub set_tools_type {
	my $location = shift();
	my %data = %{shift()};
	my $type = shift();
	
	my $loc;
	if ( $type =~ m/sim/i ) { $loc = "Simulator Setup"; }
	if (( $type =~ m/imp/i ) or ( $type =~ m/syn/i ))  { $loc = "Synthesis and Implementation Tools Setup"; }
	$location .= "\n\t=> $loc";
		
	my %selection;
	while (1) {				
		foreach $vendor ( @VENDOR_LIST ) {		
			if ( exists $data{$vendor}{$type}{selected_choice} ) {
				$selection{$vendor} = "$data{$vendor}{$type}{choice_list}{$data{$vendor}{$type}{selected_choice}}{version_name} :: $data{$vendor}{$type}{choice_list}{$data{$vendor}{$type}{selected_choice}}{version_type}";
			} else {
				$selection{$vendor} = "N/A";
			}
		}
		
		system( clear );	
		print "$location\n\n\n\n";
		print "Please select the following choices\n\n";
		
		my $ch = 0;
		foreach $vendor ( @VENDOR_LIST ) {		
				$ch++;
				print "\t$ch Set $VENDOR_LIST[$ch-1] tool <$selection{$VENDOR_LIST[$ch-1]}>\n";		
		}		
		print "\n\t(r) Return     (s) Save     (e) Exit\n\n";
		

		while ( 1 ) {
			print "Your Choice :: "; my $choice = <STDIN>; chop($choice);
			
			if ( $choice =~ /r/i )  { return(\%data); }
			elsif ( $choice =~ /s/i )  { &save( \%data ); last; }
			elsif ( $choice =~ /e/i )  { exit; }
			elsif ( $choice <= $ch and $choice > 0 ) {				
				%data = %{&set_vendor_tools($location, $VENDOR_LIST[$choice-1], \%data, $type)};
				last;
			}
			else { print "Invalid choice, try again.\n"; }			
		}
	}
}


#####################################################################
# LVL 1 
# Automated  
#####################################################################

sub set_default {
	my $location = shift();
	my %data = %{shift()};
	my %new_data = %{ dclone(\%data) };
	$location .= "\n\t=> Default Setup";
	
	my $str = "$location\n\n\n\n";
	
	if ( scalar keys %data < 1 ) {
		print "ATHENa detected no tools installed in your computer,\n";
		print "you may want to perform the following step.\n\n";
		print "\t1 : Reload ATHENa's tool settings from environmental variables\n";
		print "\t    (this option is located at top level). This option will recreate\n";
		print "\t    the list from environmental variables.\n\n";
		print "\t2 : Check whether the environmental variable is set correctly\n";
		print "\t    To do this, check whether your tool is recognized by operating\n";
		print "\t    system by typing \"echo \%PATH\%\" in command prompt. If your\n";
		print "\t	 tool is installed correctly, you should be able to see your installation\n";
		print "\t	 path there. Otherwise, you can navigate to Manual Setup and manually\n";
		print "\t	 add the path to your tool location.\n";
		system( pause );
		return( \%data );
	}
	
	&set_latest_tool_settings( \%new_data );	
	
	
	my $a = get_current_settings(\%data);
	my $b = get_current_settings(\%new_data);
	
	if ( $a eq $b ) {
		$str .= "No changes required for these settings ::\n";
		$str .= $a;
			$str .= "\n\n$b\n\n";
		$str .= "\n\n";
		system ( clear );
		print $str;
		system( pause );
		return ( \%data );
	}
	
	$str .= "Current Settings ::\n$a\n\n";
	$str .= "Default Settings ::\n$b\n\n";
	$str .= "To change any settings, navigate to Manual Setup and make adjustment accordingly.\n";
	$str .= "Would you like to accept these changes [y/n]? ";
	
	while ( 1 ) {
		system( clear );
		print $str;
		my $choice = <STDIN>; chop($choice);
		if ( $choice =~ m/y/i ) {					
			return( \%new_data );
		} elsif ( $choice =~ m/n/i ) {
			return( \%data );
		} else {
			print "Invalid input, please try again\n\n"; system( pause );
		}				
	}	
}

#####################################################################
# LVL 1 
# Manual
#####################################################################

sub set_manual {
	my $location = shift();
	my %data = %{shift()};
	my $firstrun = shift();
	
	$location .= "\n\t=> Manual Setup";
	while(1) {
		system( clear );
		print "$location\n\n\n\n";
			
		my $str = get_current_settings(\%data); print "$str";
		
		print "\n\nPlease select from the choices below :\n\n";
		print "\t1) Synthesis and Implementation Tools Setup\n";
		print "\t2) Simulator Setup\n";
		print "\t3) Logical Processor Usage Setup\n";
		if ( $firstrun == 1 ) {
			print "\n\t(s) Save     (e) Exit\n\n";
		} else {
			print "\n\t(r) Return     (s) Save     (e) Exit\n\n";
		}
		
		while ( 1 ) {
			print "Your Choice :: ";	$choice = <STDIN>; chop($choice);
			if ( $choice == 1 ) 	{	%data = %{&set_tools_type($location, \%data, "imp")}; last; }
			elsif ( $choice == 2 )  {	%data = %{&set_tools_type($location, \%data, "sim")}; last; }
			elsif ( $choice == 3 )  { &set_core_usage($location, \%data); last; }
			elsif ( $choice =~ /r/i and $firstrun != 1 )  { return(\%data); }
			elsif ( $choice =~ /s/i )  { &save( \%data ); last; }
			elsif ( $choice =~ /e/i )  { exit; }
			else { print "Invalid choice, try again.\n"; }			
		}
	}
}

#####################################################################
# LVL 0 
#####################################################################

sub set_athena {
	my %data = %{shift()};
	
	$location = "ATHENa Setup";

	while(1) {
		system( clear );
		print "$location\n\n\n\n";			

		my $str = "   Welcome to ATHENa - Automated Tool for Hardware EvaluatioN!\n";
		$str .= "   ATHENa has detected the following FPGA tools and features\n   of your computer system:\n\n\n";

		$str .= get_current_settings(\%data); print "$str";
		
		#my %os_hash =  &get_os_info();
		
		print "\n\nPlease select from the following choices :\n\n";		
		print "\t1) Manual Setup\n";
		print "\t2) Change selected tools license\n";
		print "\t3) Automatically Select Latest Version of Available Tools\n";
		print "\t4) Reload ATHENa Settings from Environmental Variables\n\n";
		print "\t(s) Save     (e) Exit\n\n";
		
		while ( 1 ) {
			print "Your Choice :: ";	$choice = <STDIN>; chop($choice);
			
			if ($choice == 1) 	{	%data = %{&set_manual($location, \%data)};		last;}
			elsif ($choice == 2) {  %data = %{&change_selected_tools_license(\%data)}; last; }
			elsif ($choice == 3) {	%data = %{&set_default($location, \%data)};		last;}
			elsif ($choice == 4) {
					while ( 1 ) {
						print "This option will PERMANENTLY delete all settings and reload a new one\n";
						print "from environmental variables. Do you still want to proceed [y/n]? ";
						my $choice2 = <STDIN>; chop($choice2);
						if ( $choice2 =~ m/y/i ) {					
							unlink( $DATA_FILE );
							if (-e $DATA_FILE ) {print "$DATA_FILE!\nNOOO!!\n";}
							%data = %{&load_tool_data()};
							last;
						} elsif ( $choice2 =~ m/n/i ) {
							last;
						} else {
							print "Invalid input, please try again\n";
						}				
					}
					last;
				}
			elsif($choice =~ /s/i) {	print "\n"; &save( \%data ); last;}
			elsif($choice =~ /e/i) { exit; }
			elsif ( $choice =~ /d/i and $DEBUG_MODE =~ /on/i) { print_data(\%data,"all"); }
			else { print "Invalid choice, try again.\n"; }			
		}
	}
}

#####################################################################
# STARTS HERE
#####################################################################

my %data = %{&load_tool_data()};
		#print_data(\%data, "all" );
&set_athena( \%data );




