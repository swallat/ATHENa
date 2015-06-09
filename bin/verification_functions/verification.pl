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
# Verification
# Version: 0.1
# 
# Contain main method of calling verification program
# 
#	return	0 for success
#	Errors:	1 for no tool installed
#####################################################################

use Storable qw(dclone);
#use File::Path qw(make_path remove_tree);

sub verify {
	
	my $vendor = shift();
	my $mode = shift();
	my @files;
	# ========== check for valid mode
	if (( $mode ne "functional") and ( $mode ne "postsynthesis" ) and ( $mode ne "postroute")) {
		print "Error : Invalid verification mode, please specify either 'functional', 'postsynthesis', or 'postroute'\n";
		return 1; 	#invalid verification mode
	}
	
	
	# ========== get info from tool_data.txt
	my %data = %{&get_info_from_data_file()};

	# ========== get path and its tool name
	my ($res, $path) = &get_selected_tool_info(\%data, $vendor, "sim", "root_dir");
	if ( $res > 0 ) { print "Error in function `verify` in `verification.pl`!!!\n No verification tool installed for $vendor.\n\n"; return 1; }	
	my ($res, $toolname) = &get_selected_tool_info(\%data, $vendor, "sim", "version_name");
	$path .= "\\vsim.exe";
	
	system( cls );
	# ========== get list of source files (in full path)	
	if ( $mode eq "functional" ) {
		my @tfiles = @{ dclone(\@SOURCE_FILES) };		
		for (my $i = 0; $i < scalar@tfiles; $i++ ) {
			$tfiles[$i] = $SOURCE_DIR."\/".$tfiles[$i];
		}		
		@files = @tfiles;	
		my @tfiles = @{ dclone(\@VERIFICATION_FILES) };
		for (my $i = 0; $i < scalar@tfiles; $i++ ) {
			$tfiles[$i] = $VERIFICATION_DIR."\/".$tfiles[$i];
		}	
		@files = (@files, @tfiles);
	} elsif ( $mode eq "postsynthesis" ) {
		@files = ("${TOP_LEVEL_ENTITY}.vhm");
	} elsif ( $mode eq "postroute" ) {
		@files = ("${TOP_LEVEL_ENTITY}.ncd");
	}
	

	# ========== Copy test vectors to sim folder
	my ( @tv, @dest_tv );
	for (my $i = 0; $i < scalar@TEST_VECTORS_FILES; $i++ ) {
		$tv[$i] = $VERIFICATION_DIR."\/".$TEST_VECTORS_FILES[$i];
		$dest_tv[$i] = $SIM_DIR."\/".$TEST_VECTORS_FILES[$i];
		copy($tv[$i], $dest_tv[$i]); #or printError("verification - Cannoy copy file $tv[$i] to $dest_tv[$]", 1 );
	}	
	
	#foreach my $file ( @files, @TEST_VECTORS_FILES ) { print "$file\n"; } exit;
		
	print "Performing $mode simulation. Please wait ...";
	# ========== verify based on specified tool
	if ( lc($toolname) eq "modelsim" ) {		
		&modelsim($path, \@files);		
	} elsif ( lc($toolname) eq "aldec" ) {
		&aldec($path, \@files);
	} else {
		print( "Error : Unsupported verification tool\n" );
		return 2; 
	}
	print "[DONE]\n";
	
	# ========== change test_result.txt and test_log.txt ==> $mode_result.txt and $mode_log.txt, respectively 
	if ( -e "$SIM_DIR\/athena_test_result.txt" ) {
		if ( $^O =~ m/$REGEX_OS_WINDOWS/i ) { #windows
			system ( "ren athena_test_result.txt athena_${mode}_result.txt" );
		} else {
			print "Unsupported OS a\n";
		}
	} else {
		print "Error : No athena_test_result.txt found after verification\n";
		return 3;
	}	
	if ( -e "athena_test_log.txt" ) {
		system ( "ren athena_test_log.txt athena_${mode}_log.txt" );
	}
	# ========== Delete test vectors and work folder if TRIM, currently unsupported
	# if ( $TRIM =~ m/on/i ) {
		# unlink(@dest_tv);		
		# my $dir = $SIM_DIR."\/work";
		# print "$dir\n";
		# remove_tree( $dir );
	# }
	
	
	# ========== Determine whether simulation pass or fail
	open(RESULT, "athena_${mode}_result.txt") || die("Could not open file!");
		my $result_data = join("",<RESULT>);	
	close(RESULT);
	
	if ( $result_data =~ m/pass/i ) { 	#pass
		print "\nYour design PASSES $mode verification!\n\n";
		return 0;
	} else { 							#fail
		return 1;
	}
}


return 1;