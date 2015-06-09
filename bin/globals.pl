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
# Global Directories
#####################################################################
# This is the workspace folder 
#<work_dir>
# |_ Application   
#   |_ Date_ProjectName_RunNo  <== workspace
$WORKSPACE = "" unless defined $WORKSPACE;
$TEMP_DIR = "" unless defined $TEMP_DIR;

#####################################################################
# Variables for the tool configuration
#####################################################################
# constants are pre declared
# Xilinx
$XST, $XNGDBUILD, $XMAP , $XPAR, $XTRACE, $XPARTGEN, $XXDL, $XNETGEN; #___ add xdl,netgen support
$ISE_VERSION, $ISE_TYPE;
# Altera
$QMAP, $QFIT, $QASM, $QTAN, $QSTA, $QPOW;
$QUARTUS_VERSION, $QUARTUS_TYPE;
# Actel


#####################################################################
# Vars for tool outputs
#####################################################################
#Xilinx
$SCRIPT_FILE, $PROJECT_FILE, $NGC_FILE, $NGD_FILE, $PCF_FILE, $NCD_FILE, $PAR_FILE;
$RUNMODE = "xflow";

#####################################################################
# Libraries
#####################################################################
%DEVICE_LIBRARY = ();
%OPTION_LIBRARY = ();

#####################################################################
# Variables for the design configuration
#####################################################################
# work directory, used as a root for all result directories
$WORK_DIR = "";

# directory containing synthesizable source files for the project
$SOURCE_DIR = "";

# synthesizable source files listed in the order suitable for synthesis and implementation
# low level modules first, top level entity last
$SOURCE_LIST_FILE = "";
@SOURCE_FILES = ();

# ===========================================
# ========== Verification
# Perform only verification (synthesis and implementation parameters are ignored)
# VERIFICATION_ONLY = <ON | OFF>
$VERIFICATION_ONLY = "";

# directory containing compilable source files of testbench
$VERIFICATION_DIR = "";

# A file list containing list of files in the order suitable for synthesis and implementation
# low level modules first, top level entity last
$VERIFICATION_LIST_FILE = "";
@VERIFICATION_FILES = ();

# A list containing test vectors
@TEST_VECTORS_FILES = ();

# name of testbench's top level entity
$TB_TOP_LEVEL_ENTITY = "";

# name of testbench's top level architecture
$TB_TOP_LEVEL_ARCH = "";

# MAX_TIME_FUNCTIONAL_VERIFICATION = <$time $unit>
#	supported unit are us and ns only
$MAX_TIME_FUNCTIONAL_VERIFICATION = "";

# FUNCTIONAL_VERIFICATION_MODE = <on | off>
$FUNCTIONAL_VERIFICATION_MODE = "";
# ========== End of verification
# ===========================================

# project name - Default Value: project1
$PROJECT_NAME = "";

# name of top level entity
$TOP_LEVEL_ENTITY = "";

# name of top level architecture
$TOP_LEVEL_ARCH = "";

# name of clock net
$CLOCK_NET = "";

#formulas for latency
$LATENCY = "";

#formulas for THROUGHPUT
$THROUGHPUT = "";

# The following 4 parameters: 
#  APPLICATION
#  OPTIMIZATION_TARGET
#  OPTIONS, and
#  EXHAUSTIVE_SEARCH_STRATEGY
# determine which top level script is called,
# and which options are used.

# OPTIMIZATION_TARGET = speed | area
$OPTIMIZATION_TARGET = "";

# OPTIONS = default | user
$OPTIONS = "";

# EXHAUSTIVE_SEARCH_STRATEGY = <exhaustive_strategy_name>
$EXHAUSTIVE_SEARCH_STRATEGY = "";


# top level script
# APPLICATION = single_run | exhaustive
# single_run: single run through synthesis and implementation with options
#             defined in the file options.<OPTIONS>_<OPTIMIZATION_TARGET>
# exhaustive: multiple runs through synthesis and implementation
#              with constant options defined in options.<OPTIONS>_<OPTIMIZATION_TARGET>
#              and variable options defined in  exhaustive.<exhaustive_strategy_name>
$APPLICATION = single_run;


#hash for list of requested devices
# requested_devices{vendor} returns an array with the list of devices for that specific vendor
%requested_devices = ();











1; #return 1 when including this file along with other scripts.