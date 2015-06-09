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

package sha2_pkg is 	
	
constant ZERO_WAIT_STATE			: integer:=0;
constant ONE_WAIT_STATE				: integer:=1;
constant DISTRIBUTED				: integer:=0; 
constant BRAM						: integer:=1; 
	
constant STATE_REG_NUM			: integer:=8;	
constant BLOCK_SIZE_512			: integer:=512;
constant HASH_SIZE_256			: integer:=256;
constant ARCH_32				: integer:=32;
constant HASH_BLOCKS_256		: integer:=HASH_SIZE_256/ARCH_32;
constant LEN_BLOCKS				: integer:=2;

constant LOG_2_2				: integer:=1; -- the biggest number of hash blocks (3bits couter for 6,7,8 blocks) 
constant LOG_2_4				: integer:=2; -- the biggest number of hash blocks (3bits couter for 6,7,8 blocks) 
constant LOG_2_8				: integer:=3; -- the biggest number of hash blocks (3bits couter for 6,7,8 blocks) 
constant LOG_2_16				: integer:=4; -- the biggest number of hash blocks (3bits couter for 6,7,8 blocks) 
constant LOG_2_32				: integer:=5; -- the biggest number of hash blocks (3bits couter for 6,7,8 blocks) 
constant LOG_2_64				: integer:=6; -- there is no log function in vhdl 
constant LOG_2_80				: integer:=7; -- there is no log function in vhdl  
constant LOG_2_512				: integer:=9; -- there is no log function in vhdl  
constant LOG_2_1024				: integer:=10; -- there is no log function in vhdl  

constant ROUNDS_64				: integer:=64;
constant ROUND_16				: integer:=16;
constant ROUND_17				: integer:=17;

constant ARCH32_CF0_1				: integer:=2;					
constant ARCH32_CF0_2				: integer:=13;					
constant ARCH32_CF0_3				: integer:=22;					
constant ARCH32_CF1_1				: integer:=6;					
constant ARCH32_CF1_2				: integer:=11;					
constant ARCH32_CF1_3				: integer:=25;					
constant ARCH32_MS0_1			: integer:=7;					
constant ARCH32_MS0_2			: integer:=18;					
constant ARCH32_MS0_3			: integer:=3;					
constant ARCH32_MS1_1			: integer:=17;					
constant ARCH32_MS1_2			: integer:=19;					
constant ARCH32_MS1_3			: integer:=10;	
				
constant SHA256_AINIT 			:std_logic_vector(ARCH_32-1 downto 0):= X"6a09e667"; 
constant SHA256_BINIT 			:std_logic_vector(ARCH_32-1 downto 0):= X"bb67ae85"; 
constant SHA256_CINIT 			:std_logic_vector(ARCH_32-1 downto 0):= X"3c6ef372"; 
constant SHA256_DINIT 			:std_logic_vector(ARCH_32-1 downto 0):= X"a54ff53a"; 
constant SHA256_EINIT 			:std_logic_vector(ARCH_32-1 downto 0):= X"510e527f"; 
constant SHA256_FINIT 			:std_logic_vector(ARCH_32-1 downto 0):= X"9b05688c"; 
constant SHA256_GINIT 			:std_logic_vector(ARCH_32-1 downto 0):= X"1f83d9ab"; 
constant SHA256_HINIT 			:std_logic_vector(ARCH_32-1 downto 0):= X"5be0cd19";
constant VCC 					:std_logic:='1';
constant GND 					:std_logic:='0';


component cons is 
generic(n :integer:=ARCH_32; a:integer:=LOG_2_64; r:integer:=ROUNDS_64);
port(
	clk			: in std_logic;	
	address			: in std_logic_vector(a-1 downto 0);
  	output			: out std_logic_vector(n-1 downto 0));
end component;


component counter 
generic (s : integer :=2; r:integer:=2; step:integer:=1);
port(
	clk			:in std_logic;
	reset 		:in std_logic;
	ena 		:in std_logic;
	ctr			:out std_logic_vector(s-1 downto 0));
end component;
 
component sigma_func 
generic( n : integer :=ARCH_32; func : string :="ms"; a : integer:=ARCH32_CF1_1; b : integer:=ARCH32_CF1_2; c : integer:=ARCH32_CF1_3);
port(
	x		:in std_logic_vector(n-1 downto 0);
	o		:out std_logic_vector(n-1 downto 0));
end component;	  

component ch_func 
generic (n : integer:=ARCH_32);
port(
	x		:in std_logic_vector(n-1 downto 0);
	y		:in std_logic_vector(n-1 downto 0);
	z		:in std_logic_vector(n-1 downto 0);
	o		:out std_logic_vector(n-1 downto 0));
end component;

component maj_func 
generic (n : integer:=ARCH_32);
port(
	x		:in std_logic_vector(n-1 downto 0);
	y		:in std_logic_vector(n-1 downto 0);
	z		:in std_logic_vector(n-1 downto 0);
	o		:out std_logic_vector(n-1 downto 0));
end component;



component muxn
generic (n : integer:=ARCH_32);
port(
	sel		: in std_logic;
	a		: in std_logic_vector(n-1 downto 0);
	b		: in std_logic_vector(n-1 downto 0);
	o		: out std_logic_vector(n-1 downto 0));
end component;

component regn  
generic(n : integer := ARCH_32);
port(
	clk			: in std_logic;
	ena			: in std_logic;
	rst			: in std_logic;
	init		: in std_logic_vector(n-1 downto 0);
	d			: in std_logic_vector(n-1 downto 0);
	q			: out std_logic_vector(n-1 downto 0));
end component;	  


component rs_round is
generic( n : integer :=ARCH_32);
port(	 
	sel_gh		:in std_logic;	 
	kw		:in std_logic_vector(n-1 downto 0);
	kwire		:in std_logic_vector(n-1 downto 0);
   	wwire		:in std_logic_vector(n-1 downto 0);	
	ain		:in std_logic_vector(n-1 downto 0);
	bin		:in std_logic_vector(n-1 downto 0);
	cin		:in std_logic_vector(n-1 downto 0);
	din		:in std_logic_vector(n-1 downto 0);
	ein		:in std_logic_vector(n-1 downto 0);
	fin		:in std_logic_vector(n-1 downto 0);
	gin		:in std_logic_vector(n-1 downto 0);
	hin		:in std_logic_vector(n-1 downto 0);	  
	kwhwire		:out std_logic_vector(n-1 downto 0);
	aout		:out std_logic_vector(n-1 downto 0);
	bout		:out std_logic_vector(n-1 downto 0);
	cout		:out std_logic_vector(n-1 downto 0);
	dout		:out std_logic_vector(n-1 downto 0);
	eout		:out std_logic_vector(n-1 downto 0);
	fout		:out std_logic_vector(n-1 downto 0);
	gout		:out std_logic_vector(n-1 downto 0);
	hout		:out std_logic_vector(n-1 downto 0));
end component;

component reg1  
port(
	clk		: in std_logic;
	ena		: in std_logic;
	rst		: in std_logic;
	d		: in std_logic;
	q		: out std_logic);
end component;

component msg_scheduler is 
generic( l: integer:=1; n : integer :=ARCH_32);
port(
	clk			: in std_logic;
	sel			: in std_logic;
	wr_data		: in std_logic;
	data		: in std_logic_vector(n-1 downto 0);
	w			: out std_logic_vector(l*n-1 downto 0));
end component;

component bl_flags is 
generic (n : integer:=32; a :integer :=6; r:integer:=10; s : integer :=2; flag: integer:=2);
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
end component;

end sha2_pkg;



