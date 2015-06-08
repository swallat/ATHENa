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


##############################################################################################################################################################################
##############################################################################################################################################################################
#	Xilinx
##############################################################################################################################################################################
##############################################################################################################################################################################


######################################################################
# Extract Xilinx's report data.
# Input =>    0  : run number
#        1  : synthesis data
#        2  : map data
#        3  : timing data
#        4  : option data
# output =>    reference to the populated hash
######################################################################
$NONE = "default";

sub extract_xilinx_report {
	#keep the refs and the data seperate..... 
	my ($family_ref, $run_ref, $synthesis_ref, $map_ref, $timing_ref, $option_ref, $config_ref) = @_;

    my $family = ${$family_ref};
	my $run = ${$run_ref}; my $synthesis_data = ${$synthesis_ref}; my $map_data = ${$map_ref};
	my $timing_data = ${$timing_ref}; my $option_data = ${$option_ref}; my $config_data = ${$config_ref};

	my $clock_net_name;
	my (  $T_SLICE, $U_SLICE, $PU_SLICE,    #slice
		$T_BRAM, $U_BRAM, $PU_BRAM,         #bram
		$T_DSP, $U_DSP, $PU_DSP,            #dsp
		$T_MULT, $U_MULT, $PU_MULT,         #mult
		$T_IO, $U_IO, $PU_IO,				#pins
		$T_FF, $U_FF, $PU_FF,				#flip flops
		$T_LUT, $U_LUT, $PU_LUT				#luts		
		)              
		= &extract_xilinx_util($family, "", $map_ref);
  
	
	my ($IMP_TOOL, $IMP_TOOL_VERSION) = &extract_xilinx_tool($map_data);
	my ($RSYN_FREQ, $RSYN_TCLK, $RIMP_FREQ, $RIMP_TCLK, $COST_TABLE, $SYN_OPT, $MAP_OPT, $IMP_OPT, @syn_time, @imp_time, @tot_time) = &extract_xilinx_option($option_data);
	my ($clkname_ref, $syntclk_ref, $synfreq_ref, $imptclk_ref, $impfreq_ref, $delay_logic_ref, $delay_route_ref) = &extract_xilinx_timing($synthesis_data, $timing_data); #return values are references
	if ($synthesis_data =~ /$REGEX_XILINX_TOOL_EXTRACT/)   {  $SYN_TOOL_VERSION = $1; $SYN_TOOL = $2;    } else {  $SYN_TOOL = "N/A";  $SYN_TOOL_VERSION = "N/A";  }
	
	### Change tools' names to the correct ones ... 
	if ( $SYN_TOOL =~ m/xst/ ) { $SYN_TOOL = "Xilinx XST"; }
	if ( $IMP_TOOL =~ m/xst/ ) { $IMP_TOOL = "Xilinx ISE"; }
	

	my @area_in = $U_SLICE;
    my @area_in = $U_LUT;
	my ( $LATENCY, $THROUGHPUT, $THROUGHPUT_AREA, $LATENCY_AREA ) = &calculate_timing_data(\$config_data, $clkname_ref, $imptclk_ref, \@area_in);
	 
	my %hash = (
		RUN_NO => $run,
		# resource utilization
		T_SLICE => $T_SLICE,    U_SLICE => $U_SLICE,    PU_SLICE => $PU_SLICE,
		T_BRAM => $T_BRAM,      U_BRAM => $U_BRAM,      PU_BRAM => $PU_BRAM,
		T_DSP => $T_DSP,      U_DSP => $U_DSP,      PU_DSP => $PU_DSP,
		T_MULT => $T_MULT,       U_MULT => $U_MULT,      PU_MULT => $PU_MULT,
		T_IO => $T_IO,        U_IO => $U_IO,        PU_IO => $PU_IO,
		T_LUT => $T_LUT,        U_LUT => $U_LUT,        PU_LUT => $PU_LUT,
		T_FF => $T_FF,			U_FF => $U_FF, 		PU_FF => $PU_FF,
		# timing 1
		RSYN_FREQ => $RSYN_FREQ,      RSYN_TCLK => $RSYN_TCLK,
		RIMP_FREQ => $RIMP_FREQ,      RIMP_TCLK => $RIMP_TCLK,
		THROUGHPUT => $THROUGHPUT,  LATENCY => $LATENCY,
		THROUGHPUT_AREA => $THROUGHPUT_AREA,
		LATENCY_AREA => $LATENCY_AREA,
        DELAY_LOGIC => @{$delay_logic_ref}[$0],    DELAY_ROUTE => @{$delay_route_ref}[$0],
		# option
		COST_TABLE => $COST_TABLE,    SYN_OPT => $SYN_OPT,
		MAP_OPT => $MAP_OPT,        IMP_OPT => $IMP_OPT,
		# tool info
		SYN_TOOL => $SYN_TOOL,      SYN_TOOL_VERSION => $SYN_TOOL_VERSION,
		IMP_TOOL => $IMP_TOOL,       IMP_TOOL_VERSION => $IMP_TOOL_VERSION,
		# execution time
		SYN_TIME => $syn_time,		IMP_TIME => $imp_time, 	
		TOT_TIME => $tot_time,
	);
	  
	#timing 2
	for ( my $i = 0; $i < scalar@{$clkname_ref}; $i++) {
		foreach my $key ( @{$CLK_KEY{xilinx}} ) {		
			my $primary_clock, $legend;
			
			# Keeps primary clock legend the same as original
			if ( $config_data =~ /$REGEX_CLOCK_NET_EXTRACT/ ) { $primary_clock = $1; }
			if ( @{$clkname_ref}[$i] eq $primary_clock ) {
				$legend = ${key};
			} else {
				$legend = "${key}_@{$clkname_ref}[$i]";	
			}		
			if ( $key =~ m/SYN_FREQ/i) { $hash{$legend} = @{$synfreq_ref}[$i]; }
			if ( $key =~ m/SYN_TCLK/i) { $hash{$legend} = @{$syntclk_ref}[$i]; }
			if ( $key =~ m/IMP_FREQ/i) { $hash{$legend} = @{$impfreq_ref}[$i]; }
			if ( $key =~ m/IMP_TCLK/i) { $hash{$legend} = @{$imptclk_ref}[$i];}
            # if ( $key =~ m/DELAY_LOGIC/i) { $hash{$legend} = @{$delay_logic_ref}[$i];}
            # if ( $key =~ m/DELAY_ROUTE/i) { $hash{$legend} = @{$delay_route_ref}[$i];}
		}
	}  
	
  return \%hash;
}

