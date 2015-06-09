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
USE ieee.std_logic_1164.all; 
use work.sha3_pkg.all;
use work.fugue_pkg.all;

entity fugue_tix is
generic (w :integer := FUGUE_WORD_SIZE);
port (	
	p 	: in	std_logic_vector(w-1 downto 0);
	i0	: in	std_logic_vector(w-1 downto 0);
	i1	: in	std_logic_vector(w-1 downto 0);
	i8	: in	std_logic_vector(w-1 downto 0);
	i10     : in	std_logic_vector(w-1 downto 0);
	i24     : in	std_logic_vector(w-1 downto 0);
	o0      : out 	std_logic_vector(w-1 downto 0);
	o1      : out 	std_logic_vector(w-1 downto 0);
	o8      : out 	std_logic_vector(w-1 downto 0);
	o10     : out 	std_logic_vector(w-1 downto 0));
end fugue_tix;

architecture fugue_tix of fugue_tix is	
signal p_in : std_logic_vector(w-1 downto 0);
begin

	--fix endian-ness

	p_in <= switch_endian_word(x=>p, width=>FUGUE_WORD_SIZE, w=>8);
	
	o0<=p_in;
	o10<=i0 xor i10;
	o8<=p_in xor i8;
	o1<=i24 xor i1;

end fugue_tix;
