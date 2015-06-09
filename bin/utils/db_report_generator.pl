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
# report_generator.pl 
# v0.1
#
# Last Updated   :  
# Purpose 	: report generator 
# Usage		: report_generator.pl $1
#		$1 = workspace directory (full path only)
#
#####################################################################

use Cwd;
use File::Path;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );	

$CONSTANT_FILE_NAME = "constants.pl"; $BIN_DIR_NAME = "bin";		$REGEX_FILE_NAME = "regex.pl";
$UTILS_DIR_NAME = "utils"; 		$CONFIG_DIR = "config"; 
$ROOT_DIR = cwd; $ROOT_DIR =~ s/\/$BIN_DIR_NAME\/$UTILS_DIR_NAME//;

$report_dir = "$ROOT_DIR\/$BIN_DIR_NAME";
$report_dir =~ s/\//\\/g;
$pause = "on";

require "$ROOT_DIR/$BIN_DIR_NAME/regex.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/extract_old.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/constants.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/report_core.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/report_conf.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/report_extract.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/support.pl";


## Debug function
sub print_prj {
	my %project = %{shift()};
	foreach $vendor	(keys %project ) {
		foreach $family (keys %{$project{$vendor}} ) {
			foreach $gid (keys %{$project{$vendor}{$family}} ) {
				foreach $device (keys %{$project{$vendor}{$family}{$gid}} ) {				
					if ( $device =~ /best_match/i ) { next; }
					foreach $run(keys %{$project{$vendor}{$family}{$gid}{$device}} ) {
						print "$vendor -> $family -> $gid -> $device -> $run :\n";
						foreach $f (sort {$a cmp $b}  keys %{$project{$vendor}{$family}{$gid}{$device}{$run}} ) {
							print "$f\n";
						}
					}
				}
			}
		}
	}
	exit;
}

sub pa {
	my @abc = @_;
	my $i = 1;
	print "\n======\n";
	foreach $val ( @abc ) {
		print "$i >> $val\n";
		$i = $i + 1;
	}
	print "======\n\n";
	system( pause );
}

