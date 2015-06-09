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

$ATHENA_VERSION = "0.6.5";

#####################################################################
# FILE/FOLDER NAMES for the design
#####################################################################
die "ERROR: Constants - Root directory does not exit!" if($ROOT_DIR eq "");
#FOLDER NAMES =========================
$DEVICE_LIBRARY_DIR_NAME = "device_lib";
$OPTION_LIBRARY_DIR_NAME = "option_lib";

#bin directories
$VENDOR_FUNCTIONS_DIR_NAME = "vendor_functions";
$APPLICATION_DIR_NAME = "apps";
$UTILITIES_DIR_NAME = "utils";

#FOLDER PATHS  =========================
$DEVICE_LIBRARY_DIR = 	"$ROOT_DIR/$DEVICE_LIBRARY_DIR_NAME";
$OPTION_LIBRARY_DIR = 	"$ROOT_DIR/$OPTION_LIBRARY_DIR_NAME";

$VENDOR_FUNCTIONS_DIR = "$BIN_DIR/$VENDOR_FUNCTIONS_DIR_NAME";
$APPLICATION_DIR = 		"$BIN_DIR/$APPLICATION_DIR_NAME";

#FILE NAMES =========================
#files
$DESIGN_CONFIGURATION_FILE_NAME = "design.config.txt";
$LOCAL_CONFIG_FILE_NAME = "local.config.txt";
$LOCAL_OPTIONS_FILE_NAME = "local.options.txt";
$REPORT_SCRIPT_NAME = "report.pl";
$DB_REPORT_GENERATOR_SCRIPT_NAME = "db_report_generator.pl";

$DEVICE_LIB_SUFFIX = "_device_lib.txt";
$OPTION_LIB_SUFFIX = "_option_lib.txt";

$XILINX_DEVICE_LIBRARY_FILE_NAME = "xilinx".$DEVICE_LIB_SUFFIX;
$XILINX_OPTION_LIBRARY_FILE_NAME = "xilinx".$OPTION_LIB_SUFFIX;

$ALTERA_DEVICE_LIBRARY_FILE_NAME = "altera".$DEVICE_LIB_SUFFIX;
$ALTERA_OPTION_LIBRARY_FILE_NAME = "altera".$OPTION_LIB_SUFFIX;

$ACTEL_DEVICE_LIBRARY_FILE_NAME = "actel".$DEVICE_LIB_SUFFIX;
$ACTEL_OPTION_LIBRARY_FILE_NAME = "actel".$OPTION_LIB_SUFFIX;

$XILINX_SYNTHESIS_CONSTRAINTS_FILE_NAME = "synth.xcf";
$XILINX_IMPLEMENTATION_CONSTRAINTS_FILE_NAME = "impl.ucf";

$OPTION_LOG_FILE_NAME = "option_log.txt";
$LOCAL_CMD_LOG_FILE_NAME = "athena_log.txt";
$LOCAL_TEMP_PROGRESS_LOG_FILE_NAME = "local_run_progress.txt";
$LOCAL_PROGRESS_LOG_FILE_NAME = "run_progress.txt";

$CMD_LOG_FILE_NAME = "athena_log.txt";
$PROGRESS_LOG_FILE_NAME = "athena_progress.txt";

$LOCAL_RUN_LOG_FILE_NAME = "run_log.txt";
$RUN_LOG_FILE_NAME = "run_log.txt";

$LOCAL_RUN_INFO_FILE_NAME = "run_info.txt";

#FILE PATHS =========================
$DESIGN_CONFIGURATION_FILE = "$CONFIG_DIR/$DESIGN_CONFIGURATION_FILE_NAME";

$DEFAULT_XILINX_DEVICE_LIBRARY_FILE = "$DEVICE_LIBRARY_DIR/$XILINX_DEVICE_LIBRARY_FILE_NAME";
$XILINX_DEVICE_LIBRARY_FILE = "$CONFIG_DIR/$XILINX_DEVICE_LIBRARY_FILE_NAME";
$XILINX_OPTION_LIBRARY_FILE = "$OPTION_LIBRARY_DIR/$XILINX_OPTION_LIBRARY_FILE_NAME";

$DEFAULT_ALTERA_DEVICE_LIBRARY_FILE = "$DEVICE_LIBRARY_DIR/$ALTERA_DEVICE_LIBRARY_FILE_NAME";
$ALTERA_DEVICE_LIBRARY_FILE = "$CONFIG_DIR/$ALTERA_DEVICE_LIBRARY_FILE_NAME";
$ALTERA_OPTION_LIBRARY_FILE = "$OPTION_LIBRARY_DIR/$ALTERA_OPTION_LIBRARY_FILE_NAME";