##########################################################
#  Extracts the tool information from the reports
##########################################################
sub extract_xilinx_tool{
	my $map_report = shift;

	# Tool :: always use xst for implementation#
	if($map_report =~ /$REGEX_XILINX_TOOL_EXTRACT/)  {  $IMP_TOOL_VERSION = $1;   $IMP_TOOL = "xst";   } else {  $IMP_TOOL = "N/A";    $IMP_TOOL_VERSION = "N/A";  }

	return $IMP_TOOL, $IMP_TOOL_VERSION;
}

##########################################################
#  Function will return the Maximum Frequency
##########################################################
sub extract_xilinx_timing {
	my $synthesis_report = shift; 
	my $timing_report = shift;
  
  
	my (@clock_name, @SYN_TCLK, @SYN_FREQ, @IMP_TCLK, @IMP_FREQ);
	my @list;
	foreach my $regex ( @REGEX_XILINX_SYNTCLK_EXTRACT ) {
		@list = ( $synthesis_report =~ /$regex/g );
		if ( scalar@list > 0 ) { last; }
	}
	
	for (my $i = 0; $i < eval(($#list+1)/2); $i++) {	
		$clock_name[$i] = $list[2*$i];
		($SYN_TCLK[$i],$SYN_FREQ[$i])  = ($list[2*$i+1] =~ m/$REGEX_XILINX_SYNTCLK_SEQUENCE/  );
		 
		
		my $REGEX_TEMP = qr/$clock_name[$i]${REGEX_XILINX_IMPTCLK_EXTRACT}/i;
		if ($timing_report =~ /$REGEX_TEMP/) {	$IMP_TCLK[$i] = $1;	} else { $IMP_TCLK[$i] = "N/A"; $IMP_FREQ[$i] = "N/A"; }
		if ( $IMP_TCLK[$i] > 0 ) {	my $temp = 1/($IMP_TCLK[$i]*(10**(-3))); $IMP_FREQ[$i] = sprintf("%.3f", $temp); }
		#print "$clock_name[$i] | $SYN_TCLK[$i] | $SYN_FREQ[$i] | $IMP_TCLK[$i] | $IMP_FREQ[$i]\n";		
	}	
	
	return (\@clock_name, \@SYN_TCLK, \@SYN_FREQ, \@IMP_TCLK, \@IMP_FREQ);
}

##############################################################################################################################################################################
##############################################################################################################################################################################
#	Altera
##############################################################################################################################################################################
##############################################################################################################################################################################

##########################################################
#  Extracts the resource utilization from the reports
##########################################################
sub extract_xilinx_option{
  my $option_report = shift;

  my $RSYN_FREQ, $RSYN_TCLK, $RIMP_FREQ, $RIMP_TCLK, $COST_TABLE, $SYN_OPT, $MAP_OPT, $syn_time, $imp_time, $tot_time;

  if($option_report =~ /$REGEX_XILINX_REQ_SYN_FREQ_EXTRACT/ ) { if ($1 <= 0) { $RSYN_FREQ = $NONE } else { $RSYN_FREQ = $1; $RSYN_FREQ = sprintf("%.${PRECISION}f", $RSYN_FREQ); }} else {  $RSYN_FREQ = $NONE;    }
  if($option_report =~ /$REGEX_XILINX_REQ_SYN_TCLK_EXTRACT/ ) { if ($1 <= 0) { $RSYN_TCLK = $NONE } else {$RSYN_TCLK = $1; $RSYN_TCLK = sprintf("%.${PRECISION}f", $RSYN_TCLK); }} else {  $RSYN_TCLK = $NONE;    }
  if($option_report =~ /$REGEX_XILINX_REQ_IMP_FREQ_EXTRACT/ ) { if ($1 <= 0) { $RIMP_FREQ = $NONE } else {$RIMP_FREQ = $1; $RIMP_FREQ = sprintf("%.${PRECISION}f", $RIMP_FREQ); }} else {  $RIMP_FREQ = $NONE;    }
  if($option_report =~ /$REGEX_XILINX_REQ_IMP_TCLK_EXTRACT/ ) { if ($1 <= 0) { $RIMP_TCLK = $NONE } else {$RIMP_TCLK = $1; $RIMP_TCLK = sprintf("%.${PRECISION}f", $RIMP_TCLK); }} else {  $RIMP_TCLK = $NONE;    }

  if($option_report =~ /$REGEX_XILINX_COSTTABLE_EXTRACT/)     {  $COST_TABLE = $1;  } else {  $COST_TABLE = $NONE;    }
  if($option_report =~ /$REGEX_XILINX_SYN_OPT_EXTRACT/)       {  $SYN_OPT = $1;    } else {  $SYN_OPT = "";    }
  if($option_report =~ /$REGEX_XILINX_MAP_OPT_EXTRACT/)       {  $MAP_OPT = $1;    } else {  $MAP_OPT = "";    }
  if($option_report =~ /$REGEX_XILINX_PAR_OPT_EXTRACT/)       {  $IMP_OPT = $1;    } else {  $IMP_OPT = "";    }
  
  # execution time
  ($syn_time, $imp_time, $tot_time) = &extract_exec_time($option_report);
   
  return $RSYN_FREQ, $RSYN_TCLK, $RIMP_FREQ, $RIMP_TCLK, $COST_TABLE, $SYN_OPT, $MAP_OPT, $IMP_OPT, $syn_time, $imp_time, $tot_time;
}

######################################################################
# Extract Altera's report data.
# Input =>    
#		 0  : run number
#        1  : synthesis data
#        2  : map data
#        3  : timing data
#        4  : option data
# output =>    reference to the populated hash
######################################################################

sub extract_report_altera {
	my $run = ${shift()}; my $synthesis_data = ${shift()}; $power_data = ${shift()};
	my $timing_data = ${shift()}; my $implementation_data = ${shift()}; my $config_data = ${shift()}; my $option_data = ${shift()};

	#============= Resource Utilization =============
	my (  	$U_LE, $T_LE, $PU_LE, #LE
			$U_ALUTS, $T_ALUTS, $PU_ALUTS, #ALUTs
			$U_LU_CA, $T_LU_CA, $PU_LU_CA, #COMB ALUT
			$U_LU_MA, $T_LU_MA, $PU_LU_MA, #MEMS ALUT
			$U_LU_LR, $T_LU_LR, $PU_LU_LR, #LUT REGs
			$U_FF, $T_FF, $PU_FF, #DEDICATED LREG (Flip Flops)
			$U_LU, $T_LU, $PU_LU, #Logic Utilization percentage
			$U_MEM, $T_MEM, $PU_MEM, #memory
			$U_DSP, $T_DSP, $PU_DSP, #dsp
			$U_MULT, $T_MULT, $PU_MULT, #multiplier
			$U_PIN, $T_PIN, $PU_PIN ) #pin
			= &extract_altera_util("", $implementation_data);
	
	if ( $U_ALUTS == 0 ) {
		$U_ALUTS = $U_LU_CA;
		$T_ALUTS = $T_LU_CA;
		$PU_ALUTS = $PU_LU_CA;
	}
	
	#============= Option (Incompleted) =============
	if ( $option_data =~ /$REGEX_ALTERA_SYNOPTS_EXTRACT/ ) { $SYN_OPT = $1; } else { $SYN_OPT = "N/A"; }
	if ( $option_data =~ /$REGEX_ALTERA_IMPOPTS_EXTRACT/ ) { $IMP_OPT = $1; } else { $IMP_OPT = "N/A"; }
	if ( $option_data =~ /$REGEX_ALTERA_SEED_EXTRACT/ ) { $SEED = $1; } else { $SEED = "N/A"; }
	# execution time extraction
	($syn_time, $imp_time, $tot_time) = &extract_exec_time($option_data);

	#============ Timing =============
	my @freq, @tclk;
	my @timing_match = ( $timing_data =~ /$REGEX_ALTERA_TIMING/g);
	if ($#timing_match > 0 ) { #TAN RPT	
		for (my $i = 0; $i < eval(($#timing_match+1)/3); $i++) {
			$clock_name[$i] = $timing_match[3*$i];
			my $obtained_timing_data = $timing_match[3*$i+2];

			if ($obtained_timing_data =~ /$REGEX_ALTERA_TIMING_DATA_EXTRACT/) {
				$freq[$i] = $1; $tclk[$i] = $2;
			} else {
				$freq[$i] = "N/A"; $tclk[$i] = "N/A";
			}
		}	
	} else {  #STA RPT
		my @sta_lines = split(/\n/, $timing_data);
		foreach $line_no (0..$#sta_lines) {
			if ($sta_lines[$line_no] =~ m/;[\s\w\d]+Model Fmax Summary/i) {
				# skip nondata lines
				$line_no = $line_no + 4;
				# should be in data section by now				
				my $i = 0; 
				while (1) {
					if( $sta_lines[$line_no] =~ m/;\s*([\d.]+)\s*[\w]*\s*;\s*([\d.]+)\s*[\w]*[\t\s]*;\s*([\w]+)/i ){
						$clock_name[$i] = $3;
						$freq[$i] = $2; #restricted Fmax	
						if ( $freq[$i] < 1 ) { $freq[$i] = $1; }	# Fmax
						
						if ( $freq[$i] < 1 ) {
							$tclk[$i] = "N/A";	$freq[$i] = "N/A";
						} else {
							my $period = 1/$freq[$i]*1000; 
							$tclk[$i]  = sprintf("%.${PRECISION}f", $period);
						}
						
					} else {						
						last;
					}
					$i++; $line_no++;
				}
				#exit foreach loop
				last;
			}
		}
	}

	if($option_data =~ /$REGEX_ALTERA_REQ_FREQ_EXTRACT/ ) {   
		$RIMP_FREQ = $1; if ( $RIMP_FREQ == 0 ) { $RIMP_FREQ = $NONE; } else { $RIMP_FREQ = sprintf("%.${PRECISION}f", $RIMP_FREQ); }
	} else {  $RIMP_FREQ = $NONE;    }
	if($option_data =~ /$REGEX_ALTERA_REQ_TCLK_EXTRACT/ ) {   
		$RIMP_TCLK = $1; if ( $RIMP_TCLK == 0 ) { $RIMP_TCLK = $NONE; } else { $RIMP_TCLK = sprintf("%.${PRECISION}f", $RIMP_TCLK); }
	} else {  $RIMP_TCLK = $NONE;    }
		

	my @area_in = ($U_LE, $U_ALUTS);
	my ( $LATENCY, $THROUGHPUT, $THROUGHPUT_AREA, $LATENCY_AREA ) = &calculate_timing_data(\$config_data, \@clock_name, \@tclk, \@area_in);
	
	#============= Tool =============
	if ( $implementation_data =~ /$REGEX_ALTERA_TOOL_EXTRACT/ ) {  $IMP_TOOL = $1; $IMP_TOOL_VERSION = "$2 $3";  } else { $IMP_TOOL = "N/A"; $IMP_TOOL_VERSION = "N/A"; }
	if ( $synthesis_data =~ /$REGEX_ALTERA_TOOL_EXTRACT/ )     {  $SYN_TOOL = $1; $SYN_TOOL_VERSION = "$2 $3";  } else { $SYN_TOOL = "N/A"; $SYN_TOOL_VERSION = "N/A"; }
	### Lazy fix for the tool versions
	if ( $IMP_TOOL_VERSION !~ m/N\/A/i  ) {
		if ( $IMP_TOOL_VERSION =~ m/([\d.\w]+)/i ) {
			$IMP_TOOL_VERSION = $1;
		} else { $IMP_TOOL_VERSION = "N/A"; }
	}
	if ( $SYN_TOOL_VERSION !~ m/N\/A/i  ) {
		if ( $SYN_TOOL_VERSION =~ m/([\d.\w]+)/i ) {
			$SYN_TOOL_VERSION = $1;
		} else { $SYN_TOOL_VERSION = "N/A"; }
	}

	

	my %hash = (
		RUN_NO => $run,
		# resource utilization
		T_LE  => $T_LE,      U_LE => $U_LE,    PU_LE => $PU_LE,
		T_MULT   => $T_MULT,    U_MULT   => $U_MULT,  PU_MULT => $PU_MULT,
		T_DSP  => $T_DSP,    U_DSP   => $U_DSP,   PU_DSP  => $PU_DSP,		
		T_MEM => $T_MEM,    U_MEM => $U_MEM,  PU_MEM => $PU_MEM,
		T_PIN => $T_PIN,    U_PIN => $U_PIN,  PU_PIN => $PU_PIN,
		T_LU => $T_LU,		U_LU => $U_LU, 		PU_LU => $PU_LU,	
		T_ALUTS => $T_ALUTS, U_ALUTS => $U_ALUTS, PU_ALUTS => $PU_ALUTS, #ALUTs
		T_LU_CA => $T_LU_CA,  U_LU_CA => $U_LU_CA,   PU_LU_CA => $PU_LU_CA,
		T_LU_MA => $T_LU_MA,  U_LU_MA => $U_LU_MA,   PU_LU_MA => $PU_LU_MA,
		T_FF => $T_FF,  U_FF => $U_FF,   PU_FF => $PU_FF,
		T_LU_LR => $T_LU_LR, U_LU_LR => $U_LU_LR,	 PU_LU_LR => $PU_LU_LR , #LUT REGs
		# timing 1
		RIMP_FREQ => $RIMP_FREQ,      RIMP_TCLK => $RIMP_TCLK,
		THROUGHPUT => $THROUGHPUT,  LATENCY => $LATENCY,
		THROUGHPUT_AREA => $THROUGHPUT_AREA,
		LATENCY_AREA => $LATENCY_AREA,
		# option
		SYN_OPT => $SYN_OPT,        IMP_OPT => $IMP_OPT,
		SEED => $SEED,
		# tool info
		SYN_TOOL => $SYN_TOOL,  SYN_TOOL_VERSION => $SYN_TOOL_VERSION,
		IMP_TOOL => $IMP_TOOL,   IMP_TOOL_VERSION => $IMP_TOOL_VERSION,
		# execution time
		SYN_TIME => $syn_time,		IMP_TIME => $imp_time, 	
		TOT_TIME => $tot_time,
	);

	### OLD
	# for ( my $i = 0; $i < scalar@clock_name; $i++) {
		# foreach my $key ( @{$CLK_KEY{altera}} ) {
			# my $legend = "${key}_$clock_name[$i]";	
			# if ( $key =~ m/IMP_TCLK/i) { $hash{$legend} = $tclk[$i]; }
			# if ( $key =~ m/IMP_FREQ/i) { $hash{$legend} = $freq[$i]; }	
		# }
	# }  
	
	### NEW
	for ( my $i = 0; $i < scalar@clock_name; $i++) {
		foreach my $key ( @{$CLK_KEY{altera}} ) {		
			my $primary_clock, $legend;
			
			# Keeps primary clock legend the same as original
			if ( $config_data =~ /$REGEX_CLOCK_NET_EXTRACT/ ) { $primary_clock = $1; }
			if ( $clock_name[$i] eq $primary_clock ) {
				$legend = ${key};
			} else {
				$legend = "${key}_$clock_name[$i]";	
			}					
			if ( $key =~ m/IMP_TCLK/i) { $hash{$legend} = $tclk[$i];	}
			if ( $key =~ m/IMP_FREQ/i) { $hash{$legend} = $freq[$i]; }
		}
	}  
 
	return \%hash;
}

##############################################################################################################################################################################
##############################################################################################################################################################################
#	Vendor Independent Fucntions
##############################################################################################################################################################################
##############################################################################################################################################################################

#####################################################################
# extract execution time
#####################################################################
sub extract_exec_time {
	my $option_report = shift();
	
	if($option_report =~ /$REGEX_SYN_TIME_EXTRACT/)       {  $syn_time = $1;    } else {  $syn_time = "N/A";    }	
	if($option_report =~ /$REGEX_SYN_TIME_EXTRACT/)       {  $syn_time = $1;    } else {  $syn_time = "N/A";    }
	if($option_report =~ /$REGEX_IMP_TIME_EXTRACT/)       {  $imp_time = $1;    } else {  $imp_time = "N/A";    }
	if (( $syn_time ne "N/A" ) and ( $imp_time ne "N/A" )) { 
	if ( $syn_time =~ /$REGEX_TIME_EXTRACT/ ) {@syn_time_temp = ($1, $2, $3, $4); }
	if ( $imp_time =~ /$REGEX_TIME_EXTRACT/ ) {@imp_time_temp = ($1, $2, $3, $4); }
		for (my $i = 0; $i < 4; $i++ ) {
			$tot_time_temp[$i] = $syn_time_temp[$i] + $imp_time_temp[$i];
		}
		while ( $tot_time_temp[3] >= 60 ) { ## Seconds
			$tot_time_temp[2]++;	$tot_time_temp[3] = $tot_time_temp[3] - 60;
		}
		while ( $tot_time_temp[2] >= 60 ) { ## Minutes
			$tot_time_temp[1]++;	$tot_time_temp[2] = $tot_time_temp[2] - 60;
		}
		while ( $tot_time_temp[1] >= 24 ) { ## Hours
			$tot_time_temp[0]++;	$tot_time_temp[1] = $tot_time_temp[1] - 24;
		}		
		$tot_time = $tot_time_temp[0] . "d " . $tot_time_temp[1] . "h:" .  $tot_time_temp[2] . "m:" . $tot_time_temp[3] . "s";
	} else { $tot_time = "N/A";    }
	 
	return ( $syn_time, $imp_time, $tot_time );
}

#####################################################################
# calculate timing data
#####################################################################
sub calculate_timing_data {
	my $config_data = ${shift()};
	my @clock_name = @{shift()};
	my @tclk	   = @{shift()};
	my @area_in	   = @{shift()};
	
#	foreach $a ( @clock_name ) { print "$a\n"; } exit;
	#selecting which tclk to use based on the specified clock net
	my $tclk_val = "N/A";	
	if ( $config_data =~ /$REGEX_CLOCK_NET_EXTRACT/ ) {
		for ( my $i = 0; $i < scalar@clock_name; $i++) {	
			if ( $1 =~ m/$clock_name[$i]/i ) {
				$tclk_val = $tclk[$i];
				last;
			}
		}
	} 	
	my ( $LATENCY, $THROUGHPUT, $THROUGHPUT_AREA, $LATENCY_AREA );
	if ( $tclk_val !~ m/N\/A/i ) {
		if ( $config_data =~ /$REGEX_LATENCY_EXTRACT/ )   { $LATENCY = $1; }   else { $LATENCY = "N/A"; }
		if ( $config_data =~ /$REGEX_THROUGHPUT_EXTRACT/ )   { $THROUGHPUT = $1; }   else { $THROUGHPUT = "N/A"; }
		if ( $LATENCY !~ m/N\/A/i ) {  $LATENCY =~ s/TCLK/$tclk_val/;    $LATENCY = eval "$LATENCY"; $LATENCY = sprintf("%.${PRECISION}f", $LATENCY); }
		if ( $THROUGHPUT !~ m/N\/A/i ) { $THROUGHPUT =~ s/TCLK/$tclk_val/; $THROUGHPUT = eval "$THROUGHPUT*1000"; $THROUGHPUT = sprintf("%.${PRECISION}f", $THROUGHPUT); }
	} else { $LATENCY = "N/A";   $THROUGHPUT = "N/A";  }
	my $area = 0;
	for ( my $i = 0; $i <= scalar@area_in; $i++ ) {
		if ( $area_in[$i] > 0 ) { $area = $area_in[$i]; }
	} 
	if ( $area <= 0 ) {
		$THROUGHPUT_AREA = "N/A"; $LATENCY_AREA = "N/A";		
	} else {
		if ( $THROUGHPUT > 0 ) {
			$THROUGHPUT_AREA = $THROUGHPUT/$area;
			$THROUGHPUT_AREA = sprintf("%.${PRECISION}f", $THROUGHPUT_AREA);
		} else { $THROUGHPUT_AREA = "N/A"; }
		if ( $LATENCY > 0 ) {
			$LATENCY_AREA  = $LATENCY*$area;
			$LATENCY_AREA  = sprintf("%.${PRECISION}f", $LATENCY_AREA);
		} else { $LATENCY_AREA  = "N/A"; }
	}
	return ( $LATENCY, $THROUGHPUT, $THROUGHPUT_AREA, $LATENCY_AREA );
}


return 1;