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

package Device;
use Structs;
#use warnings;

#####################################################################
# Print function - prints all the info about the device
#####################################################################
sub print{
	my $self = shift;
	my $output = "\n\nPrinting device info: \n";
	$output .= "RunNo: ". getRunNo($self) . "\n";
	$output .= "Vendor: ". getVendor($self) . "\n";
	$output .= "Family: ". getFamily($self) . "\n";
	$output .= "Device: ". getDevice($self) . "\n";
	
	my @temp = getRequestedFreqs($self);
	$output .= "Requested Frequencies: ". join(",",@temp) . "\n";
	my @temp = getConstraintFiles($self);
	$output .= "Constraint Files: ". join(",",@temp) . "\n";
	
	$output .= "Root Directory: ". getRootDir($self) . "\n";
	$output .= "Workspace Directory: ". getWorkspaceDir($self) . "\n";
	
	$output .= "Dispatch Type: ". getDispatchType($self) . "\n";
	$output .= "Application: ". getLocalApplication($self) . "\n";

	#print $output;
	
	return $output;
}

#####################################################################
# RunNo functions
#####################################################################
sub setRunNo {
	my $self = shift;
	if ( @_ ) {
		$self->{RUN_NO} = shift;
	}
}
sub getRunNo {
	my $self = shift;
	return $self->{RUN_NO};
}

sub checkRunNo {
	my $self = shift;
	warn "WARNING: RUN Number is not specified for this device object.\n" if ($self->{RUN_NO} eq "");
}

#####################################################################
# Vendor functions
#####################################################################
sub setVendor {
	my $self = shift;
	if ( @_ ) {
		$self->{VENDOR} = shift;
	}
	#return $self->{VENDOR};
}
sub getVendor {
	my $self = shift;
	return $self->{VENDOR};
}

sub checkVendor {
	my $self = shift;
	warn "WARNING: Vendor is not specified for this device object.\n" if ($self->{VENDOR} eq "");
}

#####################################################################
# FAMILY functions
#####################################################################
sub setFamily {
	my $self = shift;
	if ( @_ ) {
		$self->{FAMILY} = shift;
	}
	checkFamily($self);
}
sub getFamily {
	my $self = shift;
	return $self->{FAMILY};
}
#checkFamily($self);
sub checkFamily {
	my $self = shift;
	warn "WARNING: Family is not specified for this device object.\n" if ($self->{FAMILY} eq "");
}

#####################################################################
# DEVICE functions
#####################################################################
sub setDevice {
	my $self = shift;
	if ( @_ ) {
		$self->{DEVICE} = shift;
	}
	checkDevice($self);
}
sub getDevice {
	my $self = shift;
	return $self->{DEVICE};
}
#checkDevice($self);
sub checkDevice {
	my $self = shift;
	warn "WARNING: Device name is not specified for this device object.\n" if ($self->{DEVICE} eq "");
}

#####################################################################
# Trim mode
#####################################################################
sub setTrimMode {
	my $self = shift;	
	if ( @_ ) {
		$self->{trim_mode} = shift;
	}
}
sub getTrimMode {
	my $self = shift;
	return $self->{trim_mode};
}

#####################################################################
# Trim mode
#####################################################################
sub setRunDir {
	my $self = shift;	
	my $dir = shift; 
	$dir =~ s/\\\\/\//i; 
	$self->{rundir} = $dir;
	
}
sub getRunDir {
	my $self = shift;
	return $self->{rundir};
}


#####################################################################
# Generic functions
#####################################################################
sub setGenericID {
	my $self = shift;
	if ( @_ ) {
		$self->{generic_id} = shift;
	}
}
sub getGenericID {
	my $self = shift;
	return $self->{generic_id};
}
sub setGenericValue {
	my $self = shift;
	my ($generics) = @_;
	my $vendor = $self->getVendor();
	if ( $vendor =~ m/xilinx/i ) {
		$self->{generic_val} = $generics;
		if ( $generics =~ /^default$/i ) { return; }
		# insert generics into synthesis option
		$generics =~ s/,/ /;
		$generics = "{ $generics }";	
		$self->deleteToolOpt($vendor, "XST", "generics");
		$self->addOpt($vendor, "XST", "generics", $generics);		
	} elsif ( $vendor =~ m/altera/i ) {
		$self->{generic_val} = $generics;
	} else {
		print "Unsupport vendor ($vendor) for setGenericValue();\n";
		system( pause ); exit;
	}
}

