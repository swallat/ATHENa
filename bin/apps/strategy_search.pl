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
# APPLICATION: strategy_search
# Version: 0.1
# 
# This app searches for the best result based on different strategies (set of options)
# provided by the user
#####################################################################

#####################################################################
# Arguements
# PROVIDED: Vendor, Family, Device
#####################################################################
sub application{
	printOut("Running application : STRATEGY SEARCH\n");
	printLocalProgress("Application : STRATEGY SEARCH\n");
	my ($VENDOR, $FAMILY, $DEVICE);
	
	$VENDOR = uc($DEV_OBJ->getVendor());
	$FAMILY = uc($DEV_OBJ->getFamily());
	$DEVICE = uc($DEV_OBJ->getDevice());
	
	my %Strategies = %{getStrategies()};
	@DIRECTORY_LIST = ();
	
	my @StrategyFiles = keys %Strategies;
	my $RUNNO = 1;
	
	foreach my $strategyFile (@StrategyFiles){
		my $hashref = $Strategies{$strategyFile}{OPTS};
		my $synthesisToolref = $Strategies{$strategyFile}{TOOLS};
		
		#clone to get a new device with same information
		my $NEWDEV_OBJ = dclone($DEV_OBJ);
		
		#set Run Number
		$NEWDEV_OBJ->setRunNo($RUNNO);
		$RUNNO++;
		
		#set the new device parameters
		$NEWDEV_OBJ->setDispatchType($DISPATCH_TYPE_NONE);
		$NEWDEV_OBJ->setLocalApplication("single_run");
		
		$NEWDEV_OBJ->setAllOpts($VENDOR,$hashref);
		$NEWDEV_OBJ->setSynthesisTool($synthesisToolref);
		
		#dispatch device
		my $deviceDir = dispatchDevice(\$NEWDEV_OBJ);
		push(@DIRECTORY_LIST,$deviceDir);
	}
	
	#EXECUTE the scripts
	printOut("\nExecuting dispatched scripts...\n");
	my %RunHash = (
		vendor => "$VENDOR",
		title => "Athena - Strategy Search",
		directories => \@DIRECTORY_LIST,
		requested_frequency => 0,
		run_all_options => "yes",
		max_runs => $maxSimultaneousRuns,
    );
	&ExecuteScripts(\%RunHash);
	
}

#####################################################################
# Acquires strategies from userdefined directory and returns a hash consisting of these strateies
# $strategies{count} - options hash
#	
#	read the list of strategies (txt files)
#		format
#		strategy name (defaults to number), and the tool options
#####################################################################
sub getStrategies{
	my ($VENDOR) = @_;
	my (%StrategyHash);
	
	my $CONFIG_FILE = "$CONFIG_DIR/strategy_search.txt";
	printOut("CONFIG_FILE		$CONFIG_FILE\n");
	@ConfigData = @{getProcessedText($CONFIG_FILE , "strategy_search")};
	my $ConfigDataStr = join("\n", @ConfigData);
	
	my $STRATEGY_DIRECTORY = ""; #<$config_dir/strategies>
	if($ConfigDataStr =~ m/STRATEGY_DIRECTORY\s*=\s*${REGEX_PATH_IDENTIFIER}/gi){
		$STRATEGY_DIRECTORY = $1;
		$STRATEGY_DIRECTORY =~ s/<|>//g;
		$STRATEGY_DIRECTORY = processRelativePath($STRATEGY_DIRECTORY, "");
		#print "STRATEGY_DIRECTORY				 $STRATEGY_DIRECTORY\n";
	}
	
	$STRATEGY_DIRECTORY =~ s/\\/\//gi;
	$STRATEGY_DIRECTORY .= "\/" unless($STRATEGY_DIRECTORY =~ m/\/$/gi);
	print "STRATEGY_DIRECTORY				 $STRATEGY_DIRECTORY\n";
	
	#my @strategies = map{ my $file = $_; if($file =~ m/\.txt$/gi){ $_; }else{} }<"$STRATEGY_DIRECTORY*">;
	#my @strategies = <"$STRATEGY_DIRECTORY*.txt">;
	opendir(DIR, "$STRATEGY_DIRECTORY");
	my @strategies = map{ if($_ =~ m/\.txt$/gi){ "$STRATEGY_DIRECTORY$_"; }else{} } grep { $_ ne '.' && $_ ne '..' && !(-d "$STRATEGY_DIRECTORY$_")} readdir DIR;
	closedir(DIR);	
	
	#print "List of strategies : \n";
	#print join("\n", @strategies)."\n";
	
	foreach my $strategy_file (@strategies){
		my ($hashref, $synthesisToolref) = readStrategy($strategy_file); #<== hash return value
		$StrategyHash{$strategy_file}{OPTS} = $hashref;
		$StrategyHash{$strategy_file}{TOOLS} = $synthesisToolref;
	}
	
	return \%StrategyHash;
}


