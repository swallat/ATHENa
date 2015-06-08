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
# General Regex strings
#####################################################################
#use warnings;

#source file identifier  format: /\.vhd$|\.vhdl$/
@SOURCE_FILE_TYPES = qw(vhd vhdl v ngc ngd nmc tdf gdf);
my $SOURCE_STRING = "";
foreach my $str (@SOURCE_FILE_TYPES){ $SOURCE_STRING .= "\.$str\$|"; }
chop($SOURCE_STRING);
$REGEX_SOURCE_IDENTIFIER = qr/$SOURCE_STRING/;

#OS
$REGEX_OS_WINDOWS = qr/mswin/i;

#folder structure
$REGEX_FOLDER_IDENTIFIER = qr/([\w\S:!@#$%^&\/\\+ -_<>". ]+)/;
$REGEX_PATH_IDENTIFIER = qr/([\w\S :!@#$%^&\/\\+ -_<>".]+)/;

#comment
$REGEX_COMMENT_IDENTIFIER = qr/^([\w\d.\s=<>:\\\/\-\(\))]*)[\s\t]*#/;

#configuration information from design config file
#identifies numbers, words (excludes spaces, commas)
#ex 0.3, main_1, test2.1 ....
$REGEX_CONFIG_ITEM_IDENTIFIER = qr/([\w\d-_.]+)/;
#identifies numbers, words (includes spaces, commas)
#ex: list of file seperated by commas and spaces
$REGEX_CONFIG_LIST_IDENTIFIER = qr/([\w\d-_. ,]+)/;

$REGEX_CONFIG_FORMULA_IDENTIFIER = qr/([\w\d-_.\(\)\\\/\+\-\*]+)/;
#####################################################################
# Xilinx Regex strings
#####################################################################
# Xilinx utilization results

# single number extraction
$REGEX_XILINX_UTIL_NUMBER = qr/([\d,]+)/;

# sequence extraction # $1 = used IO, $2 = total IO, $3 = percentage
 #Number of Slices:                      40  out of    768     5%  
$REGEX_XILINX_UTIL_SEQUENCE = qr/([\d,]+)[a-zA-Z\s]+([\d,]+)\s*(\d+)/;
 
#====== Resource Utilization =======
# Slice extraction
# $1 = occupied slices, $2 = total slices, $3 = percentage
$X_SLICE_VAR1 = qr/Number of occupied Slices:\s*${REGEX_XILINX_UTIL_SEQUENCE}/; 		#<=== map report extraction
$X_SLICE_VAR2 = qr/Number of Slices:\s*${REGEX_XILINX_UTIL_SEQUENCE}/; 				#<=== Synthesis report extraction
@REGEX_XILINX_SLICE_EXTRACT = ($X_SLICE_VAR1, $X_SLICE_VAR2);							#<=== array with all the info
$REGEX_VENDOR_EXTRACT{lc(XILINX)}{SLICE} = \@REGEX_XILINX_SLICE_EXTRACT;

# BRAM extraction
# $1 = used IO, $2 = total IO, $3 = percentage
$X_BRAM_VAR1 = qr/Number of BlockRAM\/FIFO:\s*$REGEX_XILINX_UTIL_SEQUENCE/;
$X_BRAM_VAR2 = qr/Number of Block RAM\/FIFO:\s*$REGEX_XILINX_UTIL_SEQUENCE/;
$X_BRAM_VAR3 = qr/Number of Block RAMs:\s*$REGEX_XILINX_UTIL_SEQUENCE/;
$X_BRAM_VAR4 = qr/Number of FIFO16\/RAMB16s:\s*$REGEX_XILINX_UTIL_SEQUENCE/;
# Spartan 3
$X_BRAM_VAR5 = qr/Number of RAMB16\w*:\s*$REGEX_XILINX_UTIL_SEQUENCE/; # -- removed due to conflict
# Spartan 6 & Virtex6 
$X_BRAM_VAR6 = qr/Number of RAMB18E1[\w\d\/]+\s*:\s*$REGEX_XILINX_UTIL_SEQUENCE/;
$X_BRAM_VAR7 = qr/Number of RAMB8[\w\s]*:\s*$REGEX_XILINX_UTIL_SEQUENCE/;
# synthesis report extract for old version of xilinx
$X_BRAM_VAR8 = qr/Number of BRAMs\s*:\s*$REGEX_XILINX_UTIL_SEQUENCE/;

# Spartan 6 & Virtex6 
$X_DUAL_BRAM_VAR1 = qr/Number of RAMB36E1[\w\d\/]+\s*:\s*$REGEX_XILINX_UTIL_SEQUENCE/;
$X_DUAL_BRAM_VAR2 = qr/Number of RAMB16\w*\s*:\s*$REGEX_XILINX_UTIL_SEQUENCE/;

@REGEX_XILINX_BRAM_EXTRACT = ($X_BRAM_VAR1, $X_BRAM_VAR2, $X_BRAM_VAR3, $X_BRAM_VAR4, $X_BRAM_VAR6, $X_BRAM_VAR7, $X_BRAM_VAR8);
@REGEX_XILINX_DUAL_BRAM_EXTRACT = ($X_DUAL_BRAM_VAR1, $X_DUAL_BRAM_VAR2);
$REGEX_VENDOR_EXTRACT{lc(XILINX)}{BRAM} = \@REGEX_XILINX_BRAM_EXTRACT;

# DSP extraction
# $1 = used IO, $2 = total IO, $3 = percentage
$X_DSP_VAR1 = qr/Number of DSP48[\d\w\s]*:\s*${REGEX_XILINX_UTIL_SEQUENCE}/;

@REGEX_XILINX_DSP_EXTRACT = ($X_DSP_VAR1);
$REGEX_VENDOR_EXTRACT{lc(XILINX)}{DSP} = \@REGEX_XILINX_DSP_EXTRACT;

# MULT extraction
# $1 = used IO, $2 = total IO, $3 = percentage
$X_MULT_VAR1 = qr/Number of MULT18X18[\w\s]*:\s*${REGEX_XILINX_UTIL_SEQUENCE}/;
$X_MULT_VAR2 = qr/Number of MULT18X18SIOs:\s*${REGEX_XILINX_UTIL_SEQUENCE}/;

@REGEX_XILINX_MULT_EXTRACT = ($X_MULT_VAR1, $X_MULT_VAR2);
$REGEX_VENDOR_EXTRACT{lc(XILINX)}{MULT} = \@REGEX_XILINX_MULT_EXTRACT;

# IO extraction
# $1 = used IO, $2 = total IO, $3 = percentage
$X_IO_VAR1 = qr/Number of bonded IOBs:\s*$REGEX_XILINX_UTIL_SEQUENCE/;
@REGEX_XILINX_IO_EXTRACT = ($X_IO_VAR1);
$REGEX_VENDOR_EXTRACT{lc(XILINX)}{IO} = \@REGEX_XILINX_IO_EXTRACT;

# FF extraction
$X_FF_VAR1 = qr/Number of Slice Registers:\s*$REGEX_XILINX_UTIL_SEQUENCE/;
$X_FF_VAR2 = qr/Number of Slice Flip Flops:\s*$REGEX_XILINX_UTIL_SEQUENCE/;
@REGEX_XILINX_FF_EXTRACT = ($X_FF_VAR1, $X_FF_VAR2);

# LUT extraction
# $1 = used IO, $2 = total IO, $3 = percentage
$X_LUT_VAR1 = qr/Number of 4 input LUTs:\s*$REGEX_XILINX_UTIL_SEQUENCE/;
$X_LUT_VAR2 = qr/Number of Slice LUTs:\s*$REGEX_XILINX_UTIL_SEQUENCE/;
@REGEX_XILINX_LUT_EXTRACT = ($X_LUT_VAR1, $X_LUT_VAR2);
$REGEX_VENDOR_EXTRACT{lc(XILINX)}{LUT} = \@REGEX_XILINX_LUT_EXTRACT;


#====== Timing ========
# Xilinx frequency and minimum period from systhesis or trace report 
# $1 = frequency, $2 = units
$REGEX_XILINX_FREQ_EXTRACT = qr/Maximum Frequency:\s*([\d.]+)/i; 	#obsolete?
$REGEX_XILINX_TCLK_EXTRACT = qr/Minimum Period:\s*([\d.]+)/i;		#obsolete?

$REGEX_XILINX_SYNTCLK_SEQUENCE = qr/\s*([\d.]+)\w*\s*\(frequency: ([\d.]+)/i;
$REGEX_XILINX_SYNTCLK_EXTRACT1 = qr/Default period analysis for Clock \'(\w*)\'\s*\n\s*Clock period:(.*)/i;				#not req freq
$REGEX_XILINX_SYNTCLK_EXTRACT2 = qr/Timing constraint:[\s\w=]+\"(\w*)\"[\s\w.]*\n\s*Clock period:(.*)/i; 				#req freq (timing met)
$REGEX_XILINX_SYNTCLK_EXTRACT3 = qr/Timing constraint:[\s\w=]+\"(\w*)\"[\s\w.]*\n[\s\w\:\-.]+\n\s*Clock period:(.*)/i; 	#req freq (timing not met)
@REGEX_XILINX_SYNTCLK_EXTRACT = ($REGEX_XILINX_SYNTCLK_EXTRACT1, $REGEX_XILINX_SYNTCLK_EXTRACT2, $REGEX_XILINX_SYNTCLK_EXTRACT3);

$REGEX_XILINX_IMPTCLK_EXTRACT = qr/\s*\|\s*([\d.]+)\|/i;
#======= Tool =========
# Xilinx synthesis, implementation tool and its version extract
# $1 = ver, $2 = tool
$REGEX_XILINX_TOOL_EXTRACT = qr/Release\s*([\d\w.]+)[\s-]*([\d\w.]+)/i;
#-\s*([\d\w.]+)\s*\R/i;

#======= Option file =======
# REGEX for extracting option data from option.log
$REGEX_XILINX_REQ_SYN_FREQ_EXTRACT = qr/REQ_SYNTHESIS_FREQ = (.*)/i;
$REGEX_XILINX_REQ_SYN_TCLK_EXTRACT = qr/REQ_SYNTHESIS_TCLK = (.*)/i;
$REGEX_XILINX_REQ_IMP_FREQ_EXTRACT = qr/REQ_IMPLEMENTATION_FREQ = (.*)/i;
$REGEX_XILINX_REQ_IMP_TCLK_EXTRACT = qr/REQ_IMPLEMENTATION_TCLK = (.*)/i;
	
$REGEX_XILINX_COSTTABLE_EXTRACT = qr/COST_TABLE = (.*)/i;
$REGEX_XILINX_SYN_OPT_EXTRACT = qr/SYN_OPTS = (.*)/i;
$REGEX_XILINX_MAP_OPT_EXTRACT = qr/MAP_OPTS = (.*)/i;
$REGEX_XILINX_PAR_OPT_EXTRACT = qr/PAR_OPTS = (.*)/i;




#####################################################################
# ALTERA Regex strings
#####################################################################
$REGEX_ALTERA_UTIL_NUMBER = qr/([\d,]+)/;
$REGEX_ALTERA_UTIL_SEQUENCE = qr/([\d,]+) \/ ([\d,]+) \( ([\d< ]+) %/;

#====== Resource Utilization =======

#LOGIC_ELEMENTS
$A_LE_VAR1 = qr/Total logic elements\s*;\s*$REGEX_ALTERA_UTIL_SEQUENCE/;
$A_LE_VAR2 = qr/Total logic elements\s*;\s*$REGEX_ALTERA_UTIL_NUMBER/;
@REGEX_ALTERA_LE_EXTRACT = ($A_LE_VAR1, $A_LE_VAR2);
$REGEX_VENDOR_EXTRACT{lc(ALTERA)}{LE} = \@REGEX_ALTERA_LE_EXTRACT;


# ALUTS
$A_LU_ALUTS_VAR1 = qr/ALUTs\s*Used\s*;\s*$REGEX_ALTERA_UTIL_SEQUENCE/;
@REGEX_ALTERA_LU_ALUT_EXTRACT = ($A_LU_ALUTS_VAR1);
$REGEX_VENDOR_EXTRACT{lc(ALTERA)}{ALUTS} = \@REGEX_ALTERA_LU_ALUT_EXTRACT;

#Combination ALUTS
$A_LU_CA_VAR1 = qr/Combinational ALUTs\s*;\s*$REGEX_ALTERA_UTIL_SEQUENCE/;
$A_LU_CA_VAR2 = qr/Combinational ALUTs\s*;\s*$REGEX_ALTERA_UTIL_NUMBER/;
@REGEX_ALTERA_LU_COMB_ALUT_EXTRACT  = ($A_LU_CA_VAR1, $A_LU_CA_VAR2);
$REGEX_VENDOR_EXTRACT{lc(ALTERA)}{COMBALUT} = \@REGEX_ALTERA_LU_COMB_ALUT_EXTRACT;

#Memory ALUTs
$A_LU_MA_VAR1 = qr/Memory ALUTs\s*\;\s*$REGEX_ALTERA_UTIL_SEQUENCE/;
@REGEX_ALTERA_LU_MEMS_ALUT_EXTRACT  = ($A_LU_MA_VAR1);
$REGEX_VENDOR_EXTRACT{lc(ALTERA)}{MEMALUT} = \@REGEX_ALTERA_LU_MEMS_ALUT_EXTRACT;


#ALMS (For Stratix V)
$A_ALM_VAR1 = qr/total ALMs on device\)\s*\;\s*$REGEX_ALTERA_UTIL_SEQUENCE/;
@REGEX_ALTERA_ALM_EXTRACT  = ($A_ALM_VAR1);
$REGEX_VENDOR_EXTRACT{lc(ALTERA)}{ALMS} = \@REGEX_ALTERA_ALM_EXTRACT;

#LUT REGS
$A_LU_LR_VAR1 = qr/LUT_REGs\s*\;\s*$REGEX_ALTERA_UTIL_SEQUENCE/;
@REGEX_ALTERA_LU_LUT_REGS_EXTRACT  = ($A_LU_LR_VAR1);
$REGEX_VENDOR_EXTRACT{lc(ALTERA)}{LUTREGS} = \@REGEX_ALTERA_LU_LUT_REGS_EXTRACT;

#Dedicated Logic Register
$A_LU_DL_VAR1 = qr/Dedicated logic registers\s*\;\s*$REGEX_ALTERA_UTIL_SEQUENCE/;
$A_LU_DL_VAR2 = qr/Dedicated logic registers\s*\;\s*$REGEX_ALTERA_UTIL_NUMBER/;
@REGEX_ALTERA_LU_DEDI_LREG_EXTRACT  = ($A_LU_DL_VAR1, $A_LU_DL_VAR2);
$REGEX_VENDOR_EXTRACT{lc(ALTERA)}{DLREG} = \@REGEX_ALTERA_LU_DEDI_LREG_EXTRACT;

#Logic Utilization
$A_LU_VAR1 = qr/Logic utilization\s*\;\s*$REGEX_ALTERA_UTIL_SEQUENCE/;
@REGEX_ALTERA_LU_EXTRACT = ($A_LU_VAR1);
$REGEX_VENDOR_EXTRACT{lc(ALTERA)}{LOGIC} = \@REGEX_ALTERA_LU_EXTRACT;

#MEMORY BITS
$A_MEM_VAR1 = qr/memory bits\s*;\s*$REGEX_ALTERA_UTIL_SEQUENCE/;
$A_MEM_VAR2 = qr/memory bits\s*;\s*$REGEX_ALTERA_UTIL_NUMBER/;
@REGEX_ALTERA_MEM_EXTRACT = ($A_MEM_VAR1, $A_MEM_VAR2);
$REGEX_VENDOR_EXTRACT{lc(ALTERA)}{MEMORY} = \@REGEX_ALTERA_MEM_EXTRACT;

#IMPLEMENTATION BITS
$A_IMPMEM_VAR1 = qr/memory implementation bits\s*;\s*$REGEX_ALTERA_UTIL_SEQUENCE/;
@REGEX_ALTERA_IMPMEM_EXTRACT = ($A_IMPMEM_VAR1);

#DSP
$A_DSP9_VAR1 = qr/DSP block 9-bit elements\s*;\s*$REGEX_ALTERA_UTIL_SEQUENCE/;
$A_DSP9_VAR2 = qr/DSP block 9-bit elements\s*;\s*$REGEX_ALTERA_UTIL_NUMBER/;
$A_DSP18_VAR1 = qr/DSP block 18-bit elements\s*;\s*$REGEX_ALTERA_UTIL_SEQUENCE/;
$A_DSP18_VAR2 = qr/DSP block 18-bit elements\s*;\s*$REGEX_ALTERA_UTIL_NUMBER/;
$testa = qr/DSP block 9-bit elements\s*([.]+)/;
@REGEX_ALTERA_DSP_EXTRACT = ($A_DSP9_VAR1, $A_DSP9_VAR2, $A_DSP18_VAR1, $A_DSP18_VAR2, $testa); 
$REGEX_VENDOR_EXTRACT{lc(ALTERA)}{DSP} = \@REGEX_ALTERA_DSP_EXTRACT;

#MULTIPLIERS
$A_MULT9_VAR1 = qr/Embedded Multiplier 9-bit elements\s*; $REGEX_ALTERA_UTIL_SEQUENCE/;
$A_MULT9_VAR2 = qr/Embedded Multiplier 9-bit elements\s*; $REGEX_ALTERA_UTIL_NUMBER/;
@REGEX_ALTERA_MULT9BIT_EXTRACT = ($A_MULT9_VAR1, $A_MULT9_VAR2);
$REGEX_VENDOR_EXTRACT{lc(ALTERA)}{MULT} = \@REGEX_ALTERA_MULT9BIT_EXTRACT;

#IO
$A_IO_VAR1 = qr/Total pins\s*\; $REGEX_ALTERA_UTIL_SEQUENCE/;
$A_IO_VAR2 = qr/Total pins\s*\; $REGEX_ALTERA_UTIL_NUMBER/;
@REGEX_ALTERA_PIN_EXTRACT = ($A_IO_VAR1, $A_IO_VAR2);
$REGEX_VENDOR_EXTRACT{lc(ALTERA)}{IO} = \@REGEX_ALTERA_PIN_EXTRACT;

#======== Timing =========
$REGEX_ALTERA_TIMING = qr/Clock Setup: '(\w*)'\s* ; [\/\w]+\s* ; ([\w\d\s.(=)]+)\s* ; ([\w\d\s.(=)]+)\s* \;/;
$REGEX_ALTERA_TIMING_DATA_EXTRACT = qr/([\d.]+)[\s\w]+\( period = ([\d.]+)/;

#======= Options =======
$REGEX_ALTERA_SYNOPTS_EXTRACT = qr/SYN_OPTS = (.*)/;
$REGEX_ALTERA_IMPOPTS_EXTRACT = qr/IMP_OPTS = (.*)/;
$REGEX_ALTERA_SEED_EXTRACT = qr/SEED = (.*)/;

$REGEX_ALTERA_REQ_FREQ_EXTRACT = qr/REQ_IMPLEMENTATION_FREQ = (.*)/; #unused
$REGEX_ALTERA_REQ_TCLK_EXTRACT = qr/REQ_IMPLEMENTATION_TCLK = (.*)/; #unused

#======= Tool =========
$REGEX_ALTERA_TOOL_EXTRACT = qr/\s*(.*) Version (.*) \d+\/\d+\/\d+ (.*)/i;

#####################################################################
# ALL Vendor Regex strings
#####################################################################
$REGEX_LATENCY_EXTRACT = qr/LATENCY = (.*)/i;
$REGEX_THROUGHPUT_EXTRACT = qr/THROUGHPUT = (.*)/i;
$REGEX_BEST_MATCH_EXTRACT = qr/BEST_MATCH = (.*)\s*/i;
$REGEX_CLOCK_NET_EXTRACT = qr/CLOCK_NET\s*=\s*(.*)/i;

#======= execution time =======
$REGEX_TIME_EXTRACT = qr/(\d*)d (\d*)h:(\d*)m:(\d*)s/;
$REGEX_SYN_TIME_EXTRACT = qr/SYNTHESIS_TIME = (.*)/i;
$REGEX_IMP_TIME_EXTRACT = qr/IMPLEMENTATION_TIME = (.*)/i;


# \w*(\d*)h:(\d*)m:(\d*)s/i;
















#####################################################################
# ERROR/WARNINGS CHECKING regex strings
#####################################################################
	#########
	# XILINX
	#########
	
	# XST
	$REGEX_XILINX_XST_ERROR1 = qr/Number of errors\s*:\s*([\d,.]+)/;
	$REGEX_XILINX_XST_INFO1 = "Error(s) in XST!";
	$REGEX_XILINX_XST_ERROR2 = qr/Number of warnings\s*:\s*([\d,.]+)/;
	$REGEX_XILINX_XST_INFO2 = "Warning(s) in XST!";
	@REGEX_XILINX_XST_ERROR = ($REGEX_XILINX_XST_ERROR1, $REGEX_XILINX_XST_ERROR2);
	@REGEX_XILINX_XST_INFO = ($REGEX_XILINX_XST_INFO1, $REGEX_XILINX_XST_INFO2);
	$REGEX_VENDOR_ERROR{lc(XILINX)}{XST}{REGEX} = \@REGEX_XILINX_XST_ERROR;
	$REGEX_VENDOR_ERROR{lc(XILINX)}{XST}{INFO} = \@REGEX_XILINX_XST_INFO;
	
	# NGD BUILD
	$REGEX_XILINX_NGD_ERROR1 = qr/Number of errors:\s*([\d,.]+)/;
	$REGEX_XILINX_NGD_INFO1 = "Error(s) in NGD!";
	$REGEX_XILINX_NGD_ERROR2 = qr/Number of warnings:\s*([\d,.]+)/;
	$REGEX_XILINX_NGD_INFO2 = "Warning(s) in NGD!";
	@REGEX_XILINX_NGD_ERROR = ($REGEX_XILINX_NGD_ERROR1, $REGEX_XILINX_NGD_ERROR2);
	@REGEX_XILINX_NGD_INFO = ($REGEX_XILINX_NGD_INFO1, $REGEX_XILINX_NGD_INFO2);
	$REGEX_VENDOR_ERROR{lc(XILINX)}{NGD}{REGEX} = \@REGEX_XILINX_NGD_ERROR;
	$REGEX_VENDOR_ERROR{lc(XILINX)}{NGD}{INFO} = \@REGEX_XILINX_NGD_INFO;
	
	# MAP
	$REGEX_XILINX_MAP_ERROR1 = qr/Number of errors:\s*([\d,.]+)/;
	$REGEX_XILINX_MAP_INFO1 = "Error(s) in MAP!";
	$REGEX_XILINX_MAP_ERROR2 = qr/Number of warnings:\s*([\d,.]+)/;
	$REGEX_XILINX_MAP_INFO2 = "Warning(s) in MAP!";
	@REGEX_XILINX_MAP_ERROR = ($REGEX_XILINX_MAP_ERROR1, $REGEX_XILINX_MAP_ERROR2);
	@REGEX_XILINX_MAP_INFO = ($REGEX_XILINX_MAP_INFO1, $REGEX_XILINX_MAP_INFO2);
	$REGEX_VENDOR_ERROR{lc(XILINX)}{MAP}{REGEX} = \@REGEX_XILINX_MAP_ERROR;
	$REGEX_VENDOR_ERROR{lc(XILINX)}{MAP}{INFO} = \@REGEX_XILINX_MAP_INFO;
	
	# PAR
	$REGEX_XILINX_PAR_ERROR1 = qr/Number of error messages:\s*([\d,.]+)/;
	$REGEX_XILINX_PAR_INFO1 = "Error(s) in PAR!";
	$REGEX_XILINX_PAR_ERROR2 = qr/Number of warning messages:\s*([\d,.]+)/;
	$REGEX_XILINX_PAR_INFO2 = "Warning(s) in PAR!";
	$REGEX_XILINX_PAR_ERROR3 = qr/Placement:[\w ]+[-\s]+([\d]+)[\w\s.]+/;
	$REGEX_XILINX_PAR_INFO3 = "Placement Error(s) have occured!";
	$REGEX_XILINX_PAR_ERROR4 = qr/Routing:[\w ]+[-\s]+([\d]+)[\w\s.]+/;
	$REGEX_XILINX_PAR_INFO4 = "Routing Error(s) have occured!";
	$REGEX_XILINX_PAR_ERROR5 = qr/Timing:[\w ]+[-\s]+([\d]+)[\w\s.]+/;
	#Timing: Completed - 35 Error(s) found.
	$REGEX_XILINX_PAR_INFO5 = "Timing Error(s) have occured!";
	@REGEX_XILINX_PAR_ERROR = ($REGEX_XILINX_PAR_ERROR1, $REGEX_XILINX_PAR_ERROR2, $REGEX_XILINX_PAR_ERROR3, $REGEX_XILINX_PAR_ERROR4, $REGEX_XILINX_PAR_ERROR5);
	@REGEX_XILINX_PAR_INFO = ($REGEX_XILINX_PAR_INFO1, $REGEX_XILINX_PAR_INFO2, $REGEX_XILINX_PAR_INFO3, $REGEX_XILINX_PAR_INFO4, $REGEX_XILINX_PAR_INFO5);
	$REGEX_VENDOR_ERROR{lc(XILINX)}{PAR}{REGEX} = \@REGEX_XILINX_PAR_ERROR;
	$REGEX_VENDOR_ERROR{lc(XILINX)}{PAR}{INFO} = \@REGEX_XILINX_PAR_INFO;
	
	
	#########
	# ALTERA
	#########
	# QUARTUS_MAP
	$REGEX_ALTERA_QMAP_ERROR1 = qr/([\d]+) errors/;
	$REGEX_ALTERA_QMAP_INFO1 = "Error(s) in QUARTUS MAP!";
	$REGEX_ALTERA_QMAP_ERROR2 = qr/([\d]+) warning/;
	$REGEX_ALTERA_QMAP_INFO2 = "Warning(s) in QUARTUS MAP!";
	@REGEX_ALTERA_QMAP_ERROR = ($REGEX_ALTERA_QMAP_ERROR1, $REGEX_ALTERA_QMAP_ERROR2);
	@REGEX_ALTERA_QMAP_INFO = ($REGEX_ALTERA_QMAP_INFO1, $REGEX_ALTERA_QMAP_INFO2);
	$REGEX_VENDOR_ERROR{lc(ALTERA)}{QUARTUS_MAP}{REGEX} = \@REGEX_ALTERA_QMAP_ERROR;
	$REGEX_VENDOR_ERROR{lc(ALTERA)}{QUARTUS_MAP}{INFO} = \@REGEX_ALTERA_QMAP_INFO;
	
	# QUARTUS_FIT
	$REGEX_ALTERA_QFIT_ERROR1 = qr/([\d]+) errors/;
	$REGEX_ALTERA_QFIT_INFO1 = "Error(s) in QUARTUS FIT!";
	$REGEX_ALTERA_QFIT_ERROR2 = qr/([\d]+) warning/;
	$REGEX_ALTERA_QFIT_INFO2 = "Warning(s) in QUARTUS FIT!";
	@REGEX_ALTERA_QFIT_ERROR = ($REGEX_ALTERA_QFIT_ERROR1, $REGEX_ALTERA_QFIT_ERROR2);
	@REGEX_ALTERA_QFIT_INFO = ($REGEX_ALTERA_QFIT_INFO1, $REGEX_ALTERA_QFIT_INFO2);
	$REGEX_VENDOR_ERROR{lc(ALTERA)}{QUARTUS_FIT}{REGEX} = \@REGEX_ALTERA_QFIT_ERROR;
	$REGEX_VENDOR_ERROR{lc(ALTERA)}{QUARTUS_FIT}{INFO} = \@REGEX_ALTERA_QFIT_INFO;
	
	# QUARTUS_TAN
	$REGEX_ALTERA_QTAN_ERROR1 = qr/([\d]+) errors/;
	$REGEX_ALTERA_QTAN_INFO1 = "Error(s) in QUARTUS Timing Analyzer!";
	$REGEX_ALTERA_QTAN_ERROR2 = qr/([\d]+) warning/;
	$REGEX_ALTERA_QTAN_INFO2 = "Warning(s) in QUARTUS Timing Analyzer!";
	@REGEX_ALTERA_QTAN_ERROR = ($REGEX_ALTERA_QTAN_ERROR1, $REGEX_ALTERA_QTAN_ERROR2);
	@REGEX_ALTERA_QTAN_INFO = ($REGEX_ALTERA_QTAN_INFO1, $REGEX_ALTERA_QTAN_INFO2);
	$REGEX_VENDOR_ERROR{lc(ALTERA)}{QUARTUS_TAN}{REGEX} = \@REGEX_ALTERA_QTAN_ERROR;
	$REGEX_VENDOR_ERROR{lc(ALTERA)}{QUARTUS_TAN}{INFO} = \@REGEX_ALTERA_QTAN_INFO;

















#####################################################################
1; #return 1 when including this file along with other scripts.