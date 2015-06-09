set XILINX=D:\pawel\ISE\14.7\ISE_DS\ISE\bin\nt\
set QUARTUS_ROOTDIR=
PATH=;D:\pawel\ISE\14.7\ISE_DS\ISE\bin\nt\;D:\pawel\activeperl5.20.2\site\bin;D:\pawel\activeperl5.20.2\bin;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v4.2\\bin;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v4.2\libnvvp\;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v4.1\\bin;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v4.1\libnvvp\;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v4.0\bin\;C:\Program Files\Perl64\site\bin;C:\Program Files\Perl64\bin;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Program Files\Intel\DMIX;C:\Program Files (x86)\Microsoft SQL Server\100\Tools\Binn\;C:\Program Files\Microsoft SQL Server\100\Tools\Binn\;C:\Program Files\Microsoft SQL Server\100\DTS\Binn\;C:\Program Files\AMCC\CLI;C:\Program Files\MATLAB\R2014b\runtime\win64;C:\Program Files\MATLAB\R2014b\bin;C:\Program Files\MATLAB\R2010b\runtime\win64;C:\Program Files\MATLAB\R2010b\bin;C:\Program Files (x86)\Microsoft SQL Server\90\Tools\binn\;C:\ProgramData\NVIDIA Corporation\NVIDIA GPU Computing SDK 4.2\C\common\bin;C:\Program Files\TortoiseSVN\bin;C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\bin

cd bin
main.pl %1
if "%1" == "nopause" goto nopause
pause
:nopause
echo done.
cd ..
