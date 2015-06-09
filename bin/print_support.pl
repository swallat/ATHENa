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

################################################################################################################################################
# Primary print functions
################################################################################################################################################

#####################################################################
# PRINTs to log file
#####################################################################
sub printToLog{
	my ($LOG_FILE, $DATA, $TYPE) = @_;
	chomp($DATA);
	$DATA = "$DATA\n";
	$TYPE = $APPEND if ($TYPE == "");
	open(LOG,">>$LOG_FILE") if($TYPE == $APPEND); #<== append
	open(LOG,">$LOG_FILE") if($TYPE == $OVERWRITE); #<== over write
	print LOG "$DATA";
	close(LOG);
}

#####################################################################
# PRINTs to screen
#####################################################################
sub printToScreen{
	my ($DATA) = @_;
	#chomp($DATA);
	#$DATA = "$DATA\n";
	print $DATA;
}

################################################################################################################################################
# Support print functions
################################################################################################################################################

#####################################################################
# PRINTs to screen and local cmd log file
#####################################################################
sub printLogToScreen{
	my ($DATA) = @_;
	printToScreen($DATA);
	printOut($DATA);
}

#####################################################################
# PRINTs to local cmd log file
#####################################################################
sub printOut{
	my ($DATA) = @_;
	
	my $time =  currentTime()." - $TITLE - ";
	$DATA =~ s/[\n]+$//gi; #<== clear newline at the end of line
	$DATA =~ s/^[\n]+//gi; #<== clear newline at the beginning of line
	
	$DATA =~ s/[\n]+/\n$time\t/gi; #<== replace the middle new line chars with tabs
	$DATA = $time."\t".$DATA."\n";
	
	if (lc($CONTEXT) eq "parent"){
		printToLog($CMD_LOG_FILE, $DATA, $APPEND);
	}
	else{
		printToLog($LOCAL_CMD_LOG_FILE_NAME, $DATA, $APPEND);
	}
}

#####################################################################
# PRINTs to local progress log file
#####################################################################
sub printLocalProgress{
	my ($DATA) = @_;
	if (lc($CONTEXT) eq "parent"){
		#printToLog($PROGRESS_LOG_FILE, $DATA, $OVERWRITE); #<== This file is overwritten by multithread update. Dont use it.
	}
	else{
		printToLog($LOCAL_TEMP_PROGRESS_LOG_FILE_NAME, $DATA, $APPEND);
	}
}

#####################################################################
# PRINTs to local progress log file
#####################################################################
sub printProgress{
	my ($DATA) = @_;
	if (lc($CONTEXT) eq "parent"){
		#printToLog($PROGRESS_LOG_FILE, $DATA, $OVERWRITE); #<== This file is overwritten by multithread update. Dont use it.
	}
	else{
		printToLog($LOCAL_PROGRESS_LOG_FILE_NAME, $DATA, $APPEND);
	}
}


#####################################################################
# PRINT error info to file, as well as to screen
#####################################################################
sub printErrorToScreen{
	my ($DATA, $DIE) = @_;
	printToScreen($DATA);
	printError($DATA, $DIE);
}

#####################################################################
# PRINT error info
#####################################################################
sub printError{
	my ($DATA, $DIE) = @_;
	
	my $time =  "ERROR : ".currentTime()." - $TITLE - ";
	$DATA =~ s/[\n]+$//gi; #<== clear newline at the end of line
	$DATA =~ s/^[\n]+//gi; #<== clear newline at the beginning of line
	
	$DATA =~ s/[\n]+/\n$time\t/gi; #<== replace the middle new line chars with tabs
	$DATA = $time."\t".$DATA."\n";
	
	if (lc($CONTEXT) eq "parent"){
		printToLog($CMD_LOG_FILE, $DATA, $APPEND);
	}
	else{
		printToLog($LOCAL_CMD_LOG_FILE_NAME, $DATA, $APPEND);
	}
	if($DIE == 1){
		#print "\n\nError Log location : $LOCAL_LOG_FILE_NAME \n";
		my $loc = "${WORKSPACE}\\${LOCAL_CMD_LOG_FILE_NAME}";
		$loc =~ s/\\/\//gi;
		print "=====\nSTOPPING SCRIPT : Please check the following location for error report =>\n\t$loc\n=====\n\n";
		&exit_athena();
	}
}

#####################################################################
# PRINT error info
#####################################################################
sub printHash{
	my ($hash_ref) = @_;
	use Data::Dumper;
	my $output = Dumper $hash_ref;
	print $output."\n";
	printOut($output);
}












1;