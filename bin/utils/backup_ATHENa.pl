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
# backup_ATHENa.pl
#
# Last Updated   :  11/15/2009
# Purpose 	: Backup ATHENa project folder (can also be used for other files)
# Usage : backup_ATHENa.pl $1 $2 $3
#	$1 = INPUT_DIRECTORY PATH
#	$2 = OUTPUT DIRECTORY PATH
# 	$3 = FILE NAME (OPTIONAL)
#####################################################################
use Cwd;
use Time::Local;

$BIN_DIR_NAME = "/bin";
$UTIL_DIR_NAME = "/utils";
$ATHENA_NAME = "/ATHENa";

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my @month_abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
$year += 1900; ## $year contains no. of years since 1900, to add 1900 to make Y2K compliant

print "$abbr[$mon] $mday"; ## gives Dec 17
$input = 1 + $#ARGV;
if (( $input == 2 ) or ( $input == 3)) {
	$INPUT_DIR = shift() . "/";
	$OUTPUT_DIR = shift() . "/";
	if ( $input == 3 ) { $FILE = shift(); } else { $FILE = "ATHENa"; }
} elsif ( $input == 0 ) {
	$INPUT_DIR = cwd;
	$INPUT_DIR =~ s/$ATHENA_NAME$BIN_DIR_NAME$UTIL_DIR_NAME/\//;
	$OUTPUT_DIR = cwd . "\/";
	$FILE = "ATHENa";
} else {
	print "Invalid input arguments\n\n"; exit;
}


	
my $exit;
if ( not -e $INPUT_DIR ) {
	print "Invalid input directory\n"; $exit = 1;
}

if ( not -e $OUTPUT_DIR ) {
	print "Invalid output directory\n"; $exit = 1;
}

if ( not -e ($INPUT_DIR.$FILE) ) {
	print "Invalid backup file\n"; $exit = 1;
}
if ($exit == 1) { exit; }	

$OUTFILE = sprintf( "%s_%d%s%d_%02d%02d%02d", $FILE, $year, $month_abbr[$mon], $mday, $hour, $min, $sec );

system( "zip -9 -r -T -q $OUTPUT_DIR$OUTFILE $INPUT_DIR$FILE " );
