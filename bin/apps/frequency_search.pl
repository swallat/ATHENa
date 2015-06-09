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
# APPLICATION: frequency_search
# Version: 0.1
# - General Implementation under the assumption that the user has entered everything correctly.
# - No "idiot checks"
#
# 
# Frequency search - performs a basic run (with default or user specifed frequency), then we add our requests 
# The current version doesnot fully support multicore operation. 
# Currently this is only xilinx compatable.
#
# For more details about the algorithm please refer to the documentation
#####################################################################

#####################################################################
# application function
#####################################################################
sub application{
	printOut("\nRunning application : FREQUENCY SEARCH\n");
	printLocalProgress("Application : FREQUENCY SEARCH\n");
	
	my $OPTION_FILE = "$CONFIG_DIR/frequency_search.txt";
	&frequency_search(1, $OPTION_FILE); #starting at run number 1
}














1;