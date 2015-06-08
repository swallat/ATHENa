# =============================================
# ATHENA - Automated Tool for Hardware EvaluatioN.
# Copyright © 2009 CERG at George Mason University <cryptography.gmu.edu>.
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



# ================ FPGA VENDOR = Xilinx
# Xilinx
use IPC::Open3;
use Config;

sub add_ise {
	my %data = %{shift()};
	my $new_path = shift();	
	my $last_choice = ( scalar keys %{$data{xilinx}{imp}{choice_list}}  ) + 1;          
	#print " New path ==$new_path \n";	

















	# Locate the version no. by initiate the xst command to figure out the version number															
		#get message from calling xflow (Other programs might work but xflow doesn't require any input or produce any error messages)
		$new_path =~ s/\\/\//gi;#--mod by raj #print " New path ==$new_path \n";
		my $output = `${new_path}/xflow`;
		#set version name
		if ( $output =~ m/Release ([\d.]+) [-\s\w\d.]+\(([\w\d]+)/i ) {	
			$vername = $1;
			if ( $2 =~ /64/i ) { # check for 64 bits version
				$vname = $vername;
				$vername = "$vername 64-bit";
			}
		} else { $vername = "Unknown"; }

#check for existing path
		foreach $j ( keys %{$data{xilinx}{imp}{choice_list}} ) { 
			# for some reason, normal REGEX matching doesnt work :
				# Obsolete --> if ( $data{xilinx}{imp}{choice_list}{$j}{root_dir} =~ m/$new_path/i ) {			
			my $match = 1;
			my @s1 = split(/\/|\\/,$data{xilinx}{imp}{choice_list}{$j}{root_dir});			
			my @s2 = split(/\/|\\/,$new_path);
			foreach $cnt (0..$#s1) {
				# print "\t\t Comparing $s1[$cnt] && $s2[$cnt] ==> ";
				if ( $s1[$cnt] !~ m/$s2[$cnt]/i  ) {  $match = 0; }
			}
			if ( $match == 1 ) {
				print "Matched!!!\n";
				print "Path existed.\n";
				goto ADD_XILINX_RETURN;
			} else {
				print "Not matched!!\n";
			}
		}       

	# determine version_type
		# >>>>>>>>>>>>>>> OBSOLETE
		# $x_ds = "$ROOT_DIR\/$DEVICE_LIB_DIR\/_xilinx_${DEVICE_LIB_DIR}_designsuite\/xilinx_${DEVICE_LIB_DIR}_designsuite_$vername.txt";
		# $x_wp = "$ROOT_DIR\/$DEVICE_LIB_DIR\/_xilinx_${DEVICE_LIB_DIR}_webpack\/xilinx_${DEVICE_LIB_DIR}_webpack_$vername.txt";
		# if any of the library file for webpack or designsuite doesn't exist, force version type to be webpack to avoid problem
		# if (( not -e $x_ds ) or ( not -e $x_wp )) { 
		#	$vertype = "webpack";
		# } else {
			# use Device;
			


			# #get a device list for design suite
			# my @ds_devices;								
			# &loadDevices ( $x_ds );								
			# foreach my $f ( keys  %{$DEVICE_LIBRARY{xilinx}} ) {
				# foreach my $d ( @{$DEVICE_LIBRARY{xilinx}{$f}} ) {





					# push(@ds_devices, $d->getDevice());
				# }
			# }								
			# undef $DEVICE_LIBRARY;
			

			# #get a device list for webpack										
			# my @wp_devices;								
			# &loadDevices ( $x_wp );	
			# foreach my $f ( keys  %{$DEVICE_LIBRARY{xilinx}} ) {
				# foreach my $d ( @{$DEVICE_LIBRARY{xilinx}{$f}} ) {
					# push(@wp_devices, $d->getDevice());
				# }
			# }								
			
			# #find a device that isn't listed in webpack but existed in design suite								
			# my $designsuite_device;
			# foreach my $dsd ( @ds_devices ) {
				# foreach my $wpd ( @wp_devices ) {
					# if ($dsd =~ m/$wpd/i) { goto NEXTDEVICE; }
				# }											
				# $designsuite_device = $dsd; last;
				# NEXTDEVICE:
			# }							
		# local (*WRT, *RDR, *ERR);
		# my $pid = open3(*WRT, *RDR, *ERR, 'partgen', '-v '.$designsuite_device.' -nopkgfile');
		# waitpid( $pid, 0);
		# my $output = join("",<RDR>);


			
		# # delete temporary files
			# map(unlink($_), grep(/\.pkg$|partlist\.xct$|partlist\.xml$|run\.txt$/,<*>)); #delete temp files
		# # determine version type
			# if($output =~ m/Loading device/gi){
				# $vertype = "designsuite";
			# } else {
				# $vertype = "webpack";
			# }
		# }
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	
	# query user
	while ( 1 ) {
		print "What kind of license are you using for the version specified in the following Xilinx path?\n";
		print "PATH = $new_path\n";
		print "\t1) Webpack\n";
		print "\t2) Design Suite\n";
		my $result = <STDIN>; chop($result);
		if ( $result == 1 ) {
			$vertype = "webpack";
			last;
		} elsif ( $result == 2 ) {
			$vertype = "designsuite";
			last;
		} else {
			print "Invalid selection, please try again.\n";
		}		
	}		

	# Update list	
	%{$data{xilinx}{imp}{choice_list}{$last_choice}} = ( version_name => $vername, root_dir => $new_path, version_type => $vertype );
	ADD_XILINX_RETURN:
	return (\%data);
}



# ================ FPGA VENDOR = Altera
# Altera

sub add_quartus {
	my %data = %{shift()};
	my $new_path = shift();	
	my $last_choice = ( scalar keys %{$data{altera}{imp}{choice_list}}  ) + 1;
	print "Current choice ==> $last_choice\n";
			
	
	# >>>>>>>>>> OBSOLETE
	# Locate the version no.
		$new_path =~ s/\\/\//gi;
		my $output = `${new_path}/quartus_sh --version`;
		my $vername, $vertype;
		#set version name
		if ( $output =~ m/Version ([\d.]+)/i ) { $vername = $1;	} else { $vername = "Unknown"; }
		if ( $output =~ m/Quartus II 64-bit Shell/i ) { $vername = "$vername 64-bit"; }
		if ( $output =~ m/([a-zA-Z]+) Version/i ) { 
			$vertype = $1; 
			#make sure that the version name is correct
			if ($vertype =~ m/Full/i) {
				$vertype = "subscription_edition";
			} else {
				$vertype = "web_edition";
			}
		} else { $vertype = "web_edition"; }
		#print "$vername -- $vertype\n";
		

	# Update list
		# check for existing path
		foreach $j ( keys %{$data{altera}{imp}{choice_list}} ) { 
			if (  lc($data{altera}{imp}{choice_list}{$j}{root_dir}) eq  lc($new_path) ) {
				goto DONT_ADD_ALTERA_RETURN;	
			}
		}                               

















		%{$data{altera}{imp}{choice_list}{$last_choice}} = ( version_name => $vername, root_dir => $new_path, version_type => $vertype );
	DONT_ADD_ALTERA_RETURN:
	return (\%data);
}

# ================ Simulator tool detection
sub add_vsim {
	my %data = %{shift()};
	my $p = shift();				
	
	my $last_choice;
	
	# ignore duplicate entry
	foreach my $vendor (@VENDOR_LIST) {	
		if ( scalar keys %{$data{$vendor}{sim}} == 0 ) { next; }
		foreach my $no ( keys %{$data{$vendor}{sim}{choice_list}} ) {
			my $temp = $data{$vendor}{sim}{choice_list}{$no}{root_dir};
			if ( $p eq $temp ) {
				return( \%data );
			}
		}
	}
	
	print "\nDetecting vsim installation for $p\n";
	print "Please hold ...";
#	$p =~ s/\\/\//gi;

#	my $program = "${p}/vsim.exe -c help";	
#	local (*WRT, *RDR, *ERR);
#	my $pid = open3(*WRT, *RDR, *ERR, $program, );
#	waitpid( $pid, 0);
#	my $output = join("",<RDR>);
	my $output = `${p}/vsim -c help`;	
	#print "OUTPUT == $output\n";

	# Aldec detected 
	if ( $output =~ m/VSIMSA/i ) {
		# Aldec not supported
		next;
		if ( $output =~ m/build (\d.\d)+/i ) {		
			foreach my $vendor ( @VENDOR_LIST ) {
				$last_choice = ( scalar keys %{$data{$vendor}{sim}{choice_list}}  ) + 1;
				$data{$vendor}{sim}{choice_list}{$last_choice}{version_name} = "$STR_ALDEC";
				$data{$vendor}{sim}{choice_list}{$last_choice}{root_dir} = "$p";
				$data{$vendor}{sim}{choice_list}{$last_choice}{version_type} = "$1";
			}
		}		
	} else { # If not aldec, must be Modelsim
		if ( $output =~ m/# ([\d.\w]+)/i ) {				
			my $vno = $1;
			# detect whether it's ModelsSim for Altera or Xilinx
				if ( $p =~ m/altera/i ) {	# altera version
					$vendor = "altera";
				}  else {					# xilinx version				
					$vendor = "xilinx";
				}
			$last_choice = ( scalar keys %{$data{$vendor}{sim}{choice_list}}  ) + 1;
			$data{$vendor}{sim}{choice_list}{$last_choice}{version_name} = "$STR_MODELSIM";
			$data{$vendor}{sim}{choice_list}{$last_choice}{root_dir} = "$p";
			$data{$vendor}{sim}{choice_list}{$last_choice}{version_type} = "$vno";
		} 
	}	

	map(unlink($_), grep(/transcript$/,<*>)); #delete temp files
	print "[DONE]\n";
	return (\%data);
}


# ======== Determine whether the path should be added
# valid type = any, sim, syn, and imp
sub check_and_add_path() {
	my $type = shift();
	my $vendor = shift();
	my $path = shift();
	my %data = %{shift()};
		
	my $check_result = 1;
	
	# Looping through other possible paths 
	my @possible_paths = ("", "/lin", "/lin64", "/nt", "/nt64" );
	foreach $path_extension (@possible_paths) {
		
		my $p = "${path}${path_extension}"; 
		#print "--> \t$p\n";
		#print " $type\n";
		# synthesis and implementation
		if (( $type =~ m/imp/i ) or ($type =~ m/any/i)) {
			# xilinx
			#print "Entered if..\n";
			if (( $vendor =~ m/Xilinx/i ) or ( $vendor =~ m/any/i )) {
				#print "Entered Vendor if..\n $p/$STR_ISE_PROG_NAME \n";
				if ( -e $p."/".$STR_ISE_PROG_NAME ) { 
					print "\nDetecting Xilinx installation type for $p\nPlease hold ...";
					%data = %{&add_ise( \%data, $p )};					
					print "[DONE]\n";
					$check_result = 0; next;
				}
			}
			
			# altera		
			if (( $vendor =~ m/altera/i ) or ( $vendor =~ m/any/i )) {		
				if ( -e $p."/".$STR_QUARTUS_PROG_NAME ) {
					print "\nDetecting Altera installation type for $p\nPlease hold ...";
					%data = %{&add_quartus( \%data, $p )};
					print "[DONE]\n";
					$check_result = 0; next;
				}	
			}
		}

		# simulation 
		if (( $type =~ m/sim/i ) or ($type =~ m/any/i)) {
			if ( -e $p."/vsim" ) { 
				print "\t vsim found !! => $p\n";
				(%data) = %{&add_vsim( \%data, $p )};
				$check_result = 0; next;
			}	
		}
	}


	return( $check_result, \%data );	
}


return 1;