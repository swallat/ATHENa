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
# report_generator.pl 
# v0.1
#
# Last Updated   :  
# Purpose 	: report generator 
# Usage		: report_generator.pl $1
#		$1 = workspace directory (full path only)
#
#####################################################################

use Cwd;
use File::Path;

$CONSTANT_FILE_NAME = "constants.pl"; $BIN_DIR_NAME = "bin";		$REGEX_FILE_NAME = "regex.pl";
$UTILS_DIR_NAME = "utils"; $REPORT_SCRIPT_NAME = "report.pl";		$CONFIG_DIR = "config"; 
$ROOT_DIR = cwd; 

$ROOT_DIR =~ s/\/$BIN_DIR_NAME\/$UTILS_DIR_NAME//;

$report_dir = "$ROOT_DIR\/$BIN_DIR_NAME";
$report_dir =~ s/\//\\/g;
$report_script = "$report_dir\\$REPORT_SCRIPT_NAME";
if ( not -e $report_script ) { print "Error!!! Missing report.pl\n"; exit; }



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

sub app_choice {
	my %data = %{shift()}; 
	my $app = shift();

	while(1) {
		print "\n\nWhich project would you like to view?\n\n";
		my $i = 0;
		@app_list = keys ( %{$data{$app}} );
		@app_list = sort ( @app_list );
		foreach my $proj ( @app_list ) {
			$i++;			
			$option[$i] = $proj;
			$last_option = $i;
			print "$i.\t$proj\n";
		}
		$ret = $i+1;
		$exit = $i+2;
		print "$ret.\tReturn to a higher level menu\n";
		print "$exit.\tExit the program\n\n";

		print "Please select one of the above options [1-$exit]: ";
		$choice = <STDIN>; chop($choice);
		if ( $choice >= 1 and $choice <= $last_option  ) {
			my $call_path = "$data{$app}{$option[$choice]}";
			chdir( $report_dir ) or die "$!";            
			system( "perl \"$report_script\" \"$call_path\" display" );
            
			while (1) {
				print "\n\nWould you like to overwrite previously generated result files (y/n)?: ";
				my $result = <STDIN>; chop($result);
				if ($result =~ m/y/i) {
                    print "$report_script\n";
                    print "$call_path\n";
					system( "perl \"$report_script\" \"$call_path\" print" );
					last;
				} elsif ($result =~ m/n/i) {					
					last;
				} else {
					print "\tError: Invalid input.\n";
				}
			}
		} elsif ( $choice == $ret ) {
			return;
		} elsif ( $choice == $exit ) {
			exit;
		} else {
			print "Invalid choice. Please select between [1-$exit].\n\n";
		}
	}
}
# ===== MAIN ======

my $workspace;

if ( $#ARGV == 0 ) {
	$workspace = shift();
} elsif ( $#ARGV == -1) {
	require "$ROOT_DIR\/$BIN_DIR_NAME\/$CONSTANT_FILE_NAME";
	require "$ROOT_DIR\/$BIN_DIR_NAME\/$REGEX_FILE_NAME";
	require "$ROOT_DIR\/$BIN_DIR_NAME\/support.pl";

	open(DESIGNOPTS, "$ROOT_DIR\/$DESIGN_CONFIGURATION_FILE") || die("Could not acquire design configuration file!");
	my $data = join(" ", <DESIGNOPTS>);
	close(DESIGNOPTS);
	
	if ( $data =~ m/WORK_DIR\s*=\s*<${REGEX_FOLDER_IDENTIFIER}>/gi ) { $workspace = $1; } else { $workspace = "ATHENa_workspace"; }				
	$workspace = processRelativePath($workspace, "");
} else {
	print "Invalid input parameters. Program terminating ...\n";
}

if ( not (-e "$workspace") ) { print "No workspace found!\n\n"; exit; }

# ============ processing inputs

my @option;
my $choice;
my $exit;
my $last_option;

system( cls );

#___ removed!
#print "==========================\n";
#print "==== 3 REPORT GENERATOR ====\n";
#print "==========================";
#while(1) {
#	# populating data
#	my %data;
#	foreach my $app ( &getdirs($workspace)  ) {
#		my $app_path = $workspace . "\\" . $app;
#		foreach $proj ( &getdirs($app_path)  ) {	
#			$proj_path = $app_path . "\\". $proj;
#			$data{$app}{$proj} = $proj_path;
#		}
#	}
#
#	my $i = 0;
#	print "\n\n";
#	print "Please select one of the following applications :\n\n";
#	foreach my $app (keys %data) {
#		$i++;
#		print "$i.\t$app\n";
#		$option[$i] = $app;
#		$last_option = $i;
#	}
#	$exit = $i + 1;
#	print "$exit.\tExit the program\n\n";
#
#	print "Please select one of the above options [1-$exit]: ";
#	$choice = <STDIN>; chop($choice);
#	if ( $choice >= 1 and $choice <= $last_option  ) {
#		&app_choice(\%data, $option[$choice]);
#	} elsif ( $choice == $exit ) {
#		exit;
#	} else {
#		print "Invalid choice. Please select between [1-$exit].\n";
#	}
#
