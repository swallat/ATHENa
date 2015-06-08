#!/bin/bash

###########################
#Function to Simulate 'Pause' as in Windows
###########################

pause()
{
	read -s -n 1 -p "Press any key to continue . . ."
	echo
	}

pause