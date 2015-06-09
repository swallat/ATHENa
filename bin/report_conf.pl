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

# Usage 	:	$REPORT_NAME_FORMAT -- 	determine the header's name
#				$REPORT_ORDER		-- 	Order at which the column in each report will be sorted by
#									-- 	There are 3 report types, resource utilization (resource), option and timing reports.
#									-- 	Specify the order of the report column by left-to-right.
#				$SORTCOLUMN			--	Sort by parameter (RUN_NO by default)
#				$SORTSTYLE			--  Ascending or Descending
#				$PRECISION			-- 	How many decimal numbers should the output display				
# AbbrNote 	:	T_ = total , U_ = used, PU_ = percentage used

$REPORT_NAME_FORMAT{xilinx} = {
	RUN_NO 		=> "RUN",			
	# Resource Utilization Report
	T_SLICE 	=> "TOTAL SLICEs",		U_SLICE 	=> "SLICES",	PU_SLICE 	=> "%",	
	T_BRAM		=> 	"TOTAL BRAMs",		U_BRAM 		=>	"BRAMs",	PU_BRAM		=>	"%",
	T_MULT 		=> "TOTAL MULT",		U_MULT 		=> "MULTs",		PU_MULT 	=> "%",				
	T_DSP		=> 	"TOTAL DSPs",		U_DSP 		=>	"DSPs",		PU_DSP		=>	"%",		
	T_IO		=> "TOTAL PINs",		U_IO		=> "IO",		PU_IO		=> "%",	
	T_LUT		=> 	"TOTAL LUTs",		U_LUT 		=>	"LUTs",		PU_LUT		=>	"%",	
	T_FF		=> "Total FFs",				U_FF 	=> "FFs",	PU_FF 		=> "%",
	# Option Report
	COST_TABLE 	=> "COST TABLE",		SYN_OPT		=> "Synthesis Options",
	MAP_OPT		=> "Map Options",		IMP_OPT		=> "PAR Options",
	# Timing Report
	RSYN_FREQ	=> "REQ SYN FREQ",		SYN_FREQ		=> "SYN FREQ",
	RSYN_TCLK	=> "REQ SYN TCLK",		SYN_TCLK		=> "SYN TCLK",
	RIMP_FREQ	=> "REQ IMP FREQ",		IMP_FREQ		=> "IMP FREQ",
	RIMP_TCLK	=> "REQ IMP TCLK",		IMP_TCLK		=> "IMP TCLK",
	LATENCY		=> "LATENCY",			THROUGHPUT	=> "THROUGHPUT",
	THROUGHPUT_AREA	=> "TP\/Area",		LATENCY_AREA => "Latency*Area",
	# Execution Time Report
	SYN_TIME => "Synthesis Time",		IMP_TIME => "Implementation Time", 	
	TOT_TIME => "Elapsed Time",
};

$REPORT_NAME_FORMAT{altera} = {
	RUN_NO 		=> "RUN",			
	# Resource Utilization Report
	T_LE	=> "Total Logic Elements",	U_LE	=> "Logic Elements",	PU_LE 	=> "%",
	U_LU 	=> "Logic Util", 	PU_LU => "LU (%)",
	T_LU_CA => "Total Combinational ALUTs",			U_LU_CA => "Comb ALUTs",	 PU_LU_CA => "%",
	T_LU_MA => "Total Memory ALUTs",				U_LU_MA => "Mem ALUTs",	 	PU_LU_MA => "%",
	T_LU_RE => "Total LUT REGs",					U_LU_RE => "LUT REGs",	 	PU_LU_RE => "%",
    T_ALMS => "Total ALMs",				         	U_ALMS => "ALMs",	 	PU_ALMS => "%",
	T_ALUTS => "Total ALUTs",						U_ALUTS => "ALUTs",	 	 	PU_ALUTS => "%",
	T_FF		=> "Total FFs",				U_FF 	=> "FFs",	PU_FF 		=> "%",
	
	T_MEM 	=> "Total Memory Bits", 	U_MEM 	=> "Mem Bits", 		PU_MEM 	=> "%",
	T_MULT 	=> "TOTAL MULT",			U_MULT 	=> "MULT",				PU_MULT => "%",			
	T_DSP	=> "TOTAL DSPs",			U_DSP 	=> "DSPs", 				PU_DSP	=> "%",
	T_PIN 	=> "TOTAL PINs",			U_PIN 	=> "PINs",				PU_PIN 	=> "%",			
	# Option Report
	SYN_OPT	=> "Synthesis Options",		IMP_OPT	=> "Implementation Options",
	SEED => "SEED",
	# Timing Report
	RIMP_FREQ	=> "REQ FREQ",			IMP_FREQ		=> "FREQ",
	RIMP_TCLK	=> "REQ TCLK",			IMP_TCLK		=> "TCLK",			
	LATENCY	=> "LATENCY",				THROUGHPUT	=> "THROUGHPUT",	
	THROUGHPUT_AREA	=> "TP\/Area",		LATENCY_AREA => "Latency*Area",
	# Execution Time Report
	SYN_TIME => "Synthesis Time",		IMP_TIME => "Implementation Time", 	
	TOT_TIME => "Elapsed Time",
};
		
		
#NOTE : REPORT_ORDER should matches the variable inside the hashes of respective vendor
$REPORT_ORDER{xilinx} = {
	resource 	=> ["RUN_NO", "U_LUT", "PU_LUT", "U_SLICE", "PU_SLICE", "U_BRAM", "PU_BRAM", "U_MULT", "PU_MULT", "U_DSP", "PU_DSP",  "U_FF", "PU_FF","U_IO", "PU_IO"],
	option 		=> ["RUN_NO", "COST_TABLE", "SYN_OPT", "MAP_OPT", "IMP_OPT" ],
	timing		=> ["RUN_NO", "RSYN_FREQ", "SYN_FREQ", "RSYN_TCLK", "SYN_TCLK", "RIMP_FREQ", "IMP_FREQ", "RIMP_TCLK", "IMP_TCLK", "LATENCY", "THROUGHPUT", "THROUGHPUT_AREA", "LATENCY_AREA"],
	exec_time	=> ["RUN_NO", "SYN_TIME", "IMP_TIME", "TOT_TIME"],
};

$REPORT_ORDER{altera} = {
	resource	=> ["RUN_NO", "U_LU", "PU_LU", "U_LE", "PU_LE", 
					"U_ALUTS", "PU_ALUTS", "U_ALMS", "PU_ALMS",	
					"U_MEM", "PU_MEM", "U_DSP", "PU_DSP", "U_FF", "PU_FF",
					"U_MULT", "PU_MULT", "U_PIN", "PU_PIN"],
	option	 	=> ["RUN_NO", "SEED", "SYN_OPT", "IMP_OPT"],
	timing		=> ["RUN_NO", "RIMP_FREQ", "IMP_FREQ", "RIMP_TCLK", "IMP_TCLK", "LATENCY", "THROUGHPUT", "THROUGHPUT_AREA", "LATENCY_AREA"],
	exec_time	=> ["RUN_NO", "SYN_TIME", "IMP_TIME", "TOT_TIME"],
};

$SORTCOLUMN = "RUN_NO";
$SORTSTYLE = "ASCENDING";
$PRECISION = 3;

@BEST_CRITERIAN = ("AREA", "THROUGHPUT", "THROUGHPUT_AREA", "LATENCY", "LATENCY_AREA");