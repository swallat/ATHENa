-- =============================================
-- SHA2 source code
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.sha2_pkg.all;

entity counter is 
generic (
	s 		: integer :=2; 	-- size of counter 
	r		: integer:=2; 	-- counter limit 
	step	: integer:=1);	-- stepping 
port(
	clk		:in std_logic;
	reset 		:in std_logic;
	ena 		:in std_logic;
	ctr		:out std_logic_vector(s-1 downto 0));
end counter;

architecture a1 of counter is 
	signal reg	:std_logic_vector(s-1 downto 0);
begin

process(clk, reset)
begin
	if reset='1' then 
		reg<= (others =>'0');
	elsif (clk'event and clk='1') then 
		if ena = '1' then
			if (reg=std_logic_vector(conv_unsigned(r, s))) then
				reg<= (others =>'0');		
			else 	
				reg <=reg+step;
			end if;

		end if;

	end if;
end process;
	
	ctr <= reg;
	
end a1;
