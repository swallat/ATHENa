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
# Support functions for API
#####################################################################


#####################################################################
# compare the current highest frequency and the one yet to be extracted
#####################################################################
sub compareFreq{
	my ($highest_freq, $dir, $vendor, $clknet) = @_;
	my @result = extract_perf_results($vendor, "", "", $dir, $clknet);
	my $achieved = $result[0];
	if($achieved > $highest_freq){ $highest_freq = $achieved; }
	return ( $achieved, $highest_freq );
}


1;