#########################
## Get CSV of a record ##
#########################
sub get_csv {
	# GET HEADER FOR CSV DATA	
	my %project = %{shift()};
	my $vendor = shift();
	my $family = shift();
	my $gid = shift();
	my $device = shift();
	my $run = shift();
	my $mode = shift();
	
	# print "vendor - $vendor\n";
	# print "family - $family\n";
	# print "device - $device\n";
	# print "run - $run\n";
	# system( pause );

	my (@list, @temp_list);
	@temp_list = sort {$a cmp $b} keys %{$project{$vendor}{$family}{$gid}{$device}{$run}};
	foreach $header ( @temp_list ) {
		if ( $header =~ /disp/i ) { next; }
		push(@list, $header);
	}
	
	if ( $#list < 0 ) { return; }
	if ( $mode =~ /header/i ) {
		my $vendor_header = "GENERIC,VENDOR,FAMILY,DEVICE,";		
		my $temp = join ( ',',@list) ;
		#remove RUNNO from list
		$temp =~ s/RUNNO,//;
		#remove disp from list
		$temp =~ s/disp,//;
		$vendor_header .= "$temp\n";
		return $vendor_header;
	} elsif ( $mode =~ /data/i ) {
		# WRITING DATA
		my $str = "";
		$str .= "$project{$vendor}{$family}{$gid}{generic},$vendor,$family,$device";
		foreach my $field ( @list ) {
			if ( $field =~ /disp/i ) { next; }
			my $writeval = $project{$vendor}{$family}{$gid}{$device}{$run}{$field};
			$writeval = &trim_spaces($writeval);
			if ($writeval =~ /default/i ) { $writeval = ""; }			
			$str .= ",$writeval";
		}
		$str .= "\n";
		return $str;
	} else {
		print "Invalid mode for get_csv()\n"; system( pause ); return;
	}
}

###############################
## Generate CSV for database ##
###############################
sub generate_run_zip {
	use File::Copy;
	
	my $uid = shift();
	my $vendor = shift();
	my $src = shift();
	my $dest = shift();
	my $syntoolname = shift();
	my $imptoolname = shift();
	
	### create vendor folder if not exist
	unless (-d "$dest\\$vendor") {
		mkdir ("$dest\\$vendor");
	}	
	### Create the src directory for inserting the sources
	unless (-d "$dest\\$vendor\\src") {
		mkdir ("$dest\\$vendor\\src");
	}
	### Create metadata file
	open(METADATA,">$dest\\metadata.txt");
		print METADATA "athena_version: $ATHENA_VERSION";
	close(METADATA);
#print"Finished creating metadata.txt\n";
#system( pause );
	### 
	
	open(LOG,"$src\\athena_log.txt");
		my @log_data = <LOG>;
	close(LOG);
	my $cmd = "";

	open(BAT_SCRIPT,">$dest\\$vendor\\run.bat");
	open(SH_SCRIPT,">$dest\\$vendor\\run.sh");
	binmode( SH_SCRIPT );
	my $shell_script = "";
	foreach $line (@log_data) {	
		if ($line =~ m/Executing: (.*)/i) { 					
			my $cmdline = $1;
			$cmdline =~ s{.*/}{}; $cmdline =~ s{.*\\}{};
			if ( $cmdline =~ m/([\w.\d]+) (.*)/i ) {
				my $prog = $1;
				my $opt = $2;		
				if ( $prog =~ m/(.*).exe/i ) {
					print BAT_SCRIPT "${1}.exe $opt\n";
					print SH_SCRIPT "echo \"Executing $1 ...\"\n";
					print SH_SCRIPT "$1 $opt\n";						
					#$shell_script .= "echo \"Executing $1 ...\"\n";
					#$shell_script .= "$1 $opt\n";	
				} else {
					print BAT_SCRIPT "${prog}.exe $opt\n";
					print SH_SCRIPT "echo \"Executing $opt ...\"\n";
					print SH_SCRIPT "$prog $opt\n";					
					#$shell_script .= "echo \"Executing $opt ...\"\n";
					#$shell_script .= "$prog $opt\n";
				}
			}		
		}
	}
	
	close(BAT_SCRIPT);
	close(SH_SCRIPT);
	
	
	
	my @files = ();
	#####################################################################
	### Create the .bat and .sh script from the athena_log.txt
	### NOTE : This method is easier to recreate the exact command line 
	###        used to create the design than populate it from the hash.
	#####################################################################	
	

	my @files = ();
	
	### Xilinx
	if ( $vendor =~ m/xilinx/i ) {
		### Copy the files
		opendir(DIR, $src) || die("Cannot open directory");
		@files = readdir(DIR);		
		@files = grep(/\.xcf$|\.ucf$|\.scr$|\.prj$/,@files);
		closedir(DIR);	
		
		### Does not find any project file, try to extract from a zip
		if ( $file[0] eq "" ) {		
			if ( -e "$src\\zipped.zip" ) {
				my $zip = Archive::Zip->new("$src\\zipped.zip");
				foreach my $member ($zip->members)
				{
					next if $member->isDirectory;
					my $extractName;
					$extractName = $member->fileName;
					$extractName =~ s{.*/}{}; $extractName =~ s{.*\\}{};
					#print "$src/$extractName\n";
					$member->extractToFileNamed("$src/$extractName");
				}
				### Try to grep the file again
				opendir(DIR, $src) || die("Cannot open directory");
				@files = readdir(DIR);
				@files = grep(/\.xcf$|\.ucf$|\.scr$|\.prj$/,@files);
				closedir(DIR);
			}
		}
				
		
		my $prjfile = "";
		foreach $file (@files) {			
			&copy("$src\\$file","$dest\\$vendor\\$file") or die "Copy failed: $!";
			if ( $file =~ m/(.*\.prj)/i) {
				$prjfile = $1;
			}
		}
		
		### Modifying the .prj file to alter the source location to /src
		open(PRJFILE,"$dest\\$vendor\\$prjfile");
			my @original_data = <PRJFILE>;		
		close(PRJFILE);
		unlink( "$dest\\$vendor\\$prjfile" );	
		open(PRJFILE,">$dest\\$vendor\\$prjfile");
			foreach $line ( @original_data ) {				
				if ( $line =~ m/(.*)\".*[\/\\]([\w-]+.v[hdl]*)\"/i) {
					print PRJFILE "$1\"src\/$2\"\n";
				} else { 
					print PRJFILE "$line"; 
				}
			}
		close(PRJFILE);		
		
		### Create Readme file		
open(README_TEMP,">$dest\\$vendor\\readme_temp.txt");	
		
print README_TEMP << 'END_OF_MESSAGE';
readme.txt
----------

This folder contains all files necessary to replicate
results stored in the file results.html,
under the assumption that
 1. source files are available to the user,
 2. synthesis and implementation tools and their versions
    installed on the user's machine are identical to those 
    used to generate results.
END_OF_MESSAGE

print README_TEMP "
	The following tools are used to generate this result:
	Synthesis tool 		: $syntoolname
	Implementation tool : $imptoolname\n";

print README_TEMP << 'END_OF_MESSAGE';
----------------------------------------------------------------------------
Steps
-----

In order to repeat the synthesis and implementation run, leading to replicating 
the results, the user should follow the steps given below:

1. Make sure that the FPGA tools are properly installed and set up,
   and the proper versions of these tools are activated.

   In particular, the value of the environmental variable 'PATH' 
   should include the location at which the development tool is installed, 
   e.g., C:\Xilinx\12.3\ISE_DS\ISE\bin\nt64 for Windows, or
         /opt/Xilinx/12.3/ISE_DS/ISE/bin/lin64 for Linux.

2. Assure that the location and the names of source files
   match those specified in the file <ProjectName>.prj.

   This task can be accomplished in two ways:
   a) copy source files to the default location, 
      defined as the subfolder 'src' of the current folder.
    or
   b) open the file <ProjectName>.prj using your favorite text editor
      and replace all instantiations of the string "src/" 
      with the path to your source code folder.
      You can use either an absolute path or a path relative to the current
      folder.

3. Start the top-level script
       run.bat - for Windows
       run.sh - for Linux.

----------------------------------------------------------------------------
Files
-----

Below are the names and meanings of all files available
in this folder:

run.bat - top-level script for Windows
          required to start synthesis and implementation.

run.sh  - top-level script for Linux
          required to start synthesis and implementation.

results.html - HTML file with the detailed results to be replicated,
          and information about the corresponding design.
          This file is created automatically at the time of downloading 
          results to the ATHENa database at
            https://cryptography.gmu.edu/athenadb
          This file does not exist before the results are downloaded.

<ProjectName>.prj - Xilinx project file. 
          This file tells Xilinx tools about
              - names and location of source files,
              - hardware description language used,
              - working library (typically "work").

<ProjectName>.scr - Xilinx XST script file.
          This file contains options of Xilinx XST used for synthesis.

synth.xcf - constraint file for synthesis.
           If this file is empty, the default constraints will be used.

impl.ucf - constraint file for implementation.
           If this file is empty, the default constraints will be used.

Please refer to 'Xilinx XST User Guide' and 'Xilinx Constraints Guide' 
available at http://www.xilinx.com/support/documentation/
for more details about these files.
Please look for versions of these guides matching versions
of the development tools used to generate results.

============================================================================
The zip file used to obtain this folder was generated 
using db_report_generator, which is a part of 
Automated Tool for Hardware EvaluatioN (ATHENa).

For information about ATHENa please see:
   http://cryptography.gmu.edu/athena/
============================================================================
END_OF_MESSAGE

close(README_TEMP);
		
		
	} elsif ( $vendor =~ m/altera/i ) {
		### Copy the files
		opendir(DIR, $src) || die("Cannot open directory");
		@files = readdir(DIR);		
		@files = grep(/\.qsf$/,@files);
		closedir(DIR);
		
		### Does not find any project file, try to extract from a zip
		if ( $file[0] eq "" ) {
			if ( -e "$src\\zipped.zip" ) {
				my $zip = Archive::Zip->new("$src\\zipped.zip");
				foreach my $member ($zip->members)
				{
					next if $member->isDirectory;
					my $extractName;
					$extractName = $member->fileName;
					$extractName =~ s{.*/}{}; $extractName =~ s{.*\\}{};
					$member->extractToFileNamed("$src\\$extractName");
				}
				### Try to grep the file again
				opendir(DIR, $src) || die("Cannot open directory");
				@files = readdir(DIR);									
				@files = grep(/\.qsf$/,@files);					
				closedir(DIR);
			}
		}
		
		### Modifying the .qsf file to alter the source location to /src
		my $prjfile = $files[0];
		open(PRJFILE,"$src\\$prjfile");
			my @original_data = <PRJFILE>;		
		close(PRJFILE);
		open(PRJFILE,">$dest\\$vendor\\$prjfile");
			foreach $line ( @original_data ) {				
				if ( $line =~ m/(.*)\".*[\/\\]([\w-]+.v[hdl]*)\"/i) {
					print PRJFILE "$1\"src\/$2\"\n";
				} else { 
					print PRJFILE "$line"; 
				}
			}
		close(PRJFILE);
		
### Create Readme file		
open(README_TEMP,">$dest\\$vendor\\readme_temp.txt");	
		
print README_TEMP << 'END_OF_MESSAGE';
readme.txt
----------

This folder contains all files necessary to replicate
results stored in the file results.html,
under the assumption that
 1. source files are available to the user,
 2. synthesis and implementation tools and their versions
   installed on the user's machine are identical to those 
   used to generate results.
END_OF_MESSAGE

print README_TEMP "
	The following tools are used to generate this result:
	Synthesis tool 		: $syntoolname
	Implementation tool : $imptoolname\n";

print README_TEMP << 'END_OF_MESSAGE';
----------------------------------------------------------------------------
Steps
-----

In order to repeat the synthesis and implementation run, leading to replicating 
the results, the user should follow the given below steps:

1. Make sure that the FPGA tools are properly installed and set up,
   and the proper versions of these tools are activated.

   In particular, the value of the environmental variable 'PATH' 
   should include the location at which the development tool is installed, 
   e.g., C:\altera\10.0\quartus\bin64 for Windows, or
         /opt/altera/10.0/quartus/bin64 for Linux.

2. Assure that the location and the names of source files
   match those specified in the file <ProjectName>.qsf.

   This task can be accomplished in two ways:
   a) copy source files to the default location, 
      defined as the subfolder 'src' of the current folder.
    or
   b) open the file <ProjectName>.qsf using your favorite text editor,
      and replace all instantiations of the string "src/" 
      with the path to your source code folder.
      You can use either an absolute path or a path relative to the current
      folder.

3. Start the top-level script
       run.bat - for Windows
       run.sh - for Linux.

----------------------------------------------------------------------------
Files
-----

Below are the names and meanings of all files available
in this folder:

run.bat - top-level script for Windows
          required to start synthesis and implementation.

run.sh  - top-level script for Linux
          required to start synthesis and implementation.

results.html - HTML file with the detailed results to be replicated,
          and information about the corresponding design.
          This file is created automatically at the time of downloading 
          results to the ATHENa database at
            https://cryptography.gmu.edu/athenadb
          This file does not exist before the results are downloaded.

