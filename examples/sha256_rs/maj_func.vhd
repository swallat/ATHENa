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
use work.sha2_pkg.all;

entity maj_func is
generic( n : integer :=ARCH_32);
port(
	x		:in std_logic_vector(n-1 downto 0);
	y		:in std_logic_vector(n-1 downto 0);
	z		:in std_logic_vector(n-1 downto 0);
	o		:out std_logic_vector(n-1 downto 0));
end maj_func;

architecture basic of maj_func is
begin

			o <= (x and y) xor (x and z) xor (y and z);

end basic;

