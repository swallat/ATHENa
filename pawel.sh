#!/usr/bin/env bash
export XILINX=/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64
export QUARTUS_ROOTDIR=
export PATH=/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64:/opt/Xilinx/14.7/ISE_DS/ISE/sysgen/util:/opt/Xilinx/14.7/ISE_DS/ISE/sysgen/bin:/opt/Xilinx/14.7/ISE_DS/ISE/../../../DocNav:/opt/Xilinx/14.7/ISE_DS/PlanAhead/bin:/opt/Xilinx/14.7/ISE_DS/EDK/bin/lin64:/opt/Xilinx/14.7/ISE_DS/EDK/gnu/microblaze/lin/bin:/opt/Xilinx/14.7/ISE_DS/EDK/gnu/powerpc-eabi/lin/bin:/opt/Xilinx/14.7/ISE_DS/EDK/gnu/arm/lin/bin:/opt/Xilinx/14.7/ISE_DS/EDK/gnu/microblaze/linux_toolchain/lin64_be/bin:/opt/Xilinx/14.7/ISE_DS/EDK/gnu/microblaze/linux_toolchain/lin64_le/bin:/opt/Xilinx/14.7/ISE_DS/common/bin/lin64:$PATH

designs=(RSA_textbook_shift_key_bits_1bit.txt)
BIT_SIZE=(128)
synthesis_options=(speed area balanced)

cd bin

for i in designs; do
	perl copy_new_config.pl $i
	create_source_list.pl
	for j in $BIT_SIZE; do
		for k in $synthesis_options; do
			perl optimization_target.pl $k $j
			main.pl
		done
	done
done