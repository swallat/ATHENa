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
#use strict;
use Cwd;
use File::Path;
use Archive::Zip;
# need to get these from CPAN
use Tie::Handle::CSV; 
use Parallel::ForkManager;

glob $UTILS_DIR_NAME = "utils";
glob $BIN_DIR_NAME = "bin";
glob $ROOT_DIR = cwd; $ROOT_DIR =~ s/\/$BIN_DIR_NAME\/$UTILS_DIR_NAME//;

require "$ROOT_DIR/$BIN_DIR_NAME/extract_old.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/constants.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/regex.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/report_core.pl";
require "$ROOT_DIR/$BIN_DIR_NAME/report_conf.pl";

#######################################################
# Settings
#######################################################

my $OUTPUT_FILE = 'C:\Users\ice\Desktop\results\ches\testResults_rev2.csv';
my $MAX_CORE_USAGE = 6;
my $SOURCE_FOLDER = 'C:\Users\ice\Desktop\results\ches\_publish';
my @SOURCE_FILES =     
    (   ## BLAKE
        'BLAKE_basic.zip',
        'BLAKE_unrolled.zip',
        'BLAKE_fh4v4.zip',
        'BLAKE_unrolled.zip',
        
        # ## Groestl
        'Groestl_PpQ_folded.zip',
        'Groestl_PpQ_folded.zip',
        'Groestl_PpQ_folded.zip',
        'Groestl_PpQ_x1.zip',
        'Groestl_PsQ_folded.zip',
        'Groestl_PsQ_folded.zip',
        'Groestl_PsQ_folded.zip',
        'Groestl_PsQ_x1.zip',
        
        ## JH
        'JH_fv2.zip',
        'JH_basic.zip',        
        'JH_u2.zip',
        'JH_fv2.zip',
        'JH_basic.zip',        
        'JH_u2.zip',
        
        ## Keccak
        'Keccak_basic.zip',
        ## Skein
        'Skein_unrolled.zip',   #x1
        'Skein_basic.zip',      #x4        
        'Skein_unrolled.zip'    #x8
    );
my @DB_ZIPS_FOLDER =    
    (   ## BLAKE
        'C:\Users\ice\Desktop\results\ches\Blake\fh2',
        'C:\Users\ice\Desktop\results\ches\Blake\fh4',
        'C:\Users\ice\Desktop\results\ches\Blake\fh4v4',
        'C:\Users\ice\Desktop\results\ches\Blake\x1',
                
        ## Groestl
        'C:\Users\ice\Desktop\results\ches\Groestl\ppq_ff2',
        'C:\Users\ice\Desktop\results\ches\Groestl\ppq_ff4',
        'C:\Users\ice\Desktop\results\ches\Groestl\ppq_ff8',
        'C:\Users\ice\Desktop\results\ches\Groestl\ppq_x1',
        'C:\Users\ice\Desktop\results\ches\Groestl\psq_ff2',
        'C:\Users\ice\Desktop\results\ches\Groestl\psq_ff4',
        'C:\Users\ice\Desktop\results\ches\Groestl\psq_ff8',
        'C:\Users\ice\Desktop\results\ches\Groestl\psq_x1',
        
        ## JH
        'C:\Users\ice\Desktop\results\ches\JH\mem_fv2',
        'C:\Users\ice\Desktop\results\ches\JH\mem_ux1',
        'C:\Users\ice\Desktop\results\ches\JH\mem_ux2',
        'C:\Users\ice\Desktop\results\ches\JH\otf_fv2',
        'C:\Users\ice\Desktop\results\ches\JH\otf_ux1',
        'C:\Users\ice\Desktop\results\ches\JH\otf_ux2',
        
        ## Keccak
        'C:\Users\ice\Desktop\results\ches\Keccak\x1',
        ## Skein
        'C:\Users\ice\Desktop\results\ches\Skein\x1',
        'C:\Users\ice\Desktop\results\ches\Skein\x4',
        'C:\Users\ice\Desktop\results\ches\Skein\x8'      
    );
# my @SOURCE_FILES = (    'Groestl_PpQ_x1.zip' );
# my @DB_ZIPS_FOLDER = ( 'C:\Users\ice\Desktop\results\ches\Groestl\ppq_x1' );
my $COMPARISON_ONLY = 1;
#######################################################
# Debug Settings
# (0 = disable, 1 = enable debugging)
#######################################################

## Step 1 : Decompression and src copying
my $DEBUG_SKIP_DISK_CLEANUP = 0;
my $DEBUG_SKIP_DATA_EXTRACTION = 0;
my $DEBUG_SKIP_SRC_COPY = 0;

