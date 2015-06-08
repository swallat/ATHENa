-- =====================================================================
-- Copyright © 2009 - 2014 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

library ieee;
use ieee.std_logic_1164.all;


entity reg1 is 
generic(WIDTH : integer := 8);
port(
		clk			: in std_logic;	
		reset			: in std_logic;
		ena			: in std_logic;
		d			   : in std_logic_vector(WIDTH-1 downto 0);
		q			   : out std_logic_vector(WIDTH-1 downto 0)
	);
end reg1;

architecture struc of reg1 is 
	
begin	
	
	reg: process(clk, reset)
	begin
	   if reset ='1' then
         q <= (others => '0');
		elsif (clk'event and clk='1') then 
			if ena = '1' then
				q <= d;
			end if;
		end if; 
	end process;
end struc;