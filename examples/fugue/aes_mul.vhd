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
use work.sha3_pkg.all;

entity aes_mul is
generic (n	:integer := AES_SBOX_SIZE;	cons 	:integer := 3);
port( 
	input 		: in std_logic_vector(n-1 downto 0);
        output 		: out std_logic_vector(n-1 downto 0));
end aes_mul;
  
architecture aes_mul of aes_mul is

begin


c1:if cons=1 generate 
m3	: entity work.aes_mul(aes_mulx01) generic map (cons=>cons) port map (input=>input, output=>output);	
end generate;

c2:if cons=2 generate 
m3	: entity work.aes_mul(aes_mulx02) generic map (cons=>cons) port map (input=>input, output=>output);	
end generate;

c3:if cons=3 generate 
m3	: entity work.aes_mul(aes_mulx03) generic map (cons=>cons) port map (input=>input, output=>output);	
end generate;

c4:if cons=4 generate 
m3	: entity work.aes_mul(aes_mulx04) generic map (cons=>cons) port map (input=>input, output=>output);	
end generate;

c5:if cons=5 generate 
m3	: entity work.aes_mul(aes_mulx05) generic map (cons=>cons) port map (input=>input, output=>output);	
end generate;

c6:if cons=6 generate 
m3	: entity work.aes_mul(aes_mulx06) generic map (cons=>cons) port map (input=>input, output=>output);	
end generate;

c7:if cons=7 generate 
m3	: entity work.aes_mul(aes_mulx07) generic map (cons=>cons) port map (input=>input, output=>output);	
end generate;


end aes_mul; 


architecture aes_mulx01 of aes_mul is

begin

output <= input;	

end aes_mulx01; 


architecture aes_mulx02 of aes_mul is

begin

	output(7) <= input(6);
	output(6) <= input(5);
	output(5) <= input(4);
	output(4) <= input(7) xor input(3);
	output(3) <= input(7) xor input(2);
	output(2) <= input(1);
	output(1) <= input(7) xor input(0);
	output(0) <= input(7);

end aes_mulx02; 



architecture aes_mulx03 of aes_mul is

begin

	output(7) <= input(7) xor input(6);
	output(6) <= input(6) xor input(5);
	output(5) <= input(5) xor input(4);
	output(4) <= input(7) xor input(4) xor input(3);
	output(3) <= input(7) xor input(3) xor input(2);
	output(2) <= input(2) xor input(1);
	output(1) <= input(7) xor input(1) xor input(0);
	output(0) <= input(7) xor input(0);

end aes_mulx03; 


architecture aes_mulx04 of aes_mul is

begin

	output(7) <= input(5);
	output(6) <= input(4);
	output(5) <= input(7) xor input(3);
	output(4) <= input(7) xor input(6) xor input(2);
	output(3) <= input(6) xor input(1);
	output(2) <= input(7) xor input(0);
	output(1) <= input(7) xor input(6);
	output(0) <= input(6); 

end aes_mulx04; 

architecture aes_mulx05 of aes_mul is

begin

	output(7) <= input(5) xor input(7);
	output(6) <= input(4) xor input(6);
	output(5) <= input(3) xor input(5) xor input(7);
	output(4) <= input(2) xor input(4) xor input(6) xor input(7);
	output(3) <= input(1) xor input(3) xor input(6);
	output(2) <= input(0) xor input(2) xor input(7);
	output(1) <= input(1) xor input(6) xor input(7);
	output(0) <= input(0) xor input(6);
		
end aes_mulx05;  

architecture aes_mulx06 of aes_mul is

begin

	output(7) <= input(5) xor input(6);
	output(6) <= input(4) xor input(5);
	output(5) <= input(3) xor input(4) xor input(7);
	output(4) <= input(2) xor input(3) xor input(6);
	output(3) <= input(1) xor input(2) xor input(6) xor input(7);
	output(2) <= input(0) xor input(1) xor input(7);
	output(1) <= input(0) xor input(6);
	output(0) <= input(6) xor input(7);
		
end aes_mulx06;

architecture aes_mulx07 of aes_mul is

begin

	output(7) <= input(5) xor input(6) xor input(7);
	output(6) <= input(4) xor input(5) xor input(6);
	output(5) <= input(3) xor input(4) xor input(5) xor input(7);
	output(4) <= input(2) xor input(3) xor input(4) xor input(6);
	output(3) <= input(1) xor input(2) xor input(3) xor input(6) xor input(7);
	output(2) <= input(0) xor input(1) xor input(2) xor input(7);
	output(1) <= input(0) xor input(1) xor input(6);
	output(0) <= input(0) xor input(6) xor input(7);
		
end aes_mulx07; 