sub getGenericValue {
	my $self = shift;
	if ( defined $self->{generic_val} ) {
		return $self->{generic_val};
	} else {
		return "N/A";
	}
}

#####################################################################
# Requested freq functions
#####################################################################
sub setRequestedFreqs {
	my $self = shift;
	if ( @_ ) {
		$self->{REQ_SYN_FREQ} = shift;
		$self->{REQ_IMP_FREQ} = shift;
	}
	else{
		$self->{REQ_SYN_FREQ} = 0;
		$self->{REQ_IMP_FREQ} = 0;
	}
}
sub getRequestedFreqs {
	my $self = shift;
	return $self->{REQ_SYN_FREQ}, $self->{REQ_IMP_FREQ};
}

#####################################################################
# Constraint functions
#####################################################################
sub setConstraintFile {
	my $self = shift;
	if ( @_ ) {
		$self->{SYN_CONSTRAINT_FILE} = shift;
		$self->{IMP_CONSTRAINT_FILE} = shift;
	}
	else{
		$self->{SYN_CONSTRAINT_FILE} = "default";
		$self->{IMP_CONSTRAINT_FILE} = "default";
	}
}
sub getConstraintFiles {
	my $self = shift;
	return $self->{SYN_CONSTRAINT_FILE}, $self->{IMP_CONSTRAINT_FILE};
}

#####################################################################
# Root dir functions
#####################################################################
sub setRootDir {
	my $self = shift;
	if ( @_ ) {
		$self->{ROOT_DIR} = shift;
	}
	checkRootDir($self);
}
sub getRootDir {
	my $self = shift;
	return $self->{ROOT_DIR};
}
#checkRootDir($self);
sub checkRootDir{
	my $self = shift;
	warn "WARNING: Root directory is not specified for this device object.\n" if ($self->{ROOT_DIR} eq "");
}

#####################################################################
# Workspace dir functions
#####################################################################
sub setWorkspaceDir {
	my $self = shift;
	if ( @_ ) {
		$self->{WORKSPACE_DIR} = shift;
	}
	checkWorkspaceDir($self);
}
sub getWorkspaceDir {
	my $self = shift;
	return $self->{WORKSPACE_DIR};
}
#checkWorkspaceDir($self);
sub checkWorkspaceDir{
	my $self = shift;
	warn "WARNING: Workspace directory is not specified for this device object.\n" if ($self->{WORKSPACE_DIR} eq "");
}

#####################################################################
# Dispatch type functions
#####################################################################
sub setDispatchType {
	my $self = shift;
	if ( @_ ) {
		$self->{DISPATCH_TYPE} = shift;
	}
	else{
		$self->{DISPATCH_TYPE} = $DISPATCH_TYPE_NONE;
	}
	checkDispatchType($self);
}
sub getDispatchType {
	my $self = shift;
	return $self->{DISPATCH_TYPE};
}
#checkDispatchType($self);
sub checkDispatchType{
	my $self = shift;
	warn "WARNING: Dispatch type is not specified for this device object.\n" if ($self->{DISPATCH_TYPE} eq "");
}

#####################################################################
# LocalApplication functions
#####################################################################
sub setLocalApplication {
	my $self = shift;
	if ( @_ ) {
		$self->{LOCAL_APPLICATION} = shift;
	}
	else{
		$self->{LOCAL_APPLICATION} = $APP_SINGLE_RUN;
	}
	checkLocalApplication($self);
}
sub getLocalApplication {
	my $self = shift;
	return $self->{LOCAL_APPLICATION};
}
sub checkLocalApplication{
	my $self = shift;
	warn "WARNING: Application is not specified for this device object.\n" if ($self->{LOCAL_APPLICATION} eq "");
}

