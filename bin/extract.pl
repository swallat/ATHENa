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
# Extract.pl
# Version: 0.1
# 
# Provides functions to extract necessary data from reports
#####################################################################


#####################################################################
# Generic Extraction Function
#####################################################################
sub extract{
	my ($REGEX_REF, $REPORT_NAME, $DATA_REF) = @_;
	#print "$REGEX_REF, $REPORT_NAME, $DATA_REF\n";
	my ($TOTAL, $USED, $PERCENTAGE);
	$USED = 0; $TOTAL = 0; $PERCENTAGE = 0;

	my $REPORT_DATA = ${$DATA_REF};
	if( length($REPORT_DATA) < 1 ){ 
		open(LOG, $REPORT_NAME); # || die("Could not open report!");
		$REPORT_DATA = join(" ", <LOG>);
		close(LOG);
		#print length($REPORT_DATA)."\n";
	}
	#print length($REPORT_DATA)."\n";
    
	my @REGEX_ARRAY = @{$REGEX_REF};
	foreach my $REGEX (@REGEX_ARRAY){
		if($REPORT_DATA =~ m/$REGEX/gi){
			$USED = $1;
			$TOTAL = $2;
			$PERCENTAGE = $3;
			last;
		}
	}
	
	$USED =~ s/,//;
	$TOTAL =~ s/,//;

	#make them zeros if they are blank
	$USED = 0 unless $USED > 0;
	$TOTAL = 0 unless $TOTAL > 0;
	$PERCENTAGE = 0 unless $PERCENTAGE > 0;
	
	return $USED, $TOTAL, $PERCENTAGE;
}

#####################################################################
# Extracts the dev utilization results from device log files
#####################################################################
sub extract_util_results{
	my ($VENDOR, $FAMILY, $REPORT_NAME, $DATA_REF, $DIR, $IS_SYNTHESIZE) = @_;
	my %HASH = ();	
	
	my $REPORT_DATA = ${$DATA_REF};
	if( length($REPORT_DATA) < 1 ){ 
		open(LOG, $REPORT_NAME);
		$REPORT_DATA = join(" ", <LOG>);
		close(LOG);
		
		my $REPORT_FILE = "";
		if( length($REPORT_DATA) < 1 ){ 
			$REPORT_FILE = "$DIR/$XILINX_MAP_REPORT" if(lc($VENDOR) eq "xilinx");
			if(lc($VENDOR) eq "altera"){
				my @FILES = get_file_type($DIR, "$ALTERA_IMPLEMENTATION_REPORT_SUFFIX");
				$REPORT_FILE = "$DIR/$FILES[0]";
			}
			#print "REPORT_FILE \t\t\t $REPORT_FILE\n";
			open(LOG, $REPORT_FILE);
			$REPORT_DATA = join(" ", <LOG>);
			close(LOG);
		}		
	}

	my @DEVICE_ITEMS = @{$VENDOR_DEVICE_ITEMS{lc($VENDOR)}};
	my %REGEX_HASH = %{$REGEX_VENDOR_EXTRACT{lc($VENDOR)}};	
	
	foreach my $ITEM (@DEVICE_ITEMS){		
		#print "Processing $ITEM\n";
	
		my ($USED, $TOTAL, $PERCENTAGE);
		if ( $ITEM =~ /bram/i ) {
			($TOTAL, $USED, $PERCENTAGE) = &extract_xilinx_bram( $REPORT_NAME, $FAMILY, \$REPORT_DATA );
		} else {
			($TOTAL, $USED, $PERCENTAGE) = &extract($REGEX_HASH{$ITEM}, $REPORT_NAME, \$REPORT_DATA);
			if ( $IS_SYNTHESIZE == 1 ) { # handles virtex5 and onward for synthesize report extraction
				if (( $ITEM =~ m/slice/i ) and ( $TOTAL == 0 )) {
					($TOTAL, $USED, $PERCENTAGE) = &extract($REGEX_HASH{LUT}, $REPORT_NAME, \$REPORT_DATA);					
					$TOTAL = sprintf("%d",$TOTAL/4);
					$USED = sprintf("%d",$USED/4);
				}
			}
		}
	
		
		#print "$TOTAL, $USED, $PERCENTAGE \n";
		
		$HASH{"TOTAL_".$ITEM} = $TOTAL;
		
		#keep both of these here, because the library uses the EXACT names. So "used_" is not recognized
		#$HASH{"USED_".$ITEM} = $USED;
		$HASH{$ITEM} = $USED;
		
		$HASH{"PERCENTAGE_".$ITEM} = $PERCENTAGE;
	}
	return \%HASH;
}

