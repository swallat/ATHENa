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
# list all the directories in a folder
#####################################################################
sub getdirs{
  my $dir = shift;
  my $curdir = getcwd;
  $dir =~ s/\\/\//gi; #comment for windows

  opendir(DIR,$dir) or die "Can't open the current directory: $!\n";
  my @names = readdir(DIR);
  closedir(DIR);
  my @return = ();
  chdir($dir);
  foreach $name (@names) {
    next if (($name eq ".") or ($name eq ".."));
    if (-d $name){
      push(@return, $name);
    }
  }
  chdir($curdir);

  return @return;
}

#####################################################################
# get the twr file in current directory
#####################################################################
sub get_file_type{
  my $dir = shift; my $filetype = shift;
  opendir(DIR, $dir) || die("Cannot open directory -> $dir\n");
  my @files = readdir(DIR);
  closedir(DIR);
  my @file = grep(/\.$filetype$/,@files);
  return @file;
}

###############
# print array (debugging)
###############
sub parray {
	my @array = @{shift()};
	foreach $array (@array) {
		print "$array\n";
	}
}
######################################################################
# Device Sort
# Input =>    0  : vendor name
#        1  : a family hash of any vendor

# output =>    Sorted device list
######################################################################
sub sort_device {
	my $vendor = shift; my %hash = %{shift()};
	my $sortParam;
	if ( $vendor eq "xilinx" ) {
		$sortParam = "T_SLICE";
	} elsif ( $vendor eq "altera" ) {
		$sortParam = "T_LE";
	}

	
	# create a new hash table with only data specific to that device based on the randomly picked run
	my %h;
	foreach $device (keys %hash) {
		if ( $device =~ m/generic/i ) { next; }
		foreach $run ( keys %{$hash{$device}} ) {
			$h{$device}{value} = $hash{$device}{$run}{$sortParam};
			last;
		}
	}
	
	my @sorted_devices = sort{ $h{$a}{value} <=> $h{$b}{value} } ( keys %h );
	
	return @sorted_devices;
}

######################################################################
# Print a line consisting of dashes and plus like the marked lines in
# the following output:
# --> +-------------------+--------+--------+--------+
#     | Device            | Freq   | Slices | %      |
# --> +-------------------+--------+--------+--------+
######################################################################
sub print_dashes {
	my $output = "";
	foreach $insttype (@{shift()}) {
	$output .= "+" . "-" x ($insttype + 2);
	}
    $output .= "+\n";
	return $output;
}
######################################################################
# Extract tool info from data
# Input =>    0  : project hash data
# output =>    tool info in strings
######################################################################
sub toolInfoGen {
	my %proj = %{shift()};
	my $toolInfo = "::: Tools Info :::\n\n";
	
	$toolInfo .= "ATHENa Version :: ${ATHENA_VERSION}\n\n";
	
	my @data_name = ("Synthesis      ", "Implementation");	
	foreach $vendor ( keys %proj ) {
		#randomly pick family and device of a vendor, then choose the first run
		my ($device, $family, $random_run);
		foreach $fam ( keys %{$proj{$vendor}} ) {
			if ( $fam  !~ /generic|best_match/i ) {
				$family = $fam; last;
			}
		}
		
		#randomly pick a device of the first generic
		foreach $dev ( keys %{$proj{$vendor}{$family}{1}} ) {
			if ( $dev !~ /generic|best_match/i ) {
				$device = $dev; 
				last;
			}
		}		

		
		foreach $r ( keys %{$proj{$vendor}{$family}{1}{$device}} ) {
			$random_run = $r;
			last;
		}	
		
		$data[0] =   $proj{$vendor}{$family}{1}{$device}{$random_run}{SYN_TOOL};
		$data[1] =   $proj{$vendor}{$family}{1}{$device}{$random_run}{SYN_TOOL_VERSION};
		$data[2] =  $proj{$vendor}{$family}{1}{$device}{$random_run}{IMP_TOOL};
		$data[3] =   $proj{$vendor}{$family}{1}{$device}{$random_run}{IMP_TOOL_VERSION};
		$toolInfo .= "\t$vendor ::\n";
		for ( $i = 0; $i < 2; $i++ ) {
			$toolInfo .= "\t\t$data_name[$i]\t:\t$data[$i*2] - $data[$i*2+1]\n";
		}
		print "\n";
	}
	
	return $toolInfo;
}

