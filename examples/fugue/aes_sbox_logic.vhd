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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.sha3_pkg.all;


entity aes_sbox_logic is
    Port ( S_IN : in  STD_LOGIC_VECTOR (7 downto 0);
           S_OUT : out  STD_LOGIC_VECTOR (7 downto 0));
end aes_sbox_logic;

architecture aes_sbox_logic of aes_sbox_logic is

signal RES_MUL_X, RES_GF_INV, RES_MUL_MX : std_logic_vector (7 downto 0);

constant b : std_logic_vector (7 downto 0) := "01100011";

begin

	RES_MUL_X <= MUL_X(x=> S_IN);
	
	RES_GF_INV <= GF_INV_8 (x=> RES_MUL_X);
	
	RES_MUL_MX <= MUL_MX (x=> RES_GF_INV);
	
	S_OUT <= b xor RES_MUL_MX;

end aes_sbox_logic;

