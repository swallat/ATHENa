
Library files located in this folder contain the lists of FPGA devices 
supported by a given vendor and a version of tools.
For each FPGA device, a library file provides a summary of major 
resources (e.g. CLB slices, dedicated multipliers, etc.) available in the given device.

A library file matching a version of tools available on the user's computer
must be selected in order to allow ATHENa to perform correctly in 
the 'best_match' and 'all' execution modes.

This choice is done automatically by ATHENa_setup.

=== 

For the Xilinx ISE user, the following versions of the library files are currently available:

For Xilinx WebPACK (free version of Xilinx tools):

Folder:  _xilinx_device_lib_webpack
Files:
  xilinx_device_lib_webpack_14.7.txt
  xilinx_device_lib_webpack_14.6.txt
  xilinx_device_lib_webpack_14.5.txt
  xilinx_device_lib_webpack_14.4.txt
  xilinx_device_lib_webpack_14.3.txt
  xilinx_device_lib_webpack_14.2.txt
  xilinx_device_lib_webpack_14.1.txt
  xilinx_device_lib_webpack_13.3.txt
  xilinx_device_lib_webpack_13.2.txt
  xilinx_device_lib_webpack_13.1.txt
  xilinx_device_lib_webpack_12.4.txt
  xilinx_device_lib_webpack_12.3.txt
  xilinx_device_lib_webpack_12.2.txt
  xilinx_device_lib_webpack_12.1.txt
  xilinx_device_lib_webpack_11.5.txt
  xilinx_device_lib_webpack_11.1.txt
  xilinx_device_lib_webpack_10.1.txt
  xilinx_device_lib_webpack_9.2.txt
  xilinx_device_lib_webpack_9.1.txt

For Xilinx Design Suite (educational/full version of Xilinx tools):

Folder:  _xilinx_device_lib_designsuite
Files:
  xilinx_device_lib_designsuite_14.7.txt
  xilinx_device_lib_designsuite_14.6.txt
  xilinx_device_lib_designsuite_14.5.txt
  xilinx_device_lib_designsuite_14.4.txt
  xilinx_device_lib_designsuite_14.3.txt
  xilinx_device_lib_designsuite_14.2.txt
  xilinx_device_lib_designsuite_14.1.txt
  xilinx_device_lib_designsuite_13.3.txt
  xilinx_device_lib_designsuite_13.2.txt
  xilinx_device_lib_designsuite_13.1.txt
  xilinx_device_lib_designsuite_12.4.txt
  xilinx_device_lib_designsuite_12.3.txt
  xilinx_device_lib_designsuite_12.2.txt
  xilinx_device_lib_designsuite_12.1.txt
  xilinx_device_lib_designsuite_11.1.txt

In order to manually activate the use of an appropriate library of FPGA devices,
please copy the respective file to the folder
   ATHENa/device_lib
under the name 
   xilinx_device_lib.txt
(and replace the previous file with the same name).

To view the coverage of parts list supported by earlier tools see :
http://www.xilinx.com/ise/products/classics/parts_list.htm

Please note that the basic functionality of ATHENa can be accomplished
even if the device library version does not match exactly the version of tools
installed on your computer.

=================

For Altera Quartus user, the following versions of the library files are currently available:

For Altera Quartus II Web Edition (free version of Altera tools):

Folder:  _altera_device_lib_quartus_web_edition
Files:
  altera_device_lib_quartus_web_edition_14.0.txt
  altera_device_lib_quartus_web_edition_13.1.txt
  altera_device_lib_quartus_web_edition_13.0.txt
  altera_device_lib_quartus_web_edition_12.1.txt
  altera_device_lib_quartus_web_edition_12.0.txt
  altera_device_lib_quartus_web_edition_11.1.txt
  altera_device_lib_quartus_web_edition_11.0.txt
  altera_device_lib_quartus_web_edition_10.1.txt
  altera_device_lib_quartus_web_edition_10.0.txt
  altera_device_lib_quartus_web_edition_9.1.txt
  altera_device_lib_quartus_web_edition_9.0.txt
  altera_device_lib_quartus_web_edition_8.2.txt
  altera_device_lib_quartus_web_edition_8.1.txt

For Altera Quartus II Subscription Edition (educational/full version of Altera tools):

Folder:  _altera_device_lib_quartus_subscription_edition
Files:
  altera_device_lib_quartus_subscription_edition_14.0.txt
  altera_device_lib_quartus_subscription_edition_13.1.txt
  altera_device_lib_quartus_subscription_edition_13.0.txt
  altera_device_lib_quartus_subscription_edition_12.1.txt
  altera_device_lib_quartus_subscription_edition_12.0.txt
  altera_device_lib_quartus_subscription_edition_11.1.txt
  altera_device_lib_quartus_subscription_edition_11.0.txt
  altera_device_lib_quartus_subscription_edition_10.1.txt
  altera_device_lib_quartus_subscription_edition_10.0.txt
  altera_device_lib_quartus_subscription_edition_9.1.txt


In order to manually activate the use of an appropriate library of FPGA devices,
please copy the respective file to the folder
   ATHENa/device_lib
under the name 
   altera_device_lib.txt
(and replace the previous file with the same name).

Please note that the basic functionality of ATHENa can be accomplished
even if the device library version does not match exactly the version of tools
installed on your computer.




