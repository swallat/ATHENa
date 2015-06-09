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
use work.fugue_pkg.all;

entity fugue_cmix is
generic (w : integer:=FUGUE_WORD_SIZE);
port (	
	i0	: in std_logic_vector(w-1 downto 0);
	i1	: in std_logic_vector(w-1 downto 0);
	i2	: in std_logic_vector(w-1 downto 0);
	i4	: in std_logic_vector(w-1 downto 0);
	i5	: in std_logic_vector(w-1 downto 0);
	i6	: in std_logic_vector(w-1 downto 0);
	i15	: in std_logic_vector(w-1 downto 0);
	i16	: in std_logic_vector(w-1 downto 0);
	i17	: in std_logic_vector(w-1 downto 0);
	o0	: out std_logic_vector(w-1 downto 0);
	o1	: out std_logic_vector(w-1 downto 0);
	o2	: out std_logic_vector(w-1 downto 0);
	o15	: out std_logic_vector(w-1 downto 0);
	o16	: out std_logic_vector(w-1 downto 0);
	o17	: out std_logic_vector(w-1 downto 0));
end fugue_cmix;

architecture fugue_cmix of fugue_cmix is	
begin

	o0<=i4 xor i0;
	o15<=i4 xor i15;
	o1<=i5 xor i1;
	o16<=i5 xor i16;
	o2<=i6 xor i2;
	o17<=i6 xor i17;

end fugue_cmix;