#####################################################################
# Extracts the dev performence results from log files
#####################################################################
sub extract_perf_results{
	my ($VENDOR, $REPORT_NAME, $DATA_REF, $DIR, $CLOCK_NET) = @_;
	
	#print "($VENDOR, $REPORT_NAME, $DATA_REF, $DIR, $CLOCK_NET)\n";
	
	my $REPORT_DATA = ${$DATA_REF};
	if( length($REPORT_DATA) < 1 ){ 
		open(LOG, $REPORT_NAME);
		$REPORT_DATA = join(" ", <LOG>);
		close(LOG);
		
		my $REPORT_FILE = "";
		if( length($REPORT_DATA) < 1 ){ 
			$REPORT_FILE = "$DIR/$XILINX_TRACE_REPORT" if(lc($VENDOR) eq "xilinx");
			if(lc($VENDOR) eq "altera"){
				my @FILES = get_file_type($DIR, "$ALTERA_TIMING_REPORT_1_SUFFIX");
				$REPORT_FILE = "$DIR/$FILES[0]";
			}
		}
		
		#print "REPORT_FILE \t\t\t $REPORT_FILE\n";
		open(LOG, $REPORT_FILE);
		$REPORT_DATA = join(" ", <LOG>);
		close(LOG);
	}
	
	#print "REPORT DATA SIZE \t\t\t ".length($REPORT_DATA)."\n";
	my ($FREQ, $PERIOD);

	if(lc($VENDOR) eq "xilinx"){ 
		# Updated : Aug 29, 2010 :: Fixed to extract more report types
		my $synthesis_report = "$DIR/$XILINX_SYNTHESIS_REPORT";
		open(LOG, "$synthesis_report"); my $synthesis_data = join(" ", <LOG>);  close(LOG);

		my ($clkname_ref, $syntclk_ref, $synfreq_ref, $imptclk_ref, $impfreq_ref) = &extract_xilinx_timing($synthesis_data, $REPORT_DATA); #return values are references
		for ( my $i = 0; $i < scalar@{$clkname_ref}; $i++) {
			if ( lc(@{$clkname_ref}[$i]) eq lc($CLOCK_NET) ) {
				$FREQ =  @{$impfreq_ref}[$i];
				$PERIOD = @{$imptclk_ref}[$i];	
			}
		}
	}
	elsif(lc($VENDOR) eq "altera"){
		#; Clock Setup: 'clk'           ; N/A   ; None          ; 110.51 MHz ( period = 9.049 ns ) ; bl_datapath:datapath|regn:\sr_gen:0:sr0|r[5]    ; bl_datapath:datapath|regn:\sr_gen:0:sr0|r[31]    ; clk        ; clk      ; 0            ;
		if($REPORT_DATA =~ m/;\s*([\d.]+)([\w ]+)[\s\(]+period = ([\d.]+)([\w ]+)[ \)]+;/gi){
			$FREQ = $1;
			$PERIOD = $3;
		}
	}
	else{
		printOut("Problem with extracting performance results\n");
	}
	
	return ($FREQ, $PERIOD);
}

#####################################################################
# Testing scheme
#####################################################################
sub test{
	$ROOT_DIR = "M:/_work/ATHENa/bin";
	my $file = "M:/_work/ATHENa/ATHENa_workspace/single_run/2010_08_29_cubehash_top_twoclk_3/xilinx/virtex5/xc5vlx20tff323-2/run_1/map.log";	
	
	my $file2 = "M:/_work/ATHENa/ATHENa_workspace/GMU_Xilinx_optimization_1/2010_09_13_main_11/xilinx/spartan3/xc3s50pq208-5/run_1/";
	my $VENDOR = "xilinx";
	
	require "regex.pl";
	require "constants.pl";
	require "report_extract.pl";

	print "\n\n========= XILINX TESTS ===========\n\n";
	#my %HASH = %{extract_util_results($VENDOR, $file, "")};
	my %HASH = %{extract_util_results($VENDOR, "", "", $file2)};
	# my $area = &getArea(\%HASH, $VENDOR);	
	# print "area --> $area\n";
	# &maxRatio(123,$area,"area");
	
	my @DEVICE_ITEMS = @{$VENDOR_DEVICE_ITEMS{lc($VENDOR)}};
	foreach my $ITEM (@DEVICE_ITEMS){
		print "$ITEM used : \t".$HASH{$ITEM}." out of ".$HASH{"TOTAL_".$ITEM}." \t ".$HASH{"PERCENTAGE_".$ITEM}."%\n";
	}
	# my $file1 = "M:/_work/ATHENa/ATHENa_workspace/single_run/2010_08_29_cubehash_top_twoclk_3/xilinx/virtex5/xc5vlx20tff323-2/run_1/timing_report.twr";	
	# my $dir1 = "M:/_work/ATHENa/ATHENa_workspace/single_run/2010_08_29_cubehash_top_twoclk_3/xilinx/virtex5/xc5vlx20tff323-2/run_1/";
	# my ($FREQ, $PERIOD) = extract_perf_results($VENDOR,"","",$dir1, ,"clk");
	# print "\n Performance results : $FREQ, $PERIOD \n";
	
	# my $dir1 = "M:/_work/ATHENa/ATHENa_workspace/single_run/2010_08_28_main_1/xilinx/virtex5/xc5vlx20tff323-2/run_1/";
	# my ($FREQ, $PERIOD) = extract_perf_results($VENDOR,"","",$dir1, ,"clk");
	# print "\n Performance results : $FREQ, $PERIOD \n";

	# print "\n\n========= ALTERA TESTS ===========\n\n";
	# $file = "C:/Documents and Settings/Venkata Amirineni/Desktop/_work/ATHENa_Workspace/single_run/2010_02_09_sha256_2/altera/cyclone/ep1c12f324c6/sha256.fit.rpt";
	# $VENDOR = "altera";
	# $file1 = "C:/Documents and Settings/Venkata Amirineni/Desktop/_work/ATHENa_Workspace/single_run/2010_02_09_sha256_2/altera/cyclone/ep1c12f324c6/sha256.tan.rpt";
	
	# my %HASH = %{extract_util_results($VENDOR, $file, "")};
	
	# my @DEVICE_ITEMS = @{$VENDOR_DEVICE_ITEMS{lc($VENDOR)}};
	# foreach my $ITEM (@DEVICE_ITEMS){
		# print "$ITEM used : \t".$HASH{$ITEM}." out of ".$HASH{"TOTAL_".$ITEM}." \t ".$HASH{"PERCENTAGE_".$ITEM}."%\n";
	# }
	# my ($FREQ, $PERIOD) = extract_perf_results($VENDOR, $file1, "");
	# print "\n Performance results : $FREQ, $PERIOD \n";
	
}

# &test();
# system( pause );





1; # need to end with a true value