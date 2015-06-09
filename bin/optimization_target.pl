#___ dynamisch mehrere Bitgroessen evaluieren fuer power area balanced

use strict;
use warnings;

sub read_file {
    my ($filename) = @_;

    open my $in, '<:encoding(UTF-8)', $filename or die "Could not open '$filename' for reading $!";
    local $/ = undef;
    my $all = <$in>;
    close $in;

    return $all;
}

sub write_file {
    my ($filename, $content) = @_;

    open my $out, '>:encoding(UTF-8)', $filename or die "Could not open '$filename' for writing $!";;
    print $out $content;
    close $out;

    return;
}

sub trim_spaces {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

my $SYNTHESIS_OPTION = $ARGV[0];
my $BITSIZE = $ARGV[1];

print "ARG1 = $SYNTHESIS_OPTION :: ARG2 = $BITSIZE\n";

# SETUP OPTIMIZATION_TARGET
# SETUP PROJECT NAME WITH BITSIZE
my $filename = '../config/design.config.txt';
my $design_config = read_file($filename);
my $work_around = $design_config;
  
$design_config =~ s/OPTIMIZATION_TARGET = .*/OPTIMIZATION_TARGET = $SYNTHESIS_OPTION/g;

if ($BITSIZE >= 16){
	$work_around =~ /SOURCE_DIR = <fpga_designs\/(.*)>/;	
	my $name = &trim_spaces($1);	
	my $project_name = "$name\_$BITSIZE";
	$design_config =~ s/PROJECT_NAME = .*/PROJECT_NAME = $project_name/g;
}
write_file($filename, $design_config);

# SETUP BITSIZE IN VHDL FILE
if ($BITSIZE >= 16){
	if($design_config =~ /SOURCE_DIR = <(.*)>/){
		my $SOURCE_DIR = &trim_spaces($1);			
		my $vhd_file_name = "..\/$SOURCE_DIR/top.vhd";		
		my $vhd_file = read_file($vhd_file_name);
		$vhd_file =~ s/.*generic\(.*/  generic(bitLen : integer := $BITSIZE);/g;
		write_file($vhd_file_name, $vhd_file);
	}
}

