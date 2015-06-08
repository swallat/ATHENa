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
# clean_workspace.pl
#
# Last Updated   :  11/15/2009
# Purpose 	: clean workspace
# Usage : clean_workspace.pl $1
#	$1	: the workspace at which the user wants to be cleaned 
#		  if no input, then the workspace used in design.config will be cleaned
#
# Methodology : 
#		Navigate to project folder and look at report_option.txt.
#		If tool info is identified then proceed to the next project.
#		Otherwise, delete.
#####################################################################

use Cwd;
use File::Path;




$CONSTANT_FILE_NAME = "constants.pl"; $BIN_DIR_NAME = "bin";		$REGEX_FILE_NAME = "regex.pl";
$OPTION_REPORT_NAME = "report_option.txt";
$UTILS_DIR_NAME = "utils";
$ROOT_DIR = cwd; 

$ROOT_DIR =~ s/\/$BIN_DIR_NAME\/$UTILS_DIR_NAME//;

$CONFIG_DIR = "config"; 

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

# ===== MAIN ======

my $workspace;

if ( $#ARGV == 0 ) {
	$workspace = shift();
} elsif ( $#ARGV == -1) {
	require "$ROOT_DIR\/$BIN_DIR_NAME\/$CONSTANT_FILE_NAME";
	require "$ROOT_DIR\/$BIN_DIR_NAME\/$REGEX_FILE_NAME";
	require "$ROOT_DIR\/$BIN_DIR_NAME\/support.pl";

	open(DESIGNOPTS, "$ROOT_DIR\/$DESIGN_CONFIGURATION_FILE") || die("Could not acquire design configuration file!");
	my @data = <DESIGNOPTS>;
	close(DESIGNOPTS);
	
	foreach $line (@data) {			
		$line =~ s/#.*$//i;
		if ( $line =~ m/WORK_DIR\s*=\s*<${REGEX_FOLDER_IDENTIFIER}>/i ) { $workspace = $1; last;}
	}
	if ($workspace eq "") { $workspace = "ATHENa_workspace"; }
} else {
	print "Invalid input parameters. Program terminating ...\n";
}

$workspace = &processRelativePath($workspace, "");

print "Cleaning --> $workspace\n";
print "===========================\n";
if ( not (-d "$workspace") ) { 
	print "Path not existed. Exit cleaning routine.\n\n"; system( pause ); exit; 
}

foreach $app ( &getdirs($workspace)  ) {
	my $app_path = $workspace . "/" . $app;
	foreach $proj ( &getdirs($app_path)  ) {	
		my $delete = 0;
		$proj_path = $app_path . "/". $proj;
		$option_report_path = $proj_path."/".$OPTION_REPORT_NAME;		
		if ( -e $option_report_path ) {
			open ( FILE, "< $option_report_path" );
			my $data = join(" ", <FILE>);
			close ( FILE );
			my $tool = "";
			my $ver = "";            
			if ( $data =~ m/Synthesis[\s\t]+:[\s\t]+([\d\w. ]+)[\s\t]+-[\s\t]+([\d\w.]+)/i ) {
				$tool = $1; $ver = $2;
			}
			# tool or version name not found
			if (($tool eq "") or ($ver eq "")) {                
				$delete = 1;
			}
		} else { $delete = 1; }
		if ( $delete == 1 ) { print "deleting ... $proj_path\n"; 
        rmtree($proj_path); 
        }		
	}
}

print "===========================\n";
system( pause ); 


