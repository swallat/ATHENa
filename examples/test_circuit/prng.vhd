-- =====================================================================
-- Copyright © 2009 - 2014 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

--------------------------------------------
---- 8-bit Pseudorandom Number Generator ---
--------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity prng is
  port (
			D      : in std_logic_vector(7 downto 0);
			Q      : out std_logic_vector(7 downto 0);
			clk    : in std_logic;
			reset  : in std_logic;
			load	 : in std_logic;
			en 	 : in std_logic    
       );
end prng;

architecture arch_prng of prng is

signal Qt: std_logic_vector(7 downto 0);	
signal xor_out : std_logic;

begin
process (clk, reset)
begin
        	if reset ='1' then
                    Qt <= (others => '0');
               	elsif rising_edge(clk) then
                	if en = '1' then
                        	if load = '1' then 
                              Qt <= D ;
                        	else
                              Qt <= Qt(6 downto 0) & xor_out;
                        	end if;
                	end if;
        	end if ;
end process ;
xor_out <= Qt(0) xor Qt(4) xor Qt(5) xor Qt(7);
Q <= Qt;

end arch_prng;