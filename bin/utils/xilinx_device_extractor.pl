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
# Last Updated   :  09/15/2010
# Purpose 	: Generate Xilinx device lib
# Usage : Simply run the script, a new xilinx_device.lib will be generated in the same folder
#####################################################################
use IPC::Open3;
use File::Path;
use File::Copy;
use Cwd;
$BIN_DIR_NAME = "bin"; $UTIL_DIR_NAME = "utils"; $CUR_DIR = cwd;
$ROOT_DIR = cwd; $ROOT_DIR =~ s/\/$BIN_DIR_NAME\/$UTIL_DIR_NAME//;
#$PARTGEN = "partgen";
$PARTGEN = "/nhome/common/installations/Xilinx142/14.2/ISE_DS/ISE/bin/lin64/partgen";

#####################################################################
# get copyright text
#####################################################################
sub get_copyright{	
	open(FILE, "$ROOT_DIR\/GPL.txt") || die ( " Could not find GPL.txt\n" );
	my @input = <FILE>;
	close(FILE);
	return join("",@input)."\n\n";
}

#####################################################################
# get family list
#####################################################################
sub get_family_list{	
	system("$PARTGEN > run.txt");
	open(FILE, "run.txt");
	my @INPUT = <FILE>;
	close(FILE);
	unlink("run.txt");

	my @families = ();
	my $i = 0;
	my $size = $#INPUT;
	for($i=0;$i<$size;$i++){
		chomp($INPUT[$i]);
		if($INPUT[$i] eq "PartGen: Valid architectures are:"){
			while($i<$size){
				$i++;
				$INPUT[$i] =~ s/\s//g;
				push(@families,$INPUT[$i]);				
			}
		}
	}	
	print "LIST OF FAMILIES:\n".join(", ",@families)."\n\n";
	return @families;
}

#####################################################################
# get device list to generate part data
#####################################################################
sub get_device_list {
	# get family
	my @families = @{shift()};
	my (%xilinx, $family_order); $family_order = 0;
	foreach my $family (@families){	
		# only extract spartan, virtex, artix, or kintex families		
		if ( $family !~ m/spartan|virtex|artix|kintex/i ) { next; }		
		#print "$family - $family_order\n";
		# insert order
		$xilinx{$family}{order} = $family_order; $family_order++;
		# select part for each available device of a family	
		@device_data = `$PARTGEN -arch $family`;
		my $state = "GET_DEVICE";
		my ($device_name, @packages, %biggest_package, $package_number, $order);
		$biggest_package{value} = 0;
		$package_number = 0;
		$order = 0;
		foreach $data ( @device_data ) {		
			CHECK_DEVICE:
			#print "$state :: $data";
			if ( $state eq "GET_DEVICE" ) {
				if ( $data =~ m/^([\w\d]+)\s*SPEEDS/i ) {	
					$device_name = $1;
					$state = "GET_PACKAGE";				
				}
			} elsif ($state eq "GET_PACKAGE" ) {			
				if ( $data =~ m/^[\t\s]+([\w\d]+)/i ) {
					push( @packages, $1 );				
					if ( ($packages[$package_number] =~ m/(\d+)/i ) ) {				
						if ( $1 > $biggest_package{value}) { 						
							$biggest_package{value} = $1; 
							$biggest_package{number} = $package_number;
						}
					}				
					$package_number++;
				} else {				
					$state = "GET_DEVICE";
					$xilinx{$family}{$device_name . $packages[$biggest_package{number}]}{order} = $order;
					$biggest_package{value} = 0;
					$biggest_package{number} = 0;
					$package_number = 0;
					@packages = ();
					$order++;
					goto CHECK_DEVICE;					
				}			
			}
		}
		$xilinx{$family}{$device_name . $packages[$biggest_package{number}]}{order} = $order;
	}
	print "\n\n";
	return \%xilinx;
}

#####################################################################
# generate xct files
#####################################################################
sub generate_xct_files {
	my %xilinx = %{shift()};
	
	# get previously created file
	opendir(DIR, $CUR_DIR) || die("Cannot open directory");
	my $files = join(" ", readdir(DIR));	# get all files in a folder
	$files = join(" ", ( $files =~ m/([\w\d]+.xct)/gi)); #keep only .xct files
	closedir(DIR);

	foreach $family ( keys %xilinx ) {
		print "Generating device data for $family ::\n";		
		foreach $device (keys %{$xilinx{$family}}) {	
			if ( $device =~ m/order/i) { next; }			
			# ignore previously created xct file
			if ( $files =~ $device ) { next; } 
			print "\t$device..";
			# generate xct file
			local (*WRT, *RDR, *ERR);
			my $pid = open3(*WRT, *RDR, *ERR, $PARTGEN.'-v '.$device.' -nopkgfile');
			waitpid( $pid, 0);
			my $new_filename = $device . ".xct";
			move("partlist.xct" , "$new_filename");
			print "[done]\n";
		}
		print "[done]\n\n";
	}
}