$DEFAULT_ACTEL_DEVICE_LIBRARY_FILE = "$DEVICE_LIBRARY_DIR/$ACTEL_DEVICE_LIBRARY_FILE_NAME";
$ACTEL_DEVICE_LIBRARY_FILE = "$CONFIG_DIR/$ACTEL_DEVICE_LIBRARY_FILE_NAME";
$ACTEL_OPTION_LIBRARY_FILE = "$OPTION_LIBRARY_DIR/$ACTEL_OPTION_LIBRARY_FILE_NAME";

$REPORT_SCRIPT = "$BIN_DIR/$REPORT_SCRIPT_NAME";
$DB_REPORT_GENERATOR = "$BIN_DIR/$UTILITIES_DIR_NAME/$DB_REPORT_GENERATOR_SCRIPT_NAME";

$CMD_LOG_FILE = "$WORKSPACE/$CMD_LOG_FILE_NAME";
$PROGRESS_LOG_FILE = "$WORKSPACE/$PROGRESS_LOG_FILE_NAME";

$RUN_LOG_FILE  = "$TEMP_DIR/$RUN_LOG_FILE_NAME";

#####################################################################
# Global Flags
#####################################################################
#FILE writing options
$APPEND = 0;
$OVERWRITE = 1;

#YES NO flags
$YES = 1;
$NO = 0;

#####################################################################
# SCRIPT NAMES for the design
#####################################################################
$DISPATCH_SCRIPT_NAME = "dispatch.pl";
$GLOBAL_SYNTHESIS_SCRIPT_NAME = "synthesis.pl";
$GLOBAL_IMPLEMENTATION_SCRIPT_NAME = "implementation.pl";
$RESULT_EXTRACTION_SCRIPT_NAME = "extract.pl";

$DISPATCH_SCRIPT = "$BIN_DIR/$DISPATCH_SCRIPT_NAME";
$GLOBAL_SYNTHESIS_SCRIPT = "$BIN_DIR/$GLOBAL_SYNTHESIS_SCRIPT_NAME";
$GLOBAL_IMPLEMENTATION_SCRIPT = "$BIN_DIR/$GLOBAL_IMPLEMENTATION_SCRIPT_NAME";
$RESULT_EXTRACTION_SCRIPT = "$BIN_DIR/$RESULT_EXTRACTION_SCRIPT_NAME";

$XILINX_SYNTHESIS_SCRIPT = "$VENDOR_FUNCTIONS_DIR/xilinx/xilinx_synthesis.pl";
$XILINX_IMPLEMENTATION_SCRIPT = "$VENDOR_FUNCTIONS_DIR/xilinx/xilinx_implementation.pl";

$ALTERA_SYNTHESIS_SCRIPT = "$VENDOR_FUNCTIONS_DIR/altera/altera_synthesis.pl";
$ALTERA_IMPLEMENTATION_SCRIPT = "$VENDOR_FUNCTIONS_DIR/altera/altera_implementation.pl";

$ACTEL_SYNTHESIS_SCRIPT = "$VENDOR_FUNCTIONS_DIR/actel/actel_synthesis.pl";
$ACTEL_IMPLEMENTATION_SCRIPT = "$VENDOR_FUNCTIONS_DIR/actel/actel_implementation.pl";

$SINGLE_RUN_SCRIPT_NAME = "single_run.pl";
$SINGLE_RUN_SCRIPT = "$APPLICATION_DIR/$SINGLE_RUN_SCRIPT_NAME";

$DEVICE_MODULE = "$BIN_DIR/device.pm";
$STRUCT_MODULE = "$BIN_DIR/structs.pm";

#####################################################################
# Dispatch Lists
#####################################################################
@DISPATCH_LIST = ($DEVICE_MODULE, $STRUCT_MODULE, $DISPATCH_SCRIPT, $GLOBAL_SYNTHESIS_SCRIPT, $GLOBAL_IMPLEMENTATION_SCRIPT, $SINGLE_RUN_SCRIPT, $RESULT_EXTRACTION_SCRIPT, );

#####################################################################
# VENDOR INFORMATION
#####################################################################

# VENDORS
@VENDORS = qw(XILINX ALTERA ACTEL);

# Tool information is determined by the environmental variables
$ISE_ENV_VAR = "XILINX";
$ISE_INSTALL_FOLDER = $ENV{$ISE_ENV_VAR};
$ALTERA_ENV_VAR = "QUARTUS_ROOTDIR";
$ALTERA_INSTALL_FOLDER = $ENV{$ALTERA_ENV_VAR};
$ACTEL_ENV_VAR = "";
$ACTEL_INSTALL_FOLDER = $ENV{$ACTEL_ENV_VAR};

