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
use work.sha3_pkg.all;

package tb_pkg is 	
	
component fifo_ram is
generic ( 	
	fifo_style		: integer := BRAM;	
	depth 			: integer := 512;
	log2depth  		: integer := 9;
	n 				: integer := 64 );	
port ( 	
	clk 			: in  std_logic;
	write 			: in  std_logic;
	rd_addr 		: in  std_logic_vector (log2depth-1 downto 0);
	wr_addr 		: in  std_logic_vector (log2depth-1 downto 0);
	din 			: in  std_logic_vector (n-1 downto 0);
	dout 			: out std_logic_vector (n-1 downto 0));
end component;

component fifo
generic (
	fifo_mode		: integer := ZERO_WAIT_STATE;	
	fifo_style		: integer := BRAM;	
	depth 			: integer := 64;
	log2depth 		: integer := 6;
	N 				: integer := 32);
port (
	clk				: in std_logic;
	rst				: in std_logic;
	write			: in std_logic; 
	read			: in std_logic;
	din 			: in std_logic_vector(n-1 downto 0);
	dout	 		: out std_logic_vector(n-1 downto 0);
	full			: in std_logic; 
	empty 			: out std_logic);
END component;


end tb_pkg;



