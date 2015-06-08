-- =============================================
-- SHA2 source code
-- Copyright © 2008-2009 - 2014 CERG at George Mason University <cryptography.gmu.edu>.
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

entity sigma_func is
generic( 
	n 		: integer :=ARCH_32; 		-- size of basic operation
	func 		: string :="ms"; 		-- message scheduler or compression function
	a 		: integer:=ARCH32_CF0_1;	-- rotation values are different for MS and for CF  	 	
	b 		: integer:=ARCH32_CF0_2; 
	c 		: integer:=ARCH32_CF0_3);
port(
	x		:in std_logic_vector(n-1 downto 0);
	o		:out std_logic_vector(n-1 downto 0));
end sigma_func;

architecture sigma_func of sigma_func is
	signal tmp	:std_logic_vector(c-1 downto 0);
begin										  
	
ms:	if func="ms" generate
			tmp <= (others=>'0');
	end generate;

cf:	if func="cf" generate
			tmp <= x(c-1 downto 0);
	end generate;
			
			o <= (x(a-1 downto 0) & x(n-1 downto a))
		 	xor (x(b-1 downto 0) & x(n-1 downto b))
	 		xor (tmp & x(n-1 downto c));
						
end sigma_func;