<ProjectName>.qsf - Altera Quartus II Settings File. 
          This file tells Altera tools about
           - names and location of source files,
           - hardware description language used,
           - top level entity,
           - target family and device,
           - options of Quartus II used,
           - synthesis and implementation constraints, 
          etc.

Please refer to "Quartus II Settings File Reference Manual",
available at http://www.altera.com/literature/manual/mnl_qsf_reference.pdf ,
for more details about the .qsf file.

============================================================================
The zip file used to obtain this folder was generated 
using db_report_generator, which is a part of 
Automated Tool for Hardware EvaluatioN (ATHENa).

For information about ATHENa please see:
   http://cryptography.gmu.edu/athena/
============================================================================
END_OF_MESSAGE
close(README_TEMP);		
	}
	
	### 
	### Convert README file to windows format
	
	open(README_TEMP,"$dest\\$vendor\\readme_temp.txt");
	open(README,">$dest\\$vendor\\readme.txt");
	while(<README_TEMP>) {
		s/\n/\r\n/;
		print README $_;
	}
	close(README_TEMP);
	close(README);
	unlink("$dest\\$vendor\\readme_temp.txt");
	
	#####################################################################
	### Zip the files according to UID
	#####################################################################	
	my $current_dir = cwd;	
	chdir("$dest\\$vendor");	
	my $zip = Archive::Zip->new();
	### Add script files and src directory to list of file to be zipped
	push(@files,"src","run.sh","run.bat","readme.txt");
	foreach $file (@files) {
		if ( -e $file) {
			if ( -d $file ) {
				$zip->addTree( ".//${file}", "${file}");
			} else {
				$zip->addFile( $file, $file, 9 );
			}
		}
	}
	die 'write error.' if ( $zip->writeToFileNamed("${uid}.zip") != AZ_OK );
			
	### Remove the files after creation
	foreach $file (@files) {
		if ( -d $file ) {
			&rmtree($file);			
		} elsif ( -f $file ) {
			unlink $file;
		}		
	}
	chdir($current_dir);
}

