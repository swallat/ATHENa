#!/usr/bin/env bash
export XILINX="/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64"
export QUARTUS_ROOTDIR=""
export PATH=":/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64:$PATH"

designs=(RSA_textbook_shift_key_bits_1bit.txt)
BIT_SIZE=(128)
#synthesis_options=(speed area balanced)
synthesis_options=(speed)
ATHENa_WORKSPACE="ATHENa_workspace"
MAIN_DIR=`pwd`
echo $MAIN_DIRs

trap cleanup INT

function cleanup() {
	echo "Cleanup..."
	cd $MAIN_DIR
	rm -rf "ATHENa_workspace"
}

cd bin

for i in ${designs[@]}; do
	perl copy_new_config.pl $i
	perl create_source_list.pl
	for j in ${BIT_SIZE[@]}; do
		for k in ${synthesis_options[@]}; do
			perl optimization_target.pl $k $j
			perl main.pl
		done
	done
done

cleanup