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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity coregen_example is
    Port ( i : in  STD_LOGIC_VECTOR (2 downto 0);
		   clk : in std_logic;
           o : out  STD_LOGIC_VECTOR (6 downto 0));
end coregen_example;

architecture Behavioral of coregen_example is
	component dsp48_macro IS
		port (
		clk: IN std_logic;
		a: IN std_logic_VECTOR(2 downto 0);
		b: IN std_logic_VECTOR(2 downto 0);
		c: IN std_logic_VECTOR(2 downto 0);
		p: OUT std_logic_VECTOR(6 downto 0));
	END component;

	signal i1, i2 : std_logic_vector(2 downto 0);
begin
	process  ( clk ) 
	begin
		if rising_edge( clk ) then
			i1 <= i;
			i2 <= i1;
		end if;
	end process;

	dsp_gen : dsp48_macro port map ( clk => clk, a => i, b => i1, c => i2, p => o );
end Behavioral;