###############################
## Generate CSV for database ##
###############################
sub gen_db_csv {
	my %project = %{shift()};
	my %criterian = %{shift()};
	my $query_mode = shift();
	my $db_zip = shift();
	my $path = shift();
	
    $result_dir = "$path\\db";
	mkdir($result_dir);
	chdir($result_dir);
    
	## change query_mode name
	if ( $query_mode =~ /overall/i ) {
		$query_mode = "best_overall";
	} elsif ( $query_mode =~ /generic/i ) {
		$query_mode = "best_per_generic";
	} elsif ( $query_mode =~ /device/i ) {
		$query_mode = "best_per_device";
	}
	
	my %best =	%{ &extract_best_result( \%project, "db" ) };
	my @critarr = ();
	my @dest_folders = ();
	foreach $crit ( keys %criterian ) {		
		if ( $criterian{$crit} =~ /y/i ) { push(@critarr, $crit); }
	}
		
	if ( scalar@critarr < 1 ) { 
		print "\n\nWarning!!! No criterian(s) selected. Please select a criteria or change query mode to NONE first.\n\n";
		if ( $pause =~ m/on/i ) {
            system( pause );
        }
		return;
	}

    if ( $query_mode =~ /none/i ) {
        print "\n\nWarning!!! No query mode selected. Please select a query mode.\n\n";
        if ( $pause =~ m/on/i ) {
            system( pause );
        }
		return;
    }
	############################
	### ask for verification ###
	############################
	if ( $query_mode =~ /none/i ) {
		print "\n\tWarning!!! You have selected NO QUERY mode.\n";
		print "\tThis will generate zip file(s)\n";
		print "\tto all the selected data :: \n\n";	
		&view_data_selection( \%project, "limit", "off" );
	} else {
		print "\nATHENa DB entry file for the following result(s) will be generated ::\n\n";
		#######################
		### Printing Result ###
		#######################
		my %best_result = %{ &print_best_result( \%project, \%best, \@critarr, $query_mode) };
		foreach $crit ( keys %best_result ) {
			print "$best_result{$crit}\n";
		}
	}	
    
    if ( $pause =~ m/on/i ) {
        while(1) {
            print "\nWould you like to proceed [y/n]? ";
            $choice = <STDIN>; chop($choice);
            if ( $choice =~ m/^y$/i ) {
                last;
            } elsif ( $choice =~ m/^n$/i ) {
                return;
            } else {
                print "Invalid choice. Please try again.\n\n";				
            }
        }
    }

	####################
	### query = none ###
	####################
	if ( $query_mode =~ /none/i ) {
		my $dest = "(${query_mode})";
		foreach my $vendor (keys %project ) {  
			if ($mode =~ /db/i) {
				if ( $vendor =~ /disp/i) { next; } 
				if ( $project{$vendor}{disp} =~ /n/i ) { next; }			
			}		
			#########################					
			# checking for valid folder
			if ( not -e "$dest" ) {	mkdir( "$dest" ); }		
			
			# checking for existing file		
			if ( -e "$dest\\${vendor}_athena_result.csv" ) {
				my $skip;
				while(1) {
					print "\n\nWarning! : File \"$dest\\athena_result.csv\" already exists.\nWould you like to overwrite [y/n]?\n";
					print "Note: Selecting 'n' will skip the population of CSV file with query '$query_mode' mode for $vendor.\n::";
					$choice = <STDIN>; chop($choice);
					if ( $choice =~ /y/i ) {
						$skip = 0; last;
					} elsif ( $choice =~ /n/i ) {
						$skip = 1; last;
					} else {
						print "Invalid input. Please try again.\n";
					}
				}
			}
			if ( $skip == 1 ) { next; }
			open(CSV, ">$dest\\${vendor}_athena_result.csv") || die("Could not create file!");
			#########################
			my $header = 1;
			foreach my $family ( keys %{$project{$vendor}} ) {
				if ($mode =~ /db/i) {
					if ($family =~ /disp/i) { next; } 
					if ( $project{$vendor}{$family}{disp} =~ /n/i ) { next; }
				}
				foreach my $gid ( keys %{$project{$vendor}{$family}} ) {
					if ($mode =~ /db/i) {
						if ($gid =~ /disp/i) { next; } 
						if ( $project{$vendor}{$family}{$gid}{disp} =~ /n/i ) { next; }	
					}	
					foreach my $device ( keys %{$project{$vendor}{$family}{$gid}} ) {
						if ($device =~ /generic|all/i ) { next; }
						if ($mode =~ /db/i) {
							if ( $device =~ /disp/i) { next; } 
							if ( $project{$vendor}{$family}{$gid}{$device}{disp} =~ /n/i ) { next; }			
						}			
						foreach my $run ( keys %{$project{$vendor}{$family}{$gid}{$device}} ) {
							if ($mode =~ /db/i) {
								if ( $run =~ /disp/i) { next; } 
								if ( $project{$vendor}{$family}{$gid}{$device}{$run}{disp} =~ /n/i ) { next; }			
							}
							if ( $header == 1 ) {
								$csv = &get_csv( \%project, $vendor, $family, $gid, $device,$run, "header" );
								print CSV "$csv";
								$header = 0;
							}
							$csv = &get_csv( \%project, $vendor, $family, $gid, $device,$run, "data" );
							print CSV "$csv";
						}
					}
				}
			}
			close ( CSV );
		}
		push (@dest_folders,$dest);
		if ( $db_zip !~ /zip/i ) {
			return;
		} else {
			goto DB_ZIP;
		}
	}

	#########################
	### Other query modes ###
	#########################
	my $csv;
	foreach $crit ( @critarr ) {		
		my $dest = "(${query_mode})_${crit}";
		foreach $vendor ( keys %{$best{$crit}} ) {		
			my $uid = 1;
			#########################
			if ( not -e "$dest" ) {	mkdir( "$dest" ); }					
			
			open(CSV, ">$dest\\${vendor}_athena_result.csv") || die("Could not create file!");
			#########################
			my $header = 1;
			foreach  $family ( keys %{$best{$crit}{$vendor}} ) {				
				if ( $query_mode =~ /best_overall/i ) {
					my $device_name = $best{$crit}{$vendor}{$family}{all}{device};
					my $run_name =  $best{$crit}{$vendor}{$family}{all}{run};
					my $gid_id =  $best{$crit}{$vendor}{$family}{all}{gid};
					my $gid_value = $project{$vendor}{$family}{$gid_id}{generic};
					if ( $header == 1 ) {
						$csv = &get_csv( \%project, $vendor, $family, $gid_id, $device_name,$run_name, "header" );
						print CSV "UID,$csv";
						$header = 0;
					}
					$csv = &get_csv( \%project, $vendor, $family, $gid_id, $device_name,$run_name, "data" );
					print CSV "$uid,$csv";
					$uid = $uid + 1;
					next;
				}												
				foreach $gid ( sort keys %{$best{$crit}{$vendor}{$family}} ) {					
					if ( $gid =~ /^all$/i ) { next; }
					my $gid_value = $project{$vendor}{$family}{$gid}{generic};
					if ( $query_mode =~ /^best_per_generic$/i ) {
						my $device_name = $best{$crit}{$vendor}{$family}{$gid}{all}{device};
						my $run_name =  $best{$crit}{$vendor}{$family}{$gid}{all}{run};
						if ( $header == 1 ) {
							$csv = &get_csv( \%project, $vendor, $family, $gid, $device_name,$run_name, "header" );
							print CSV "UID,$csv";
							$header = 0;
						}
						$csv = &get_csv( \%project, $vendor, $family, $gid, $device_name,$run_name, "data" );
						print CSV "$uid,$csv";
						$uid = $uid + 1;
						next;
					}						
					my @devices = sort {$a cmp $b}   keys %{$best{$crit}{$vendor}{$family}{$gid}};
					foreach $device ( @devices ) {
						if ( $device =~ /^disp$|^generic$|^best_match$|^all$/i ){ next; }								
						my $run_name =  $best{$crit}{$vendor}{$family}{$gid}{$device}{run};
						if ( $header == 1 ) {
							$csv = &get_csv( \%project, $vendor, $family, $gid, $device,$run_name, "header" );
							print CSV "UID,$csv";
							$header = 0;
						}
						$csv = &get_csv( \%project, $vendor, $family, $gid, $device,$run_name, "data" );
						print CSV "$uid,$csv";
						$uid = $uid + 1;
						next;
					}
				}
			}
			close(CSV);		
			#########################			
		}
		push (@dest_folders,$dest);
	}
	### Post-processing the csv file to generate the zip file
	DB_ZIP:
	if ($db_zip =~ m/^zip$/i) {
		# print "\n==Zipping==\n\n";		
		foreach $folder (@dest_folders) {
			#print "==$folder==\n";	
			#print "$path\n";
			
			my @csvs = get_file_type("$folder","csv");
			
			### Reread the csv files for data
			my @warning_msg = ();
			foreach $csv ( @csvs) {											
				### Read csv file into a hash with UID for each hash field
				### --> $hash{$UID}{$field} = $data
				my %new_data; my @csv_data = ();	
				if ( -e "$folder\\$csv" ) {					
					open(CSVFILE, "$folder\\$csv"); @csv_data = <CSVFILE>;				
				} else { #skip a vendor if no csv file was generated
					print "Opening CSV file failed, skipping --> $folder\\$csv\n"; 
                    if ( $pause =~ m/on/i ) {
                        system( pause );
                    }
					next;
				}
				my @headers = split(",",$csv_data[0]);
				for $line_no (1..$#csv_data ) {
					#print "Line number --> $line_no\n";
					my @line_data = split(",",$csv_data[$line_no]);
					my $cnt = 1;
					for $header_no (1..$#headers ) {
						$new_data{$line_data[0]}{$headers[$header_no]} = $line_data[$cnt];
						$cnt = $cnt + 1;
					}
				}
				close ( CSVFILE );
				
				
				### get location of data for each field
				foreach $uid ( keys %new_data) {					
					my $vendor = $new_data{$uid}{VENDOR};
					my $family = $new_data{$uid}{FAMILY};					
					### determine generic folder
					my $generic_value = $new_data{$uid}{GENERIC};
					my @families = &getdirs("$path//$vendor");
					my $generic;		
					foreach $fam ( @families ) {
						my @fam_name = split("_",$fam);
						if ( $family eq "$fam_name[0]" ) {
							#print "opening file --> $path\\$vendor\\$fam\\generics.txt\n"; system( pause );
							my $value;
							if ( -e "$path\\$vendor\\$fam\\generics.txt" ) {
								open(GENERIC_FILE,"$path\\$vendor\\$fam\\generics.txt");
								$value = join("",<GENERIC_FILE>); close(GENERIC_FILE);
							} else {
								print "Error!! Cannot find generic file in --> $path\\$vendor\\$fam\\generics.txt.\n"; 
                                if ( $pause =~ m/on/i ) {
                                    system( pause );
                                }
							}													
							
							# print "$value -- $generic_value\n";
							if ( $value =~ m/^$generic_value$/i ) {
								$generic = $fam_name[1];
								last;
							}
						}						
					}
					my $device = $new_data{$uid}{DEVICE};
					my $run = $new_data{$uid}{RUN_NO};			
					my $src = "$path\\$vendor\\${family}_${generic}\\$device\\run_${run}";
					my $syntoolname = "$new_data{$uid}{SYN_TOOL} - $new_data{$uid}{SYN_TOOL_VERSION}";
					my $imptoolname = "$new_data{$uid}{IMP_TOOL} - $new_data{$uid}{IMP_TOOL_VERSION}";										
					
					### At this point, we have source folder
					if ( -d $src ) {						
						#print "Genering run zip -->\nUID:\t$uid\nVendor:\t$vendor\nSrcLocation:\t$src\nCriterian:\t$folder\n\n"; system( pause ) ;						
						&generate_run_zip($uid,$vendor,$src,$folder, $syntoolname, $imptoolname);
					} else {
						push(@warning_msg, "Warning!!! Cannot find destination path at $src.");
					}															
				}
				if ( $#warning_msg > -1 ) {						
					print join("\n",@warning_msg); system( pause );
				}
			}
		
			### Zip the whole thing and remove them		
			
			my $current_dir = cwd;
			chdir ("$current_dir\\$folder");
			opendir ( DIR, "$current_dir\\$folder" ) or die "Can't open the current directory: $current_dir\\$folder\n"; 
				my @files = readdir(DIR);
			closedir(DIR);	
			my $zip = Archive::Zip->new();
			foreach $file ( @files ) {			
				if ( $file !~ /^\.$|^\.\.$/i)  {
					if ( -d $file ) {
						$zip->addTree( ".//${file}", "${file}");
					} else {
						$zip->addFile( $file, $file, 9 );
					}
				}
			}
			die 'write error.' if ( $zip->writeToFileNamed("$current_dir\\${folder}.ATHENa.zip") != AZ_OK );			
			chdir ($current_dir);			
			### remove the created folder
			&rmtree("$current_dir\\$folder");
		}
	}
	print "\nATHENa DB entry file generated. You can locate the file(s) at -->\n";
	print cwd . "\n\n";
	if ( $pause =~ m/on/i ) {
        system( pause );
    }
}

