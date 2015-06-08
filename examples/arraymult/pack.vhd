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
use ieee.std_logic_arith.all;

package pack is		   
	constant clkperiod : time := 30 ns;
	

	component reg1 is 
		port(
			clk			: in std_logic;			
			ena			: in std_logic;
			d			: in std_logic;
			q			: out std_logic);
	end component;
	
	component mfa is    
	generic ( not_and : std_logic := '0' );
	port ( 
		a : in std_logic;
		x : in std_logic;
		s : in std_logic;
		c : in std_logic;
		
		cout   : out std_logic;
		sumout : out std_logic
	);
	end component; 
	

	component fa is    						  
	port ( 
		a : in std_logic;
		b : in std_logic;		
		c : in std_logic;
		
		cout   : out std_logic;
		sumout : out std_logic
	);
	end component;


end package;   
