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
	my ($REGEX_REF, $REPORT_NAME, $DATA_REF, $PRINT) = @_;
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
		#print "\t\t\t\t\ttest \t $REGEX\n";
		if($REPORT_DATA =~ m/$REGEX/gi){
			$USED = $1;
			$TOTAL = $2;
			$PERCENTAGE = $3;
			last;
		}
	}
	if ( $PRINT == 1 ) {
		print "u -> $USED\n T => $TOTAL \n pu => $PERCENTAGE\n";
	
	}
	
	if ( $PRINT == 1 ) {
		if ($REPORT_DATA =~ m/Combinational ALUTs\s*;([\d\w\s]+)/i) {
			print "$1\n";
		} else {
			print "not match\n";
		}		exit;
	}
	
	$USED =~ s/,//g;
	$TOTAL =~ s/,//g;
	
	#make them zeros if they are blank
	$USED = 0 unless $USED > 0;
	$TOTAL = 0 unless $TOTAL > 0;
	$PERCENTAGE = 0 unless $PERCENTAGE > 0;
	
	return $TOTAL, $USED, $PERCENTAGE;
}

#============================================================================================================================================================================
#																		XILINX
#============================================================================================================================================================================
#####################################################################
# Extracts slice util info from xilinx reports
#####################################################################
sub extract_xilinx_slice{
	my ($REPORT_NAME, $DATA_REF) = @_;
	my ($TOTAL, $USED, $PERCENTAGE) = extract(\@REGEX_XILINX_SLICE_EXTRACT, $REPORT_NAME, $DATA_REF);
	#print "$TOTAL, $USED, $PERCENTAGE\n";
	return ($TOTAL, $USED, $PERCENTAGE);
}

#####################################################################
# Extracts bram util info from xilinx reports
#####################################################################
sub extract_xilinx_bram{
	my ($REPORT_NAME, $FAMILY, $DATA_REF) = @_;

    my ($TOTAL, $USED, $PERCENTAGE, $TOTAL2, $USED2, $PERCENTAGE2) = (0, 0, 0, 0, 0, 0);

    if ($FAMILY =~ m/spartan3/i) {
        my @tempRegex = (@REGEX_XILINX_BRAM_EXTRACT, $X_BRAM_VAR5);
        ($TOTAL, $USED, $PERCENTAGE) = extract(\@tempRegex, $REPORT_NAME, $DATA_REF);
    } elsif ($FAMILY =~ m/virtex4|virtex5/i) {   # if not spartan3, virtex4 or virtex5, assumes two block ram exists
        ($TOTAL, $USED, $PERCENTAGE) = extract(\@REGEX_XILINX_BRAM_EXTRACT, $REPORT_NAME, $DATA_REF);






    } else {
        ($TOTAL, $USED, $PERCENTAGE) = extract(\@REGEX_XILINX_BRAM_EXTRACT, $REPORT_NAME, $DATA_REF);
        ($TOTAL2, $USED2, $PERCENTAGE2) = extract(\@REGEX_XILINX_DUAL_BRAM_EXTRACT, $REPORT_NAME, $DATA_REF);
    }


    # print "\n$FAMILY\n";
	# print "$TOTAL, $USED, $PERCENTAGE\n";
	# print "$TOTAL2, $USED2, $PERCENTAGE2\n";

	if ( $USED2 > 0 ) { # if there is a dual block ram usage add them up
		$USED = $USED + $USED2*2;	
        $TOTAL = $TOTAL + $TOTAL2*2;
		$PERCENTAGE = sprintf ( "%d", ($USED*100)/$TOTAL );	



	}
    # print "$TOTAL, $USED, $PERCENTAGE\n";

	return ($TOTAL, $USED, $PERCENTAGE);
}

