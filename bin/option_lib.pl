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
# Option Library Script
#
# The library is loaded into a single HASH
# OPTION_LIBRARY(%) -> VENDORS(%) -> TOOLS(%) -> FAMILIES(%) -> OPTIONS(%) -> 
# OPTIONS{1} = readable option format
# OPTIONS{2} = readable flag format
# OPTIONS{3} = tool option format
# OPTIONS{4} = tool flag format
#####################################################################

my @XILINX_SYNTHESIS_TOOLS = qw(SYNPLIFY XST);
my @XILINX_IMPLEMENTATION_TOOLS = qw(NGDBUILD MAP PAR TRACE);

my @ALTERA_SYNTHESIS_TOOLS = qw(QUARTUS_MAP);
my @ALTERA_IMPLEMENTATION_TOOLS = qw(QUARTUS_FIT QUARTUS_ASM QUARTUS_TAN);

my @ACTEL_SYNTHESIS_TOOLS = qw();
my @ACTEL_IMPLEMENTATION_TOOLS = qw();

my (@SYNTHESIS_TOOLS, @IMPLEMENTATION_TOOLS, @ALLTOOLS);

#list of all families <== read from device_library
my (@FAMILIES);

#####################################################################
# Loads the device library
#####################################################################
sub loadOptLib{
	print "Loading option library...";
	
	replace_chars("$XILINX_OPTION_LIBRARY_FILE", "\t", "");
	replace_chars("$ALTERA_OPTION_LIBRARY_FILE", "\t", "");
	replace_chars("$ACTEL_OPTION_LIBRARY_FILE", "\t", "");
	
	loadOptions($XILINX_OPTION_LIBRARY_FILE);
	loadOptions($ALTERA_OPTION_LIBRARY_FILE);
	print "done\n";
}

#============================================================================= change device data to something else