#####################################################################
# MaxRun functions
#####################################################################
sub setMaxRuns {
	my $self = shift;
	if ( @_ ) {
		$self->{MAX_RUNS} = shift;
	}
}
sub getMaxRuns {
	my $self = shift;
	return $self->{MAX_RUNS};
}

#####################################################################
# Util factors functions
#####################################################################
sub setUtilizationFactors {
	my $self = shift;
	if ( @_ ) {
		$self->{UTIL_FACTORS} = shift; # <== parameter is a hash reference
	}	
}
sub getUtilizationFactors {
	my $self = shift;
	return $self->{UTIL_FACTORS}; # <== returning hash reference
}

#####################################################################
# DEVICE_SPECS functions
#####################################################################
sub setDeviceSpecs {
	my $self = shift;
	if ( @_ ) {
		$self->{DEVICE_SPECS} = shift; # <== parameter is a hash reference
	}
}
sub getDeviceSpecs {
	my $self = shift;
	return $self->{DEVICE_SPECS}; # <== returning hash reference
}

#
#
#
#
#									NEED TO ADD 
#							UTIL_RESULTS and PERF_RESULTS 
#									functions
#
#
#
#
#
#
#


#####################################################################################
#                          TOOL OPTION FUNCTIONS                                    #
# addOpt(), checkOpt()																#
# deleteToolOpt(), deleteAllToolOpts(), deleteAllOpts()								#
# getToolOpts(tool name), 		getAllOpts()										#
# setToolOpts(tool name, hash), setAllOpts(hash)									#
# printOpts()																		#
#####################################################################################

=begin COMMENTS ##########################################

The tool options are delt as hashes. format
$HASH{TOOL}{OPT} = flag;

=end COMMENTS ############################################
=cut

#####################################################################
# printOpts()
#####################################################################
sub printOpts{
	my $self = shift;
	my $output = "";
	$output .= "\nPrinting device options: \n";
	
	my %TOOL_HASH = %{$self->{TOOL_OPTIONS}};
	my @TOOLS = (keys %TOOL_HASH);
	foreach $TOOL (@TOOLS){
		my %OPT_HASH = %{$TOOL_HASH{$TOOL}};
		my @OPTS = (keys %OPT_HASH);
		foreach $OPT (@OPTS){
			my $FLAG = $OPT_HASH{$OPT};
			$output .= "$TOOL \t $OPT \t $FLAG \n";
		}
	}
	#print $output;
	return $output;
}

#####################################################################
# addOpt($VENDOR, $TOOL, $OPT, $FLAG)
#####################################################################
sub addOpt{
	my $self = shift;
	my ($VENDOR, $TOOL, $OPT, $FLAG) = @_;
	#print "Adding option : $VENDOR, $TOOL, $OPT, $FLAG \n";
	
	my $local_vendor = $self->{VENDOR};
	if($local_vendor =~ m/^$VENDOR$/gi){
		$self->{TOOL_OPTIONS}{$TOOL}{$OPT} = $FLAG;
	}
	else{
		warn "WARNING: Vendor mismatch ($local_vendor =! $VENDOR), ignoring ($TOOL, $OPT, $FLAG) option\n";
	}
}

#####################################################################
# checkOpt($VENDOR, $TOOL, $OPT, $FLAG)
#####################################################################
sub checkOpt{
	my $self = shift;
	my ($VENDOR, $TOOL, $OPT, $FLAG) = @_;
	#print "\nChecking option : $VENDOR, $TOOL, $OPT, $FLAG \n";
	
	my $local_vendor = $self->{VENDOR};
	#print "Local vendor = $local_vendor\n";
	my %TOOL_HASH = %{$self->{TOOL_OPTIONS}};
	#my @tools = keys %TOOL_HASH;
	#print "TOOLS = ".join(" - ",@tools)."\n";
	
	my %OPT_HASH = %{$TOOL_HASH{$TOOL}};
	#my @options = keys %OPT_HASH;
	#print "OPTS = ".join(" - ",@options)."\n";
	
	my $local_flag = $OPT_HASH{$OPT};
	#print "LOCAL FLAG = $local_flag\n";
	
	return "true" if(($local_vendor =~ m/$VENDOR/gi));#and ($local_flag =~ m/^$FLAG$/gi));
	return "false";
}