##############################
## View best queried result ##
##############################
sub view_result {
	my %project = %{shift()};
	my $query_mode = shift();
	my $display_mode = shift();
	my %criterian = %{shift()};
	
	### change query_mode name
	if ( $query_mode =~ /overall/i ) {
		$query_mode = "best_overall";
	} elsif ( $query_mode =~ /generic/i ) {
		$query_mode = "best_per_generic";
	} elsif ( $query_mode =~ /device/i ) {
		$query_mode = "best_per_device";
	} else {
		print "Invalid query mode <$query_mode>.\n"; system( pause );
		return;
	}

	
	my @crit = ();
	if ( $display_mode =~ m/all/i ) {
		@crit = ("AREA", "THROUGHPUT", "THROUGHPUT_AREA", "LATENCY", "LATENCY_AREA" );
	} else {
		foreach $critt ( keys %criterian ) {		
			if ( $criterian{$critt} =~ /y/i ) { push(@crit, $critt); }
		}
	}
	my %best_data =	%{ &extract_best_result( \%project, "db" ) };
	my %best_result = %{ &print_best_result( \%project, \%best_data, \@crit, $query_mode, "db") };

	foreach $crit ( keys %best_result ) {
		print "$best_result{$crit}\n";
	}
	system ( pause );
}

##############################
## Check for data selection ##
##############################

sub view_data_selection {
	my %project = %{shift()};
	my $mode = shift();		# show all
	my $nopause = shift();
	
	my $valid = 0;
	foreach $vendor (keys %project) {
		if ($vendor =~ /disp/i ) { next; }
		if ( $project{$vendor}{disp} =~ /y/i ) { $valid = 1; last; }
	}
	if ( $valid == 0 ) { print "\n No data selected!\n"; } else { print "\n"; }
	foreach $vendor (keys %project) {
		if ($vendor =~ /disp/i ) { next; }
		
		print "\n$vendor\n";
		my @sorted_family = sort {$a cmp $b} keys %{$project{$vendor}};
		foreach $family ( @sorted_family ) {
			if ($family =~ /disp/i ) { next; }
			if ( $project{$vendor}{$family}{disp} =~ /y/i ) { 
				print "  $family\n"; 
			} else { 
				if ( $mode =~ /all/i ) {
					print "  ($family)\n";
				} else { next; }
			}
			my @sorted_gid = sort keys %{$project{$vendor}{$family}};
			foreach $gid ( @sorted_gid ) {
				#print "gid --> $gid\n";
				if ( $gid =~ /disp/i ) { next; }				
				if ( $project{$vendor}{$family}{$gid}{disp} =~ /y/i ) { 
					print "    $project{$vendor}{$family}{$gid}{generic}\n"; 
				} else { 					
					if ( $mode =~ /all/i ) {
						print "    ($project{$vendor}{$family}{$gid}{generic})\n";
					} else { next; }
				}						
				my @sorted_device = sort {$a cmp $b} keys %{$project{$vendor}{$family}{$gid}};
				foreach $device ( @sorted_device ) {
					if ($device =~ /disp|best_match|generic/i ) { next; }
					if ( $project{$vendor}{$family}{$gid}{$device}{disp} =~ /y/i ) { 
						printf ("      %-20s\t{ ", $device); 
					} else { 					
						if ( $mode =~ /all/i ) {
							my $temp = $device;
							$temp =~ s/${temp}/(${temp})/i;
							printf ("      %-20s\t{ ", $temp);
						} else { next; }
					}									
					
					my @run_name = keys %{$project{$vendor}{$family}{$gid}{$device}};
					my @run_list = ();
					# get all the numbers in order 
					foreach $run (@run_name) {
						if ( $run =~ /disp/i ) { next; }
						$run =~ s/run_//i;
						push(@run_list,$run);
					}
					my @sorted_run = sort {$a <=> $b } @run_list;
					foreach $run (@sorted_run) {
						my $field = "run_$run";
						if ( $project{$vendor}{$family}{$gid}{$device}{$field}{disp} =~ /y/i ) {
							print "$run ";
						} else {
							if ($mode =~ /all/i ) {
								print "($run) ";
							}
						}
					}										
					print "}\n";
				}
			}
		}
	}
	if ( $mode =~ m/all/i ) {
		print "\n\nNote:\tParentheses denote data that is not being queried.\n";
		print "\tTo remove data from being queried, press 'q' to modify data in query.\n";
	}
	if ( $nopause !~ /off/i) {
		system( pause );
	}
}

##############################
# This function will convert all the display mode of each data field to "NO" if its sub-hiearchy is turned off
##############################

sub check_display_value {
	my %project = %{shift()};
	my $cleaning_status;
	do {
		$cleaning_status = 0;
		foreach $vendor (keys %project) {		
			if ( $vendor =~ /disp/i ) { next; }		
			if ( $project{$vendor}{disp} =~ /n/i ) { next; };
			my $lvl1 = "n";
			foreach $family (keys %{$project{$vendor}}) {
				if ( $family =~ /disp/i ) { next; }
				if ( $project{$vendor}{$family}{disp} =~ /n/i ) { next; };
				$lvl1 = "y";
				my $lvl2 = "n";
				foreach $gid (keys %{$project{$vendor}{$family}}) {
					if ( $gid =~ /disp/i ) {next;}
					if ( $project{$vendor}{$family}{$gid}{disp} =~ /n/i ) { next; };
					$lvl2 = "y";
					my $lvl3 = "n";
					foreach $device (keys %{$project{$vendor}{$family}{$gid}}) {
						if ( $device =~ /disp|best_match|generic/i ) {next;}
						if ( $project{$vendor}{$family}{$gid}{$device}{disp} =~ /n/i ) { next; };
						$lvl3 = "y";
						my $lvl4 = "n";
						foreach $run (keys %{$project{$vendor}{$family}{$gid}{$device}}) {
							if ( $run =~ /disp/i) {next;}
							if ( $project{$vendor}{$family}{$gid}{$device}{$run}{disp} =~ /n/i ) { next; };
							$lvl4 = "y";
						}	
						if ( $lvl4 =~ /n/i ) { $project{$vendor}{$family}{$gid}{$device}{disp} = "n"; $cleaning_status = 1; }					
					}
					if ( $lvl3 =~ /n/i ) { $project{$vendor}{$family}{$gid}{disp} = "n"; $cleaning_status = 1; }			
				}
				if ( $lvl2 =~ /n/i ) { $project{$vendor}{$family}{disp} = "n"; $cleaning_status = 1; }
			}		
			if ( $lvl1 =~ /n/i ) { $project{$vendor}{disp} = "n"; $cleaning_status = 1; }
		}
	} while ( $cleaning_status == 1 );
	return \%project;
}

