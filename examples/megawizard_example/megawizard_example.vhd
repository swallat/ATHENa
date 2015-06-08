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

entity megawizard_example is
    Port ( a, b : in  STD_LOGIC_VECTOR (15 downto 0);
		   clk : in std_logic;
           y : out  STD_LOGIC_VECTOR (31 downto 0));
end megawizard_example;

architecture mixed of megawizard_example is

component Embedded_Multiplier_16
	PORT
	(
		dataa		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
end component;


	signal ap, bp: std_logic_vector(15 downto 0);

	signal yp: std_logic_vector(31 downto 0);

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

	Embedded_Multiplier_16_inst : Embedded_Multiplier_16 PORT MAP (
		dataa	 => ap,
		datab	 => bp,
		result	 => yp
	);

	process  (clk) 
	begin
		if rising_edge(clk) then
			y <= yp;
		end if;
	end process;


end mixed;