@XILINX_SYNTHESIS_TOOLS = qw(SYNPLIFY XST);
@XILINX_IMPLEMENTATION_TOOLS = qw(NGDBUILD MAP PAR TRACE);
@ALL_XILINX_TOOLS = (@XILINX_SYNTHESIS_TOOLS, @XILINX_IMPLEMENTATION_TOOLS); 

@ALTERA_SYNTHESIS_TOOLS = qw(QUARTUS_MAP);
@ALTERA_IMPLEMENTATION_TOOLS = qw(QUARTUS_FIT QUARTUS_ASM QUARTUS_TAN);
@ALL_ALTERA_TOOLS = (@ALTERA_SYNTHESIS_TOOLS, @ALTERA_IMPLEMENTATION_TOOLS); 

@ACTEL_SYNTHESIS_TOOLS = qw(SYNPLIFY);
@ACTEL_IMPLEMENTATION_TOOLS = qw();
@ALL_ACTEL_TOOLS = (@ACTEL_SYNTHESIS_TOOLS, @ACTEL_IMPLEMENTATION_TOOLS);

$VENDOR_TOOLS{lc(XILINX)} = \@ALL_XILINX_TOOLS;
$VENDOR_TOOLS{lc(ALTERA)} = \@ALL_ALTERA_TOOLS;
$VENDOR_TOOLS{lc(ACTEL)} = \@ALL_ACTEL_TOOLS;

#####################################################################
# Device/Vendor information
#####################################################################
@VENDORS = qw(XILINX ALTERA ACTEL);

@XILINX_DEVICE_ITEMS = qw(SLICE BRAM DSP MULT IO);
@XILINX_DEVICE_ITEMS_NAMES = ("SLICES", "BLOCK RAMS", "DSP", "MULTIPLIERS", "IO");
@XILINX_DEVICE_UTIL_DEFAULTS = qw(0.8 1 1 1 0.9);
$VENDOR_DEVICE_ITEMS{lc(XILINX)} = \@XILINX_DEVICE_ITEMS;
$VENDOR_DEVICE_UTIL_DEFAULTS{lc(XILINX)} = \@XILINX_DEVICE_UTIL_DEFAULTS;

@ALTERA_DEVICE_ITEMS = qw(LE COMBALUT ALM MEMALUT DLREG MEMORY DSP MULT IO LOGIC);
@ALTERA_DEVICE_ITEMS_NAMES = ("LOGIC ELEMENTS", "COMBINATIONAL ALUT", "ADAPTIVE LOGIC MODULES", "MEMORY ALUT", "DEDICATED LOGIC REGISTERS", "MEMORY", "DSP", "MULTIPLIERS", "IO", "TOTAL LOGIC");
@ALTERA_DEVICE_UTIL_DEFAULTS = qw(0.8 0.8 0.8 1 1 1 1 1 0.9 0.8);
$VENDOR_DEVICE_ITEMS{lc(ALTERA)} = \@ALTERA_DEVICE_ITEMS;
$VENDOR_DEVICE_UTIL_DEFAULTS{lc(ALTERA)} = \@ALTERA_DEVICE_UTIL_DEFAULTS;

@ACTEL_DEVICE_ITEMS = qw();
@ALTERA_DEVICE_ITEMS_NAMES = ("");
@ACTEL_DEVICE_UTIL_DEFAULTS = qw();
$VENDOR_DEVICE_ITEMS{lc(ACTEL)} = \@ACTEL_DEVICE_ITEMS;
$VENDOR_DEVICE_UTIL_DEFAULTS{lc(ACTEL)} = \@ACTEL_DEVICE_UTIL_DEFAULTS;

#####################################################################
# Device/Vendor zero utilization factor options
#####################################################################

# XILINX XST ========================================================
my @OPTS = qw(slice_utilization_ratio);
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(SPARTAN3)}{XST}{SLICE} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(SPARTAN6)}{XST}{SLICE} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(VIRTEX4)}{XST}{SLICE} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(VIRTEX5)}{XST}{SLICE} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(VIRTEX6)}{XST}{SLICE} = \@OPTS;

my @OPTS = qw(bram_utilization_ratio);
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(SPARTAN3)}{XST}{BRAM} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(SPARTAN6)}{XST}{BRAM} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(VIRTEX4)}{XST}{BRAM} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(VIRTEX5)}{XST}{BRAM} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(VIRTEX6)}{XST}{BRAM} = \@OPTS;

