-- =============================================
-- SHA2 source code
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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.sha2_pkg.all;	

entity bl_flags is 
generic (
	n 				:integer :=ARCH_32;    	-- size of basic operations
	s 				:integer:=LOG_2_8; 		-- width of ctr for number of blocks of hash digest
	flag			:integer:=HASH_BLOCKS_256; -- number of blocks of hash digest
	a 				:integer:=LOG_2_64;  	-- width of address bus 
	r				:integer:=ROUNDS_64);	--number of rounds
port (
	clk					:in 	std_logic;	
	rd_num				:in 	std_logic_vector(a-1 downto 0);
	exam_block			:in 	std_logic_vector(n-1 downto 0);	
	chunk_len			:in     std_logic_vector(n-1 downto 0);
	chunk_ctr			:in     std_logic_vector(n-1 downto 0);	  
	out_ctr				:in		std_logic_vector(s downto 0); 
	wr_lb				:in		std_logic;  
	wr_md				:in		std_logic;
	rst					:in 	std_logic;
	rst_flags			:in 	std_logic;
	z16					:out 	std_logic;
	lb					:out 	std_logic;	
	md					:out 	std_logic;
	zlast				:out 	std_logic;
	skip_word			:out 	std_logic;
	o8					:out	std_logic);
end bl_flags;

architecture a1 of bl_flags is 


signal z16_in			:std_logic;
signal z16_out			:std_logic;	
signal md_in			:std_logic;
signal md_out			:std_logic;		   		   
signal lb_in			:std_logic;
signal lb_out			:std_logic;		   	
signal zlast_in			:std_logic;
signal zlast_out		:std_logic;	
signal o8_in			:std_logic;
signal skip_word_in		:std_logic;
signal zero				:std_logic_vector(n-1 downto 0); 
signal rst_flags_reg	:std_logic;	
signal cmp				:std_logic_vector(s downto 0);

									 
begin
	
	zero <= (others=>'0');				 	   
	rst_flags_reg <= rst or rst_flags;
	
	lb_in <= '0' when (chunk_ctr<chunk_len) else '1';
	md_in  <= '1' when (exam_block=zero) and (lb_out='1') else '0'; 				
	z16_in <= '1' when (rd_num=std_logic_vector(to_unsigned(ROUND_16-3, a))) else '0';
	zlast_in <= '1' when (rd_num=std_logic_vector(to_unsigned(r-3, a))) else '0';

	cmp <= std_logic_vector(to_unsigned(flag, s+1));
	o8_in <= '1' when (out_ctr=cmp) else '0';	
		
	skip_word_in <= '1' when (exam_block=zero) else '0';	
		
	r0: reg1 port map (clk=>clk, rst=>rst, ena=>VCC, d=>z16_in, q=>z16_out); 
	r1: reg1 port map (clk=>clk, rst=>rst, ena=>VCC, d=>zlast_in, q=>zlast_out);
	r2: reg1 port map (clk=>clk, rst=>rst_flags_reg, ena=>wr_md, d=>md_in, q=>md_out);
	r3: reg1 port map (clk=>clk, rst=>rst_flags_reg, ena=>wr_lb, d=>lb_in, q=>lb_out);

	z16 <= z16_out;										
	zlast <= zlast_out;	 
	md <= md_out or md_in;
	lb<=lb_out;	   
	o8 <= o8_in;
	skip_word <= skip_word_in;			   
	
end a1;