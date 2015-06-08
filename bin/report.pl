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
# Version     :  0.4
# Purpose 	: Generate reports for an ATHENa project
# Usage 	: report.pl $1 $2
# 
#  $1 	: the FULL PATH to the project folder. The path should locate in your application folder inside your workspace.
#		  For instance, $WORKSPACE/$APPLICATION/$FOLDER.
#  $2	: Mode of operation ( display, print OR both )
#		  	"display" generates reports on the screen
#			"print" create report files
#			"both" performs "display" and "print" functionality
#
# Note 		: Case sensitive
#####################################################################

use Cwd;
use File::Copy;

$BIN_DIR_NAME = "bin"; $CONFIG_DIR_NAME = "config";
$ROOT_DIR = cwd; $ROOT_DIR =~ s/\/$BIN_DIR_NAME//;

require "$ROOT_DIR/$BIN_DIR_NAME/regex.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/support.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/extract_old.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/constants.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/report_core.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/report_conf.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/report_extract.pl";

$DEBUG_ON = 0;

# This global var is used for multiple clocks detection (Should be moved to local var)


###############################################################################################################################################################
#
# Execution starts here
#
###############################################################################################################################################################

use Time::Local;
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); $year -= 100;
my @abbr = qw( JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC );

($PROJECTFOLDER, $FORMAT) = @ARGV;

if (( $FORMAT !~ m/print/i) and ($FORMAT !~ m/both/i) and ($FORMAT !~ m/display/i) and ($FORMAT !~ m/debug/i)) {
	print "Invalid format mode!! Please use either 'display', 'print', or 'both'. Script will now terminate."; exit;
}
if ($FORMAT =~ m/debug/i) { 
	print "\n\n=========================\n";
	print "===  DEBUGGING MODE   ===\n";
	print "=========================\n\n\n";
}

	######################################################################
	######################## POPULATING DATA #############################
	######################################################################

my %project = %{&extract_project_data($PROJECTFOLDER)};

	######################################################################
	######################## DATA POPULATED ##############################
	######################################################################

	############################################
	########### GET BEST RESULT	################
	############################################
my %best = %{&extract_best_result(\%project, "normal")};

	## Printing best result based on best over all result
my %best_result = %{&print_best_result(\%project, \%best, \@BEST_CRITERIAN, "best_overall")};

	############################################
	########## BEST RESULT OBTAINED ############
	############################################


	######################################################################################
	######################## GENERATING TABLE TO OUTPUT ##################################
	######################################################################################
	
my $report_resource_util = "";
my $report_option = "";
my $report_timing= "";
my $report_exec_time = "";

foreach $vendor (keys %project ) {  
	$report_option .= &gen_report_table( $vendor, \%{$project{$vendor}}, \@{$REPORT_ORDER{$vendor}{option}} );
	$report_resource_util .= &gen_report_table( $vendor, \%{$project{$vendor}}, \@{$REPORT_ORDER{$vendor}{resource}} );
	$report_timing .= &gen_report_table( $vendor, \%{$project{$vendor}}, \@{$REPORT_ORDER{$vendor}{timing}} );		
	$report_exec_time .= &gen_report_table( $vendor, \%{$project{$vendor}}, \@{$REPORT_ORDER{$vendor}{exec_time}} );
}
$report_resource_util .= "\n$best_result{AREA}\n";

$report_timing .= "\n\tNote : Units of Frequency, TCLK, Latency and Throughput are MHz, ns, ns and Mbit/s, respectively.";
$report_timing .= "\n\t       Area in TP/Area denotes 'Slice' for Xilinx and 'Logic Element' or 'Combinational ALUTs' for Altera.\n\n";
$report_timing .= "$best_result{THROUGHPUT}";
$report_timing .= "$best_result{THROUGHPUT_AREA}";
$report_timing .= "$best_result{LATENCY}";
$report_timing .= "$best_result{LATENCY_AREA}";
	######################################################################################
	######################## END OF TABLE GENERATION #####################################
	######################################################################################

	##########################################################
	############## GENERATING DEVICE LIST ####################
	##########################################################

