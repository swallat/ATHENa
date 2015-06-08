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

# Device Library Script

#

# The library is loaded into a single HASH

# DEVICE_LIB(%) -> VENDORS(%) -> FAMILIES(%) -> DEVICES(@) -> DEVICE(STRUCT)

#####################################################################



#####################################################################

# Configure Library

# only the main function calls this

#####################################################################

sub ConfigureDevLib{

	my @VENDORS = @_;

	printOut("Copying device library...");

	

	#reassign device lib values as they were incorrect init in main

	$XILINX_DEVICE_LIBRARY_FILE = "$CONFIG_DIR/$XILINX_DEVICE_LIBRARY_FILE_NAME";

	$ALTERA_DEVICE_LIBRARY_FILE = "$CONFIG_DIR/$ALTERA_DEVICE_LIBRARY_FILE_NAME";

	$ACTEL_DEVICE_LIBRARY_FILE = "$CONFIG_DIR/$ACTEL_DEVICE_LIBRARY_FILE_NAME";

	

	foreach my $VENDOR (@VENDORS){

		#i can use a hash, but lazy programming

		copy($DEFAULT_XILINX_DEVICE_LIBRARY_FILE, $XILINX_DEVICE_LIBRARY_FILE) or printError("Library missing\n",0) if(lc($VENDOR) eq "xilinx");

		copy($DEFAULT_ALTERA_DEVICE_LIBRARY_FILE, $ALTERA_DEVICE_LIBRARY_FILE) or printError("Library missing\n",0) if(lc($VENDOR) eq "altera");

		copy($DEFAULT_ACTEL_DEVICE_LIBRARY_FILE, $ACTEL_DEVICE_LIBRARY_FILE) or printError("Library missing\n",0) if(lc($VENDOR) eq "actel");

	}

	printOut("done\n");

}



#####################################################################

# Loads the device library

#####################################################################

sub loadDevLib{

	my @VENDORS = @_;

	printOut("Loading device library...");

	

	foreach my $VENDOR (@VENDORS){

		#i can use a hash, but lazy programming

		loadDevices($XILINX_DEVICE_LIBRARY_FILE) if(lc($VENDOR) eq "xilinx");

		loadDevices($ALTERA_DEVICE_LIBRARY_FILE) if(lc($VENDOR) eq "altera");

		loadDevices($ACTEL_DEVICE_LIBRARY_FILE) if(lc($VENDOR) eq "actel");

		

	}

	printOut("done\n");

}



#####################################################################

# Loads the devices from the file provided

#####################################################################

