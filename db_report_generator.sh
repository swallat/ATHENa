#!/bin/bash 

#####################################
#Shell Script to genrate Data base 
#up-load ready reports
#####################################

cd bin/utils
perl db_report_generator.pl
cd ../..
