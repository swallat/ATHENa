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
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all; 
use work.sha3_pkg.all;	
use work.fugue_pkg.all;

entity fugue_smix is
generic( w: integer:=FUGUE_WORD_SIZE);
	port (	
		clk		: in std_logic;
		I0		: in std_logic_vector(w-1 downto 0);
		I1	      	: in std_logic_vector(w-1 downto 0);
		I2		: in std_logic_vector(w-1 downto 0);
		I3		: in std_logic_vector(w-1 downto 0);
		O0	      	: out std_logic_vector(w-1 downto 0);
		O1		: out std_logic_vector(w-1 downto 0);
		O2		: out std_logic_vector(w-1 downto 0);
		O3		: out std_logic_vector(w-1 downto 0));
end fugue_smix;

architecture fugue_smix of fugue_smix is	

type array16 is array (0 to 15) of std_logic_vector(7 downto 0);
signal addr, d, mul_by_four, mul_by_seven : array16;
signal d8x6, d13x6, d2x6 : std_logic_vector(7 downto 0);
signal d7x6, d12x5, d1x5, d6x5, d11x5 : std_logic_vector(7 downto 0);
	
begin

	I0boxgen: for i in 0 to 3 generate
		addr(i)<=I0(((8*i)+7) downto 8*i);
		addr(4+i)<=I1(((8*i)+7) downto 8*i);
		addr(8+i)<=I2(((8*i)+7) downto 8*i);
		addr(12+i)<=I3(((8*i)+7) downto 8*i);

	end generate I0boxgen;
		
	--make 16 Sbox ROMs
	sboxes: for i in 0 to 15 generate
		sboxi 	:aes_sbox port map ( clk=>clk, input => addr(i), output => d(i));
		amb4	:entity work.aes_mul(aes_mul) generic map (cons=>4) port map (input=>d(i), output=>mul_by_four(i));
		amb7	:entity work.aes_mul(aes_mul) generic map (cons=>7) port map (input=>d(i), output=>mul_by_seven(i));

	end generate sboxes;
			
		
	am6a: entity work.aes_mul(aes_mul) generic map (cons=>6) port map (input=>d(2), output=>d2x6);
	am6b: entity work.aes_mul(aes_mul) generic map (cons=>6) port map (input=>d(7), output=>d7x6);
	am6c: entity work.aes_mul(aes_mul) generic map (cons=>6) port map (input=>d(8), output=>d8x6);
	am6d: entity work.aes_mul(aes_mul) generic map (cons=>6) port map (input=>d(13), output=>d13x6);

	am5a: entity work.aes_mul(aes_mul) generic map (cons=>5) port map (input=>d(1), output=>d1x5);
	am5b: entity work.aes_mul(aes_mul) generic map (cons=>5) port map (input=>d(6), output=>d6x5);
	am5c: entity work.aes_mul(aes_mul) generic map (cons=>5) port map (input=>d(11), output=>d11x5);
	am5d: entity work.aes_mul(aes_mul) generic map (cons=>5) port map (input=>d(12), output=>d12x5);

	O0(7 downto 0)  <=d(0) xor mul_by_four(1) xor mul_by_seven(2) xor d(3) xor d(4) xor d(8) xor d(12);	
	
	O0(15 downto 8) <=d(1) xor d(4) xor d(5) xor mul_by_four(6) xor mul_by_seven(7) xor d(9) xor d(13); 
	
	O0(23 downto 16)<=d(2) xor d(6) xor mul_by_seven(8)xor d(9) xor d(10) xor mul_by_four(11) xor d(14);
	
	O0(w-1 downto 24)<=d(3) xor d(7) xor d(11) xor mul_by_four(12) xor mul_by_seven(13)xor d(14) xor d(15);

	O1(7 downto 0)  <=mul_by_four(5) xor mul_by_seven(6) xor d(7) xor d(8) xor d(12); 
	
	
	O1(15 downto 8) <=d(1) xor d(8) xor mul_by_four(10) xor mul_by_seven(11) xor d(13);
	
	O1(23 downto 16)<=d(2) xor d(6) xor mul_by_seven(12) xor d(13) xor mul_by_four(15); 
	
	O1(w-1 downto 24)<=mul_by_four(0) xor mul_by_seven(1) xor d(2) xor d(7) xor d(11);

	O2(7 downto 0)  <=mul_by_seven(4) xor d8x6 xor mul_by_four(9) xor mul_by_seven(10) xor d(11) xor mul_by_seven(12);	 
	
	O2(15 downto 8) <=mul_by_seven(1) xor mul_by_seven(9) xor d(12) xor d13x6 xor mul_by_four(14) xor mul_by_seven(15);

	O2(23 downto 16)<=mul_by_seven(0) xor d(1) xor d2x6 xor mul_by_four(3) xor mul_by_seven(6) xor mul_by_seven(14);
	
	O2(w-1 downto 24)<=mul_by_seven(3) xor mul_by_four(4) xor mul_by_seven(5) xor d(6) xor d7x6 xor mul_by_seven(11);

	O3(7 downto 0)  <=mul_by_four(4) xor mul_by_four(8) xor d12x5 xor mul_by_four(13) xor mul_by_seven(14) xor d(15);
	
	O3(15 downto 8) <=d(0) xor d1x5 xor mul_by_four(2)xor mul_by_seven(3) xor mul_by_four(9) xor mul_by_four(13);
	
	O3(23 downto 16)<=mul_by_four(2) xor mul_by_seven(4) xor d(5) xor d6x5 xor mul_by_four(7) xor mul_by_four(14);
	
	O3(w-1 downto 24)<=mul_by_four(3) xor mul_by_four(7) xor mul_by_four(8) xor mul_by_seven(9) xor d(10) xor d11x5;

end fugue_smix;
