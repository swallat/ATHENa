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

package fugue_pkg is
   
	
	
constant FUGUE_STATE_SIZE		:integer:=2048;
constant FUGUE_WORD_SIZE		:integer:=32;
constant FUGUE_WORD_SIZE_LOG2	:integer:=5;

constant FUGUE_HASH_SIZE_224	:integer:=224;
constant FUGUE_HASH_SIZE_256	:integer:=256;
constant FUGUE_HASH_SIZE_384	:integer:=384;
constant FUGUE_HASH_SIZE_512	:integer:=512;
constant FUGUE_INIT_224			:std_logic_vector(FUGUE_HASH_SIZE_224-1 downto 0) := x"0d12c9f457f786621ce039eecbe374e0627c12a115d2439a9a678dbd";
constant FUGUE_INIT_256			:std_logic_vector(FUGUE_HASH_SIZE_256-1 downto 0) := x"debd52e95f13716668f6d4e094b5b0d21d626cf9de29f9fb99e8499148c2f834";
constant FUGUE_INIT_384			:std_logic_vector(FUGUE_HASH_SIZE_384-1 downto 0) := x"0dec61aa1f2e2531c7b41da0850960004af45e219c5e1b749a3e69fa40b03e478aae02e5e0259ca97c5195bca195105c";
constant FUGUE_INIT_512			:std_logic_vector(FUGUE_HASH_SIZE_512-1 downto 0) := x"7ea5078875af16e6dbe4d3c527b09aac17f115d954cceeb60b02e806d1ef924ac9e2c6aa9813b2dd3858e6ca3f207f43e778ea25d6dd1f951dd16eda67353ee1";
	
type state is array (0 to 29) of std_logic_vector(FUGUE_WORD_SIZE-1 downto 0);

component fugue_state IS
generic ( hashsize : inTEGER := FUGUE_HASH_SIZE_256; w: integer:=FUGUE_WORD_SIZE );
port (	
	clk 			: in 	std_logic;
	rst 			: in 	std_logic;		   
	en 				: in 	std_logic;
	input 			: in	state;
	output 			: out 	state);			 
end component;

component fugue_TIX
generic( w: integer:=FUGUE_WORD_SIZE);
port(
	P 				: in std_logic_vector(w-1 downto 0);
	I0 				: in std_logic_vector(w-1 downto 0);
	I1 				: in std_logic_vector(w-1 downto 0);
	I8 				: in std_logic_vector(w-1 downto 0);
	I10 			: in std_logic_vector(w-1 downto 0);
	I24 			: in std_logic_vector(w-1 downto 0);          
	O0 				: out std_logic_vector(w-1 downto 0);
	O1 				: out std_logic_vector(w-1 downto 0);
	O8 				: out std_logic_vector(w-1 downto 0);
	O10 			: out std_logic_vector(w-1 downto 0));
end component;

component fugue_cmix
generic( w: integer:=FUGUE_WORD_SIZE);
port(
	I0 				: in std_logic_vector(w-1 downto 0);
	I1 				: in std_logic_vector(w-1 downto 0);
	I2 				: in std_logic_vector(w-1 downto 0);
	I4 				: in std_logic_vector(w-1 downto 0);
	I5 				: in std_logic_vector(w-1 downto 0);
	I6 				: in std_logic_vector(w-1 downto 0);
	I15 			: in std_logic_vector(w-1 downto 0);
	I16 			: in std_logic_vector(w-1 downto 0);
	I17 			: in std_logic_vector(w-1 downto 0);          
	O0 				: out std_logic_vector(w-1 downto 0);
	O1 				: out std_logic_vector(w-1 downto 0);
	O2 				: out std_logic_vector(w-1 downto 0);
	O15 			: out std_logic_vector(w-1 downto 0);
	O16	 			: out std_logic_vector(w-1 downto 0);
	O17 			: out std_logic_vector(w-1 downto 0));
end component;

component fugue_smix 
generic( w: integer:=FUGUE_WORD_SIZE);
port(
	clk				: in std_logic;	
	I0 				: in std_logic_vector(w-1 downto 0);
	I1 				: in std_logic_vector(w-1 downto 0);
	I2 				: in std_logic_vector(w-1 downto 0);
	I3 				: in std_logic_vector(w-1 downto 0);          
	O0 				: out std_logic_vector(w-1 downto 0);
	O1 				: out std_logic_vector(w-1 downto 0);
	O2 				: out std_logic_vector(w-1 downto 0);
	O3 				: out std_logic_vector(w-1 downto 0));
end component;
	
component fugue_round IS
generic ( hashsize : integer := FUGUE_HASH_SIZE_256; w:integer :=FUGUE_WORD_SIZE );
port (	output : out	 	state;	 
		curr_p	:in std_logic_vector(w-1 downto 0);
		clk, mode1_n,mode3_n, pad_n : in 		std_logic;
		input : in 	state );
end component;
	
	
component fugue_padding
generic( w: integer:=FUGUE_WORD_SIZE);
port(
	input 			: in std_logic_vector(4 downto 0);          
	output 			: out std_logic_vector(w-1 downto 0));
end component;

component fugue_datapath
generic( hashsize : integer := FUGUE_HASH_SIZE_256; w:integer :=FUGUE_WORD_SIZE);-- size of hash
port(
	din 			: in std_logic_vector(w-1 downto 0);
	clk 			: in std_logic;
	rst 			: in std_logic;
	load_seg_len	: in std_logic;
	cnt_rst 		: in std_logic;
	cnt_en 			: in std_logic;
	mode1_n 		: in std_logic;
	pad_n 			: in std_logic;
	mode2_n 		: in std_logic;
	mode3_n 		: in std_logic;
	mode4_n 		: in std_logic;
	final_n 		: in std_logic;
	shiftout		: in std_logic;
	cnt_lt 			: out std_logic;
	len_zero 		: out std_logic;
	dout 			: out std_logic_vector(w-1 downto 0));
end component;	

component fugue_control is
port 
(
	clk				:in std_logic;
	rst				:in std_logic;
	mode1_n			:out std_logic;
	pad_n			:out std_logic;
	mode2_n			:out std_logic;
	mode3_n			:out std_logic;
	mode4_n			:out std_logic;
	final_n 		:out std_logic;
	src_ready		:in std_logic;
	len_zero		:in std_logic;
	cnt_lt			:in std_logic;
	dst_ready		:in std_logic;
	load_seg_len	:out std_logic;
	cnt_rst 		:out std_logic;
	cnt_en 			:out std_logic;
	src_read 		:out std_logic;
	dst_write 		:out std_logic;
	shiftout 		:out std_logic;
	dp_rst 			:out std_logic);

end component;



end fugue_pkg;

package body fugue_pkg is


end package body fugue_pkg;