##############################
# adjust display values and its sub hiearchy
#############################
sub set_path_display_value {
	my %project = %{shift()}; 
	my $value = shift();
	my @argv = @_;
	my $argc = scalar @argv;
	my $vendor = $argv[0];
	my $family = $argv[1];
	my $gid = $argv[2];
	my $device = $argv[3];
	my $run = $argv[4];
	
	# print "argc - $argc\n";
	# print "value - $value\n";
	# print "vendor - $vendor\n";
	# print "family - $family\n";
	# print "device - $device\n";
	# print "run - $run\n";
	# system( pause );
	

	if ( $argc == 1 ) { #vendor provided
		goto LEVEL1;
	} elsif ( $argc == 2 ) { #family provided
		goto LEVEL2;
	} elsif ( $argc == 3 ) { #gid provided
		goto LEVEL3;
	} elsif ( $argc == 4 ) { #device provided
		goto LEVEL4;
	} elsif ( $argc == 5 ) { #run provided
		goto LEVEL5;
	}
	
	LEVEL0:
	foreach $vendor (keys %project) {		
		if ( $vendor =~ /disp/i ) { next; }
		$project{$vendor}{disp} = $value;
		foreach $family (keys %{$project{$vendor}}) {			
			if ( $family =~ /disp/i ) { next; }
			$project{$vendor}{$family}{disp} = $value;	
			foreach $gid (keys %{$project{$vendor}{$family}}) {
				if ( $gid =~ /disp/i ) { next; }
				$project{$vendor}{$family}{$gid}{disp} = $value;	
				foreach $device (keys %{$project{$vendor}{$family}{$gid}}) {
					if ( $device =~ /disp|best_match|generic/i ) {next;}
					$project{$vendor}{$family}{$gid}{$device}{disp} = $value;			
					foreach $run (keys %{$project{$vendor}{$family}{$gid}{$device}}) {
						if ( $run =~ /disp/i) {next;}
						$project{$vendor}{$family}{$gid}{$device}{$run}{disp} = $value;
					}
				}
			}
		}
	}
	return \%project;

	LEVEL1:
	$project{$vendor}{disp} = $value;
	foreach $family (keys %{$project{$vendor}}) {
		if ( $family =~ /disp/i ) { next; }
		$project{$vendor}{$family}{disp} = $value;	
		foreach $gid (keys %{$project{$vendor}{$family}}) {
			if ( $gid =~ /disp/i ) { next; }
			$project{$vendor}{$family}{$gid}{disp} = $value;	
			foreach $device (keys %{$project{$vendor}{$family}{$gid}}) {
				if ( $device =~ /disp|best_match|generic/i ) {next;}
				$project{$vendor}{$family}{$gid}{$device}{disp} = $value;			
				foreach $run (keys %{$project{$vendor}{$family}{$gid}{$device}}) {
					if ( $run =~ /disp/i) {next;}
					$project{$vendor}{$family}{$gid}{$device}{$run}{disp} = $value;
				}
			}
		}
	}
	return \%project;
	
	LEVEL2:
	# setting above if on
	if ( $value =~ /y/i ) {
		$project{$vendor}{disp} = $value;		
	}	
	# setting below	
	$project{$vendor}{$family}{disp} = $value;		
	foreach $gid (keys %{$project{$vendor}{$family}}) {
		if ( $gid =~ /disp/i ) { next; }
		$project{$vendor}{$family}{$gid}{disp} = $value;	
		foreach $device (keys %{$project{$vendor}{$family}{$gid}}) {
			if ( $device =~ /disp|best_match|generic/i ) {next;}
			$project{$vendor}{$family}{$gid}{$device}{disp} = $value;			
			foreach $run (keys %{$project{$vendor}{$family}{$gid}{$device}}) {
				if ( $run =~ /disp/i) {next;}
				$project{$vendor}{$family}{$gid}{$device}{$run}{disp} = $value;
			}
		}
	}
	return \%project;
	
	LEVEL3:
	# setting above if on
	if ( $value =~ /y/i ) {
		$project{$vendor}{disp} = $value;
		$project{$vendor}{$family}{disp} = $value;		
	}	
	# setting below
	$project{$vendor}{$family}{$gid}{disp} = $value;		
	foreach $device (keys %{$project{$vendor}{$family}{$gid}}) {
		if ( $device =~ /disp|best_match|generic/i ) {next;}
		$project{$vendor}{$family}{$gid}{$device}{disp} = $value;			
		foreach $run (keys %{$project{$vendor}{$family}{$gid}{$device}}) {
			if ( $run =~ /disp/i) {next;}
			$project{$vendor}{$family}{$gid}{$device}{$run}{disp} = $value;
		}
	}
	return \%project;
	
	LEVEL4:
	# setting above if on
	if ( $value =~ /y/i ) {
		$project{$vendor}{disp} = $value;
		$project{$vendor}{$family}{disp} = $value;		
		$project{$vendor}{$family}{$gid}{disp} = $value;
	}
	# setting below
	$project{$vendor}{$family}{$gid}{$device}{disp} = $value;			
	foreach $run (keys %{$project{$vendor}{$family}{$gid}{$device}}) {
		if ( $run =~ /disp/i) {next;}
		$project{$vendor}{$family}{$gid}{$device}{$run}{disp} = $value;
	}
	return \%project;
	
	LEVEL5:
	# setting above if on
	if ( $value =~ /y/i ) {
		$project{$vendor}{disp} = $value;
		$project{$vendor}{$family}{disp} = $value;		
		$project{$vendor}{$family}{$gid}{disp} = $value;
		$project{$vendor}{$family}{$gid}{$device}{disp} = $value;
	}
	# setting below
	$project{$vendor}{$family}{$gid}{$device}{$run}{disp} = $value;
	return \%project;
}
###########################
## Modify Data Selection ##
##		For each selection criteria, appropriate mode needs to be selected.
## 		Valid modes are MOD (MODIFY) and NAV (NAVIGATE)
###########################
sub modify_selection {
	my %project = %{shift()};
	my $mode = shift(); #modify, navigate
	my $query = shift(); #all, limit, overall
	my %criterian = %{shift()};
	my $project_path = shift();
	my @argv = @_;	
	my $argc = scalar @argv;
	my $vendor = $argv[0];
	my $family = $argv[1];
	my $gid  = $argv[2];
	my $device = $argv[3];
	
	while(1) {
		system( cls );
		my ( @choices, %temp );
		
		# Get choice list
		if ( $argc == 0 ) {
			%temp = %project; 	
			print "\n";
		} elsif ( $argc == 1 ) {
			%temp = %{$project{$vendor}};			 
			print "\nCurrent Path : $vendor";
		} elsif ( $argc == 2 ) {
			%temp = %{$project{$vendor}{$family}};
			print "\nCurrent Path : $vendor -> $family";
		} elsif ( $argc == 3 ) {
			%temp = %{$project{$vendor}{$family}{$gid}};
			print "\nCurrent Path : $vendor -> $family -> $project{$vendor}{$family}{$gid}{generic}";
		} elsif ( $argc == 4 ) {
			%temp = %{$project{$vendor}{$family}{$gid}{$device}};
			print "\nCurrent Path : $vendor\t-> $family\t-> $project{$vendor}{$family}{$gid}{generic}\t-> $device";
		} 
			print "\n\n";
			#remove disp from choice
			foreach $tempval (sort {$a cmp $b} (keys %temp) ) {
				if ( $tempval !~ /^disp$|^best_match$|^generic$/i ) { push ( @choices, $tempval ); }
			}
		
		# display mode
		if ( $mode =~ /nav/i ) {
			print "Selection Mode : Navigate\n";
		} else {
			print "Selection Mode : Modify\n";
		}
		if ( $query =~ /overall/i ) {
			print "\n\nQuery Mode     : Best overall (This will query within the same family but across all generics and devices)\n";
		} elsif ($query =~ /generic/i) {
			print "\n\nQuery Mode     : Best per generic (This will query within the same family and generics but across devices)\n";
		} elsif ($query =~ /device/i) {
			print "\n\nQuery Mode     : Best per device (This will query within the same family, generics and devices)\n";
		} else {
			print "\n\nQuery Mode     : None (This will generate CVS file for all selected data)\n";
		}
		print "\n\nPlease select the following choices :\n\n";
	
	
		### Printing choice list
		my $all_on = 1; my @display_list;
		if ( $argc == 2 ) { # display generic value instead of ID
			foreach $choice ( @choices ) { 
				push ( @display_list, $project{$vendor}{$family}{$choice}{generic} );
			}
		} elsif ( $argc == 4 ) {# sort run number
			for ( $i = 0; $i <= $#choices; $i++ ) {
				$choices[$i] =~ s/run_//i;		
			}		
			@choices = sort { $a <=> $b } ( @choices );
			for ( $i = 0; $i <= $#choices; $i++ ) {
				$choices[$i] = "run_${choices[$i]}";				
			}		
			@display_list = @choices;
		} else {
			@display_list = @choices;
		}		
		for ( $i = 1; $i <= $#choices+1; $i++ ) {
			if ( $temp{$choices[$i-1]}{disp} =~ /n/i ) {
				print "\t$i) ($display_list[$i-1])\n";
				$all_on = 0;
			} else {
				print "\t$i) $display_list[$i-1]\n";
			}
		}
		
		print "\n\t(a) All/none of the above\n\n";
		if ( $argc < 4 ) { print "\t(m) Toggle selection modes (navigate/modify)\n"; }
		print "\t(q) Toggle query modes (overall/generic/device/none)\n";
		print "\t(g) Generate database csv result\n\n";
		print "\t(v)  View data in query";
		print "\t(va) View all available data\n";
		print "\t(vb) View best result\t";
		print "\t(vq) View queried result\n\n";
		print "\t(r) Return\t\t(e) Exit\n\n";
		print "Your choice: ";
		$choice = <STDIN>; chop($choice);
		
		# Choice handlers
		if ( $choice >= 1 and $choice <= scalar@choices ) {
			if ( $mode =~ /nav/i ) { #navigate mode
				push (@argv, $choices[$choice-1]);
				if ( $argc < 3 ) { 
					%project = %{ &modify_selection(  \%project, "nav", $query, \%criterian, $project_path, @argv ) };
				} else {
					%project = %{ &modify_selection(  \%project, "mod", $query, \%criterian, $project_path, @argv ) };
				}
				pop ( @argv );
			} else { #toggle display
				my @temparr = @argv;			
				push (@temparr, $choices[$choice-1]);				
				if ( $temp{$choices[$choice-1]}{disp} =~ /y/i ) { 
					# disable all data below this hierarchy
					%project = %{ &set_path_display_value( \%project, "n", @temparr )};
					%project = %{ &check_display_value( \%project ) }; #turn higher hierachy display off if everyting is turned off
				} else { 
					# enable all data below this hierarchy
					%project = %{ &set_path_display_value( \%project, "y", @temparr )};
					#enable all associated data above this hierachy					
				}
			}
			%project = %{ &check_display_value( \%project ) };
		} elsif ( $choice =~ /^a$/i ) { #toggle on or off
			if ( $all_on == 0 ) {
				%project = %{ &set_path_display_value( \%project, "y", @argv )};
			} else {
				%project = %{ &set_path_display_value( \%project, "n", @argv )};
				%project = %{ &check_display_value( \%project ) }; #turn higher hierachy display off if everyting is turned off
			}
		} elsif (($choice =~ m/^m$/i) and ($argc < 3) ) {
			if ( $mode =~ /nav/i ) { $mode = "mod"; } else { $mode = "nav"; }
		} elsif ($choice =~ m/^q$/i) {
			if ( $query =~ /overall/i ) { 
				$query = "generic"; 
			} elsif ( $query =~ /generic/i ) {
				$query = "device";
			} elsif ( $query =~ /device/i ) {	
				$query = "none";			
			} else {
				$query = "overall";
			}
		} elsif ( $choice =~ m/^g$/i ) {
			&gen_db_csv( \%project, \%criterian, $query, "zip", $project_path );
		} elsif ( $choice =~ m/^va$/i ) {
			&view_data_selection( \%project, "all" );
		} elsif ( $choice =~ m/^vb$/i ) {
			&view_result( \%project, $query, "all", \%criterian );
		} elsif ( $choice =~ m/^vq$/i ) {
			&view_result( \%project, $query, "query", \%criterian );
		} elsif ( $choice =~ m/^v$/i ) {
			&view_data_selection( \%project, "limit" );
		} elsif ( $choice =~ m/^r$/i ) {
			return \%project;
		} elsif ( $choice =~ m/^e$/i ) {
			exit;
		} else {
			print "Invalid choice. Please try again.\n\n";
			system( pause );
		}
	}
}

