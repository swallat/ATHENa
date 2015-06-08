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

package Structs;
use Class::Struct;

struct 'Device' =>
{
	RUN_NO => '$',
	
	ROOT_DIR => '$',
	WORKSPACE_DIR => '$',
	
	VENDOR => '$',
	FAMILY  => '$',
	DEVICE => '$',
	REQ_SYN_FREQ => '$',
	REQ_IMP_FREQ => '$',
	SYN_CONSTRAINT_FILE => '$',
	IMP_CONSTRAINT_FILE => '$',
	
	DISPATCH_TYPE => '$',
	LOCAL_APPLICATION => '$',
	
	UTIL_FACTORS => '%',
	DEVICE_SPECS => '%',
	UTIL_RESULTS => '%',
	PERF_RESULTS => '%',
	
	TOOL_OPTIONS => '%',
	SYNTHESIS_TOOLS => '%',
	
	MAX_RUNS => '$',
};


=begin COMMENT ##########################################

The tool options are stored as hashes. 
Format:
$TOOL_OPTIONS{TOOL}{OPT} = flag;

$UTIL_FACTOR{MAX_$DEVITEM_UTILIZATION} = #percentage

=end COMMENT ############################################
=cut















return 1;