#####################################################################
# Loads the devices from the file provided
#####################################################################
sub loadOptions{
	my $LIBRARY_FILE = $_[0];
	#print "FILE\t$LIBRARY_FILE\n";
	open(DEFOPTS, "$LIBRARY_FILE") || die("Could not acquire library file - $LIBRARY_FILE");
	my @DEVICE_DATA = <DEFOPTS>;
	close(DEFOPTS);
	my $size = @DEVICE_DATA;
	
	my $i = 0;
	for($i=0;$i<$size;$i++){

		#skip all the # signs in the options
		my $substring = substr $DEVICE_DATA[$i], 0, 1;
		next if($substring =~ /#/);
		
		my ($vendor_done, $tool_done);
		if($DEVICE_DATA[$i] =~ m/VENDOR=(\w+)/gi){
			my $VENDOR = $1;
			
			if(lc($VENDOR) eq "xilinx"){
				@SYNTHESIS_TOOLS = (@XILINX_SYNTHESIS_TOOLS);
				@IMPLEMENTATION_TOOLS = (@XILINX_IMPLEMENTATION_TOOLS);
			}
			elsif(lc($VENDOR) eq "altera"){
				@SYNTHESIS_TOOLS = (@ALTERA_SYNTHESIS_TOOLS);
				@IMPLEMENTATION_TOOLS = (@ALTERA_IMPLEMENTATION_TOOLS);
			}
			elsif(lc($VENDOR) eq "actel"){
				@SYNTHESIS_TOOLS = (@ACTEL_SYNTHESIS_TOOLS);
				@IMPLEMENTATION_TOOLS = (@ACTEL_IMPLEMENTATION_TOOLS);
			}
			@ALLTOOLS = (@SYNTHESIS_TOOLS, @IMPLEMENTATION_TOOLS);
			
			@FAMILIES = getFamilies(lc($VENDOR));
			
			#print "$VENDOR\n";
			$vendor_done = 0; #0 = false, 1=true
			while ($vendor_done == 0){
				$i++;
				my $substring = substr $DEVICE_DATA[$i], 0, 1;
				if($DEVICE_DATA[$i] =~ /END[\s^\w]*VENDOR/i){
					$vendor_done = 1;
				}
				elsif($substring =~ /[\s\\\\-_\/#]+/){}
				else{
					#================================================================================
					# READING TOOL OPTIONS
					#================================================================================
					foreach $TOOL (@ALLTOOLS){
						my $TOOL_STR = uc($VENDOR."_".$TOOL."_"."OPT");
						if($DEVICE_DATA[$i] =~ m/${TOOL_STR}=/gi){
							$tool_done = 0;
							while ($tool_done == 0){
								$i++;
								my $substring = substr $DEVICE_DATA[$i], 0, 1;
								if($DEVICE_DATA[$i] =~ /END[\s^\w]*OPT/i){
									$tool_done = 1;
								}
								elsif($substring =~ /[\s\\\\-_\/#]+/){}
								else{
									#================================================================================
									# READING FAMILY SPECIFIC OPTIONS
									#================================================================================
									my ($family_done);
									while($DEVICE_DATA[$i] =~ m/FAMILY=([\w\s,-_]+)/gi){
										my $FAMILY_STR = $1;
										#print "FAMILIES = $FAMILY_STR";
										# process the families
										# could be multiple families
										# check for strings like 'NOT' before family name
										# 3 types allowed - all, not family, explicit family names.
										# explicit families can be seperated by commas
										
										@FAMILY_SPLIT = split(/[\s,]+/, $FAMILY_STR);
										#print join("~", @FAMILY_SPLIT)."\n";
										if(lc($FAMILY_SPLIT[0]) eq "not"){
											#print "$#FAMILY_SPLIT \n";
											#ALL FAMILIES EXCEPT THESE
											@PROCESSED_FAMILIES = @FAMILIES;
											for $i (0..$#PROCESSED_FAMILIES){
												foreach $j (0..$#FAMILY_SPLIT){
													if(lc($PROCESSED_FAMILIES[$i]) eq lc($FAMILY_SPLIT[$j])){
														splice(@PROCESSED_FAMILIES, $i, 1);
														splice(@FAMILY_SPLIT, $j, 1);
													}
												}
											}
										}
										elsif(lc($FAMILY_SPLIT[0]) eq "all"){
											#ALL FAMILIES
											@PROCESSED_FAMILIES = @FAMILIES;
										}
										else{
											#EXPLICIT FAMILIES
											@PROCESSED_FAMILIES = @FAMILY_SPLIT;
										}
										
										#print join(",",@PROCESSED_FAMILIES)."\n";
										#print $#PROCESSED_FAMILIES."\n";
										
										my (@OPTS, @READABLE_SPLIT, @TOOL_SPLIT, @READABLE_FLAG_SPLIT, @TOOL_FLAG_SPLIT, $READABLE_OPT, $TOOL_OPT);
										$family_done = 0; #0 = false, 1=true
										while ($family_done == 0){
											$i++;
											my $substring = substr $DEVICE_DATA[$i], 0, 1;
											if($DEVICE_DATA[$i] =~ /END[\s^\w]*FAMILY/i){
												$family_done = 1;
											}
											elsif($substring =~ /[\s\\\\-_\/#]+/){}
											else{
												chomp($DEVICE_DATA[$i]);
												#OPTIMIZATION_EFFORT = SPEED, AREA | -opt_mode speed, area
												@OPTS = split(/\|\s/,$DEVICE_DATA[$i]);
												#if($#OPTS > 1 || $#OPTS < 1){ print "ERROR: error reading option library at line $i";}
												next if($#OPTS > 1 || $#OPTS < 1);
												@READABLE_SPLIT = split(/=\s/,$OPTS[0]);
												@TOOL_SPLIT = split(/=\s/,$OPTS[1]);
												@READABLE_FLAG_SPLIT = split(/,\s/,$READABLE_SPLIT[1]);
												@TOOL_FLAG_SPLIT = split(/,\s/,$TOOL_SPLIT[1]);
												
												$READABLE_OPT = $READABLE_SPLIT[0];
												$TOOL_OPT = $TOOL_SPLIT[0];
												
												#print "$READABLE_OPT = ".join(" ~ ",@READABLE_FLAG_SPLIT)."\n";
												#print "$TOOL_OPT = ".join(" ~ ",@TOOL_FLAG_SPLIT)."\n";
												
												# OPTION_LIBRARY(%) -> VENDORS(%) -> TOOLS(%) -> FAMILIES(%) -> OPTIONS(%) -> 
												
												foreach my $FAMILY (@PROCESSED_FAMILIES){
													$OPTION_LIBRARY{lc($VENDOR)}{lc($TOOL)}{lc($FAMILY)}{lc($READABLE_OPT)}{1} = $READABLE_OPT;
													$OPTION_LIBRARY{lc($VENDOR)}{lc($TOOL)}{lc($FAMILY)}{lc($READABLE_OPT)}{2} = \@READABLE_FLAG_SPLIT;
													$OPTION_LIBRARY{lc($VENDOR)}{lc($TOOL)}{lc($FAMILY)}{lc($READABLE_OPT)}{3} = $TOOL_OPT;
													$OPTION_LIBRARY{lc($VENDOR)}{lc($TOOL)}{lc($FAMILY)}{lc($READABLE_OPT)}{4} = \@TOOL_FLAG_SPLIT;
													
													#$OPTION_LIBRARY{$VENDOR}{$TOOL}{$FAMILY}{$READABLE_OPT}{1} = $READABLE_OPT;
													#$OPTION_LIBRARY{$VENDOR}{$TOOL}{$FAMILY}{$READABLE_OPT}{2} = \@READABLE_FLAG_SPLIT;
													#$OPTION_LIBRARY{$VENDOR}{$TOOL}{$FAMILY}{$READABLE_OPT}{3} = $TOOL_OPT;
													#$OPTION_LIBRARY{$VENDOR}{$TOOL}{$FAMILY}{$READABLE_OPT}{4} = \@TOOL_FLAG_SPLIT;
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}


#####################################################################
# Prints all the information from the library
#####################################################################
sub printOptLibrary{
	#use Storable;
	#store (\%OPTION_LIBRARY, 'file.txt');
	
	my @VENDORS = (keys %OPTION_LIBRARY);
	foreach  $VENDOR (@VENDORS){
		print "VENDOR: $VENDOR\n";
		my %TOOL_HASH = %{$OPTION_LIBRARY{$VENDOR}};
		my @TOOLS = (keys %TOOL_HASH);
		foreach $TOOL (@TOOLS){
			print "	TOOL: $TOOL\n";
			my %FAMILY_HASH = %{$TOOL_HASH{$TOOL}};
			my @FAMILIES = (keys %FAMILY_HASH);
			foreach $FAMILY (@FAMILIES){
				print "	FAMILY: $FAMILY\n";
				my %OPTION_HASH = %{$FAMILY_HASH{$FAMILY}};
				my @OPTIONS = (keys %OPTION_HASH);
				foreach $OPTION (@OPTIONS){
					print "\t\t\tOPTION: $OPTION\n";
					my %HASH = %{$OPTION_HASH{$OPTION}};
					my $READABLE_OPT = $HASH{1};
					my @READABLE_FLAGS = @{$HASH{2}};
					my $TOOL_OPT = $HASH{3};
					my @TOOL_FLAGS = @{$HASH{4}};
					
					print "\t\t\t\t$READABLE_OPT = ".join(" ~ ",@READABLE_FLAGS)."\t";
					print "$TOOL_OPT = ".join(" ~ ",@TOOL_FLAGS)."\n";
				}
			}
		}
		print "\n";
	}
}

#####################################################################
# Translates one option from Readable version to tool version
#####################################################################
sub translateOption{
	my ($VENDOR, $FAMILY, $TOOL, $OPT, $FLAG) = @_;	
	$VENDOR = lc($VENDOR);
	$FAMILY = lc($FAMILY);
	$TOOL = lc($TOOL);
	$OPT = lc($OPT);
	$FLAG = lc($FLAG);
	
	my %TOOL_HASH = %{$OPTION_LIBRARY{$VENDOR}};
	my %FAMILY_HASH = %{$TOOL_HASH{$TOOL}};
	my %OPTION_HASH = %{$FAMILY_HASH{$FAMILY}};	

	#The option doesnt seem to work... so trick around it
	my @OPTIONS = (keys %OPTION_HASH);
	foreach my $OPTION (@OPTIONS){ $OPT = $OPTION if($OPTION =~ m/$OPT/ig);}
	
	my %HASH = %{$OPTION_HASH{$OPT}};	
	my $READABLE_OPT = $HASH{1};
	my @READABLE_FLAGS = @{$HASH{2}};
	my $TOOL_OPT = $HASH{3};
	my @TOOL_FLAGS = @{$HASH{4}};
	
	my $ITEM_NO = $#READABLE_FLAGS+1; 
	for my $i (0..$#READABLE_FLAGS){
		#print "comparing $READABLE_FLAGS[$i] to $FLAG\n";
		if(lc($READABLE_FLAGS[$i]) eq lc($FLAG)){
			$ITEM_NO = $i;
			$FOUND = "yes";
			last;
		}
	}
	#print "\t\t\t\t$READABLE_OPT = ".join(" ~ ",@READABLE_FLAGS)."\t"."$TOOL_OPT = ".join(" ~ ",@TOOL_FLAGS)."\n";
	return $TOOL_OPT, $TOOL_FLAGS[$ITEM_NO];
}

#####################################################################
# Translates multiple options from Readable version to tool version
#####################################################################
sub translateOptions{
	my ($VENDOR, $FAMILY, $TOOL, $OPT, @FLAGS) = @_;
	my ($TOOL_OPT, @TOOL_FLAGS);
	foreach my $FLAG (@FLAGS){
		my ($OPT, $FLAG1) = translateOption($VENDOR, $FAMILY, $TOOL, $OPT, $FLAG);
		$TOOL_OPT = $OPT;
		push(@TOOL_FLAGS, $FLAG1);
	}
	return $TOOL_OPT, @TOOL_FLAGS;
}


#####################################################################
# Test function
#####################################################################
sub test{
	require "support.pl";
	require "structs.pl";
	require "device_lib.pl";
	$XILINX_DEVICE_LIBRARY_FILE = "../device_lib/xilinx_device.lib";
	$ALTERA_DEVICE_LIBRARY_FILE = "../device_lib/altera_device.lib";
	loadDevLib();
	#printLibrary();
	
	$XILINX_OPTION_LIBRARY_FILE = "../option_lib/xilinx_option_lib.txt";
	$ALTERA_OPTION_LIBRARY_FILE = "../option_lib/altera_option_lib.txt";
	copy($XILINX_OPTION_LIBRARY_FILE, "../option_lib/xilinx.txt");
	$XILINX_OPTION_LIBRARY_FILE = "../option_lib/xilinx.txt";
	replace_chars("$XILINX_OPTION_LIBRARY_FILE", "\t", "");
	
	loadOptLib();
	#printOptLibrary();
	
	my ($TOOL_OPT, $TOOL_FLAG) = translateOption("xilinx", "spartan3", "synplify", "OPTIMIZATION_EFFORT", "H");
	print "\nOPTIMIZATION_EFFORT - H  = $TOOL_OPT, $TOOL_FLAG\n\n";
	
	my @GUI_FLAGS = qw(A B C D);
	my ($TOOL_OPT, @TOOL_FLAGS) = translateOptions("xilinx", "virtex-4_sx", "synplify", "OPTIMIZATION_EFFORT", @GUI_FLAGS);
	print "\OPTIMIZATION_EFFORT - ". join("~",@GUI_FLAGS) . " = $TOOL_OPT, " . join("~",@TOOL_FLAGS) . "\n\n";
	

	unlink($XILINX_OPTION_LIBRARY_FILE);
}
#&test();








1; # need to end with a true value