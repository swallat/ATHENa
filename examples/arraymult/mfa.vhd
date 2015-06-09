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

-- ==============================
-- Example - Array Multiplier
-- ==============================

library ieee;
use ieee.std_logic_1164.all;


entity mfa is 
	generic ( not_and : std_logic := '0' );
	port ( 
		a : in std_logic;
		x : in std_logic;
		s : in std_logic;
		c : in std_logic;
		
		cout   : out std_logic;
		sumout : out std_logic
	);
end mfa;

architecture structure of mfa is 
	signal y : std_logic;
begin 				
	y_and : if not_and = '0' generate
		y <= a and x;
	end generate;
	
	y_nand : if not_and = '1' generate
		y <= not( a and x );
	end generate;
	
	cout <= (y and s) or (y and c) or (s and c);
	sumout <= y xor s xor c;	
end structure;