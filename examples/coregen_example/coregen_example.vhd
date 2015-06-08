-- =============================================
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity coregen_example is
    Port ( a, b : in  STD_LOGIC_VECTOR (31 downto 0);
		   clk : in std_logic;
           y : out  STD_LOGIC_VECTOR (31 downto 0));
end coregen_example;

architecture mixed of coregen_example is

	component DSP_Adder32
		port (
		a: IN std_logic_VECTOR(31 downto 0);
		b: IN std_logic_VECTOR(31 downto 0);
		s: OUT std_logic_VECTOR(31 downto 0));
	end component;


	signal ap, bp, yp : std_logic_vector(31 downto 0);
begin
	process  (clk) 
	begin
		if rising_edge(clk) then
			ap <= a;
		end if;
	end process;

	process  (clk) 
	begin
		if rising_edge(clk) then
			bp <= b;
		end if;
	end process;


        dsp_adder : DSP_Adder32
		port map (
			a => ap,
			b => bp,
			s => yp);

	process  (clk) 
	begin
		if rising_edge(clk) then
			y <= yp;
		end if;
	end process;


end mixed;