#####################################################################
# Read options from option files
# 
# VENDOR, TOOL name = uppercase
# ALTERA needs options uppercase, XILINX needs them lowercase <== call it a pain in the A55
# Option , flag = lower if xilinx, upper if altera
#####################################################################
sub readStrategy{
	my ($StrategyFile) = @_;
	
	my %OPT_HASH = ();
	my %SYNTHESIS_TOOL = ();
	
	my $OPTIONS_FILE = $StrategyFile;
	my @optdata = @{getProcessedText($OPTIONS_FILE , "strategy_search")};
	my $ConfigDataStr = join("\n", @optdata);
	
	my $size = $#optdata;
	#printOut("$size\n");
	my $i = 0;
	for($i=0;$i<$size;$i++)
	{
		#skip all the # signs in the options
		my $substring = substr $optdata[$i], 0, 1;
		next if($substring =~ /#/);
		
		foreach my $VENDOR (@VENDORS){
			$VENDOR = uc($VENDOR);
			my @TOOLS = ();
			if(lc($VENDOR) eq "xilinx"){ @TOOLS = @ALL_XILINX_TOOLS; }
			elsif(lc($VENDOR) eq "altera"){ @TOOLS = @ALL_ALTERA_TOOLS; }
			elsif(lc($VENDOR) eq "actel"){ @TOOLS = @ALL_ACTEL_TOOLS; }
			
			my $SYN_TOOL_VAR = $VENDOR."_SYNTHESIS_TOOL";
			if($optdata[$i] =~ m/${SYN_TOOL_VAR}\s*=\s*${REGEX_CONFIG_ITEM_IDENTIFIER}/gi){
				#printOut("SYNTHESIS_TOOL				 $1\n");
				$SYNTHESIS_TOOL{$VENDOR} = $1;
			}
			
			foreach my $TOOL (@TOOLS){
				$TOOL = uc($TOOL);
				my $TOOL_STR = $VENDOR."_".$TOOL."_OPT";
				if($optdata[$i] =~ m/${TOOL_STR}\s*=/gi){
					my $toolDone = 0;
					while ($toolDone == 0){
						$i++;
						my $substring = substr $optdata[$i], 0, 1;
						if(($optdata[$i] =~ /END[\s^\w]*OPT/i)){
							$toolDone = 1;
						}
						elsif($substring =~ /[\s\\\\-_\/#]+/){}
						else{
							chomp($optdata[$i]);
							#printOut("$VENDOR - $TOOL - $optdata[$i]\n");
							$optdata[$i] =~ s/-//gi;
							my @splitdata = split(/[= ]+/,$optdata[$i]);
							
							#ALTERA needs options uppercase, XILINX needs them lowercase <== call it a pain in the A55
							$OPT_HASH{$TOOL}{lc($splitdata[0])} = lc($splitdata[1]."") if(lc($VENDOR) eq "xilinx");
							$OPT_HASH{$TOOL}{uc($splitdata[0])} = uc($splitdata[1]."") if(lc($VENDOR) eq "altera");
							
							#Option translations happens here
						}
					}
				}
			}
		}
	}
	return \%OPT_HASH, \%SYNTHESIS_TOOL;
}










1;