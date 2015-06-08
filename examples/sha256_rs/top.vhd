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

entity top is
generic( n : integer :=ARCH_32; l:integer:=10);
port (
    	clk					:in std_logic;
    	rst					:in std_logic;
    	din					:in std_logic_vector(n-1 downto 0); 
    	src_read				:out std_logic_vector(l-1 downto 0);
    	src_ready				:in std_logic;
    	dout					:out std_logic_vector(n-1 downto 0); 
    	dst_write				:out std_logic_vector(l-1 downto 0);
    	dst_ready				:in std_logic);
end top;

architecture top of top is 		   	   

component sha256 is
generic( n : integer :=ARCH_32);
port (
    	clk					:in std_logic;
    	rst					:in std_logic;
    	din					:in std_logic_vector(n-1 downto 0); 
    	src_read				:out std_logic;
    	src_ready				:in std_logic;
    	dout					:out std_logic_vector(n-1 downto 0); 
    	dst_write				:out std_logic;
    	dst_ready				:in std_logic);
end component;

type matrix is array (0 to l) of std_logic_vector(n-1 downto 0);
signal wire	: matrix;



begin

wire(0) <= din;

sr_gen: for i in 0 to l-1 generate	
sr			: sha256 	generic map (n=>n) 
					port map (clk=>clk, 
					rst=>rst, 
					din=>wire(i), 
					src_ready=>src_ready, 
					src_read=>src_read(i), 
					dout=>wire(i+1), 
					dst_write=>dst_write(i), 
					dst_ready=>dst_ready);	
end generate;

dout <= wire(l);


end top;