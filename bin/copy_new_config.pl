
use strict;
use warnings;

use File::Copy qw(copy);
my $design = $ARGV[0];

my $src = "../config/$design";
my $dst = "../config/design.config.txt";

print "src=$src\n";
print "dst=$dst\n";

copy $src, $dst;
