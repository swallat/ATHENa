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
# APPLICATION: single_run
# Version: 0.1
# 
# Single run application performs the synthesis and implementation 
# once based on the options file.
#####################################################################

#####################################################################
# Performs the single run
# Arguements
# PROVIDED: Vendor, Family, Device
# GLOBAL: sources, tool information
#####################################################################
sub single_run{
	printOut("Running application : SINGLE RUN\n");
	my $vendor = $_[0];

	
	printProgress("Starting Synthesis\n");
	#run the synthesis
	$synthesis_results = synthesis($vendor);
	if($synthesis_results ne 0){ 
		printProgress("Synthesis failed with output $synthesis_results\n");
		return($synthesis_results);
	}
	else{ 
		printProgress("Synthesis completed!\n");
		printProgress("Starting Implementation\n");
		#run the implementation
		$implementation_results = implementation($vendor);
		if($implementation_results eq 0){ printProgress("Implementation completed!\n"); }
		else{ printProgress("Implementation failed with output $implementation_results\n"); }
	}
	
	$trim_mode = $DEV_OBJ->getTrimMode();
	$rundir = $DEV_OBJ->getRunDir();
	&trim($rundir, $trim_mode );
	
	return($synthesis_results, $implementation_results);
}















1; #return 1 when including this file along with other scripts.