########################
## Select DB Strategy ##
########################

sub db_selection {
	my $project_path = shift();
	
	print "Please hold, extracting project data ...\n";
	my %project = %{&extract_project_data( $project_path )};
	
	my $query = "overall";
	
	my %criterian = (
		THROUGHPUT => "n",
		AREA => "n",
		THROUGHPUT_AREA => "n",
		LATENCY => "n",
		LATENCY_AREA => "n",
	);
	
	## Make sure that all runs are selected
	%project = %{ &set_path_display_value( \%project, "y" )};
	## Make sure that all invalid runs are deselected
	%project = %{ &check_display_value( \%project ) };
	
	while(1) {
		system( cls );
		print "\n\n\n\n";		
		if ( $query =~ /overall/i ) {
			print "\n\nQuery Mode     : Best overall (This will query within the same family but across all generics and devices)\n";
		} elsif ($query =~ /generic/i) {
			print "\n\nQuery Mode     : Best per generic (This will query within the same family and generics but across devices)\n";
		} elsif ($query =~ /device/i) {
			print "\n\nQuery Mode     : Best per device (This will query within the same family, generics and devices)\n";
		} else {
			print "\n\nQuery Mode     : None\n";
		}
		print "\n";
		print "\nPlease select the following criterian(s)\n\n";
		print "\t1) Highest Throughput"; if ( $criterian{THROUGHPUT} =~ m/y/i ) { print " <<<\n"; } else { print "\n"; }
		print "\t2) Smallest Area";		if ( $criterian{AREA} =~ m/y/i ) { print " <<<\n"; } else { print "\n"; }
		print "\t3) Highest Throughput to Area Ratio";	if ( $criterian{THROUGHPUT_AREA} =~ m/y/i ) { print " <<<\n"; } else { print "\n"; }
		print "\t4) Smallest Latency";	if ( $criterian{LATENCY} =~ m/y/i ) { print " <<<\n"; } else { print "\n"; }
		print "\t5) Smallest Latency*Area";	if ( $criterian{LATENCY_AREA} =~ m/y/i ) { print " <<<\n\n"; } else { print "\n\n"; }
		print "\t(a) All/none of the above\n\n";		
		print "\t(q) Toggle query mode (overall/generic/device/none)\n";
		print "\t(m) Modify data in query (all data is selected by default)\n";
		print "\t(g) Generate zip file\n\n";
		print "\t(v)  View data in query";
		print "\t(va) View all available data\n";
		print "\t(vb) View best result";
		print "\t(vq) View queried result\n\n";		
		print "\t(r) Return\t\t(e) Exit\n\n";
		
		print "Your choice: ";
		$choice = <STDIN>; chop($choice);
		
		if ( $choice == 1 ) {
			if ( $criterian{THROUGHPUT} =~ m/n/i ) { $criterian{THROUGHPUT} = "y"; } 		else { $criterian{THROUGHPUT} = "n"; }
		} elsif ( $choice == 2 ) {
			if ( $criterian{AREA} =~ m/n/i ) 		{ $criterian{AREA} = "y"; } 			else { $criterian{AREA} = "n"; }
		} elsif ( $choice == 3 ) {
			if ( $criterian{THROUGHPUT_AREA} =~ m/n/i ) { $criterian{THROUGHPUT_AREA} = "y"; } 	else { $criterian{THROUGHPUT_AREA} = "n"; }
		} elsif ( $choice == 4 ) {
			if ( $criterian{LATENCY} =~ m/n/i ) 	{ $criterian{LATENCY} = "y"; } 			else { $criterian{LATENCY} = "n"; }
		} elsif ( $choice == 5) {
			if ( $criterian{LATENCY_AREA} =~ m/n/i ) { $criterian{LATENCY_AREA} = "y"; } 	else { $criterian{LATENCY_AREA} = "n"; }
		} elsif ( $choice =~ /^a$/i ) {
			if (( $criterian{THROUGHPUT} =~ m/y/i) 	and ( $criterian{AREA} =~ m/y/i) and 
				( $criterian{THROUGHPUT_AREA} =~ m/y/i) and ( $criterian{LATENCY} =~ m/y/i) and
				( $criterian{LATENCY_AREA} =~ m/y/i)) {
					$criterian{THROUGHPUT} = "n";	$criterian{AREA} = "n";			$criterian{THROUGHPUT_AREA} = "n";
					$criterian{LATENCY} = "n";		$criterian{LATENCY_AREA} = "n";				
			} else {
					$criterian{THROUGHPUT} = "y";	$criterian{AREA} = "y";			$criterian{THROUGHPUT_AREA} = "y";
					$criterian{LATENCY} = "y";		$criterian{LATENCY_AREA} = "y";				
			}			
		} elsif ( $choice =~ m/^m$/i ) {
			%project = %{ &modify_selection( \%project, "nav", $query, \%criterian, $project_path ) };
		} elsif ($choice =~ m/^q$/i) {
			if ( $query =~ /overall/i ) { 
				$query = "generic"; 
			} elsif ( $query =~ /generic/i ) {
				$query = "device";
			} elsif ( $query =~ /device/i ) {	
				$query = "none";
			} else {
				$query = "overall";
			}
		} elsif ( $choice =~ m/^g$/i ) {
			&gen_db_csv( \%project, \%criterian, $query, "zip", $project_path );
		} elsif ( $choice =~ m/^va$/i ) {
			&view_data_selection( \%project, "all" );
		} elsif ( $choice =~ m/^vb$/i ) {
			&view_result( \%project, $query, "all", \%criterian );
		} elsif ( $choice =~ m/^vq$/i ) {
			&view_result( \%project, $query, "query", \%criterian );
		} elsif ( $choice =~ m/^v$/i ) {
			&view_data_selection( \%project, "limit" );
		} elsif ( $choice =~ m/^r$/i ) {
			return;
		} elsif ( $choice =~ m/^e$/i ) {
			exit;
		} else {
			print "Invalid choice. Please try again.\n\n";
			system( pause );
		}
	}
	
	return;
}

