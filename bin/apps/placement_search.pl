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
# APPLICATION: placement_search
# Version: 0.1
# 
# This app searches for the best result based on 100 costtable values
#####################################################################

#####################################################################
# Arguements
# PROVIDED: Vendor, Family, Device
#####################################################################
sub application{
	printOut("Running application : PLACEMENT SEARCH\n");
	printLocalProgress("Application : PLACEMENT SEARCH\n");
	
	my $option_file = "$CONFIG_DIR/placement_search.txt";
	&placement_search(1, $option_file); #starting at run number 1
}

1; #return 1 when including this file along with other scripts.