######################################################################
# Report's Table Generation
# Input =>
#        0  : vendor name
#        1  : vendor hash data
#        2  : Column Order
# output =>    Generated Report Table
######################################################################
sub gen_report_table {
  my $vendor_name = shift;
  my %vendor = %{shift()};;
  @col_order = @{shift()};
  my $report = "";
  @unsorted_family = keys %vendor;
  @sorted_family = sort { lc($a) cmp lc($b) } @unsorted_family;  #sort family alphabetically

	foreach $family ( @sorted_family ) {
		my @gids = keys %{$vendor{$family}};
		#####################
		# get sorted gid
		#####################
		my @generic_names = ();
		my @sorted_gids = ();
		foreach $i (0..$#gids) {
			push(@generic_names , $vendor{$family}{$gids[$i]}{generic});
		}		
		foreach $name ( sort @generic_names ) {	
			foreach $i (0..$#gids) {
				if ( $vendor{$family}{$gids[$i]}{generic} =~ m/^$name$/i ) {
					push(@sorted_gids,$gids[$i]);
					last;
				}
			}
		}
		

		################################### 
		# finding appropriate table size
		###################################
		my %legendinfo;
		
		$legendinfo{generic}{len} = length("GENERIC");
		$legendinfo{generic}{order} = 0;
		$legendinfo{generic}{header_name} = "GENERIC";
		
		$legendinfo{device}{len} = length("DEVICE");
		$legendinfo{device}{order} = 1;
		$legendinfo{device}{header_name} = "DEVICE";
		
		
		my $track = 1;
		#looping through each generic id to find the biggest field
		foreach $gid ( @sorted_gids ) {
			# finding the biggest generic field
			if ( $legendinfo{generic}{len} < length($vendor{$family}{$gid}{generic}) ) { $legendinfo{generic}{len} = length($vendor{$family}{$gid}{generic}); }
			
			#Remove generic tag from the sorted list
			my @sorted_devices; my $i = 0;
			foreach $device (&sort_device( $vendor_name, \%{$vendor{$family}{$gid}})) { 
				if ( $device !~ /generic|best_match/i ) { $sorted_devices[$i] = $device; $i++;  }
			}
			
			foreach $device (@sorted_devices) {
				my $size = length($device);  
				if ( $vendor{$family}{$gid}{best_match} eq $device ) { $size++;}
				if($legendinfo{device}{len} < $size){ $legendinfo{device}{len} = $size; }

				# get first valid run
				my $valid_run;
				foreach $r (keys %{$vendor{$family}{$gid}{$device}} )  {
					$valid_run = $r;
					last;
				}
				
				foreach $legend (keys %{$vendor{$family}{$gid}{$device}{$valid_run}} ) {	#for each field							
					foreach my $col ( @col_order ) {	
						# ignore the legend that isn't listed in the sort field
						if (($legend =~ m/^$col$/i ) or (( $legend =~ m/$col/i ) and ($legend =~ m/IMP_FREQ|IMP_TCLK/i)))   {		
							$legendinfo{$legend}{header_name} = $REPORT_NAME_FORMAT{$vendor_name}{$col};							
							# for more than one clock, the header name must be different
							foreach $timing_key ( @{$CLK_KEY{$vendor_name}} ) { 
								if ( $legend =~ m/${timing_key}_(.*)/i ) {						
									$legendinfo{$legend}{header_name} = $legendinfo{$legend}{header_name}." '${1}'";
								}
							}
							
							if ( $legendinfo{$legend}{len} < length($legendinfo{$legend}{header_name})) {
								$legendinfo{$legend}{len} = length($legendinfo{$legend}{header_name});
							}
							
							# looping through the data to find the biggest run field
							foreach $run (keys %{$vendor{$family}{$gid}{$device}} ) {
								if( $legendinfo{$legend}{len} < length($vendor{$family}{$gid}{$device}{$run}{$legend} )) {
									$legendinfo{$legend}{len} = length($vendor{$family}{$gid}{$device}{$run}{$legend} );
								}
							}
							last;
						}
					}
				}
								
				$track++;
			}
		}

		# adding order to the rest of the legendinfo

		my @sorted_legend_len, @sorted_legend_name; my $i = 2;
		my @sorted_legend_order_id = ("generic", "device");
		$sorted_legend_len[0] = $legendinfo{generic}{len};	
		$sorted_legend_name[0] = $legendinfo{generic}{header_name};	
		$sorted_legend_len[1] = $legendinfo{device}{len};	
		$sorted_legend_name[1] = $legendinfo{device}{header_name};	
		my $i = 2; #starting at 2 since GENERIC and DEVICE are fix fields

		foreach $col (@col_order) {			
			foreach my $legend (keys %legendinfo ) {				

				if ($legend =~ m/^$col/i) {
					my $unique = 0;
					foreach $sorted_legend_id (@sorted_legend_order_id) {				
						if ( $sorted_legend_id =~ m/^$legend$/i ) { $unique = 1; last;	}				
					}
					if ( $unique == 0 ) {						
						#print "$col -> $legend -> order ($i)\n";
						$legendinfo{$legend}{order} = $i;
						$sorted_legend_len[$i] = $legendinfo{$legend}{len};
						$sorted_legend_name[$i] = $legendinfo{$legend}{header_name};	
						push(@sorted_legend_order_id, $legend);	




						$i++;
					}
				}


			}









		}		

		#################
		#printing header
		$report .= "\n$vendor : $family \n";
		$report .= &print_dashes(\@sorted_legend_len);
		$i = 0;
		foreach $header (@sorted_legend_order_id) {
			#print "$header\n";
			$report .= sprintf("| %-${sorted_legend_len[$i]}s ", $sorted_legend_name[$i]); $i++;
		}		
		$report .= sprintf("|\n");
		$report .= &print_dashes(\@sorted_legend_len);
		#print "========\n";
		#################
		# printing data #
		#################
		
		
		foreach $gid ( @sorted_gids ) {			
			#$report .= sprintf("| %- ${size}s%s ",$vendor{$family}{$gid}{generic});	
			foreach $device (&sort_device( $vendor_name, \%{$vendor{$family}{$gid}})) {
				
				if ( $device =~ /generic|best_match/i ) { next;  }
				# get field size for generic and device
				my $star = ""; 
				my $device_field_size = $legendinfo{device}{len};  if ( $vendor{$family}{$gid}{best_match} eq $device ) { $star = "*"; $device_field_size--; }
				my $generic_field_size = $legendinfo{generic}{len};
				
				# get run number in ascending order
				my @sorted_param;
				if ( $SORTSTYLE eq "ASCENDING" ) {
				  @sorted_param = sort{ $vendor{$family}{$gid}{$device}{$a}{$SORTCOLUMN} <=> $vendor{$family}{$gid}{$device}{$b}{$SORTCOLUMN} } keys %{$vendor{$family}{$gid}{$device}};
				} else {
				  @sorted_param = sort{ $vendor{$family}{$gid}{$device}{$b}{$SORTCOLUMN} <=> $vendor{$family}{$gid}{$device}{$a}{$SORTCOLUMN} } keys %{$vendor{$family}{$gid}{$device}};
				}

				foreach my $run (@sorted_param) {
					if ( $run eq "" ) { next; }
					$report .= sprintf("| %- ${generic_field_size}s ",$vendor{$family}{$gid}{generic});	
					$report .= sprintf("| %- ${device_field_size}s%s ",$device, $star);		           
					for ( my $i = 0; $i <= $#sorted_legend_order_id; $i++ ) {
						$legend = $sorted_legend_order_id[$i];
						next if ($legend =~ /^device|^generic/i);
						$len = $sorted_legend_len[$i];
						if ( exists $vendor{$family}{$gid}{$device}{$run}{$legend} ) {  #if no data availabe, print ==> N/A
							$report .= sprintf("| %- ${len}s ",$vendor{$family}{$gid}{$device}{$run}{$legend} );
						} else {
						$report .= sprintf("| %- ${len}s ", "N/A" );
						}
						if ( $i == $#sorted_legend_order_id ) { $report .= sprintf("|\n"); }          
					}
				}		
			}
		}

		$report .= &print_dashes(\@sorted_legend_len);
	}
	return $report;
}


######################################################################
# CSV file generation
# Input =>
#        0  : vendor name
#        1  : vendor hash data
# output =>    Generated CSV file for that vendor
######################################################################
sub gen_vendor_csv {
	# GET HEADER FOR CSV DATA	
	my $vendor = shift();
	my %project = %{shift()};
	
	my @list = "";
	my $vendor_header = "GENERIC,VENDOR,FAMILY,DEVICE,RUN_NO,";	
	foreach my $family (keys %{$project{$vendor}} ) {
		foreach my $gid (keys %{$project{$vendor}{$family}} ) {
			foreach my $device (keys %{$project{$vendor}{$family}{$gid}} ) {	
				next if ($device =~ m/generic|best_match/i);

				foreach my $run (keys %{$project{$vendor}{$family}{$gid}{$device}} ) {
					my $run_name = "run_${run}";
					@list = keys %{$project{$vendor}{$family}{$gid}{$device}{$run_name}};
					#remove RUN_NO from list				

					my $temp = join ( ',',@list) ;
					$temp =~ s/RUN_NO,//;
					$vendor_header .= $temp;
					last;
				}
				last;
			}
			last;
		}
	}
	
	# WRITING DATA
	my $str = "";
	$str .= "$vendor_header\n";
	foreach my $family (keys %{$project{$vendor}} ) {
		foreach my $gid (keys %{$project{$vendor}{$family}} ) {			
			my @sorted_devices = &sort_device( $vendor, \%{$project{$vendor}{$family}{$gid}});
			foreach my $device (@sorted_devices) {
				next if ($device =~ m/generic|best_match/i);
				foreach my $run (keys %{$project{$vendor}{$family}{$gid}{$device}} ) {
					$generic = $project{$vendor}{$family}{$gid}{generic};
					$str .= "$generic,$vendor,$family,$device,$project{$vendor}{$family}{$gid}{$device}{$run}{RUN_NO},";
					foreach my $field ( @list ) {
						if ( $field eq "RUN_NO" ) { next; }
						my $writeval = $project{$vendor}{$family}{$gid}{$device}{$run}{$field};
						if ($writeval =~ /default/i ) { $writeval = ""; }
						$writeval = &trim_spaces($writeval);
						$str .= "$writeval,";
					}
					$str .= "\n";
				}
			}
		}
	}
	return $str;
}

######################################################################
# Extract best result in term of AREA, TP, TP/AREA, Latency and Latency*Area
# Input =>
#        0  : a hash containing run data
# output =>  hash data containing best results
######################################################################

sub extract_best_result {
	my %project = %{shift()};
	my $mode = shift();
	my %best;
	
	my $inf = 9**9**9;
	foreach my $vendor (keys %project ) {  
		if ($mode =~ /db/i) {
			if ( $vendor =~ /disp/i) { next; } 
			if ( $project{$vendor}{disp} =~ /n/i ) { next; }			
		}	
		foreach my $family ( keys %{$project{$vendor}} ) {			
			if ($mode =~ /db/i) {
				if ($family =~ /disp/i) { next; } 
				if ( $project{$vendor}{$family}{disp} =~ /n/i ) { next; }			
			}	
			$best{AREA}{$vendor}{$family}{all}{value} = $inf;
			$best{AREA}{$vendor}{$family}{all}{device} = "N/A";
			$best{AREA}{$vendor}{$family}{all}{run} = "N/A";
			$best{AREA}{$vendor}{$family}{all}{unit} = "N/A";
			
			$best{THROUGHPUT}{$vendor}{$family}{all}{value} = -1;
			$best{THROUGHPUT}{$vendor}{$family}{all}{device} = "N/A";
			$best{THROUGHPUT}{$vendor}{$family}{all}{run} = "N/A";
			$best{THROUGHPUT}{$vendor}{$family}{all}{unit} = "Mbit/s";
			
			$best{THROUGHPUT_AREA}{$vendor}{$family}{all}{value} = -1;
			$best{THROUGHPUT_AREA}{$vendor}{$family}{all}{device} = "N/A";
			$best{THROUGHPUT_AREA}{$vendor}{$family}{all}{run} = "N/A";
			$best{THROUGHPUT_AREA}{$vendor}{$family}{all}{unit} = "";
			
			$best{LATENCY}{$vendor}{$family}{all}{value} = $inf;
			$best{LATENCY}{$vendor}{$family}{all}{device} = "N/A";
			$best{LATENCY}{$vendor}{$family}{all}{run} = "N/A";
			$best{LATENCY}{$vendor}{$family}{all}{unit} = "ns";
			
			$best{LATENCY_AREA}{$vendor}{$family}{all}{value} = $inf;
			$best{LATENCY_AREA}{$vendor}{$family}{all}{device} = "N/A";
			$best{LATENCY_AREA}{$vendor}{$family}{all}{run} = "N/A";
			$best{LATENCY_AREA}{$vendor}{$family}{all}{unit} = "";
			foreach my $gid ( keys %{$project{$vendor}{$family}} ) { 
				if ($mode =~ /db/i) {
					if ($gid =~ /disp/i) { next; } 
					if ( $project{$vendor}{$family}{$gid}{disp} =~ /n/i ) { next; }			
				}
				$best{AREA}{$vendor}{$family}{$gid}{all}{value} = $inf;
				$best{AREA}{$vendor}{$family}{$gid}{all}{device} = "N/A";
				$best{AREA}{$vendor}{$family}{$gid}{all}{run} = "N/A";
				$best{AREA}{$vendor}{$family}{$gid}{all}{unit} = "N/A";
				
				$best{THROUGHPUT}{$vendor}{$family}{$gid}{all}{value} = -1;
				$best{THROUGHPUT}{$vendor}{$family}{$gid}{all}{device} = "N/A";
				$best{THROUGHPUT}{$vendor}{$family}{$gid}{all}{run} = "N/A";
				$best{THROUGHPUT}{$vendor}{$family}{$gid}{all}{unit} = "Mbit/s";
				
				$best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{all}{value} = -1;
				$best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{all}{device} = "N/A";
				$best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{all}{run} = "N/A";
				$best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{all}{unit} = "";
				
				$best{LATENCY}{$vendor}{$family}{$gid}{all}{value} = $inf;
				$best{LATENCY}{$vendor}{$family}{$gid}{all}{device} = "N/A";
				$best{LATENCY}{$vendor}{$family}{$gid}{all}{run} = "N/A";
				$best{LATENCY}{$vendor}{$family}{$gid}{all}{unit} = "ns";
				
				$best{LATENCY_AREA}{$vendor}{$family}{$gid}{all}{value} = $inf;
				$best{LATENCY_AREA}{$vendor}{$family}{$gid}{all}{device} = "N/A";
				$best{LATENCY_AREA}{$vendor}{$family}{$gid}{all}{run} = "N/A";
				$best{LATENCY_AREA}{$vendor}{$family}{$gid}{all}{unit} = "";
			
				foreach my $device ( keys %{$project{$vendor}{$family}{$gid}} ) {
					if ($device =~ /generic|all/i ) { next; }
					if ($mode =~ /db/i) {
						if ( $device =~ /disp/i) { next; } 
						if ( $project{$vendor}{$family}{$gid}{$device}{disp} =~ /n/i ) { next; }			
					}					
					
					$best{AREA}{$vendor}{$family}{$gid}{$device}{value} = $inf;
					$best{AREA}{$vendor}{$family}{$gid}{$device}{run} = "N/A";
					$best{AREA}{$vendor}{$family}{$gid}{$device}{unit} = "N/A";
					
					$best{THROUGHPUT}{$vendor}{$family}{$gid}{$device}{value} = -1;
					$best{THROUGHPUT}{$vendor}{$family}{$gid}{$device}{run} = "N/A";
					$best{THROUGHPUT}{$vendor}{$family}{$gid}{$device}{unit} = "Mbit/s";
					
					$best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{$device}{value} = -1;
					$best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{$device}{run} = "N/A";
					$best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{$device}{unit} = "";
					
					$best{LATENCY}{$vendor}{$family}{$gid}{$device}{value} = $inf;
					$best{LATENCY}{$vendor}{$family}{$gid}{$device}{run} = "N/A";
					$best{LATENCY}{$vendor}{$family}{$gid}{$device}{unit} = "ns";
					
					$best{LATENCY_AREA}{$vendor}{$family}{$gid}{$device}{value} = $inf;
					$best{LATENCY_AREA}{$vendor}{$family}{$gid}{$device}{run} = "N/A";
					$best{LATENCY_AREA}{$vendor}{$family}{$gid}{$device}{unit} = "";
					
					
					foreach my $run ( keys %{$project{$vendor}{$family}{$gid}{$device}} ) {
						if ($mode =~ /db/i) {
							if ( $run =~ /disp/i) { next; } 
							if ( $project{$vendor}{$family}{$gid}{$device}{$run}{disp} =~ /n/i ) { next; }			
						}
						
						##### Best result within the same generic, family and device
						# Area (Lower is better)
						if ( $vendor =~ /xilinx/i ) {
                            my $type = "U_SLICE";
                            my $unit = "Slices";
                            
							if ( $project{$vendor}{$family}{$gid}{$device}{$run}{$type} < $best{AREA}{$vendor}{$family}{$gid}{$device}{value} ) {
								$best{AREA}{$vendor}{$family}{$gid}{$device}{value} = $project{$vendor}{$family}{$gid}{$device}{$run}{$type};
								$best{AREA}{$vendor}{$family}{$gid}{$device}{run} = $run;
								$best{AREA}{$vendor}{$family}{$gid}{$device}{unit} = $unit;
							}
							
						} elsif ( $vendor =~ /altera/i ) {
							my $area, $unit;
							if ( $project{$vendor}{$family}{$gid}{$device}{$run}{U_LE} > 0 ) {
								$area = $project{$vendor}{$family}{$gid}{$device}{$run}{U_LE};
								$unit = "LEs";
							} elsif ( $project{$vendor}{$family}{$gid}{$device}{$run}{U_ALUTS} > 0 ) {
								$area = $project{$vendor}{$family}{$gid}{$device}{$run}{U_ALUTS};
								$unit = "ALUTs";
							} else {
								$area = $project{$vendor}{$family}{$gid}{$device}{$run}{U_ALMS};
								$unit = "ALMs";
							}
							if ( $area < $best{AREA}{$vendor}{$family}{$gid}{$device}{value} ) {
								$best{AREA}{$vendor}{$family}{$gid}{$device}{value} = $area;
								$best{AREA}{$vendor}{$family}{$gid}{$device}{run} = $run;
								$best{AREA}{$vendor}{$family}{$gid}{$device}{unit} = $unit;
							}											
						}
						# Throughput	(Higher is better)						
						if ( $project{$vendor}{$family}{$gid}{$device}{$run}{THROUGHPUT} > $best{THROUGHPUT}{$vendor}{$family}{$gid}{$device}{value} ) {
							$best{THROUGHPUT}{$vendor}{$family}{$gid}{$device}{value} = $project{$vendor}{$family}{$gid}{$device}{$run}{THROUGHPUT};
							$best{THROUGHPUT}{$vendor}{$family}{$gid}{$device}{run} = $run;
						}						
						# TP/Area	(Higher is better)						
						if ( $project{$vendor}{$family}{$gid}{$device}{$run}{THROUGHPUT_AREA} > $best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{$device}{value} ) {
							$best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{$device}{value} = $project{$vendor}{$family}{$gid}{$device}{$run}{THROUGHPUT_AREA};
							$best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{$device}{run} = $run;
						}							
						# LATENCY	(Lower is better)						
						if ( $project{$vendor}{$family}{$gid}{$device}{$run}{LATENCY} < $best{LATENCY}{$vendor}{$family}{$gid}{$device}{value} ) {
							$best{LATENCY}{$vendor}{$family}{$gid}{$device}{value} = $project{$vendor}{$family}{$gid}{$device}{$run}{LATENCY};
							$best{LATENCY}{$vendor}{$family}{$gid}{$device}{run} = $run;
						}	
						# LATENCY * AREA	(Lower is better)						
						if ( $project{$vendor}{$family}{$gid}{$device}{$run}{LATENCY_AREA} < $best{LATENCY_AREA}{$vendor}{$family}{$gid}{$device}{value} ) {
							$best{LATENCY_AREA}{$vendor}{$family}{$gid}{$device}{value} = $project{$vendor}{$family}{$gid}{$device}{$run}{LATENCY_AREA};
							$best{LATENCY_AREA}{$vendor}{$family}{$gid}{$device}{run} = $run;
						}
					}
										
					##### Best result within the same
					# AREA 
					if ( $best{AREA}{$vendor}{$family}{$gid}{$device}{value} < $best{AREA}{$vendor}{$family}{$gid}{all}{value} ) {
						$best{AREA}{$vendor}{$family}{$gid}{all}{value} = $best{AREA}{$vendor}{$family}{$gid}{$device}{value};;
						$best{AREA}{$vendor}{$family}{$gid}{all}{device} = $device;
						$best{AREA}{$vendor}{$family}{$gid}{all}{run} = $best{AREA}{$vendor}{$family}{$gid}{$device}{run};
						$best{AREA}{$vendor}{$family}{$gid}{all}{unit} = $best{AREA}{$vendor}{$family}{$gid}{$device}{unit};
					}
					# Throughput
					if ( $best{THROUGHPUT}{$vendor}{$family}{$gid}{$device}{value} > $best{THROUGHPUT}{$vendor}{$family}{$gid}{all}{value} ) {
						$best{THROUGHPUT}{$vendor}{$family}{$gid}{all}{value} = $best{THROUGHPUT}{$vendor}{$family}{$gid}{$device}{value};
						$best{THROUGHPUT}{$vendor}{$family}{$gid}{all}{device} = $device;
						$best{THROUGHPUT}{$vendor}{$family}{$gid}{all}{run} = $best{THROUGHPUT}{$vendor}{$family}{$gid}{$device}{run};
					}
					# TP/AREA
					if ( $best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{$device}{value} > $best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{all}{value} ) {
						$best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{all}{value} = $best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{$device}{value};;
						$best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{all}{device} = $device;
						$best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{all}{run} = $best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{$device}{run};
					}	
					# LATENCY
					if ( $best{LATENCY}{$vendor}{$family}{$gid}{$device}{value} < $best{LATENCY}{$vendor}{$family}{$gid}{all}{value} ) {
						$best{LATENCY}{$vendor}{$family}{$gid}{all}{value} = $best{LATENCY}{$vendor}{$family}{$gid}{$device}{value};;
						$best{LATENCY}{$vendor}{$family}{$gid}{all}{device} = $device;
						$best{LATENCY}{$vendor}{$family}{$gid}{all}{run} = $best{LATENCY}{$vendor}{$family}{$gid}{$device}{run};
					}	
					# LATENCY * AREA
					if ( $best{LATENCY_AREA}{$vendor}{$family}{$gid}{$device}{value} < $best{LATENCY_AREA}{$vendor}{$family}{$gid}{all}{value} ) {
						$best{LATENCY_AREA}{$vendor}{$family}{$gid}{all}{value} = $best{LATENCY_AREA}{$vendor}{$family}{$gid}{$device}{value};;
						$best{LATENCY_AREA}{$vendor}{$family}{$gid}{all}{device} = $device;
						$best{LATENCY_AREA}{$vendor}{$family}{$gid}{all}{run} = $best{LATENCY_AREA}{$vendor}{$family}{$gid}{$device}{run};
					}	
				}
				##### Best result within the same generic 
				# AREA 
				if ( $best{AREA}{$vendor}{$family}{$gid}{all}{value} < $best{AREA}{$vendor}{$family}{all}{value} ) {
					$best{AREA}{$vendor}{$family}{all}{value} = $best{AREA}{$vendor}{$family}{$gid}{all}{value};
					$best{AREA}{$vendor}{$family}{all}{device} = $best{AREA}{$vendor}{$family}{$gid}{all}{device};
					$best{AREA}{$vendor}{$family}{all}{run} = $best{AREA}{$vendor}{$family}{$gid}{all}{run};
					$best{AREA}{$vendor}{$family}{all}{gid} = $gid;
					$best{AREA}{$vendor}{$family}{all}{unit} = $best{AREA}{$vendor}{$family}{$gid}{all}{unit};
				}
				# Throughput
				if ( $best{THROUGHPUT}{$vendor}{$family}{$gid}{all}{value} > $best{THROUGHPUT}{$vendor}{$family}{all}{value} ) {
					$best{THROUGHPUT}{$vendor}{$family}{all}{value} = $best{THROUGHPUT}{$vendor}{$family}{$gid}{all}{value};
					$best{THROUGHPUT}{$vendor}{$family}{all}{device} = $best{THROUGHPUT}{$vendor}{$family}{$gid}{all}{device};
					$best{THROUGHPUT}{$vendor}{$family}{all}{run} = $best{THROUGHPUT}{$vendor}{$family}{$gid}{all}{run};
					$best{THROUGHPUT}{$vendor}{$family}{all}{gid} = $gid;
					$best{THROUGHPUT}{$vendor}{$family}{all}{unit} = $best{THROUGHPUT}{$vendor}{$family}{$gid}{all}{unit};
				}
				# TP/AREA
				if ( $best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{all}{value} > $best{THROUGHPUT_AREA}{$vendor}{$family}{all}{value} ) {
					$best{THROUGHPUT_AREA}{$vendor}{$family}{all}{value} = $best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{all}{value};
					$best{THROUGHPUT_AREA}{$vendor}{$family}{all}{device} = $best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{all}{device};
					$best{THROUGHPUT_AREA}{$vendor}{$family}{all}{run} = $best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{all}{run};
					$best{THROUGHPUT_AREA}{$vendor}{$family}{all}{gid} = $gid;
					$best{THROUGHPUT_AREA}{$vendor}{$family}{all}{unit} = $best{THROUGHPUT_AREA}{$vendor}{$family}{$gid}{all}{unit};
				}
				# LATENCY
				if ( $best{LATENCY}{$vendor}{$family}{$gid}{all}{value} < $best{LATENCY}{$vendor}{$family}{all}{value} ) {
					$best{LATENCY}{$vendor}{$family}{all}{value} = $best{LATENCY}{$vendor}{$family}{$gid}{all}{value};
					$best{LATENCY}{$vendor}{$family}{all}{device} = $best{LATENCY}{$vendor}{$family}{$gid}{all}{device};
					$best{LATENCY}{$vendor}{$family}{all}{run} = $best{LATENCY}{$vendor}{$family}{$gid}{all}{run};
					$best{LATENCY}{$vendor}{$family}{all}{gid} = $gid;
					$best{LATENCY}{$vendor}{$family}{all}{unit} = $best{LATENCY}{$vendor}{$family}{$gid}{all}{unit};
				}	
				# LATENCY * AREA
				if ( $best{LATENCY_AREA}{$vendor}{$family}{$gid}{all}{value} < $best{LATENCY_AREA}{$vendor}{$family}{all}{value} ) {
					$best{LATENCY_AREA}{$vendor}{$family}{all}{value} = $best{LATENCY_AREA}{$vendor}{$family}{$gid}{all}{value};
					$best{LATENCY_AREA}{$vendor}{$family}{all}{device} = $best{LATENCY_AREA}{$vendor}{$family}{$gid}{all}{device};
					$best{LATENCY_AREA}{$vendor}{$family}{all}{run} = $best{LATENCY_AREA}{$vendor}{$family}{$gid}{all}{run};
					$best{LATENCY_AREA}{$vendor}{$family}{all}{gid} = $gid;
					$best{LATENCY_AREA}{$vendor}{$family}{all}{unit} = $best{LATENCY_AREA}{$vendor}{$family}{$gid}{all}{unit};
				}	
			}
		}
	}
	return \%best;
}


######################################################################
# Printing project data
######################################################################
sub printProject {
	my %project = %{shift()};
	foreach $vendor ( keys %project ) {
		print "$vendor\n";
		foreach $family ( keys %{$project{$vendor}} ) {			
			foreach $gid ( keys %{$project{$vendor}{$family}} ) {
				print "-> $family - $project{$vendor}{$family}{$gid}{generic}\n";
				foreach $device ( keys %{$project{$vendor}{$family}{$gid}} ) {
					print "\t$device\n";
				}
			}
		}
	}
	system ( pause );	
}

######################################################################
# Extract best result in term of AREA, TP, TP/AREA, Latency and Latency*Area
# Input =>
#        0  : a hash containing run data
#		 1  : a hash containing best result from extract_best_result function
# output =>  a hash of strings
######################################################################
sub print_best_result {
	my %project = %{shift()};
	my %best = %{shift()};
	my @criterian = @{shift()};
	my $query_mode = shift(); #best_overall, best_per_device, best_per_generic
	my $mode = shift();
	
	my %best_result;
	my $MAXLEN_VENDOR = 6;
	my $MAXLEN_FAMILY = 15;
	my $MAXLEN_GENERIC = 25;
	my $MAXLEN_DEVICE = 25;
	my $MAXLEN_RUN = 7;
	
	if ( $query_mode !~ /best_overall|best_per_device|best_per_generic/i ) {
		print "Invalid query_mode for print_best_result().\n";
		system( pause );
		return;
	}
	if ( scalar@criterian == 0 ) { print "Warning - No criterian selected!\n"; }
	foreach $crit ( @criterian ) {
		if ( $crit =~ /^AREA$/i ) 			{ $best_result{AREA} = "Best area::\n"; }
		if ( $crit =~ /^THROUGHPUT$/i ) 		{ $best_result{THROUGHPUT} = "Best throughput::\n"; }
		if ( $crit =~ /^THROUGHPUT_AREA$/i ) 	{ $best_result{THROUGHPUT_AREA} = "Best throughput to area ratio::\n"; }
		if ( $crit =~ /^LATENCY$/i ) 			{ $best_result{LATENCY} = "Best latency::\n"; }
		if ( $crit =~ /^LATENCY_AREA$/i ) 	{ $best_result{LATENCY_AREA} = "Best latency*area::\n"; }
	}
	foreach $crit ( @criterian ) {
		foreach $vendor ( keys %{$best{$crit}} ) {
			foreach  $family ( keys %{$best{$crit}{$vendor}} ) {
				#print "$crit -> $vendor -> $family\n";
				if ( $query_mode =~ /best_overall/i ) {
					my $device_name = $best{$crit}{$vendor}{$family}{all}{device};
					my $run_name =  $best{$crit}{$vendor}{$family}{all}{run};
					my $gid_id =  $best{$crit}{$vendor}{$family}{all}{gid};
					my $gid_value = "best ($project{$vendor}{$family}{$gid_id}{generic})";
					$best_result{$crit}  .= sprintf("\t%+${MAXLEN_VENDOR}s/%+${MAXLEN_FAMILY}s/%+${MAXLEN_GENERIC}s/%+${MAXLEN_DEVICE}s\t=>\t%-${MAXLEN_RUN}s :    %s %s\n", $vendor, $family,  $gid_value, $device_name, $run_name, $best{$crit}{$vendor}{$family}{all}{value}, $best{$crit}{$vendor}{$family}{all}{unit});
                    if ( $vendor =~ m/xilinx/i ) {
                        $best_result{$crit}  .= sprintf("\t\tSlice=%s LUTs=%s FFs=%s BRAMs=%s",
                                                    $project{$vendor}{$family}{$gid_id}{$device_name}{$run_name}{U_SLICE},
                                                    $project{$vendor}{$family}{$gid_id}{$device_name}{$run_name}{U_LUT},
                                                    $project{$vendor}{$family}{$gid_id}{$device_name}{$run_name}{U_FF},
                                                    $project{$vendor}{$family}{$gid_id}{$device_name}{$run_name}{U_BRAM} );
                    } elsif ( $vendor =~ m/altera/i ) {
                        $best_result{$crit}  .= sprintf("\t\tLEs=%s ALUTs=%s ALMs=%s FFs=%s MemBits=%s",
                                                    $project{$vendor}{$family}{$gid_id}{$device_name}{$run_name}{U_LE},
                                                    $project{$vendor}{$family}{$gid_id}{$device_name}{$run_name}{U_ALUTS},
                                                    $project{$vendor}{$family}{$gid_id}{$device_name}{$run_name}{U_ALMS},
                                                    $project{$vendor}{$family}{$gid_id}{$device_name}{$run_name}{U_FF},
                                                    $project{$vendor}{$family}{$gid_id}{$device_name}{$run_name}{U_MEM} );

                    }
                    $best_result{$crit}  .= sprintf(" DSP=%s ImpFreq=%s Ratio=%s\n",
                                                        $project{$vendor}{$family}{$gid_id}{$device_name}{$run_name}{U_DSP},
                                                        $project{$vendor}{$family}{$gid_id}{$device_name}{$run_name}{IMP_FREQ},
                                                        $project{$vendor}{$family}{$gid_id}{$device_name}{$run_name}{THROUGHPUT_AREA} );
					next;
				}
                # Sort gid ID based on its generic
                @gid_sorted = keys %{$best{$crit}{$vendor}{$family}};
                #   Construct a hash    
                foreach $id (@gid_sorted) {
                    @generic_combo = split(' ',$project{$vendor}{$family}{$id}{generic});                
                    foreach $combo (@generic_combo) { 
                        ($generic, $value) = split('=',$combo);
                        $tmpgid{$id}{$generic} = $value;
                    }
                }
                #   Recursive sort
                @generics = sort {$b cmp $a} keys %{$tmpgid{$gid_sorted[0]}};                
                foreach $generic (@generics) {                    
                    @gid_sorted = sort {$tmpgid{$a}{$generic} <=> $tmpgid{$b}{$generic}}  (@gid_sorted);                                        
                }
				foreach $gid ( @gid_sorted ) {
					if ( $gid =~ /^all$/i ) { next; }
					my $gid_value = $project{$vendor}{$family}{$gid}{generic};
					if ( $query_mode =~ /^best_per_generic$/i ) {
						my $dev = $best{$crit}{$vendor}{$family}{$gid}{all}{device};
						my $device_name = "best ($best{$crit}{$vendor}{$family}{$gid}{all}{device})";
						my $run_name =  $best{$crit}{$vendor}{$family}{$gid}{all}{run};
						$best_result{$crit}  .= sprintf("\t%+${MAXLEN_VENDOR}s/%+${MAXLEN_FAMILY}s/%+${MAXLEN_GENERIC}s/%+${MAXLEN_DEVICE}s\t=>\t%-${MAXLEN_RUN}s :    %s %s\n", $vendor, $family,  $gid_value, $device_name, $run_name, $best{$crit}{$vendor}{$family}{$gid}{all}{value}, $best{$crit}{$vendor}{$family}{$gid}{all}{unit});
                        $best_result{$crit}  .= sprintf("\t\tImpFreq=%s MHz Latency=%s ns", $project{$vendor}{$family}{$gid}{$dev}{$run_name}{IMP_FREQ},$project{$vendor}{$family}{$gid}{$dev}{$run_name}{LATENCY});
						if ( $vendor =~ m/xilinx/i ) {
                            $best_result{$crit}  .= sprintf(", Logic Delay=%s ns, Routing Delay = %s ns\n\t\tSlice=%s LUTs=%s FFs=%s BRAMs=%s",
                                                        $project{$vendor}{$family}{$gid}{$dev}{$run_name}{DELAY_LOGIC},
                                                        $project{$vendor}{$family}{$gid}{$dev}{$run_name}{DELAY_ROUTE},
														$project{$vendor}{$family}{$gid}{$dev}{$run_name}{U_SLICE},
                                                        $project{$vendor}{$family}{$gid}{$dev}{$run_name}{U_LUT},
                                                        $project{$vendor}{$family}{$gid}{$dev}{$run_name}{U_FF},
														$project{$vendor}{$family}{$gid}{$dev}{$run_name}{U_BRAM} );
						} elsif ( $vendor =~ m/altera/i ) {
							$best_result{$crit}  .= sprintf("\n\t\tLEs=%s ALUTs=%s ALMs=%s FFs=%s MemBits=%s",
																$project{$vendor}{$family}{$gid}{$dev}{$run_name}{U_LE},
                                                                $project{$vendor}{$family}{$gid}{$dev}{$run_name}{U_ALUTS},
                                                                $project{$vendor}{$family}{$gid}{$dev}{$run_name}{U_ALMS},                                                                
                                                                $project{$vendor}{$family}{$gid}{$dev}{$run_name}{U_FF},
																$project{$vendor}{$family}{$gid}{$dev}{$run_name}{U_MEM} );

							}
						$best_result{$crit}  .= sprintf(" DSP=%s Ratio=%s\n",
															$project{$vendor}{$family}{$gid}{$dev}{$run_name}{U_DSP},															
															$project{$vendor}{$family}{$gid}{$dev}{$run_name}{THROUGHPUT_AREA} );
						next;
					}						
					my @devices = sort {$a cmp $b}   keys %{$best{$crit}{$vendor}{$family}{$gid}};
					foreach $device ( @devices ) {
						if ( $device =~ /^disp$|^generic$|^best_match$|^all$/i ){ next; }
						my $run_name =  "best ($best{$crit}{$vendor}{$family}{$gid}{$device}{run})";						
						my $run_no = $best{$crit}{$vendor}{$family}{$gid}{$device}{run};
						$best_result{$crit}  .= sprintf("\t%+${MAXLEN_VENDOR}s/%+${MAXLEN_FAMILY}s/%+${MAXLEN_GENERIC}s/%+${MAXLEN_DEVICE}s\t=>\t%-${MAXLEN_RUN}s :    %s %s\n", $vendor, $family,  $gid_value, $device, $run_name, $best{$crit}{$vendor}{$family}{$gid}{$device}{value}, $best{$crit}{$vendor}{$family}{$gid}{$device}{unit});
                        $best_result{$crit}  .= sprintf("\t\tImpFreq=%s MHz Latency=%s ns", $project{$vendor}{$family}{$gid}{$dev}{$run_name}{IMP_FREQ},$project{$vendor}{$family}{$gid}{$dev}{$run_name}{LATENCY});
						if ( $vendor =~ m/xilinx/i ) {
							$best_result{$crit}  .= sprintf(", Logic Delay=%s ns, Routing Delay = %s ns\n\t\tSlice=%s LUTs=%s FFs=%s BRAMs=%s",
                                                        $project{$vendor}{$family}{$gid}{$device}{$run_no}{DELAY_LOGIC},
                                                        $project{$vendor}{$family}{$gid}{$device}{$run_no}{DELAY_ROUTE},
														$project{$vendor}{$family}{$gid}{$device}{$run_no}{U_SLICE},
                                                        $project{$vendor}{$family}{$gid}{$device}{$run_no}{U_LUT},
                                                        $project{$vendor}{$family}{$gid}{$device}{$run_no}{U_FF},
														$project{$vendor}{$family}{$gid}{$device}{$run_no}{U_BRAM} );
						} elsif ( $vendor =~ m/altera/i ) {
							$best_result{$crit}  .= sprintf("\n\t\tLEs=%s ALUTs=%s ALMs=%s FFs=%s MemBits=%s",
                                                                $project{$vendor}{$family}{$gid}{$device}{$run_no}{U_LE},
																$project{$vendor}{$family}{$gid}{$device}{$run_no}{U_ALUTS},
                                                                $project{$vendor}{$family}{$gid}{$device}{$run_no}{U_ALMS},
                                                                $project{$vendor}{$family}{$gid}{$device}{$run_no}{U_FF},
																$project{$vendor}{$family}{$gid}{$device}{$run_no}{U_MEM} );

             						}
						$best_result{$crit}  .= sprintf(" DSP=%s Ratio=%s\n",
															$project{$vendor}{$family}{$gid}{$device}{$run_no}{U_DSP},
															$project{$vendor}{$family}{$gid}{$device}{$run_no}{THROUGHPUT_AREA} );
						next;
					}
				}
			}
		}
	}
	return \%best_result;
}

######################################################################
# Extract project data
# Input =>
#        0  : project path 
# output =>  hash data containing project results
#
# Note :::
# 	This function is the core of report!!!
######################################################################
sub extract_project_data {

	my $project_path = shift();	chdir($project_path);
	my $config_file = "$project_path/config/$DESIGN_CONFIGURATION_FILE_NAME"; $config_file =~ s/\\/\//gi;
	open(LOG, "$config_file");    
		my $config_data = join(" ", <LOG>);    
	close(LOG);

	my @vendor = getdirs($project_path);
	
	my %project;
	$project_path = cwd;

	foreach $vendor (@vendor) {
		next if (( $vendor =~ /config/i ) or ( $vendor =~ /temp/i ) or ($vendor =~ /sim/i));
		@families = getdirs("$project_path/$vendor");
		chdir("$project_path/$vendor");		
		foreach $family_folder (@families){
			my $gid = 1;
			#my $family = $family_folder;
			my ($family) = ( $family_folder =~ m/([\w\d-\s]+)_\d+/i );		
			open( READFILE, "$project_path/$vendor/$family_folder/generics.txt" ); my $generic = join(" ", <READFILE>);	close( READFILE );				
			# get generic id				
			if ( exists $project{$vendor} ) {
				if ( exists $project{$vendor}{$family} ) {
					# get max id number
					my @array = sort { $a <=> $b } keys %{$project{$vendor}{$family}};  
					$gid = $array[-1] + 1;				
				}
			}
			
			my @devices = getdirs($family_folder);					
			
			foreach $device (@devices) {
				next if ($device eq "all"); 								
				############
				## XILINX ##
				############
				if ( $vendor =~ m/xilinx/i ) {						
					if ( $device =~ /best_match/i ) {    # Determining best_match device
						my $option_report = "$project_path\/$vendor\/$family_folder\/$device\/$XILINX_OPTION_REPORT";
						open(LOG, "$option_report");  my $option_data = join(" ", <LOG>);    close(LOG);
						#print "OPTION DATA = $option_data\n";
						if ( $option_data =~ /$REGEX_BEST_MATCH_EXTRACT/ ) { $project{$vendor}{$family}{$gid}{best_match} = $1; }
						next;
					}
					my @devicesRunNumber = getdirs("$family_folder/$device");					
					foreach $run (@devicesRunNumber){						
						next if ($run eq "xst");
						my $rundir = "$family_folder/$device/$run";
						my $no; if ( $run =~ m/(\d+)/ ) { $no = $1; } else { print "Cannot find run number {$run}!\n"; exit; }
						
						my $synthesis_report = "$rundir/$XILINX_SYNTHESIS_REPORT";
						my $map_report = "$rundir/$XILINX_MAP_REPORT";
						my $timing_report = "$rundir/$XILINX_TRACE_REPORT";
						my $option_report = "$rundir/$XILINX_OPTION_REPORT";

						open(LOG, "$synthesis_report"); my $synthesis_data = join(" ", <LOG>);  close(LOG);
						open(LOG, "$map_report");     my $map_data = join(" ", <LOG>);     close(LOG);
						open(LOG, "$timing_report");  my $timing_data = join(" ", <LOG>);    close(LOG);
						open(LOG, "$option_report");  my $option_data = join(" ", <LOG>);    close(LOG);
						
						my $emptydata = 0;
						if ( $synthesis_data eq "" ) { $emptydata = 1; if ($DEBUG_ON == 1) { print "\nWARNING!!! $device\/$run || synthesis_report is missing, this device will be skipped"; }}
						if ( $map_data eq "" )       { $emptydata = 1; if ($DEBUG_ON == 1) { print "\nWARNING!!! $device\/$run || map_report is missing, this device will be skipped"; }}
						if ( $timing_data eq "" )    { $emptydata = 1; if ($DEBUG_ON == 1) { print "\nWARNING!!! $device\/$run || timing_report is missing, this device will be skipped"; }}
						if ( $option_data eq "" )    { $emptydata = 1; if ($DEBUG_ON == 1) { print "\nWARNING!!! $device\/$run || option_report is missing, this device will be skipped"; }}
						next if( $emptydata == 1 );
						
						$project{$vendor}{$family}{$gid}{$device}{$run} = &extract_xilinx_report(\$family, \$no, \$synthesis_data, \$map_data, \$timing_data, \$option_data, \$config_data);						
					}
				############
				## ALTERA ##
				############
				} elsif ( $vendor =~ m/altera/i ) {
					if ( $device eq "best_match" ) {    # Determining best_match device
						my $option_report = "$project_path\/$vendor\/$family_folder\/$device\/$ALTERA_OPTION_REPORT";
						open(LOG, "$option_report");  my $option_data = join(" ", <LOG>);    close(LOG);
						if ( $option_data =~ /$REGEX_BEST_MATCH_EXTRACT/ ) {  $project{$vendor}{$family}{$gid}{best_match} = $1; }
						next;
					}
					my @devicesRunNumber = getdirs("$family_folder/$device");

					foreach $run (@devicesRunNumber){
						next if (($run eq "db") or ($run eq "incremental_db"));
						my $rundir = "$family_folder/$device/$run";
						my $no; if ( $run =~ m/(\d+)/ ) { $no = $1; } else { print "Cannot find run number {$run}!\n"; exit; }

						my @file = get_file_type($rundir, "$ALTERA_SYNTHESIS_REPORT_SUFFIX");             my $synthesis_report = "$rundir/$file[0]";
						@file = get_file_type($rundir, "$ALTERA_POWER_REPORT_SUFFIX");                 my $power_report = "$rundir/$file[0]";
						@file = get_file_type($rundir, "$ALTERA_TIMING_REPORT_1_SUFFIX");
						if ( $file[0] eq "" ) { @file = get_file_type($rundir, "$ALTERA_TIMING_REPORT_2_SUFFIX"); }  my $timing_report = "$rundir/$file[0]";
						@file = get_file_type($rundir, "$ALTERA_IMPLEMENTATION_REPORT_SUFFIX");             my $implementation_report = "$rundir/$file[0]";
						my $option_report = "$rundir/$ALTERA_OPTION_REPORT";

						open(LOG, "$synthesis_report");     	my $synthesis_data = join(" ", <LOG>);    		close(LOG);
						#open(LOG, "$power_report");       		my $power_data = join(" ", <LOG>);       		close(LOG);		#unsupported
						open(LOG, "$timing_report");      		my $timing_data = join(" ", <LOG>);      		close(LOG);
						open(LOG, "$implementation_report");  	my $implementation_data = join(" ", <LOG>);  	close(LOG);
						open(LOG, "$option_report");      		my $option_data = join(" ", <LOG>);    			close(LOG);

						#print "$timing_report\n"; exit;

						my $emptydata = 0;
						if ( $synthesis_data eq "" ) 		{ $emptydata = 1; if ($DEBUG_ON == 1) { print "\nWARNING!!! $device\t||\tsynthesis_report is missing, this device will be skipped"; }}
						#if ( $power_data eq "" )       	{ $emptydata = 1; if ($DEBUG_ON == 1) { print "\nWARNING!!! $device\t||\tpower_data is missing, this device will be skipped"; }}
						if ( $timing_data eq "" )    		{ $emptydata = 1; if ($DEBUG_ON == 1) { print "\nWARNING!!! $device\t||\ttiming_report is missing, this device will be skipped"; }}
						if ( $implementation_data eq "" ) { $emptydata = 1; if ($DEBUG_ON == 1) { print "\nWARNING!!! $device\t||\timplementation_data is missing, this device will be skipped"; }}
						if ( $option_report eq "" ) 		{ $emptydata = 1; if ($DEBUG_ON == 1) { print "\nWARNING!!! $device\t||\toption_report is missing, this device will be skipped"; }}
						next if( $emptydata == 1 );

						$project{$vendor}{$family}{$gid}{$device}{$run} = &extract_report_altera(\$no, \$synthesis_data, \$power_data, \$timing_data, \$implementation_data, \$config_data, \$option_data);
					}
				} else {
					print "Unsupported vendor!! Generation of { $vendor } report will be skipped \n"; next;
				}
			}
			# check if there's any result. If there is , write a generic value.
			if ( exists $project{$vendor} ) { 
				if ( exists $project{$vendor}{$family} ) {							
					$project{$vendor}{$family}{$gid}{generic} = $generic;
				}
			}
		}
	}

	return \%project;
}

return 1;