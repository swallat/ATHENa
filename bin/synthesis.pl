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
# Xilinx_synthesis
# Version: 0.1
# 
# Single run application performs the synthesis and implementation 
# once based on the options file.
#####################################################################

#####################################################################
# Synthesis
# Arguements: VENDOR
# Other information is provided to the vendor functions through a global struct
#####################################################################	
sub synthesis{
	my $syn_start_time = time();
	my $VENDOR = $_[0];	
	my $retval = 0;
	
	if(lc($VENDOR) eq "xilinx"){
		printOut "Starting Xilinx synthesis!\n";
		$retval = xilinx_synthesis();
	}
	elsif(lc($VENDOR) eq "altera"){
		printOut "Starting Altera synthesis!\n";
		$retval = altera_synthesis();
	}
	elsif(lc($VENDOR) eq "actel"){
		
	}
	
	my $syn_elapsed_time = elapsed_time($syn_start_time);
	printOut "SYNTHESIS time: $syn_elapsed_time\n";
	&printToLog($OPTION_LOG_FILE_NAME, "SYNTHESIS_TIME = $syn_elapsed_time");
	

	# shift right by 8 to get the correct return code
	return ($retval >> 8);
}






1; #return 1 when including this file along with other scripts.