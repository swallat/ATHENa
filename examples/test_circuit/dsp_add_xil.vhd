-- =====================================================================
-- Copyright © 2009 - 2014 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

----------------------
-- DSP Adder in Xilinx
----------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dsp_add_xil is
generic (
		WIDTH : integer := 8
        );
port 
    ( 
	  a : in std_logic_vector (WIDTH-1 downto 0);
	  b : in std_logic_vector (WIDTH-1 downto 0);
	  s : out std_logic_vector (WIDTH-1 downto 0)
    );
end dsp_add_xil;

architecture struct of dsp_add_xil is

attribute use_dsp48 : string ;
attribute use_dsp48 of s : signal is "yes";

begin
  
s <= std_logic_vector(unsigned(a) + unsigned(b));

end struct;