## Step 2 : 
my $DEBUG_SKIP_ACTUAL_RUNS = 0;


#######################################################
# Functions
#######################################################
sub GetYesOrNo 
{
    my $text = shift();
    while(1) {
        print $text;
        my $choice = <STDIN>; chop($choice);
        if ( $choice =~ m/^y$/i ) {
            return "y";
        } elsif ( $choice =~ m/^n$/i ) {
            return "n";
        } else {
            print "Invalid entry. Please try again. \n\n";
        }
    }
}

sub GetDataFromFile 
{
    my $filepath = shift();
    open( DATAHANDLER, $filepath );
    my $dat = join(" ", <DATAHANDLER>);     
    close(DATAHANDLER);
    return \$dat;
}

sub RunScripts
{
    my %data = %{shift()};
    print "\n\nRunning Scripts ..\n\n";
    my $pm = new Parallel::ForkManager($MAX_CORE_USAGE);
    my @names = qw( Ignore Jim Lily Steve Jessica Bob Dave Christine Rico Sara );

    for ( my $iKey = 0; $iKey < scalar( keys %data ); $iKey++ )
    {
        my $pid = $pm->start( "CID".$iKey ) and next;
        
        chdir( $data{$iKey}{runFolder} );  
        print("\t\tRunning script (CID$iKey) : $data{$iKey}{scriptFile}\n");
        ## Executing them line by line to avoid problem
        open( RUNFILE,  $data{$iKey}{scriptFile} );
        foreach my $line (<RUNFILE>) {
            print("\t\t  Executing (CID$iKey) : $line\n");
            if ( $DEBUG_SKIP_ACTUAL_RUNS == 0 ) 
            {
                my $output = `$line`;
                if ( $output =~ /error/i ) { #stop from execution if error is found
                    my $errorText = "**Problem with CID$iKey in folder --> $data{$iKey}{runFolder}.\n";
                    $data{$iKey}{error} = $errorText;
                    last;
                }
            }
        }
        close( RUNFILE );
        $pm->finish;
    }
    $pm->wait_all_children;
}    