my $devcount = 0;
my $disp_device_list = "";
foreach $vendor ( keys  %project ) {
	$disp_device_list .= "$vendor :: \n";
	foreach $family ( keys %{$project{$vendor}} ) {
		$disp_device_list .= "\t$family :\n";
		my $i = 0; $disp_device_list .= "\t\t";
		
		my @device_list;
		# get a list of unique devices
		foreach $gid ( keys %{$project{$vendor}{$family}} ) {
			foreach $device ( keys %{$project{$vendor}{$family}{$gid}} ) {
				my $add = 1;
				if ( $device =~ /generic|best_match/i ) { $add = 0; }
				foreach $dev ( @device_list ) {
					if ( $device =~ /$dev/i ) { $add = 0; }					
				}
				if ( $add == 1 ) {	push ( @device_list, $device ); $devcount++; }
			}
		}
		# print the unique devices
		foreach $device ( sort {$a cmp $b} @device_list ) {
			$disp_device_list .= sprintf("%- 20s ",$device );
			if ( $i == 2 ) { $disp_device_list .= "\n\t\t"; $i = 0 }
			$i++;
		}
		$disp_device_list .= "\n";
	}
}
	##########################################################
	########### END OF DEVICE LIST GENERATION ################
	##########################################################
	
	
my $toolInfo = toolInfoGen( \%project );

# error check
chdir($PROJECTFOLDER);
if ( $devcount <= 0 ) {
	my $err = "\n\n=======================================================================\n";
	$err .= "\tReport Generation Error!!\n";
	$err .= "No device was successfully implemented\\fitted\n\n";
	$err .= "Please refer to to following project location for more detail :\n$PROJECTFOLDER\n";	
	$err .= "=======================================================================\n";
	print $err;
	open(REPORTERROR, ">report_error.txt") || die("Could not create file!");
		print REPORTERROR "$err\n";
	close(REPORTERROR);
	exit;
}

if ($FORMAT =~ m/debug/i) { exit;}


# $abc =  "\n$best_result{AREA}\n";
# $abc .= "$best_result{THROUGHPUT}";
# $abc .= "$best_result{THROUGHPUT_AREA}";
# $abc .= "$best_result{LATENCY}";
# $abc .= "$best_result{LATENCY_AREA}";
# print "$abc\n"; exit;

my $summary = "\n\n$toolInfo\n";
$summary .= "\n\n::: Device List :::\n\n$disp_device_list\n";  
$summary .= "\n\n::: Option Report :::\n$report_option\n";
$summary .= "\n\n::: Resource Utilization Report :::\n$report_resource_util\n";    
$summary .= "\n\n::: Timing Report :::\n$report_timing\n";
$summary .= "\n\n::: Execution Time Report :::\n$report_exec_time\n";

if (($FORMAT =~ m/display/i) or ($FORMAT =~ m/both/i)) { print $summary; } 

if (( $FORMAT =~ m/print/i) or ($FORMAT =~ m/both/i)) {
	# === REPORT GEN ===
	open(REPORT, ">report_resource_utilization.txt") || die("Could not create file!");
		print REPORT "$toolInfo\n";
		print REPORT "$report_resource_util";
	close(REPORT);

	open(REPORT, ">report_option.txt") || die("Could not create file!");
		print REPORT "$toolInfo\n";
		print REPORT "$report_option";
	close(REPORT);

	open(REPORT, ">report_timing.txt") || die("Could not create file!");
		print REPORT "$toolInfo\n";
		print REPORT "$report_timing";
	close(REPORT);

	open(REPORT, ">report_execution_time.txt") || die("Could not create file!");
		print REPORT "$toolInfo\n";
		print REPORT "$report_exec_time";
	close(REPORT);  
  
	open(REPORT, ">report_summary.txt") || die("Could not create file!");		
		print REPORT "$summary";
	close(REPORT);  

	# === CSV Gen ===
	
	foreach $vendor (keys %project ) {		
		open(CSV, ">report_${vendor}_${mday}$abbr[$mon]${year}_${hour}-${min}-${sec}.csv") || die("Could not create file!");
		my $csv_data = &gen_vendor_csv($vendor, \%project);
		print CSV "$csv_data";
		close(CSV);
	}
	
}
	#####################################################
	########## END OF OUTPUT GENERATION #################
	#####################################################
	
	
###############################################################################################################################################################