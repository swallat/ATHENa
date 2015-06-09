-- =====================================================================
-- Copyright © 2009 - 2014 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

-----------------------
-- DSP Adder in Altera
-----------------------

--Basic function of ALTMULT_ADD, using 8 bit input data

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity dsp_add_alt is  
  generic (WIDTH: integer := 8);
  port (
			a0        : in  std_logic_vector(WIDTH-1 downto 0);
			a1        : in  std_logic_vector(WIDTH-1 downto 0);
			w         : out std_logic_vector(WIDTH-1 downto 0)
    	);
end dsp_add_alt;

architecture struct of dsp_add_alt is

  signal a0_un : unsigned(WIDTH-1 downto 0);
  signal b0_un : unsigned(WIDTH-1 downto 0);
  signal a1_un : unsigned(WIDTH-1 downto 0);
  signal b1_un : unsigned(WIDTH-1 downto 0);
  signal p0     : std_logic_vector(2*WIDTH-1 downto 0);
  signal zeros	: unsigned(WIDTH-1 downto 0);

begin

	zeros <= (others => '0');
    a0_un <= unsigned(a0);
    b0_un <= unsigned(zeros(WIDTH-1 downto 1) & '1');
    a1_un <= unsigned(a1);
    b1_un <= unsigned(zeros(WIDTH-1 downto 1) & '1');
        
    p0 	<= std_logic_vector( unsigned((a0_un * b0_un) + (a1_un * b1_un)) );
	w	<= (p0(2*WIDTH-1 downto WIDTH+1) & '0') xor p0(WIDTH-1 downto 0);
		
end struct;


