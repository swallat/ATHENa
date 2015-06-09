#!/bin/bash
###########################
#Shell Script to Run ATHENa
###########################
#Function to Simulate 'Pause' as in Windows
pause()
{
	read -s -n 1 -p "ATHENa Execution Completed. Press any key to continue . . ."
	echo
	}
#Setting Path Variables
export XILINX="/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64"
export QUARTUS_ROOTDIR=""
export PATH=":/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64:$PATH"

#Starting ATHENa
cd bin
perl main.pl $1
if [ "$1" = "nopause" ] ; then #Req. for ATHENa Spooler
	echo done
	cd ..
else					         #ATHENa Execution Complete

	pause


	cd ..
fi
#EOF