#####################################################################
# populate data from xct files
#####################################################################
sub populate_data_from_xct {		
	my %xilinx = %{shift()};
	foreach $family ( keys %xilinx ) {	
		foreach $device (keys %{$xilinx{$family}})  {		
			if ($device =~ m/order/i) { next; }
			my $device_file = $device . ".xct";
			open(FILE, "$device_file");
				my @device_data = <FILE>;
			close(FILE);
			$device_data = join("", @device_data );
					
			if($device_data =~ m/NUM_CLB=([\d]+)/i){
				$xilinx{$family}{$device}{num_clb} = $1;
			} else {
				delete $xilinx{$family}{$device};
				next;
			}

			if($device_data =~ m/SLICES_PER_CLB=([\d]+)/i){	
				$xilinx{$family}{$device}{slices_per_clb} = $1;		
			} else { 
				$xilinx{$family}{$device}{slices_per_clb} = 0; 
			}
			
			if($device_data =~ m/NUM_BLK_RAMS=([\d]+)/i){
				$xilinx{$family}{$device}{num_blk_rams} = $1;
			} else {
				$xilinx{$family}{$device}{num_blk_rams} = 0;
			}
			
			if($device_data =~ m/NUM_DSP=([\d]+)/i){
				$xilinx{$family}{$device}{num_dsp} = $1;
			} else {
				$xilinx{$family}{$device}{num_dsp} = 0;
			}
			
			if($device_data =~ m/NUM_MULT=([\d]+)/i){
				$xilinx{$family}{$device}{num_mult} = $1;
			} else {
				$xilinx{$family}{$device}{num_mult} = 0;
			}		
			
			if($device_data =~ m/NBIOBS=([\d]+)/i){
				$xilinx{$family}{$device}{nbiobs} = $1;
			} else {
				$xilinx{$family}{$device}{nbiobs} = 0;
			}

			if($device_data =~ m/SPEEDGRADE=(-[\d]+)\s*/i){
				$xilinx{$family}{$device}{speedgrade} = $1;
			} else {
				$xilinx{$family}{$device}{speedgrade} = 0;
			}
			
			$xilinx{$family}{$device}{slices} = $xilinx{$family}{$device}{num_clb} * $xilinx{$family}{$device}{slices_per_clb};				
		}
	}

	return \%xilinx;
}
###############################################################################################################################################################
#
# Execution starts here
#
###############################################################################################################################################################

# make sure there's no artifact from previous run
unlink("partlist.xct"); unlink("partlist.xml"); unlink("xilinx_device_lib.txt");

#get version 
$device_data = `$PARTGEN -i`;
$device_data =~ m/^Release\s*([\d.\w]+)/i;
$version = $1;

# get family list
my @families = &get_family_list();
print "Family List == @families\n";
# get device list
my %xilinx = %{&get_device_list(\@families)};


# generate xct files
&generate_xct_files(\%xilinx);

# populate data from xct files
%xilinx = %{&populate_data_from_xct(\%xilinx)};

@sorted_family = (sort{$xilinx{$a}{order} <=> $xilinx{$b}{order}} keys %xilinx);

# text generation for library
my $str; 
foreach $family (@sorted_family) {
	delete $xilinx{$family}{order};
	$str .= "FAMILY = $family\n";	
	my @sorted_device = (sort{$xilinx{$family}{$a}{order} <=> $xilinx{$family}{$b}{order}} keys %{$xilinx{$family}});
	
	foreach $device ( @sorted_device )  {
		if ( $device =~ /order/i ) { next; }
		$str .= "$device$xilinx{$family}{$device}{speedgrade}, $xilinx{$family}{$device}{slices}, $xilinx{$family}{$device}{num_blk_rams}, $xilinx{$family}{$device}{num_dsp}, $xilinx{$family}{$device}{num_mult}, $xilinx{$family}{$device}{nbiobs}\n";		
	}
	$str .= "END_FAMILY\n\n";
}
	
# Generating library file
open(OUTFILE, "> xilinx_device_lib.txt") || die ( " Could not write to output\n" );
print OUTFILE &get_copyright();
print OUTFILE "#####################################################################################\n";
print OUTFILE "# This file was generated using xilinx_device_extractor script located under\n";
print OUTFILE "# $root/bin/utils folder. The information contain in this library come from\n";
print OUTFILE "# Xilinx's partgen.exe tool.\n#\n";
print OUTFILE "# Supported families for this library file are :\n# ";
print "Family List == @families\n";
my $count = 0;
foreach $family (@families ) {
	if ( $selected_families !~ m/$family/i ) { next; }
	print "Family == $family \n";
	print OUTFILE "$family, ";
	$count++;
	if ( $count == 6 ) {
		$count = 0;
		print OUTFILE "\n#\n";
	}
}
print OUTFILE "#\n#\n# Xilinx ____ $version\n";
print OUTFILE "#####################################################################################\n\n";
print OUTFILE "VENDOR = Xilinx\n#Device, Total Slices, Block RAMs, DSP, Dedicated Multipliers, Maximum User I/O\n\n";
print OUTFILE "\nITEM_ORDER = SLICE, BRAM, DSP, MULT, IO\n\n";
print OUTFILE $str;
print OUTFILE "END_VENDOR";
close(OUTFILE);

# final clean up
map(unlink($_), grep(/\.pkg$|\.xct$|\.xml$/,<*>));