sub ExtractAndCompareResults 
{
    my %data = %{shift()};
    print "Verifying results ...\n"; 
    open ( OUTFILE, ">$OUTPUT_FILE" ) or die ("Cannot create $OUTPUT_FILE for write\n");
    print OUTFILE "Test Folder,Expected Area,Achieved Area,Result,Expected TCLK,Achieved TCLK,Result\n";
    for ( my $i = 1; $i < scalar( keys %data )+1; $i++ )
    {
        my $rundir = $data{$i-1}{runFolder};

        my $area = 0;
        my $tclk = 0;
        
        ## Extracting results    
        if ( $data{$i-1}{vendor} =~ m/xilinx/i ) ## xilinx
        {
            ## area
            (undef, $area, undef) = extract_xilinx_slice( "", GetDataFromFile( "$rundir\\$XILINX_MAP_REPORT") );
            
            ## tclk
            my $timing_data = ${GetDataFromFile( "$rundir\\$XILINX_TRACE_REPORT")};     
            my @lines = split( /\n/, $timing_data );
            for ( my $lineNo = 0; $lineNo < $#lines; $lineNo++ )
            {           
                if ($lines[$lineNo] =~ m/Clock to Setup on destination clock clk/i)
                {
                    $lineNo = $lineNo + 5;
                    if ($lines[$lineNo] =~ m/$REGEX_XILINX_IMPTCLK_EXTRACT/i) 
                    { 
                        $tclk = $1;	
                    }
                    last;
                }            
            }                
        }
        else    ## altera
        {
            my @file = get_file_type($rundir, "$ALTERA_TIMING_REPORT_1_SUFFIX");
            if ( $file[0] eq "" ) { @file = get_file_type($rundir, "$ALTERA_TIMING_REPORT_2_SUFFIX"); }
            my $timing_report = "$rundir\\$file[0]";

            @file = get_file_type($rundir, "$ALTERA_IMPLEMENTATION_REPORT_SUFFIX");
            my $implementation_report = "$rundir\\$file[0]";
      
            my $timing_data = ${GetDataFromFile( $timing_report )};
            my $implementation_data = ${GetDataFromFile( $implementation_report )};                

            ## get Area
            (undef, $area, undef) = extract(\@REGEX_ALTERA_LU_ALUT_EXTRACT, "", \$implementation_data);
            if ( $area == 0 )
            {
                (undef, $area, undef)  = extract(\@REGEX_ALTERA_LE_EXTRACT, "", \$implementation_data);
            }

            ## get TCLK
            my @sta_lines = split(/\n/, $timing_data);
            my @tclkValues;
            my @freq;
            foreach my $line_no (0..$#sta_lines)
            {
                my $temp = 0;
                if ($sta_lines[$line_no] =~ m/;[\s\w\d]+Model Fmax Summary/i)
                {
                    ## skip nondata lines
                    $line_no = $line_no + 4;
                    ## should be in data section by now				
                    while (1)
                    {
                        if( $sta_lines[$line_no] =~ m/;\s*([\d.]+)\s*[\w]*\s*;\s*([\d.]+)\s*[\w]*[\t\s]*;\s*([\w]+)/i )
                        {
                            $freq[$temp] = $2; ## restricted Fmax	
                            if ( $freq[$temp] < 1 ) { $freq[$temp] = $1; }	## Fmax

                            if ( $freq[$temp] < 1 ) {
                                $tclkValues[$temp] = "N/A";	$freq[$temp] = "N/A";
                            } else {
                                my $period = 1/$freq[$temp]*1000;
                                $tclkValues[$temp]  = sprintf("%.${PRECISION}f", $period);
                            }

                        } else {						
                            last;
                        }
                        $temp++; $line_no++;
                    }
                    last;
                }
            }
            
            $tclk = $tclkValues[0];
        }

        ## Checking the results
        print OUTFILE "$rundir,$data{$i-1}{area},";
        if ($area > 0) 
        { 
            print OUTFILE "$area,";
        }
        else
        {   
            print OUTFILE "N/A,",
        }
        
        if ( $area == $data{$i-1}{area} )
        {
            print OUTFILE "passed,";
        }
        else
        {
            print OUTFILE "-->failed,";                
        }

        print OUTFILE "$data{$i-1}{tclk},";
        if ($tclk > 0) 
        { 
            print OUTFILE "$tclk,";
        }
        else
        {   
            print OUTFILE "N/A,",
        }
        if ( $tclk == $data{$i-1}{tclk} )
        {
            print OUTFILE "passed\n";
        }
        else
        {
            print OUTFILE "-->failed\n";
        }
    }

    close( OUTFILE );
    print "Done! You can view the verification results at => $OUTPUT_FILE\n";


}

#######################################################
# Main
#######################################################
#foreach my $folder ( sort @DB_ZIPS_FOLDER ) {

# my @areas;
# my @tclks;
# my @scriptFiles;
# my @runFolders;
# my @vendors; # vendor name corresponding to the result array
# my @errors;
glob %data; 

if ( $#SOURCE_FILES != $#DB_ZIPS_FOLDER ) {
    print "Error! Not equal number of folder and corresponding zip files\n";
    print "Program terminating.\n";
    exit;
}
      
#######################################################
# Create test folders and copy source files into appropriate directory
# src file must be in the zip format with /src folder
#######################################################
if ( $COMPARISON_ONLY == 0 ) {
    for ( my $iCount = 0; $iCount < scalar( @DB_ZIPS_FOLDER ); $iCount++ ) {
        my $testFolderName = $DB_ZIPS_FOLDER[$iCount];
        opendir(DIR, $testFolderName) or die("Cannot open $testFolderName");
        my @dbFiles = grep(/\.zip$/, readdir(DIR) );
        my $testPath = $testFolderName.'\\test';

        unless ( -d $testPath ) {
            mkdir( $testPath ) or die("Cannot create $testPath\n");
        }

        print "Checking : $testFolderName\n";
        foreach my $file ( sort @dbFiles ) {
            (my $folderName = $file) =~ s/\.[^.]+$//;      
            my $testFile = $testFolderName . '\\' . $file;
            my $testFolder = $testPath .'\\' . $folderName;            

            #######################################################
            # REMOVE the previously created directory and
            # create a new one for testing.
            #######################################################
            if ( $DEBUG_SKIP_DISK_CLEANUP == 0 ) {
                if ( -d $testFolder )
                {
                    # If test folder exist, remove and create a folder corresponding to the db report file
                    #my $choice = &GetYesOrNo("$testFolder exists! Would you like to overwrite the current folder? [Y/N] \n");
                    my $choice = "y"; #temporary
                    if ( $choice =~ m/^y$/i ) 
                    {
                        &rmtree( $testFolder );
                        mkdir ( $testFolder );
                    }
                    else
                    {
                        print "\tSkipping results from => $testFile\n";
                        next;
                    }
                }
                else
                {
                    mkdir ( $testFolder );
                }
            }
            print "\tExtracting results from =>\n\t    $testFile\n\t  to\n\t    $testFolder\n";

            #######################################################
            # extract data inside the test folder
            #######################################################
            if ( $DEBUG_SKIP_DATA_EXTRACTION == 0 ) {
                my $zipname = $testFile;
                my $destinationDirectory = $testFolder;
                my $zip = Archive::Zip->new($zipname);
                foreach my $member ($zip->members)
                {
                    # ignore metadata.txt
                    next if ($member->fileName =~ /metadata/i);
                    next if $member->isDirectory;
                    (my $extractName = $member->fileName) =~ s{.*/}{};
                    $member->extractToFileNamed(
                      "$destinationDirectory/$extractName");
                }
            }         

            opendir(TESTDIR, $testFolder) or die("Cannot open $testFolder");  
            my @runZips = grep(/\.zip$/, readdir(TESTDIR));               

            #######################################################
            # Unzip all the runs and delete the zip files
            #######################################################
            if ( $DEBUG_SKIP_DATA_EXTRACTION == 0 ) {
                for ( my $i = 1; $i < scalar( @runZips )+1; $i++ ) {
                    $zipname = $testFolder . '\\' . $i . ".zip";
                    $destinationDirectory = $testFolder . '\\' . $i;

                    ## create directory
                    unless ( -d $destinationDirectory ) {
                        mkdir( $destinationDirectory );
                    }

                    ## unzip
                    my $zip = Archive::Zip->new($zipname);
                    $zip->extractTree(undef, $destinationDirectory."\\" );

                    ## delete
                    unlink( $zipname );
                }
            }
            
            #######################################################
            # Copy the source codes corresponding
            # to the DB_ZIPS_FOLDER to the /src folder
            #######################################################
            if ( $DEBUG_SKIP_SRC_COPY == 0 ) {
                for ( my $i = 0; $i < scalar( @runZips ); $i++ ) {
                    $destinationDirectory = $testFolder . '\\' . ($i+1) . '\\src\\';
                    $zipname = $SOURCE_FOLDER . '\\' . $SOURCE_FILES[$iCount];
                                    
                    ## unzip
                    my $zip = Archive::Zip->new($zipname);
                    $zip->extractTree('src', $destinationDirectory );
                }  
                
            }
        }
    }
}

#######################################################
# Read CSV file and retrieve Area and TCLK information
# This step is required for the following process tow orks properly
#######################################################
my $dataCount = 0;
for ( my $iCount = 0; $iCount < scalar( @DB_ZIPS_FOLDER ); $iCount++ ) 
{
    my $folderName = $DB_ZIPS_FOLDER[$iCount];
    opendir(DIR, $folderName) or die("Cannot open $folderName\m");
    my @dbFiles = grep(/\.zip$/, readdir(DIR) );
    my $testPath = $folderName.'\\test';
    foreach my $file ( sort @dbFiles ) 
    {
        # my $folderName = $file;
        # $folderName =~ s/\.[^.]+$//;
        
        (my $folderName = $file) =~ s/\.[^.]+$//;        
        my $testFolder = $testPath .'\\' . $folderName;
    
        opendir(TESTDIR, $testFolder) or die("Cannot open $testFolder\m");               
        my @dirs = readdir(TESTDIR);
        closedir(TESTDIR);
        my @temp = grep(/\.csv$/, @dirs);
        my @runZips = grep(/\.zip$/, @dirs);  

        my $csvFileName = $temp[0];
        (my $vendor = $csvFileName) =~ s/_[\w\W_.]+//i;
        my $csvFH = Tie::Handle::CSV->new(  $testFolder.'\\'.$csvFileName,
                                            header => 1, key_case => 'any');

        my $iFolder = 1;
        while (my $csv_line = <$csvFH>) {
            my $area;
            my $tclk;
            if ( $vendor =~ /xilinx/i ) {
                $area = $csv_line->{'U_SLICE'};
            } else {
                $area = $csv_line->{'U_ALUTS'};
                if ( $area == 0 ) { # cyclone families handler
                    $area = $csv_line->{'U_LE'};
                }
            }
            $tclk = $csv_line->{'IMP_TCLK'};
   
            $data{$dataCount}{area} = $area;
            $data{$dataCount}{tclk} = $tclk;
            $data{$dataCount}{vendor} = $vendor;
            $data{$dataCount}{runFolder} = $testFolder . '\\' . $iFolder;
            $data{$dataCount}{scriptFile} = $testFolder . '\\' . $iFolder . "\\run.bat";
            
            $iFolder++;
            $dataCount++;
        }
        close $csvFH;
    }
}

#######################################################
# Run the script for all the unzipped
# files at the same time
#######################################################

if ( $COMPARISON_ONLY == 0 ) {
    RunScripts(\%data);
}


#######################################################
# Extract And Compare Results
#######################################################

ExtractAndCompareResults( \%data );
