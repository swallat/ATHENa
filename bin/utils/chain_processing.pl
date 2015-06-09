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
# chain_processing.pl 
# v0.1
#
# Last Updated   :  
# Purpose 	: Queuing ATHENa projects by automated the design_configuration process.
# Usage		: chain_processing.pl
#
#####################################################################


use Cwd;
use File::Path;
use File::Copy;

print "\n\n";
$CONSTANT_FILE_NAME = "constants.pl"; $BIN_DIR_NAME = "bin";		$REGEX_FILE_NAME = "regex.pl";
$UTILS_DIR_NAME = "utils"; $REPORT_SCRIPT_NAME = "report.pl";		$CONFIG_DIR_NAME = "config"; 
$ROOT_DIR = cwd; 

$ROOT_DIR =~ s/\/$BIN_DIR_NAME\/$UTILS_DIR_NAME//;

$SPOOL_DIR_NAME = "spool";
$SPOOL_DIR = "$ROOT_DIR/$CONFIG_DIR_NAME/$SPOOL_DIR_NAME";
$PROCESSING_DIR = "$ROOT_DIR/$CONFIG_DIR_NAME/$SPOOL_DIR_NAME/processing";
$COMPLETED_DIR = "$ROOT_DIR/$CONFIG_DIR_NAME/$SPOOL_DIR_NAME/completed";
$CONFIG_DIR = "$ROOT_DIR/$CONFIG_DIR_NAME";
$ATHENA = "\"$ROOT_DIR/ATHENa.bat\" nopause";
$DESIGN_CONFIG = "$CONFIG_DIR/design.config.txt";

#####################################################################
# list all the directories in a folder
#####################################################################
sub get_design_config {  
  
  opendir(DIR,$SPOOL_DIR) or die "Can't open the current directory: $!\n";
  unless(-d $PROCESSING_DIR){    mkdir $PROCESSING_DIR or die; }
  unless(-d $COMPLETED_DIR) {    mkdir $COMPLETED_DIR or die; }

  my @names = readdir(DIR);
  closedir(DIR);
  foreach $name (@names) {
    next if (($name eq ".") or ($name eq "..") or ($name =~ /completed/i) or (-d $name) or ( $name !~ /.txt$/i) or ($name =~ /processing/i));
    return $name;
  }  
}

##############################
##############################
# MAIN
##############################
##############################

my $file = &get_design_config();

if ( $file eq "" ) { print "No file(s) to run\n\n"; exit; }

while ( $file ne "" ) {
	unlink( $DESIGN_CONFIG );
	copy("$SPOOL_DIR/$file", $DESIGN_CONFIG );
	print "\n\n ============== \n RUNNING ==> $file\n ==============\n";
	move("$SPOOL_DIR/$file", "$PROCESSING_DIR/$file" );
	sleep( 3 ); 	
	$result = system( "$ATHENA" );	
	move("$PROCESSING_DIR/$file", "$COMPLETED_DIR/$file" );
	$file = &get_design_config();
}