#####################################################################
# Extracts dsp util info from xilinx reports
#####################################################################
sub extract_xilinx_dsp{
	my ($REPORT_NAME, $DATA_REF) = @_;
	my ($TOTAL, $USED, $PERCENTAGE) = extract(\@REGEX_XILINX_DSP_EXTRACT, $REPORT_NAME, $DATA_REF);
	#print "$TOTAL, $USED, $PERCENTAGE\n";
	return ($TOTAL, $USED, $PERCENTAGE);
}

#####################################################################
# Extracts multiplier util info from xilinx reports
#####################################################################
sub extract_xilinx_mult{
	my ($REPORT_NAME, $DATA_REF) = @_;
	my ($TOTAL, $USED, $PERCENTAGE) = extract(\@REGEX_XILINX_MULT_EXTRACT, $REPORT_NAME, $DATA_REF);
	#print "$TOTAL, $USED, $PERCENTAGE\n";
	return ($TOTAL, $USED, $PERCENTAGE);
}

#####################################################################
# Extracts I/O util info from xilinx reports
#####################################################################
sub extract_xilinx_io{
	my ($REPORT_NAME, $DATA_REF) = @_;
	my ($TOTAL, $USED, $PERCENTAGE) = extract(\@REGEX_XILINX_IO_EXTRACT, $REPORT_NAME, $DATA_REF);
	#print "$TOTAL, $USED, $PERCENTAGE\n";
	return ($TOTAL, $USED, $PERCENTAGE);
}

#####################################################################
# Extracts I/O util info from xilinx reports
#####################################################################
sub extract_xilinx_lut{
	my ($REPORT_NAME, $DATA_REF) = @_;
	my ($TOTAL, $USED, $PERCENTAGE) = extract(\@REGEX_XILINX_LUT_EXTRACT, $REPORT_NAME, $DATA_REF);
	#print "$TOTAL, $USED, $PERCENTAGE\n";
	return ($TOTAL, $USED, $PERCENTAGE);
}

#####################################################################
# Extracts the dev utilization results from xilinx device log files
#####################################################################
sub extract_xilinx_util{
	my ($FAMILY, $REPORT_NAME, $DATA_REF) = @_;
		

	my ($TOTAL_SLICES, $USED_SLICES, $P_SLICES) = extract_xilinx_slice($REPORT_NAME, $DATA_REF);
	my ($TOTAL_BRAM, $USED_BRAM, $P_BRAM) = extract_xilinx_bram($REPORT_NAME, $FAMILY, $DATA_REF);
	my ($TOTAL_DSP, $USED_DSP, $P_DSP) = extract_xilinx_dsp($REPORT_NAME, $DATA_REF);
	my ($TOTAL_MULT, $USED_MULT, $P_MULTS) = extract_xilinx_mult($REPORT_NAME, $DATA_REF);
	my ($TOTAL_IO, $USED_IO, $P_IO) = extract_xilinx_io($REPORT_NAME, $DATA_REF);
	my ($TOTAL_LUT, $USED_LUT, $P_LUT) = extract_xilinx_lut($REPORT_NAME, $DATA_REF);
	my ($TOTAL_FF, $USED_FF, $P_FF) = extract(\@REGEX_XILINX_FF_EXTRACT, $REPORT_NAME, $DATA_REF);
	return ($TOTAL_SLICES, $USED_SLICES, $P_SLICES,
			$TOTAL_BRAM, $USED_BRAM, $P_BRAM,
			$TOTAL_DSP, $USED_DSP, $P_DSP,
			$TOTAL_MULT, $USED_MULT, $P_MULTS, 			
			$TOTAL_IO, $USED_IO, $P_IO,
			$TOTAL_FF, $USED_FF, $P_FF,
			$TOTAL_LUT, $USED_LUT, $P_LUT);
}

