-- =====================================================================
-- Copyright © 2009 - 2014 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

-------------------------------
-- Simple Multiplier in Xilinx
-------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mult_xil is
generic (
				WIDTH : integer := 8
        );
port 
    ( 
	  a : in std_logic_vector (WIDTH-1 downto 0);
	  b : in std_logic_vector (WIDTH-1 downto 0);
	  s : out std_logic_vector (WIDTH-1 downto 0)
    );
end mult_xil;

architecture struct1 of mult_xil is

signal temp : std_logic_vector(2*WIDTH -1 downto 0);

attribute use_dsp48 : string ;
attribute use_dsp48 of S : signal is "no";

begin

temp <= STD_LOGIC_VECTOR(unsigned(a) * unsigned(b));
s <= temp(WIDTH-1 downto 0);

end struct1;