#######################
## Project Selection ##
#######################

sub project_selection {
	my %data = %{shift()}; 
	my $app = shift();

	while(1) {
		print "\n\nWhich project would you like to view?\n\n";
		my $i = 0;
		@app_list = keys ( %{$data{$app}} );
		@app_list = sort ( @app_list );
		foreach my $proj ( @app_list ) {
			$i++;			
			$option[$i] = $proj;
			$last_option = $i;
			print "$i.\t$proj\n";
		}

		print "\n(r)\tReturn\t\t(e)\tExit\n\n";

		print "Please select one of the above options [1-$last_option]: ";
		$choice = <STDIN>; chop($choice);
		if ( $choice >= 1 and $choice <= $last_option  ) {
			my $project_path = "$data{$app}{$option[$choice]}";
			print "$project_path\n";
			&db_selection( $project_path );			
		} elsif ( $choice =~ m/r/i ) {
			return;
		} elsif ( $choice =~ m/e/i ) {
			exit;
		} else {
			print "Invalid choice. Please select between [1-$last_option].\n\n";
		}
	}
}
###############################
##########  MAIN    ###########
###############################

# Preparing data

my $workspace;

%project;

if ( $#ARGV == 0 ) { # ONLY WORKSPACE IS SPECIFIED
	$workspace = shift();
} elsif ( $#ARGV == -1) {
	require "$ROOT_DIR\/$BIN_DIR_NAME\/$CONSTANT_FILE_NAME";
	require "$ROOT_DIR\/$BIN_DIR_NAME\/$REGEX_FILE_NAME";
	require "$ROOT_DIR\/$BIN_DIR_NAME\/support.pl";

	open(DESIGNOPTS, "$ROOT_DIR\/$DESIGN_CONFIGURATION_FILE") || die("Could not acquire design configuration file!");
	my $data = join(" ", <DESIGNOPTS>);
	close(DESIGNOPTS);
	
	if ( $data =~ m/WORK_DIR\s*=\s*<${REGEX_FOLDER_IDENTIFIER}>/gi ) { $workspace = $1; } else { $workspace = "ATHENa_workspace"; }	
	$workspace = &processRelativePath($workspace, "");
} elsif ( $#ARGV == 2 ) {# CMD LINE MODE
    my $project_path = &trim_spaces(shift());
    my $query_mode = &trim_spaces(shift());
    my $criteria = &trim_spaces(shift());
    $pause = "off";
    
    my %criterian = (
		THROUGHPUT => "n",
		AREA => "n",
		THROUGHPUT_AREA => "n",
		LATENCY => "n",
		LATENCY_AREA => "n",
	);
    
    if ( $criteria =~ m/^THROUGHPUT$/i ) {
        $criterian{THROUGHPUT} = "y";
    } elsif ( $criteria =~ m/^AREA$/i ) {
        $criterian{AREA} = "y";
    } elsif ( $criteria =~ m/^THROUGHPUT_AREA$/i ) {   
        $criterian{THROUGHPUT_AREA} = "y";
    } elsif ( $criteria =~ m/^LATENCY$/i ) {
        $criterian{LATENCY} = "y";
    } elsif ( $criteria =~ m/^LATENCY_AREA$/i ) {
        $criterian{LATENCY_AREA} = "y";
    }       
    
    #print "prj=\"$project_path\"\nquery=\"$query_mode\"\ncrit=\"$criteria\"\n";
    my %project = %{&extract_project_data( $project_path )};
    
    $result_dir = "$project_path\\db";
	mkdir($result_dir);
	chdir($result_dir);
    
	&gen_db_csv( \%project, \%criterian, $query_mode, "zip", $project_path );
    
    exit;
} else {
	print "Invalid number of inputs parameters. Program terminating ...\n";
}


if ( not (-e "$workspace") ) { print "No workspace found!\n\n"; exit; }

# populating data
my %data;
foreach my $app ( &getdirs($workspace)  ) {
	my $app_path = $workspace . "\\" . $app;
	foreach $proj ( &getdirs($app_path)  ) {	
		$proj_path = $app_path . "\\". $proj;
		$data{$app}{$proj} = $proj_path;
	}
}

###########################
## Application Selection ##
###########################

my @option;
my $choice;
my $exit;
my $last_option;

system( cls );

#___ removed!
#print "==========================\n";
#print "==== 1 REPORT GENERATOR ====\n";
#print "==========================";

#while(1) {
#	my $i = 0;
#	print "\n\n";
#	print "Please select one of the following applications :\n\n";
#	foreach my $app (keys %data) {
#		$i++;
#		print "$i.\t$app\n";
#		$option[$i] = $app;
#		$last_option = $i;
#	}
#
#	print "\n(e)\tExit\n\n";
#
#	print "Please select one of the above options [1-$last_option]: ";
#	$choice = <STDIN>; chop($choice);
#	if ( $choice >= 1 and $choice <= $last_option  ) {
#		&project_selection(\%data, $option[$choice]);
#	} elsif ( $choice =~ m/e/i ) {
#		exit;
#	} else {
#		print "Invalid choice. Please select between [1-$last_option].\n";
#	}
#}
