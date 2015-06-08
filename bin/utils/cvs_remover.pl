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
# Purpose 	: Remove all the cvs folders
# Usage : Simply run the script, a new xilinx_device.lib will be generated in the same folder
#####################################################################
#use IPC::Open3;
use File::Path;
use File::Copy;
use Cwd;
$BIN_DIR_NAME = "bin"; $UTIL_DIR_NAME = "utils"; $CUR_DIR = cwd;
$ROOT_DIR = cwd; $ROOT_DIR =~ s/\/$BIN_DIR_NAME\/$UTIL_DIR_NAME//;

sub get_user_verification {
	print "Warning!! You're deleting all the CVS folders\n";
	print "starting from the ATHENa's root directory.\n";
	
	while ( 1 ) {
		print "Would you like to proceed? [y/n] :: ";
		my $choice = <STDIN>; chop($choice);
		if ($choice =~ m/^y$/i ) {
			return;
		} elsif ( $choice =~ m/^n$/i ) {
			exit;
		} else {
			print "Invalid input. Please try again.\n";
		}
	}
}

sub search_and_delete_cvs {	
	my $path = ${shift()};
		
	opendir(DIR, $path) || die("Cannot open directory");
	my @files = readdir(DIR);	# get all files in a folder
	closedir(DIR);

	foreach $file ( @files ) {
		if ($file =~ /^.$|^..$/i ) { next; }
		$dir = "$path/$file";
		if ( $file =~ m/cvs/i ) { &rmtree($dir); }	
		if ( -d $dir ) { 			
			&search_and_delete_cvs(\$dir);
		}
	}
	return;
}

&get_user_verification();
&search_and_delete_cvs(\$ROOT_DIR);
