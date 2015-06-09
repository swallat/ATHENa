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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;   
use work.fugue_pkg.all;
 
entity fugue_padding is 
generic( w: integer:=FUGUE_WORD_SIZE);	  
  port (input   : in std_logic_vector(4 downto 0);   
        output  : out std_logic_vector(31 downto 0));   
end fugue_padding;   		   

architecture fugue_padding of fugue_padding is   
  type rom_type is array (31 downto 0) 
    of std_logic_vector (31 downto 0);   
  constant rom : rom_type :=  --padding rom
  ("11111111111111111111111111111111",
	"11111111111111111111111111111110",
	"11111111111111111111111111111100",
	"11111111111111111111111111111000",
	"11111111111111111111111111110000",
	"11111111111111111111111111100000",
	"11111111111111111111111111000000",
	"11111111111111111111111110000000",
	"11111111111111111111111100000000",
	"11111111111111111111111000000000",
	"11111111111111111111110000000000",
	"11111111111111111111100000000000",
	"11111111111111111111000000000000",
	"11111111111111111110000000000000",
	"11111111111111111100000000000000",
	"11111111111111111000000000000000",
	"11111111111111110000000000000000",
	"11111111111111100000000000000000",
	"11111111111111000000000000000000",
	"11111111111110000000000000000000",
	"11111111111100000000000000000000",
	"11111111111000000000000000000000",
	"11111111110000000000000000000000",
	"11111111100000000000000000000000",
	"11111111000000000000000000000000",
	"11111110000000000000000000000000",
	"11111100000000000000000000000000",
	"11111000000000000000000000000000",
	"11110000000000000000000000000000",
	"11100000000000000000000000000000",
	"11000000000000000000000000000000",
	"10000000000000000000000000000000");   
begin   
  output <= rom(conv_integer(unsigned(input))); --return byte from rom at address a
end fugue_padding;
 