#####################################################################
# deleteToolOpt($VENDOR, $TOOL, $OPT)
#####################################################################
sub deleteToolOpt{
	my $self = shift;
	my ($VENDOR, $TOOL, $OPT) = @_;
	#print "Deleting option : $VENDOR, $TOOL, $OPT \n";
	
	#my $local_vendor = $self->{VENDOR};
	#my %TOOL_HASH = %{$self->{TOOL_OPTIONS}};
	#my %OPT_HASH = %{$TOOL_HASH{$TOOL}};
	#delete $OPT_HASH{$OPT};
	#$TOOL_HASH{$TOOL} = \%OPT_HASH;
	#$self->{TOOL_OPTIONS} = \%TOOL_HASH;
	
	delete $self->{TOOL_OPTIONS}{$TOOL}{$OPT};
	#return checkOpt($self, $VENDOR, $TOOL, $OPT, $FLAG);
	#not working
}

#####################################################################
# deleteAllToolOpts($VENDOR, $TOOL)
#####################################################################
sub deleteAllToolOpts{
	my $self = shift;
	my ($VENDOR, $TOOL) = @_;
	#print "Deleting all options for tool: $VENDOR, $TOOL \n";
	delete $self->{TOOL_OPTIONS}{$TOOL};
}

#####################################################################
# deleteAllOpts($VENDOR)
#####################################################################
sub deleteAllOpts{
	my $self = shift;
	my ($VENDOR) = @_;
	#print "Deleting all options: $VENDOR \n";
	$self->{TOOL_OPTIONS} = ();
}

#####################################################################
# getToolOpts($VENDOR, $TOOL)
#####################################################################
sub getToolOpts{
	my $self = shift;
	my ($VENDOR, $TOOL) = @_;
	#print "Acquiring tool options: $VENDOR, $TOOL\n";
	
	my %TOOL_HASH = %{$self->{TOOL_OPTIONS}};
	return %{$TOOL_HASH{$TOOL}};
}

#####################################################################
# getAllOpts($VENDOR)
#####################################################################
sub getAllOpts{
	my $self = shift;
	my ($VENDOR) = @_;
	#print "Acquiring all tool options: $VENDOR\n";
	
	return %{$self->{TOOL_OPTIONS}};
}
	
#####################################################################
# setToolOpts($VENDOR, $TOOL, $HASH)
#####################################################################
sub setToolOpts{
	my $self = shift;
	my ($VENDOR, $TOOL, $HASH_REF) = @_;
	#print "Setting tool options: $VENDOR, $TOOL\n";
	
	$self->{TOOL_OPTIONS}{$TOOL} = $HASH_REF;
}

#####################################################################
# setToolOptFlags($VENDOR, $TOOL, $OPTION, $VALUE)
#####################################################################
sub setToolOptFlags{
	my $self = shift;
	my ($VENDOR, $TOOL, $OPTION, $FLAGS) = @_;
	#print "Setting tool options: $VENDOR, $TOOL\n";
	
	$self->{TOOL_OPTIONS}{$TOOL}{$OPTION} = $FLAGS;
}

#####################################################################
# deleteToolOptFlags($VENDOR, $TOOL, $OPTION, $VALUE)
#####################################################################
sub deleteToolOptFlags{
	my $self = shift;
	my ($VENDOR, $TOOL, $OPTION) = @_;
	#print "Setting tool options: $VENDOR, $TOOL\n";
	
	delete $self->{TOOL_OPTIONS}{$TOOL}{$OPTION};
}

#####################################################################
# setAllOpts($VENDOR, $HASH)
#####################################################################
sub setAllOpts{
	my $self = shift;
	my ($VENDOR, $HASH_REF) = @_;
	#print "Setting all tool options: $VENDOR\n";
	
	$self->{TOOL_OPTIONS} = $HASH_REF;
}


