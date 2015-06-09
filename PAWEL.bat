REM #___
echo off

set XILINX=D:\pawel\ISE\14.7\ISE_DS\ISE\bin\nt
set QUARTUS_ROOTDIR=
set ATHENa_workspace=ATHENa_workspace
cd bin

set designs=(RSA_textbook_shift_key_bits_1bit.txt)
set BIT_SIZES=(128)
set synthesis_options=(speed area balanced)

for %%d in %designs% do (
	perl copy_new_config.pl %%d
	create_source_list.pl
	for %%i in %BIT_SIZES% do (
		for %%n in %synthesis_options% do (
			perl optimization_target.pl %%n %%i
			main.pl
		)
	)
)

RMDIR /S /Q ATHENa_workspace