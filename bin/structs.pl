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


use Class::Struct;

#####################################################################
# These structs are used to store the requested device information 
# from the design configuration
#####################################################################
struct XilinxReqDev =>
[
	VENDOR => '$',
	FAMILY  => '$',
	DEVICE => '$',
	MAX_SLICE_UTILIZATION  => '$',
	MAX_BRAM_UTILIZATION => '$',
	MAX_DSP_UTILIZATION => '$',
	MAX_MUL_UTILIZATION  => '$',
	MAX_PIN_UTILIZATION  => '$',
	SYN_CONSTRAINT_FILE => '$',
	IMP_CONSTRAINT_FILE => '$',
	REQ_SYN_FREQ => '$',
	REQ_IMP_FREQ => '$',
];

struct ActelReqDev =>
[
	VENDOR => '$',
	FAMILY  => '$',
	DEVICE => '$',
	MAX_UTILIZATION  => '$',
];

struct AlteraReqDev =>
[
	VENDOR => '$',
	FAMILY  => '$',
	DEVICE => '$',
	MAX_LE_UTILIZATION  => '$',
    MAX_MEMORY_UTILIZATION => '$',
	MAX_DSP_UTILIZATION => '$',
	MAX_MUL_UTILIZATION => '$',
	MAX_PIN_UTILIZATION => '$',
	MAX_LOGIC_UTILIZATION => '$',
	
	SYN_CONSTRAINT_FILE => '$',
	IMP_CONSTRAINT_FILE => '$',
	REQ_SYN_FREQ => '$',
	REQ_IMP_FREQ => '$',
];

#####################################################################
# Device library structs
#####################################################################
struct XilinxLibDev =>
[
	VENDOR => '$',
	FAMILY => '$',
	NAME  => '$',
	SLICE => '$',
	BRAM => '$',
	DSP => '$',
	MULT => '$',
	IO => '$',
];

struct ActelLibDev =>
[
	VENDOR => '$',
	FAMILY => '$',
	NAME  => '$',
];

struct AlteraLibDev =>
[
	VENDOR  => '$',
	FAMILY => '$',
	NAME  => '$',
	LE => '$',
	MEMORY => '$',
	DSP => '$',
	MULT => '$',
	IO => '$',
];





1; #return 1 when including this file along with other scripts.