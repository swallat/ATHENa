-- =====================================================================
-- Copyright © 2009 - 2014 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.

-- Adder code
-- =====================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.pack.all;

entity adder is
generic (
          vendor : integer := XILINX;				-- vendor 		: XILINX=0, ALTERA=1
          adder_type : integer:= ADD_DSP_BASED; 	-- adder_type 	: ADD_SCCA_BASED=0, ADD_DSP_BASED=1 
		    WIDTH : integer := 8					-- width 		: width (fixed width for input and output)
        );
port 
    ( 
	  a : in std_logic_vector (WIDTH-1 downto 0);
	  b : in std_logic_vector (WIDTH-1 downto 0);
	  s : out std_logic_vector (WIDTH-1 downto 0)
    );
end adder;

architecture adder of adder is
begin

--	-- default addition is performed using SCCA adder
	scca_adder_gen : if adder_type = ADD_SCCA_BASED generate
		s <= std_logic_vector(unsigned(a) + unsigned(b));
	end generate;
	
	xil_dsp_add_gen : if (adder_type=ADD_DSP_BASED and vendor = XILINX) generate
	add_xil:	entity work.adder(xilinx_dsp_add) generic map ( WIDTH => WIDTH ) 
											         port map (a => a, b => b, s => s );
	end generate;
	
	
	alt_dsp_add_gen : if (adder_type=ADD_DSP_BASED and vendor = ALTERA) generate
	add_alt:	entity work.adder(altera_dsp_add) generic map ( WIDTH => WIDTH ) 
											         port map (a => a, b => b, s => s );
	end generate;
	
end adder;
-- =======================================================
	
architecture xilinx_dsp_add of adder is

	signal s1 : std_logic_vector(WIDTH -1 downto 0);
	attribute use_dsp48 : string ;
	attribute use_dsp48 of s1 : signal is "yes";
	begin
	  
	s1 <= std_logic_vector(unsigned(a) + unsigned(b));
   s <= s1;
end xilinx_dsp_add;	
-- =======================================================

architecture altera_dsp_add of adder is
	  signal a0_un : unsigned(WIDTH-1 downto 0);
	  signal b0_un : unsigned(WIDTH-1 downto 0);
	  signal a1_un : unsigned(WIDTH-1 downto 0);
	  signal b1_un : unsigned(WIDTH-1 downto 0);
	  signal p0    : std_logic_vector(2*WIDTH-1 downto 0);
	  
	begin

		 a0_un <= unsigned(a);
		 b0_un <= unsigned(zeros(WIDTH-1 downto 1) & '1');
		 a1_un <= unsigned(b);
		 b1_un <= unsigned(zeros(WIDTH-1 downto 1) & '1');
			  
		 p0 	<= std_logic_vector( unsigned((a0_un * b0_un) + (a1_un * b1_un)) );
		  s	<= (p0(2*WIDTH-1 downto WIDTH+1) & '0') xor p0(WIDTH-1 downto 0);


end altera_dsp_add;
-- =======================================================