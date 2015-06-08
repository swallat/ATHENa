-- =============================================
-- SHA2 source code
-- Copyright © 2008-2009 - 2014 CERG at George Mason University <cryptography.gmu.edu>.
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
use work.sha2_pkg.all;

entity msg_scheduler is 
generic( l: integer:=1; n : integer :=ARCH_32);
port(
	clk			: in std_logic;
	sel			: in std_logic;
	wr_data		: in std_logic;
	data		: in std_logic_vector(n-1 downto 0);
	w			: out std_logic_vector(l*n-1 downto 0));
end msg_scheduler;

architecture a1 of msg_scheduler is				 

type matrix is array (0 to 16) of std_logic_vector(n-1 downto 0);
signal wires	: matrix;

signal wwires		: std_logic_vector(n-1 downto 0);

signal d_one_wire 	: std_logic_vector(n-1 downto 0);
signal d_zero_wire	: std_logic_vector(n-1 downto 0);  


begin

m0		:  muxn generic map (n=> n)port map (sel=>sel, a=>data, b=>wwires, o=>wires(0));


rg	: for i in 0 to 15 generate
		regs: Process(clk)
		begin		
			
			if (clk'event and clk = '1') then
					if (wr_data = '1') then
						wires(i+1)<=wires(i);
					end if;
				end if;   
		end process;	  
end generate;	

d0	: sigma_func  	generic map (n=>n, func=>"ms", a=>ARCH32_MS0_1, b=>ARCH32_MS0_2, c=>ARCH32_MS0_3) port map (x=>wires(15), o=>d_zero_wire);
d1	: sigma_func  	generic map (n=>n, func=>"ms", a=>ARCH32_MS1_1, b=>ARCH32_MS1_2, c=>ARCH32_MS1_3) port map (x=>wires(2), o=>d_one_wire);

wwires <= wires(7) + wires(16) + d_zero_wire + d_one_wire;

output: for i in 1 to l generate 
	w((i*n-1) downto (i-1)*n) <= wires(i);
end generate;	

end a1;

