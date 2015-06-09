-- =====================================================================
-- Copyright © 2009 - 2014 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

-------------------------------
-- Simple Multiplier in Altera
-------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity mult_alt is

 generic (WIDTH: integer := 8);
 port (
       a        : in  std_logic_vector(WIDTH-1 downto 0);
       b        : in  std_logic_vector(WIDTH-1 downto 0);
       s         : out std_logic_vector(WIDTH-1 downto 0));
end mult_alt;

architecture structl of mult_alt is
signal temp : std_logic_vector(2*WIDTH -1 downto 0);

attribute multstyle : string ;
attribute multstyle of s : signal is "logic";

begin

temp <= STD_LOGIC_VECTOR(unsigned(a) * unsigned(b));
s <= temp(WIDTH-1 downto 0);

end structl;