#####################################################################
# Extracts the dev performence results from xilinx devices
#####################################################################
sub xilinx_performence{
	my ($REPORT_NAME, $DATA_REF) = @_;
	
	open(LOG, $REPORT); # || die("Could not open report!");
	my $REPORT_DATA = join(" ", <LOG>);
	close(LOG);
	
	my ($FREQ, $PERIOD);

	if($REPORT_DATA =~ m/$REGEX_XILINX_FREQ_EXTRACT/gi) {
		$FREQ = $1;
	}
	if($REPORT_DATA =~ m/$REGEX_XILINX_TCLK_EXTRACT/gi) {
		$PERIOD = $1;
	}
	
	return ($FREQ, $PERIOD);
}

#============================================================================================================================================================================
#																		ALTERA
#============================================================================================================================================================================

#####################################################################
# Extracts the dev utilization results from altera device log files
#####################################################################
sub extract_altera_util{
	my ($REPORT_NAME, $DATA) = @_;

	my ($T_LE, $U_LE, $PU_LE) = extract(\@REGEX_ALTERA_LE_EXTRACT, $REPORT_NAME, \$DATA);
	my ($T_ALUTS, $U_ALUTS, $PU_ALUTS) = extract(\@REGEX_ALTERA_LU_ALUT_EXTRACT, $REPORT_NAME, \$DATA);
	my ($T_LU_CA, $U_LU_CA,  $PU_LU_CA) = extract(\@REGEX_ALTERA_LU_COMB_ALUT_EXTRACT, $REPORT_NAME, \$DATA);
    my ($T_LU_MA, $U_LU_MA,  $PU_LU_MA) = extract(\@REGEX_ALTERA_LU_MEMS_ALUT_EXTRACT, $REPORT_NAME, \$DATA);    
    my ($T_ALMS, $U_ALMS, $PU_ALMS) = extract(\@REGEX_ALTERA_ALM_EXTRACT, $REPORT_NAME, \$DATA);    
    my ($T_FF, $U_FF, $PU_FF) = extract(\@REGEX_ALTERA_LU_DEDI_LREG_EXTRACT, $REPORT_NAME, \$DATA);
	my ($T_LU_LR, $U_LU_LR, $PU_LU_LR) = extract(\@REGEX_ALTERA_LU_LUT_REGS_EXTRACT, $REPORT_NAME, \$DATA);
    my ($T_LU, $U_LU, $PU_LU) = extract(\@REGEX_ALTERA_LU_EXTRACT, $REPORT_NAME, \$DATA);
    my ($T_MEM, $U_MEM, $PU_MEM) = extract(\@REGEX_ALTERA_MEM_EXTRACT, $REPORT_NAME, \$DATA);
	my ($T_DSP, $U_DSP, $PU_DSP) = extract(\@REGEX_ALTERA_DSP_EXTRACT, $REPORT_NAME, \$DATA);
	my ($T_MULT, $U_MULT, $PU_MULT) = extract(\@REGEX_ALTERA_MULT9BIT_EXTRACT, $REPORT_NAME, \$DATA);
	my ($T_PIN, $U_PIN, $PU_PIN) = extract(\@REGEX_ALTERA_PIN_EXTRACT, $REPORT_NAME, \$DATA);
		
	return ( $U_LE, $T_LE, $PU_LE, #LE
		$U_ALUTS, $T_ALUTS, $PU_ALUTS, #ALUTs
        $U_LU_CA, $T_LU_CA, $PU_LU_CA, #COMB ALUT
        $U_LU_MA, $T_LU_MA, $PU_LU_MA, #MEMS ALUT
        $U_ALMS, $T_ALMS, $PU_ALMS, #ALMS (For Virtex 5)
		$U_LU_LR, $T_LU_LR, $PU_LU_LR, #LUT REGs
        $U_FF, $T_FF, $PU_FF, #DEDICATED LREG (FLIPFLOPS)
        $U_LU, $T_LU, $PU_LU, #Logic Utilization percentage
        $U_MEM, $T_MEM, $PU_MEM, #memory
        $U_DSP, $T_DSP, $PU_DSP, #dsp
        $U_MULT, $T_MULT, $PU_MULT, #multiplier
        $U_PIN, $T_PIN, $PU_PIN );
}






















































1; # need to end with a true value