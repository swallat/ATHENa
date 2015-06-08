-- =============================================
-- SHA3 source code
-- Copyright © 2009 - 2014 CERG at George Mason University <cryptography.gmu.edu>.
--
-- This source code is free; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This source code is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this source code; if not, see http://www.gnu.org/licenses
-- or write to the Free Software Foundation,Inc., 51 Franklin Street,
-- Fifth Floor, Boston, MA 02110-1301  USA.
-- =============================================

library ieee;
use ieee.std_logic_1164.all; 
use work.sha3_pkg.all; 


entity regn is
	generic ( 

		N : integer := 32;
		init : std_logic_vector
	);
	port ( 	  
	    clk 	: in std_logic;
		rst 	: in std_logic;
	    en 		: in std_logic; 
		input  	: in std_logic_vector(N-1 downto 0);
        output 	: out std_logic_vector(N-1 downto 0)
	);
end regn;

architecture struct of regn is
--signal reg : std_logic_vector(N-1 downto 0);
begin	
	gen : process( clk )
	begin
		if rising_edge( clk ) then
			if ( rst = '1' ) then
				output <= init;
			elsif ( en = '1' ) then
				output<= input;
			end if;
		end if;
	end process;
	--output <= reg;  
end struct;