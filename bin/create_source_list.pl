#___ erstellt automatisch die source_list.txt, top.vhd muss immer existent sein und das topmodul darstellen
use File::Copy;
use Storable;
use File::Path qw(remove_tree rmtree);

use strict;
use warnings;

my $filename = '..\\config\\design.config.txt';
my $data = read_file($filename);

if($data =~ /SOURCE_DIR = <(.*)>/){
	my $PROJECT_NAME = &trim_spaces($1);			
	warn "PROJECT_NAME $PROJECT_NAME\n";
	
	my $directory = "..\/$PROJECT_NAME";
	
	warn "directory = $directory";
	
	opendir ( DIR, $directory ) or die "Can't open the current directory: $!\n"; 
	my $source_list_present = 0;
    while (my $file = readdir(DIR)) {
        #print "$file\n";
		
		if ($file =~ /source_list.txt/) {
			$source_list_present = 1;
		}	
    }
	closedir(DIR);	
	
	if($source_list_present == 1){
		warn "source list is already present. Doing nothing";
	}
	else {
		warn "source list needs to be created";
		
		opendir (DIR, $directory ) or die "Can't open the current directory: $!\n"; 
		open(my $content_to_write, '>>', "$directory/source_list.txt") or die;
		while (my $file = readdir(DIR)) {
			if ($file =~ /.*.vhd/) {
				if(!($file =~ "top.vhd")) {
					#print "$file\n";
					say $content_to_write "$file";
				}
			}	
		}
		say $content_to_write "top.vhd";
		
		closedir(DIR);	
		close $content_to_write;
	}
}

sub read_file {
    my ($filename) = @_;

    open my $in, '<:encoding(UTF-8)', $filename or die "Could not open '$filename' for reading $!";
    local $/ = undef;
    my $all = <$in>;
    close $in;

    return $all;
}

sub trim_spaces {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
