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

entity reg1 is 
port(
	clk		: in std_logic;
	ena		: in std_logic;
	rst		: in std_logic;
	d		: in std_logic;
	q		: out std_logic);
end reg1;

architecture a1 of reg1 is 
signal r	:std_logic;
begin
	
reg: 	process(clk)
		begin

			if (clk'event and clk='1') then 
				if rst ='1' then
					r <= '0'; 
				elsif ena = '1' then
					r <= d; 
				end if;
			end if; 

		end process;
	  q<=r;
end a1;
