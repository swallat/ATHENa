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

package sha3_pkg is	 				
	constant CPA_BASED : integer := 0;	
	constant CPA_TREE_BASED : integer := 1;
	constant CSA_BASED : integer := 2;
	constant PC_BASED : integer := 3;
	constant CSA_CPA_BASED : integer := 4;


	constant ZERO_WAIT_STATE			: integer:=0;
	constant ONE_WAIT_STATE				: integer:=1;  
	constant ZERO_WAIT_STATE_PREFETCH		: integer:=2; 

	constant DISTRIBUTED				: integer:=0; 
	constant BRAM					: integer:=1; 
	constant COMBINATIONAL				: integer:=2; -- not supported yet, waiting for code from Kris

	-- clock sync entity style -- MR: I added this temporarily
	constant NEW_SYNC				: integer:=0;
	constant OLD_SYNC				: integer:=1;



	constant COUNTER_STYLE_1				: integer:=1; 
	constant COUNTER_STYLE_2				: integer:=2; 
	constant COUNTER_STYLE_3				: integer:=3; 
	
	
	constant GND					: std_logic := '0';
	constant VCC					: std_logic := '1';
	
	constant AES_SBOX_SIZE				:integer:=8;
	constant AES_WORD_SIZE				:integer:=32;
	constant AES_BLOCK_SIZE				:integer:=128;
	constant AES_KEY_SIZE				:integer:=128;
	
	function shrx (signal x : in std_logic_vector; y : in integer) return std_logic_vector;	
	function shlx (signal x : in std_logic_vector; y : in integer) return std_logic_vector;	
	function rorx (signal x : in std_logic_vector; y : in integer) return std_logic_vector;	
	function rolx (signal x : in std_logic_vector; y : in integer) return std_logic_vector;
	function log2 (N: natural) return positive;
	function switch_endian (  x : std_logic_vector; width : integer; w : integer ) return std_logic_vector;
	function switch_endian_word (  x : std_logic_vector; width : integer; w : integer ) return std_logic_vector;

	function GF_SQ_SCL_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR;
	function GF_SCL_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR;
	function GF_MUL_2 ( x,y : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR;
	function GF_MUL_SCL_2 ( x,y : in  STD_LOGIC_VECTOR (1 downto 0))return STD_LOGIC_VECTOR;   
	function GF_INV_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR;
	function GF_SQ_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR;
	function MUL_X ( x : in  STD_LOGIC_VECTOR (7 downto 0)) return STD_LOGIC_VECTOR;
	function MUL_MX ( x : in  STD_LOGIC_VECTOR (7 downto 0)) return STD_LOGIC_VECTOR; 
	function GF_INV_4 ( x : in  STD_LOGIC_VECTOR (3 downto 0))return STD_LOGIC_VECTOR;
	function GF_MUL_4 ( x, y : in  STD_LOGIC_VECTOR (3 downto 0))return STD_LOGIC_VECTOR;  
	function GF_SQ_SCL_4 ( x : in  STD_LOGIC_VECTOR (3 downto 0))return STD_LOGIC_VECTOR;  
	function GF_INV_8 ( x : in  STD_LOGIC_VECTOR (7 downto 0))return STD_LOGIC_VECTOR; 
   
	component csa is 
		generic (n :integer := 32);
		port (
			a		: in std_logic_vector(n-1 downto 0);
			b		: in std_logic_vector(n-1 downto 0);
			cin		: in std_logic_vector(n-1 downto 0);
			s		: out std_logic_vector(n-1 downto 0);
			cout	: out std_logic_vector(n-1 downto 0));
	end component;	   	
	
	component pc is 
	generic (n :integer :=32);
	port (
		a		: in std_logic_vector(n-1 downto 0);
		b		: in std_logic_vector(n-1 downto 0);
		c		: in std_logic_vector(n-1 downto 0);
		d		: in std_logic_vector(n-1 downto 0);
		e		: in std_logic_vector(n-1 downto 0);
		s0		: out std_logic_vector(n-1 downto 0);
		s1		: out std_logic_vector(n-1 downto 0);
		s2		: out std_logic_vector(n-1 downto 0)
	);
	end component;

	component regn is
		generic ( 
			N : integer := 32;
			init : std_logic_vector
		);
		port ( 	  
		    clk : in std_logic;	 
			rst : in std_logic;
		    en : in std_logic; 
			input  : in std_logic_vector(N-1 downto 0);
	        output : out std_logic_vector(N-1 downto 0)
		);
	end component;


	component d_ff is 
	port(
		clk		: in std_logic;
		ena		: in std_logic;
		rst		: in std_logic;
		d		: in std_logic;
		q		: out std_logic);
	end component;

	component piso is
		generic ( 
			N	: integer := 512;	--inputs
			M	: integer := 32		--outputs -- N must be divisible by M
		);
		port (
			clk 	 : in std_logic;
			en   : in std_logic;
			sel	 : in std_logic;
			input  : in std_logic_vector(N-1 downto 0);
			output : out std_logic_vector(M-1 downto 0)
		);
	end component;
	
	component sipo is
		generic ( 
			N	: integer := 512;
			M	: integer := 32		-- N must be divisible by M
		);
		port (
			clk 	 : in std_logic;				 
			en     : in std_logic;
			input  : in std_logic_vector(M-1 downto 0);
			output : out std_logic_vector(N-1 downto 0)
		);
	end component;
	
	component countern is
		generic ( 
		    N : integer := 2;
		    step:integer:=1;
		    style	:integer :=COUNTER_STYLE_1	
		);
		port ( 	  
		clk : in std_logic;
		rst : in std_logic;
	    load : in std_logic;
	    en : in std_logic; 
		input  : in std_logic_vector(N-1 downto 0);
        output : out std_logic_vector(N-1 downto 0)
		);
	end component; 
	
	component decountern is
		generic ( 
		    n : integer := 64			
		);
		port ( 	  
			clk : in std_logic;
			rst		: in std_logic;
		    load : in std_logic;
		    en : in std_logic; 
			input  : in std_logic_vector(n-1 downto 0);
			sub    : in std_logic_vector(n-1 downto 0);
	        output : out std_logic_vector(n-1 downto 0)
		);
	end component;
	
	component sr_reg is							
		port (					
			rst			: in std_logic;
			clk 		: in std_logic;
			set     	: in std_logic;
			clr         : in std_logic;
			output		: out std_logic
		);				 
	end component;

	component sync_clock is
		generic (
		fr : integer := 1;
		style :integer:=NEW_SYNC
		);
		port (						 
			rst		   	: in std_logic;
			fast_clock 	: in std_logic;
			slow_clock 	: in std_logic;
			pre_sync, sync		: out std_logic
		);
	end component;
	
	component fifo_ram is
		generic ( 	
			fifo_mode	: integer := ZERO_WAIT_STATE;	
			depth 		: integer := 512;
			log2depth  	: integer := 9;
			n 		: integer := 64 );	
		port ( 	
			clk 		: in  std_logic;
			write 		: in  std_logic;
			rd_addr 	: in  std_logic_vector (log2depth-1 downto 0);
			wr_addr 	: in  std_logic_vector (log2depth-1 downto 0);
			din 		: in  std_logic_vector (n-1 downto 0);
			dout 		: out std_logic_vector (n-1 downto 0));
	end component;
	
	component fifo
		generic (
			fifo_mode	: integer := ONE_WAIT_STATE;	
			depth 		: integer := 64;
			log2depth 	: integer := 6;
			N 		: integer := 32);
		port (
			clk				: in std_logic;
			rst				: in std_logic;
			write			: in std_logic; 
			read			: in std_logic;
			din 			: in std_logic_vector(n-1 downto 0);
			dout	 		: out std_logic_vector(n-1 downto 0);
			full			: in std_logic; 
			empty 			: out std_logic);
	end component; 

	component aes_sbox is
	generic (n :integer :=AES_SBOX_SIZE; rom_style :integer:=DISTRIBUTED);	
	port( 
			clk		: in std_logic;
			input 		: in std_logic_vector(n-1 downto 0);
	        	output 		: out std_logic_vector(n-1 downto 0));
	end component;
	
	component aes_mul is
	generic (n :integer := AES_SBOX_SIZE; cons :integer := 3);
	port( 
		input 		: in std_logic_vector(n-1 downto 0);
	        output 		: out std_logic_vector(n-1 downto 0));
	end component;
	
	component aes_mixcolumn is
	generic (n	:integer := AES_SBOX_SIZE * 4);
	port( 
		input 		: in std_logic_vector(n-1 downto 0);
	        output 		: out std_logic_vector(n-1 downto 0));
	end component;
	
	
	component aes_shiftrow is
	generic (n	:integer := AES_BLOCK_SIZE;	s 	:integer := AES_SBOX_SIZE);
	port( 
		input 		: in std_logic_vector(n-1 downto 0);
	        output 		: out std_logic_vector(n-1 downto 0));
	end component;
	
	component aes_round is
	generic (n:integer := AES_BLOCK_SIZE; rom_style :integer:=DISTRIBUTED);
	port( 
		clk			: in std_logic;
		input 		: in std_logic_vector(n-1 downto 0);
		key			: in std_logic_vector(n-1 downto 0);
        output 		: out std_logic_vector(n-1 downto 0));
	end component;
	
	
	component sha3_fsm1 is
		generic ( bseg : integer := 16; log2bseg : integer := 4 );
		port (
		io_clk : in std_logic;
		rst : in std_logic;		
		
		-- datapath sigs
		zc0 : in std_logic;
		zcblock : in std_logic;   
		ein : out std_logic;
		lc : out std_logic;
		ec : out std_logic;
		
		-- Control communication
		sync : in std_logic;
		block_read 	: in std_logic;	
		block_ready_set : out std_logic;
		msg_end_set : out std_logic;
		
		-- FIFO communication
		src_ready : in std_logic;
		src_read    : out std_logic	
		);
	end component;	 
	
	component sha3_fsm3 is					
		generic ( hseg : integer := 8; log2hseg : integer := 3 );
		port (	   
			--global
			io_clk  : in std_logic;
			rst		: in std_logic;
		
			-- datapath
			eo : out std_logic;
			
			-- fsm 2 handshake signal
			output_write : in std_logic;	
			output_write_clr : out std_logic;	
			output_busy_clr  : out std_logic;	
			
			-- fifo
			dst_ready : in std_logic;
			dst_write : out std_logic
		);
	end component;

	component aes_sbox_logic is
	    Port ( S_IN : in  STD_LOGIC_VECTOR (7 downto 0);
	           S_OUT : out  STD_LOGIC_VECTOR (7 downto 0));
	end component;

end sha3_pkg;

package body sha3_pkg is
	function shrx ( signal x : in std_logic_vector; y : in integer) return std_logic_vector is
		variable zeros	: std_logic_vector(y-1 downto 0) := (others => '0'); 
	begin						 							
		return (zeros & x(x'high downto y));
	end shrx;	   
	
	function shlx ( signal x : in std_logic_vector; y : in integer) return std_logic_vector is
		variable zeros	: std_logic_vector(y-1 downto 0) := (others => '0');
	begin		
		return (x(x'high-y downto x'low) & zeros);
	end shlx;																						 
	
	function rorx ( signal x : in std_logic_vector; y : in integer) return std_logic_vector is
	begin						 							
		return (x(y-1 downto x'low) & x(x'high downto y));
	end rorx;	   
	
	function rolx ( signal x : in std_logic_vector; y : in integer) return std_logic_vector is
	begin						 							
		return (x(x'high-y downto x'low) & x(x'high downto x'high-y+1));
	end rolx;	   
	
	function log2 (N: natural) return positive is
	begin
		if N < 2 then
			return 1;
		else
			return 1 + log2(N/2);
		end if;	
	end;

	function switch_endian (  x : std_logic_vector; width : integer; w : integer ) return std_logic_vector is
		variable xseg : integer := width/w;
		variable wseg : integer := w/8;			   
		variable retval : std_logic_vector(width-1 downto 0);
	begin				  
		for i in xseg downto 1 loop
			for j in 0 to wseg-1 loop
				retval(i*w - 1 - j*8 downto i*w - 8 - j*8 ) := x(i*w - 1 - (wseg-1-j)*8 downto i*w - 8 - (wseg-1-j)*8);
			end loop;
		end loop;
		return(retval);				
	end switch_endian;	
	
	function switch_endian_word ( x : std_logic_vector; width : integer; w : integer ) return std_logic_vector is
		variable xseg : integer := width/w;   
		variable retval : std_logic_vector(width-1 downto 0);
	begin				  
		for i in xseg downto 1 loop			
			retval(i*w - 1 downto w*(i-1) ) := x(w*(xseg-i+1) - 1 downto w*(xseg-i));			
		end loop;
		return(retval);				
	end switch_endian_word;	
	
	function GF_SQ_SCL_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR is 
		variable y : STD_LOGIC_VECTOR (1 downto 0);
	begin
		y := x(1) & (x(1) xor x(0));	
		return y;
	end GF_SQ_SCL_2;
	
	
	function GF_SCL_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR is 	
		variable y : STD_LOGIC_VECTOR (1 downto 0);	
	begin
		y := x(0) & (x(1) xor x(0));	
		return y;
	end GF_SCL_2;


	function GF_MUL_2 ( x,y : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR is 
		variable o : STD_LOGIC_VECTOR (1 downto 0);	
	begin			
		o := (((x(1) xor x(0)) and (y(1) xor y(0))) xor (x(1) and y(1))) & (((x(1) xor x(0)) and (y(1) xor y(0))) xor (x(0) and y(0)));		
		return o;
	end GF_MUL_2; 
	
	
	function GF_MUL_SCL_2 ( x,y : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR is 	
		variable o : STD_LOGIC_VECTOR (1 downto 0);	
	begin		
		o := (((x(1) xor x(0)) and (y(1) xor y(0))) xor (x(0) and y(0))) & ((x(1) and y(1)) xor (x(0) and y(0)));		
		return o;
	end GF_MUL_SCL_2;		 

	
	function GF_INV_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR is 
		variable y : STD_LOGIC_VECTOR (1 downto 0);
	begin
		y(1) := x(0);
	  	y(0) := x(1);
		return y;
	end GF_INV_2;
	
	
	function GF_SQ_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR is 
		variable y : STD_LOGIC_VECTOR (1 downto 0);
	begin
	  	y(1) := x(0);
	  	y(0) := x(1);
		return y;
	end GF_SQ_2; 
	
	function MUL_X ( x : in  STD_LOGIC_VECTOR (7 downto 0)) return STD_LOGIC_VECTOR is 
		variable y : STD_LOGIC_VECTOR (7 downto 0);
	begin
		y(7) := x(7) xor x(6) xor x(5) xor x(2) xor x(1) xor x(0);
		y(6) := x(6) xor x(5) xor x(4) xor x(0);
		y(5) := x(6) xor x(5) xor x(1) xor x(0);	
		y(4) := x(7) xor x(6) xor x(5) xor x(0);
		y(3) := x(7) xor x(4) xor x(3) xor x(1) xor x(0);
		y(2) := x(0);
		y(1) := x(6) xor x(5) xor x(0);
		y(0) := x(6) xor x(3) xor x(2) xor x(1) xor x(0);
		return y;
	end MUL_X;	  

	function MUL_MX ( x : in  STD_LOGIC_VECTOR (7 downto 0)) return STD_LOGIC_VECTOR is 
		variable y : STD_LOGIC_VECTOR (7 downto 0);
	begin
		y(7) := x(5) xor x(3);	
		y(6) := x(7) xor x(3);
		y(5) := x(6) xor x(0);
		y(4) := x(7) xor x(5) xor x(3);
		y(3) := x(7) xor x(6) xor x(5) xor x(4) xor x(3);
		y(2) := x(6) xor x(5) xor x(3) xor x(2) xor x(0);
		y(1) := x(5) xor x(4) xor x(1);
		y(0) := x(6) xor x(4) xor x(1);
	return y;
	end MUL_MX;	   


	
	function GF_INV_4 ( x : in  STD_LOGIC_VECTOR (3 downto 0)) return STD_LOGIC_VECTOR is 
		variable y : STD_LOGIC_VECTOR (3 downto 0);
		variable r0, r1, SQ_IN, SQ_OUT, MUL_1_OUT, GF_INV_IN, GF_INV_OUT, MUL_2_OUT , MUL_3_OUT :STD_LOGIC_VECTOR (1 downto 0);
	begin
		r1 := x(3 downto 2);
		r0 := x(1 downto 0);
		SQ_IN := r1 xor r0;
		SQ_OUT := GF_SQ_SCL_2 ( x => SQ_IN);
		MUL_1_OUT := GF_MUL_2( x => r1, y => r0);
		GF_INV_IN := MUL_1_OUT xor SQ_OUT;
		GF_INV_OUT := GF_INV_2(x => GF_INV_IN);
		MUL_2_OUT := GF_MUL_2 ( x => r1, y => GF_INV_OUT);
		MUL_3_OUT := GF_MUL_2 ( x => GF_INV_OUT, y => r0);
		y := MUL_3_OUT & MUL_2_OUT;
		return y;
	end GF_INV_4;
	

	function GF_MUL_4 ( x,y : in  STD_LOGIC_VECTOR (3 downto 0)) return STD_LOGIC_VECTOR is 
		variable o : STD_LOGIC_VECTOR (3 downto 0);
		variable tao1, tao0, delta1, delta0, fi1, fi0, tmp1, tmp0, RES_MUL1, RES_MUL0,RES_MUL_SCL: std_logic_vector (1 downto 0);
	begin
		tao1 := x(3 downto 2);
		tao0 := x(1 downto 0);
		delta1 := y(3 downto 2);
		delta0 := y(1 downto 0);
		tmp1 := tao1 xor tao0;
		tmp0 := delta1 xor delta0;
		RES_MUL1 := GF_MUL_2 ( x=> tao1, y=> delta1);
		RES_MUL0 := GF_MUL_2 ( x=> tao0, y=> delta0);
		RES_MUL_SCL := GF_MUL_SCL_2( x=> tmp1, y=> tmp0);
		fi1 := RES_MUL1 xor RES_MUL_SCL;
		fi0 := RES_MUL0 xor RES_MUL_SCL;
		o := fi1 & fi0;
		return o;
	end GF_MUL_4;	

	function GF_SQ_SCL_4 ( x : in  STD_LOGIC_VECTOR (3 downto 0)) return STD_LOGIC_VECTOR is 
		variable y : STD_LOGIC_VECTOR (3 downto 0);
		variable tao1, tao0, delta1, delta0, tmp1, tmp0: std_logic_vector (1 downto 0);
	begin
		tao1 := x(3 downto 2);
		tao0 := x(1 downto 0);
		tmp1 := tao1 xor tao0;
		tmp0 := GF_SCL_2 ( x => tao0);
		delta1 := GF_SQ_2( x=> tmp1);
		delta0 := GF_SQ_2 ( x=> tmp0);
		y := delta1 & delta0;
		return y;
	end GF_SQ_SCL_4;  
	

	function GF_INV_8 ( x : in  STD_LOGIC_VECTOR (7 downto 0)) return STD_LOGIC_VECTOR is 
		variable y : STD_LOGIC_VECTOR (7 downto 0);
		variable r0, r1, SQ_IN, SQ_OUT, MUL_1_OUT, GF_INV_IN, GF_INV_OUT, MUL_2_OUT , MUL_3_OUT :STD_LOGIC_VECTOR (3 downto 0);
	begin
		r1 := x(7 downto 4);
		r0 := x(3 downto 0);
		SQ_IN := r1 xor r0;
		SQ_OUT := GF_SQ_SCL_4 ( x => SQ_IN);
		MUL_1_OUT := GF_MUL_4 ( x => r1, y => r0);	
		GF_INV_IN := MUL_1_OUT xor SQ_OUT;	
		GF_INV_OUT := GF_INV_4 (x => GF_INV_IN);
		MUL_2_OUT := GF_MUL_4 ( x => r1, y => GF_INV_OUT);	
		MUL_3_OUT := GF_MUL_4 ( x => GF_INV_OUT, y => r0);	
		y := MUL_3_OUT  & MUL_2_OUT;
		return y;
	end GF_INV_8;
	
end package body sha3_pkg;