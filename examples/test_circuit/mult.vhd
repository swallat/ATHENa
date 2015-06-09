-- =====================================================================
-- Copyright © 2009 - 2014 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.

-- MULTIPLIER code
-- =====================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.pack.all;

entity mult is
generic 
		(
          vendor : integer := XILINX;							-- vendor 			: XILINX=0, ALTERA=1
          multiplier_type : integer:= MUL_DEDICATED;   -- multiplier_type 	: MUL_LOGIC_BASED=0, MUL_DSP_BASED=1 
		    WIDTH : integer := 8									-- width 			: width (fixed width for input and output)
      );
port 
    ( 	
			a : in std_logic_vector (WIDTH-1 downto 0);
			b : in std_logic_vector (WIDTH-1 downto 0);
			s : out std_logic_vector (WIDTH-1 downto 0)
    );
end mult;

architecture mult of mult is

begin

	xil_dsp_mult_gen : if (multiplier_type = MUL_DEDICATED and vendor = XILINX) generate
	mult_xil:	entity work.mult(xilinx_dsp) generic map ( WIDTH => WIDTH ) 
											         port map (a => a, b => b, s => s );
			end generate;
	
	xil_logic_mult_gen : if (multiplier_type=MUL_LOGIC_BASED and vendor = XILINX) generate
	mult_xil:	entity work.mult(xilinx_logic) generic map ( WIDTH => WIDTH ) 
											         port map (a => a, b => b, s => s );
	end generate; 

   alt_dsp_mult_gen : if (multiplier_type=MUL_DEDICATED and vendor = ALTERA) generate
	mult_alt:	entity work.mult(altera_dsp) generic map ( WIDTH => WIDTH ) 
											         port map (a => a, b => b, s => s );
	end generate;

	
	alt_logic_mult_gen : if (multiplier_type=MUL_LOGIC_BASED and vendor = ALTERA) generate
	mult_alt:	entity work.mult(altera_logic) generic map ( WIDTH => WIDTH ) 
											         port map (a => a, b => b, s => s );
	end generate;
	
end mult;	
-- =======================================================

architecture xilinx_logic of mult is
	signal temp1 : std_logic_vector(2*WIDTH -1 downto 0);

	attribute mult_style : string ;
	attribute mult_style of temp1: signal is "lut";

	begin

		temp1 <= STD_LOGIC_VECTOR(unsigned(a) * unsigned(b));
		s <= temp1(WIDTH-1 downto 0);

end xilinx_logic;	
-- =======================================================

architecture xilinx_dsp of mult is
	signal temp2 : std_logic_vector(2*WIDTH -1 downto 0);

	attribute mult_style : string ;
	attribute mult_style of temp2: signal is "block";

	begin

		temp2 <= STD_LOGIC_VECTOR(unsigned(a) * unsigned(b));
		s <= temp2(WIDTH-1 downto 0);

end xilinx_dsp;
-- =======================================================

architecture altera_logic of mult is
	signal temp : std_logic_vector(2*WIDTH -1 downto 0);

	attribute multstyle : string ;
	attribute multstyle of altera_logic : architecture is "logic";
	begin

		temp <= STD_LOGIC_VECTOR(unsigned(a) * unsigned(b));
		s <= temp(WIDTH-1 downto 0);

end altera_logic;	
-- =======================================================

architecture altera_dsp of mult is
	signal temp : std_logic_vector(2*WIDTH -1 downto 0);

	attribute multstyle : string ;
	attribute multstyle of altera_dsp : architecture is "dsp";	
	begin

		temp <= STD_LOGIC_VECTOR(unsigned(a) * unsigned(b));
		s <= temp(WIDTH-1 downto 0);

end altera_dsp;	
-- =======================================================