sub loadDevices{

	my $LIBRARY_FILE = $_[0];

	open(DEFOPTS, "$LIBRARY_FILE") || printError("Could not acquire library - $LIBRARY_FILE\n", 0);

	my @DEVICE_DATA = <DEFOPTS>;

	close(DEFOPTS);

	@DEVICE_DATA = @{remove_comments(\@DEVICE_DATA)};

	

	#REMOVE COMMENTS

	for $i (0..$#DEVICE_DATA) {

		$DEVICE_DATA[$i] =~ s/#[\d\w\s\W]*//i;

	}



	for $i (0..$#DEVICE_DATA) {								

		my ($vendor_done, $family_done);

		

		while($DEVICE_DATA[$i] =~ m/VENDOR\s*=\s*(\w+)/gi){

			my $VENDOR = &trim_spaces($1);

			my %FAMILY_LIST = ();

			my @GLOBAL_ITEM_ORDER = ();

			$vendor_done = 0; #0 = false, 1=true

			while ($vendor_done == 0){

				$i++;

				my $substring = substr $DEVICE_DATA[$i], 0, 1;

				if(($DEVICE_DATA[$i] =~ /END[\s^\w]*VENDOR/i)){

					$vendor_done = 1;

				}

				elsif($substring =~ /[\s\\\\-_\/#]+/){}

				else{

					if($DEVICE_DATA[$i] =~ m/ITEM_ORDER\s*=\s*([\w, ]+)/gi){

						@GLOBAL_ITEM_ORDER = split(/[, ]+/,$1);

						#print "Item order \t $#ITEM_ORDER \t".join("-",@ITEM_ORDER)."\n";

					}

					

					#================================================================================

					# START READING FAMILY

					#================================================================================

					while($DEVICE_DATA[$i] =~ m/FAMILY\s*=\s*([\w_ -]+)/gi){

						my $FAMILY = &trim_spaces($1);

						my @DEVICE_LIST = ();

						my @ITEM_ORDER = @GLOBAL_ITEM_ORDER;

						$family_done = 0; #0 = false, 1=true						

						while ($family_done == 0){

							$i++;

							my $substring = substr $DEVICE_DATA[$i], 0, 1;

							if($DEVICE_DATA[$i] =~ m/ITEM_ORDER\s*=\s*([\w, ]+)/gi){

								@ITEM_ORDER = split(/[, ]+/,$1);

								#print "Item order \t $#ITEM_ORDER \t".join("-",@ITEM_ORDER)."\n";

							} elsif(($DEVICE_DATA[$i] =~ /END[\s^\w]*FAMILY/i)){

								$family_done = 1;

							}

							elsif($substring =~ /[\s\\\\-_\/#]+/){}

							else{

								#print "Item order \t $#ITEM_ORDER \t".join("-",@ITEM_ORDER)."\n";

								

								if($#ITEM_ORDER < 0){

									printOut("Device item order has not been specified. Corrupted library file.\n");

									last;

								}

								chomp($DEVICE_DATA[$i]);

								my @StringList = split('[,\s]+',$DEVICE_DATA[$i]);

								

								my $DEVICE = new Device();

								$DEVICE->setVendor(lc($VENDOR));

								$DEVICE->setFamily(lc($FAMILY));

								$DEVICE->setDevice(lc($StringList[0]));

								

								my %ITEMSIZE = ();

								

								foreach my $i (0..$#ITEM_ORDER){

									my $ITEM = $ITEM_ORDER[$i];

									$ITEMSIZE{$ITEM} = $StringList[$i+1];

								}

								$DEVICE->setDeviceSpecs(\%ITEMSIZE);

								

								push(@DEVICE_LIST, $DEVICE);

								undef $DEVICE;

							}

						}

						$FAMILY_LIST{lc($FAMILY)} = \@DEVICE_LIST;

					}

					#================================================================================

					# END READING FAMILY

					#================================================================================

				}

			}

			$DEVICE_LIBRARY{lc($VENDOR)} = \%FAMILY_LIST;

		}

	}

}



# #####################################################################

# # DEBUG

# #####################################################################

sub findDev{

	my ($CONTINUE, $VENDOR, $FAMILY, $UTIL_RESULTS_Ref, $UTIL_FACTORS_Ref) = @_;

	my %UTIL_FACTORS = %{$UTIL_FACTORS_Ref};

	my %UTIL_RESULTS = %{$UTIL_RESULTS_Ref};

	

	my %FAMILY_HASH = %{$DEVICE_LIBRARY{lc($VENDOR)}};

	my @DEVICES = @{$FAMILY_HASH{lc($FAMILY)}};

	

	#Result

	my @RETURN_ARRAY = ();

	my $RESULT = "";

	#printOut("===============================================================\n");

	

	foreach my $DEV (@DEVICES){		

		my %DEVICE_SPECS = %{$DEV->getDeviceSpecs()};

		my @UTIL_FACTORS_KEYS = keys %UTIL_FACTORS;

		#printOut("UTIL_FACTORS_KEYS\t".join(", ",@UTIL_FACTORS_KEYS)."\n");

		

		my @UTIL_RESULTS_KEYS = keys %UTIL_RESULTS;

		#printOut("UTIL_RESULTS_KEYS\t".join(", ",@UTIL_RESULTS_KEYS)."\n");

		

		my $PASS = 0;

		

		my $name = $DEV->getDevice();

		#print "\n\n$name check\n";

		foreach my $ITEM (keys %DEVICE_SPECS){

			$PASS = 0;

			

			#device specs * util factor > results

			if (( $ITEM =~ m/^le$/i ) and ( $UTIL_RESULTS{$ITEM} == 0 )) {

				$ITEM = "LOGIC";

			}

			my $devspec = $DEVICE_SPECS{$ITEM};

			my $utilfactor = $UTIL_FACTORS{$ITEM};

			my $result = $UTIL_RESULTS{$ITEM};

			

			

			

			$available = $devspec * $utilfactor;

			

			$PASS = 1 if($devspec * $utilfactor >= $result);			

			

			#print "$ITEM -> A : $available -- R: $result\n";

			#print "Doesn't pass $ITEM!!!\n" if($PASS != 1);

			last if($PASS != 1);

		}

		if($PASS == 1){

			if($CONTINUE eq "true"){

				push(@RETURN_ARRAY, $DEV);

			}

			else{

				$RESULT = $DEV;

				last;

			}

		}

	}

	if(($CONTINUE eq "true") and ($#RETURN_ARRAY >= 0)){

		return @RETURN_ARRAY;

	}

	else{

		return $RESULT unless ($RESULT eq "");

	}

	return "none";

}



#####################################################################

# Find device(s) based on parameters

#####################################################################

# sub findDev{

	# my ($CONTINUE, $VENDOR, $FAMILY, $UTIL_RESULTS_Ref, $UTIL_FACTORS_Ref) = @_;

	# my %UTIL_FACTORS = %{$UTIL_FACTORS_Ref};

	# my %UTIL_RESULTS = %{$UTIL_RESULTS_Ref};

	

	# my %FAMILY_HASH = %{$DEVICE_LIBRARY{lc($VENDOR)}};

	# my @DEVICES = @{$FAMILY_HASH{lc($FAMILY)}};

	

	# #Result

	# my @RETURN_ARRAY = ();

	# my $RESULT = "";

	# #printOut("===============================================================\n");

	

	

	# foreach my $DEV (@DEVICES){		

		# my %DEVICE_SPECS = %{$DEV->getDeviceSpecs()};

		# my @UTIL_FACTORS_KEYS = keys %UTIL_FACTORS;

		# my @UTIL_RESULTS_KEYS = keys %UTIL_RESULTS;

		# my $PASS = 0;

		# foreach my $ITEM (keys %DEVICE_SPECS){

			# $PASS = 0;			

			# #device specs * util factor > results

			# my $devspec = $DEVICE_SPECS{$ITEM};

			# my $utilfactor = $UTIL_FACTORS{$ITEM};

			# my $result = $UTIL_RESULTS{$ITEM};		

			# $PASS = 1 if($devspec * $utilfactor >= $result);			

			# last if($PASS != 1);

		# }

		# if($PASS == 1){

			# if($CONTINUE eq "true"){

				# push(@RETURN_ARRAY, $DEV);

			# }

			# else{

				# $RESULT = $DEV;

				# last;

			# }

		# }

	# }

	# if(($CONTINUE eq "true") and ($#RETURN_ARRAY >= 0)){

		# return @RETURN_ARRAY;

	# }

	# else{

		# return $RESULT unless ($RESULT eq "");

	# }

	# return "none";

# }



#####################################################################

# Find best device based on parameters

# usage: 

# $result = findBestDev("vendor", 1000, 15, 4, 500);

# if($d eq "none"){ print "No device has been found\n";}

# else {print $d->NAME, "\n";}

#####################################################################

sub findBestDev{

	return findDev("false", @_);

}



#####################################################################

# Returns all the devices in one family that match the specs provided

#####################################################################

sub findAllDev{

	return findDev("true", @_);

}



#####################################################################

# Returns the smallest device of a family

#####################################################################

sub getSmallestDev{

	my $result = findBestDev(@_, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1);

}



#####################################################################

# Returns the largest device of a family

#####################################################################

sub getLargestDev{

	my @DEVICES = findAllDev(@_, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1);

	return $DEVICES[$#DEVICES];

}



#####################################################################

# Prints all the devices from the library

#####################################################################

sub printDevLibrary{

	my $output = "";

	my @VENDORS = (keys %DEVICE_LIBRARY);

	foreach my $VENDOR (@VENDORS){

		$output .= "VENDOR: $VENDOR\n";

		my %FAMILY_HASH = %{$DEVICE_LIBRARY{$VENDOR}};

		my @FAMILIES = (keys %FAMILY_HASH);

		foreach my $FAMILY (@FAMILIES){

			$output .= "	FAMILY: $FAMILY\n";

			my @DEVICES = @{$FAMILY_HASH{$FAMILY}};

			foreach my $DEVSTRUCT (@DEVICES){

				$output .= "			";

				$output .= $DEVSTRUCT->getDevice();

				my %hash = %{$DEVSTRUCT->getDeviceSpecs()};

				my @keys = keys %hash;

				#$output .= "\t".join("-",@keys);

				foreach my $item (@keys){

					$output .= "\t[$item - $hash{$item}]";

				}

				$output .= "\n";

			}

		}

		$output .= "\n";

	}

	print "\n\n===LIBRARY===\n";

	print "$output\n";

	print "============\n";

	printOut($output);

}



#####################################################################

# Check devices

#####################################################################

sub checkLibDevice{

	my ($VENDOR, $FAMILY, $DEVICE) = @_;

	my %FAMILY_HASH = %{$DEVICE_LIBRARY{lc($VENDOR)}};

	my @FAMILIES = (keys %FAMILY_HASH);

	

	#check families

	my $fam_check = grep{lc($FAMILY) eq lc($_)} @FAMILIES;

	if($fam_check == 0){ return 0 };

	

	#check device

	my @DEVICES = @{$FAMILY_HASH{lc($FAMILY)}};

	#print "Devices ".join(" - ", @DEVICES)."\n";

	my $DEV_FOUND = 0;

	foreach my $DEVSTRUCT (@DEVICES){

		my $libDev = $DEVSTRUCT->getDevice();

		#EP3C10F256C6

		#xc4vlx15ff668-12

		my $partial = $libDev;

		if($libDev =~ m/([^\d]+)([\d]+)([^\d]+)([\d]+)/gi){

			$partial = $1.$2.$3.$4;

			#print "$partial\n";

		}

		

		$DEV_FOUND = 1 if($DEVICE =~ m/$partial/gi);

	}

	return 0 if ($DEV_FOUND == 0);

	

	return 1;

}



#####################################################################

# Returns the supported families for a specific vendor

#####################################################################

sub getFamilies{

	my ($VENDOR) = @_;

	my %FAMILY_HASH = %{$DEVICE_LIBRARY{lc($VENDOR)}};

	my @FAMILIES = (keys %FAMILY_HASH);

	return @FAMILIES;

}



#####################################################################

# Test function

#####################################################################

sub test{

	use Device;

	require "support.pl";

	$XILINX_DEVICE_LIBRARY_FILE = "../device_lib/xilinx_device_lib.txt";

	$ALTERA_DEVICE_LIBRARY_FILE = "../device_lib/altera_device_lib.txt";

	loadDevLib(qw(xilinx altera));

	#printDevLibrary();

	

	

	# print "\n\n\nXilinx TESTS\n\n";

	

	# my (%UTIL_RESULTS, %UTIL_FACTORS) = ();

	# my $VENDOR = "altera";

	# my $FAMILY = "cyclone III";

	

	# %UTIL_RESULTS = (SLICE => 768, BRAM => 0, DSP => 0, MULT => 0, IO => 22,);	

	# %UTIL_FACTORS = (SLICE => 0.8, BRAM => 1, DSP => 1, MULT => 1, IO => 0.9,);

	

	# my $BEST_DEV = findBestDev($VENDOR , $FAMILY, \%UTIL_RESULTS, \%UTIL_FACTORS);

	# if($BEST_DEV eq "none" || $BEST_DEV eq ""){ print "none\n\n\n 	";}

	# else{ print "Best dev :".$BEST_DEV->getDevice()."\n\n\n"; }

	

	# my $SMALLEST_DEV = getSmallestDev($VENDOR , $FAMILY);

	# if($SMALLEST_DEV eq "none" || $SMALLEST_DEV eq ""){ print "none\n\n\n 	";}

	# else{ print "Smallest dev :".$SMALLEST_DEV->getDevice()."\n\n\n"; }

	

	# my $LARGEST_DEV = getLargestDev($VENDOR , $FAMILY);

	# if($LARGEST_DEV eq "none" || $LARGEST_DEV eq ""){ print "none\n\n\n 	";}

	# else{ print "Largest dev :".$LARGEST_DEV->getDevice()."\n\n\n"; }

	

	

	# my @BEST_DEVICES = findAllDev($VENDOR , $FAMILY, \%UTIL_RESULTS, \%UTIL_FACTORS);

	# foreach my $device (@BEST_DEVICES){

		# if($device eq "none"){print "Cannot fit the curret architecture on $FAMILY Family\n";}

		# else{ print $device->getDevice()."\n";}

	# }

	

	$val = checkLibDevice("altera","cyclone III","EP3C40F780C6");

	print $val;

}

#&test();







1; # need to end with a true value