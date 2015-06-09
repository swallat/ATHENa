
%VENDOR_TOOLS = ();
my @VTOOLS = qw(ISE SYNPLIFY);
$VENDOR_TOOLS{XILINX} = \@VTOOLS;
my @VTOOLS = qw(QUARTUS SYNPLIFY);
$VENDOR_TOOLS{ALTERA} = \@VTOOLS;
my @VTOOLS = qw(SYNPLIFY);
$VENDOR_TOOLS{ACTEL} = \@VTOOLS;

#my @VERSIONS = qw(9.1 9.2 10.1 11.1 11.3 11.4);
#$VENDOR_TOOL_VERSIONS{XILINX}{ISE} = \@VERSIONS;

%VENDOR_SYNTHESIS_TOOLS = ();
my @SYNTOOLS = qw(XST);
$VENDOR_SYNTHESIS_TOOLS{XILINX}{ISE} = \@SYNTOOLS;
my @SYNTOOLS = qw(SYNPLIFY);
$VENDOR_SYNTHESIS_TOOLS{XILINX}{SYNPLIFY} = \@SYNTOOLS;

my @SYNTOOLS = qw(QUARTUS_MAP);
$VENDOR_SYNTHESIS_TOOLS{ALTERA}{QUARTUS} = \@SYNTOOLS;
my @SYNTOOLS = qw(SYNPLIFY);
$VENDOR_SYNTHESIS_TOOLS{ALTERA}{SYNPLIFY} = \@SYNTOOLS;

my @SYNTOOLS = qw(SYNPLIFY);
$VENDOR_SYNTHESIS_TOOLS{ACTEL}{SYNPLIFY} = \@SYNTOOLS;

%VENDOR_IMPLEMENTATION_TOOLS = ();
my @IMPTOOLS = qw(NGDBUILD MAP PAR TRACE);
$VENDOR_IMPLEMENTATION_TOOLS{XILINX}{ISE} = \@IMPTOOLS;

my @IMPTOOLS = qw(QUARTUS_FIT QUARTUS_ASM QUARTUS_TAN QUARTUS_STA QUARTUS_POW);
$VENDOR_IMPLEMENTATION_TOOLS{ALTERA}{QUARTUS} = \@IMPTOOLS;

%VENDOR_TOOL_EXECUTABLES = ();

$VENDOR_TOOL_EXECUTABLES{XILINX}{ISE}{XST} = "";
$VENDOR_TOOL_EXECUTABLES{XILINX}{ISE}{NGDBUILD} = "";
$VENDOR_TOOL_EXECUTABLES{XILINX}{ISE}{MAP} = "";
$VENDOR_TOOL_EXECUTABLES{XILINX}{ISE}{PAR} = "";
$VENDOR_TOOL_EXECUTABLES{XILINX}{ISE}{TRACE} = "";

$VENDOR_TOOL_EXECUTABLES{XILINX}{SYNPLIFY}{SYNPLIFY} = "";

$VENDOR_TOOL_EXECUTABLES{ALTERA}{QUARTUS}{QUARTUS_MAP} = "";
$VENDOR_TOOL_EXECUTABLES{ALTERA}{QUARTUS}{QUARTUS_FIT} = "";
$VENDOR_TOOL_EXECUTABLES{ALTERA}{QUARTUS}{QUARTUS_ASM} = "";
$VENDOR_TOOL_EXECUTABLES{ALTERA}{QUARTUS}{QUARTUS_TAN} = "";
$VENDOR_TOOL_EXECUTABLES{ALTERA}{QUARTUS}{QUARTUS_STA} = "";
$VENDOR_TOOL_EXECUTABLES{ALTERA}{QUARTUS}{QUARTUS_POW} = "";

$VENDOR_TOOL_EXECUTABLES{ALTERA}{SYNPLIFY}{SYNPLIFY} = "";

$VENDOR_TOOL_EXECUTABLES{ACTEL}{SYNPLIFY}{SYNPLIFY} = "";