my @OPTS = qw(dsp_utilization_ratio);
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(SPARTAN6)}{XST}{DSP} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(VIRTEX4)}{XST}{DSP} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(VIRTEX5)}{XST}{DSP} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(VIRTEX6)}{XST}{DSP} = \@OPTS;

my @OPTS = qw(mult_utilization_ratio);
$VENDOR_ZERO_UTIL_OPTS{lc(XILINX)}{lc(SPARTAN3)}{XST}{MULT} = \@OPTS;


# ALTERA QUARTUS_MAP ================================================

my @OPTS = qw(); #qw(MAX_RAM_BLOCKS_M512 MAX_RAM_BLOCKS_M4K MAX_RAM_BLOCKS_MRAM); #some options are device specific, http://www.altera.com/literature/manual/mnl_qsf_reference.pdf
$VENDOR_ZERO_UTIL_OPTS{lc(ALTERA)}{lc("Cyclone")}{QUARTUS_MAP}{MEMORY} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(ALTERA)}{lc("Cyclone II")}{QUARTUS_MAP}{MEMORY} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(ALTERA)}{lc("Cyclone III")}{QUARTUS_MAP}{MEMORY} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(ALTERA)}{lc("Stratix")}{QUARTUS_MAP}{MEMORY} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(ALTERA)}{lc("Stratix II")}{QUARTUS_MAP}{MEMORY} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(ALTERA)}{lc("Stratix III")}{QUARTUS_MAP}{MEMORY} = \@OPTS;

my @OPTS = qw(); #qw(MAX_BALANCING_DSP_BLOCKS);
$VENDOR_ZERO_UTIL_OPTS{lc(ALTERA)}{lc("Cyclone")}{QUARTUS_MAP}{DSP} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(ALTERA)}{lc("Cyclone II")}{QUARTUS_MAP}{DSP} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(ALTERA)}{lc("Cyclone III")}{QUARTUS_MAP}{DSP} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(ALTERA)}{lc("Stratix")}{QUARTUS_MAP}{DSP} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(ALTERA)}{lc("Stratix II")}{QUARTUS_MAP}{DSP} = \@OPTS;
$VENDOR_ZERO_UTIL_OPTS{lc(ALTERA)}{lc("Stratix III")}{QUARTUS_MAP}{DSP} = \@OPTS;



#####################################################################
# reports/logs
#####################################################################

# XILINX
$XILINX_SYNTHESIS_REPORT = "synthesis_report.log";
$XILINX_NGDBUILD_REPORT = "ngdbuild.log";
$XILINX_MAP_REPORT = "map.log";
$XILINX_PAR_REPORT = "par.log";
$XILINX_TRACE_REPORT = "timing_report.twr";
$XILINX_OPTION_REPORT = $OPTION_LOG_FILE_NAME;
# ALTERA

$ALTERA_SYNTHESIS_REPORT = "map.rpt";
$ALTERA_POWER_REPORT = "pow.rpt";
$ALTERA_TIMING_REPORT_1 = "tan.rpt";
$ALTERA_TIMING_REPORT_2 = "sta.rpt";
$ALTERA_IMPLEMENTATION_REPORT = "fit.rpt";
$ALTERA_OPTION_REPORT = $OPTION_LOG_FILE_NAME;

$ALTERA_SYNTHESIS_REPORT_SUFFIX = "map.rpt";
$ALTERA_POWER_REPORT_SUFFIX = "pow.rpt";
$ALTERA_TIMING_REPORT_1_SUFFIX = "tan.rpt";
$ALTERA_TIMING_REPORT_2_SUFFIX = "sta.rpt";
$ALTERA_IMPLEMENTATION_REPORT_SUFFIX = "fit.rpt";

$ALTERA_OPTION_REPORT = $OPTION_LOG_FILE_NAME;

#####################################################################
# Constants for dispatch scripts
#####################################################################

#DISPATCH_TYPE
$DISPATCH_TYPE_NONE = "none";
$DISPATCH_TYPE_BEST_MATCH = "best_match";
$DISPATCH_TYPE_ALL = "all";


#####################################################################
# Default configuration parameter
#####################################################################
$DEFAULT_VERIFICATION_ONLY = "off";
$DEFAULT_FUNCTIONAL_VERFICATION_MODE = "off";

#####################################################################
# ATHENa Setup parameters
#####################################################################
$DEFAULT_SIM_VENDOR = "modelsim";


#####################################################################
# ATHENa Report parameters
#####################################################################
%CLK_KEY = (
	altera => ["IMP_TCLK", "IMP_FREQ"],
	xilinx => ["SYN_FREQ", "SYN_TCLK", "IMP_FREQ", "IMP_TCLK"],	
);









1; #return 1 when including this file along with other scripts.