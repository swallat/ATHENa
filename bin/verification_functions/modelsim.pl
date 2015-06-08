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


sub modelsim {
	my $path = shift();
	my @files = @{shift()};
	
	# create stimulus.do file
		# create work library
		my $str = "vlib work;\n";
		
		# COMMANDS BEFORE loading design should be located here ::
		$str .= "# COMMANDS BEFORE loading design should be located here ::\n";		
		
		# create compile order
		foreach $file ( @files ) {
			#process special characters
			$file = &process_special_char($file);
			
			# check for type of file (VHDL or Verilog)
			if ( $file =~ m/.vhd/ ) {
				$str .= "vcom $file;\n";
			} elsif ( $file =~ m/.v/ ) {
				$str .= "vlog $file;\n";
			} elsif ( $file =~ m/.vhm/ ) {
				# do something here
			} elsif ( $file =~ m/.ncd/ ) {
				# do something here
			} else {
				# do something here
			}
		}

		# load design
		$str .= "vsim -c -quiet work.${TB_TOP_LEVEL_ENTITY} -wlf ${TB_TOP_LEVEL_ENTITY}.wlf;\n";
				
		# COMMANDS AFTER loading design should be located here ::
		$str .= "# COMMANDS AFTER loading design should be located here ::\n";

		$str .= "add wave *;\n";
		# run simulation
		$str .= "run $MAX_TIME_FUNCTIONAL_VERIFICATION;\n";
		# exit
		$str .= "exit;\n";
	
	# ==== write to file
	my $stimfile = "stimulus.do";
	open(STIM, ">$stimfile") || die("Could not create file!");
	print STIM "$str";
	close( STIM );
		
	#run the generated stimulus.do file	
	my $transcript = `$path -c -do "${stimfile}"`;
	#system( "$path -c -do $stimfile" );
	
	return 0;
}

# process special character for modelsim
sub process_special_char {
	my $file = shift();
	$file =~ s/\\/\//gi;	# convert '\' to '/'
	#$file =~ s/\//\\\//gi;	# append back slash with front slash (ie '/' to '\/')
	#$file =~ s/\(/\\\(/gi;  # convert '(' to '\('
	#$file =~ s/\)/\\\)/gi;	# convert ')' to '\)'
	#$file =~ s/ /\\ /gi;	# convert ' ' to '\ '
	return ( $file );
}

return 1;