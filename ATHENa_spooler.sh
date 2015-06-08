#!/bin/bash 
###########################
#Shell Script to Run ATHENa Spooler
###########################
#Function to Simulate 'Pause' as in Windows
pause()
{
	read -s -n 1 -p "ATHENa Spooler Execution Completed. Press any key to Exit . . ."
	echo
	}
	
# Calling ATHENa Spooler Script
	
perl bin/utils/chain_processing.pl
pause