#####################################################################
# setPlacementLocation ($location) : cost table or seed values
#####################################################################
sub setPlacementLocation{
	my $self = shift;
	my ($loc) = @_;
	
	my $vendor = &getVendor($self);
	my $family = &getFamily($self);
	
	if (lc($vendor) eq "xilinx"){	
		if($family =~ /virtex5|spartan6|virtex6/i){
			$self->deleteToolOpt($vendor, "MAP", "t");

			$self->addOpt($vendor, "MAP", "t", $loc);
		}
		else{

			$self->deleteToolOpt($vendor, "PAR", "t");
			$self->addOpt($vendor, "PAR", "t", $loc);
		}
	}
	elsif (lc($vendor) eq "altera"){
		$self->deleteToolOpt($vendor, "QUARTUS_FIT", "SEED");
		$self->addOpt($vendor, "QUARTUS_FIT", "SEED", $loc);
	}	
}

#####################################################################
# setAllOpts($strategy)
#####################################################################
sub setOptimizationStrategy{
	my $self = shift;
	my ($strat) = @_;
	
	#print "strategy => $strat"; system( pause );
	
	my $vendor = &getVendor($self);
	if ( $strat =~ /area/i ) {
		if ( $vendor =~ /xilinx/i ) {
			$self->setToolOptFlags($vendor,"XST","opt_mode","area");
			$self->setToolOptFlags($vendor,"MAP","cm","area");
		} elsif ( $vendor =~ /altera/i ) {
			$self->setToolOptFlags($vendor,"QUARTUS_MAP","OPTIMIZE","AREA");
			$self->setToolOptFlags($vendor,"QUARTUS_FIT","PACK_REGISTER","MINIMIZE_AREA");
		}			
	} elsif ( $strat =~ /speed/i ) {
		if ( $vendor =~ /xilinx/i ) {
			$self->setToolOptFlags($vendor,"XST","opt_mode","speed");
			$self->setToolOptFlags($vendor,"MAP","cm","speed");
		} elsif ( $vendor =~ /altera/i ) {
			$self->setToolOptFlags($vendor,"QUARTUS_MAP","OPTIMIZE","SPEED");
			$self->deleteToolOptFlags($vendor,"QUARTUS_FIT","PACK_REGISTER");
		}		
	} elsif ( $strat =~ /balanced/i ) {
		if ( $vendor =~ /xilinx/i ) {
			$self->setToolOptFlags($vendor,"XST","opt_mode","speed");
			$self->setToolOptFlags($vendor,"MAP","cm","area");
		} elsif ( $vendor =~ /altera/i ) {
			$self->setToolOptFlags($vendor,"QUARTUS_MAP","OPTIMIZE","BALANCED");
			$self->setToolOptFlags($vendor,"QUARTUS_FIT","PACK_REGISTER","AUTO");
		}			
	} else {
		print "Invalid optimization strategy!!!\n\n";
		system( pause ); exit;
	}

}





#####################################################################
# Synthesis tool functions
#####################################################################
sub setSynthesisTool {
	my $self = shift;
	if ( @_ ) { #detailed
		if($#_ > 1){
			$self->{SYNTHESIS_TOOLS}->{XILINX} = shift;
			$self->{SYNTHESIS_TOOLS}->{ALTERA} = shift;
			$self->{SYNTHESIS_TOOLS}->{ACTEL} = shift;
		}
		else{ #hash
			#print "sysnthesis tools set hash \n";
			$self->{SYNTHESIS_TOOLS} = shift;
		}
	}
}

sub getSynthesisTool {
	my $self = shift;
	if( lc($_[0]) eq "detailed"){ 
		return 
			$self->{SYNTHESIS_TOOLS}->{XILINX},
			$self->{SYNTHESIS_TOOLS}->{ALTERA},
			$self->{SYNTHESIS_TOOLS}->{ACTEL};
	}
	else { return %{$self->{SYNTHESIS_TOOLS}}; }
}

sub checkSynthesisTool{
	my $self = shift;
	warn "WARNING: Synthesis tool is not specified for this device object.\n" if ($self->{SYNTHESIS_TOOL} eq "");
}


1; #return 1 when including this file along with other scripts.