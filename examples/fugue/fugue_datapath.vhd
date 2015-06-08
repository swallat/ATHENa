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
use ieee.std_logic_unsigned.all;  
use work.sha3_pkg.all;
use work.fugue_pkg.all;

entity fugue_datapath is
	 generic( hashsize : integer := FUGUE_HASH_SIZE_256; w :integer :=FUGUE_WORD_SIZE);-- size of hash
    port (					din : in std_logic_vector(w-1 downto 0);
								clk, rst : in std_logic;
								load_seg_len, cnt_rst, cnt_en : in std_logic; --input from controller
								mode1_n, pad_n, mode2_n, mode3_n, mode4_n, final_n : in std_logic; --input from controller
								shiftout : in std_logic; --input from controller
								cnt_lt, len_zero : out std_logic; --output to controller
								dout : out std_logic_vector(w-1 downto 0));
    end fugue_datapath;

architecture Behavioral of fugue_datapath is
		
signal i, s : state;
signal fb_sel : std_logic;
signal outsig : std_logic_vector(hashsize-1 downto 0);
signal out_en : std_logic;
signal data_cnt, cnt_val, cnt_val_inter, piso_out  : std_logic_vector(w-1 downto 0);
signal padq : std_logic_vector(4 downto 0);
signal curr_p : std_logic_vector(w-1 downto 0);
signal padding : std_logic_vector(w-1 downto 0);
signal total_msg_len : std_logic_vector(63 downto 0);
signal pad_half : std_logic;
signal idle, en_piso : std_logic;
signal to_ctr	:std_logic_vector(63 downto 0);
constant zero	:std_logic_vector(w-1 downto 0):=(others=>'0');	 
signal cnt_lt_in: std_logic;
signal cnt_val_tmp	:std_logic_vector(w-1-FUGUE_WORD_SIZE_LOG2 downto 0); 
signal len_zero_in: std_logic;
begin
	-- should go to controller
	idle <= mode1_n AND pad_n AND mode2_n AND mode3_n AND mode4_n AND final_n;
	
	-- counter for accumulation
	to_ctr <= zero & din;
	cr: countern generic map (N=>64, step=>1, style=>COUNTER_STYLE_3)
	port map(clk =>clk, rst =>rst, load =>'0', en =>load_seg_len, input=>to_ctr ,output =>total_msg_len);
	
	-- this rst=>'0' is radiculous
	rg: regn generic map (N=>FUGUE_WORD_SIZE, init=>zero) port map ( clk =>clk, rst =>'0', en => load_seg_len, input => din, output =>data_cnt);

		 	
	len_zero_in<='1' when din=X"00000000" else '0';	

	
	lzd: d_ff port map(clk=>clk, rst=>rst, ena=>load_seg_len, d=>len_zero_in, q=>len_zero);	
		
						
--	r : countern generic map (N=>FUGUE_WORD_SIZE, step=>FUGUE_WORD_SIZE, style=>COUNTER_STYLE_1) port map (clk=>clk, rst=>cnt_rst, en=>cnt_en, load=>GND, input=>zero, output=>cnt_val_inter);

	r : countern generic map (N=>FUGUE_WORD_SIZE-FUGUE_WORD_SIZE_LOG2, step=>1, style=>COUNTER_STYLE_1) port map (clk=>clk, rst=>cnt_rst, en=>cnt_en, load=>GND, input=>zero(w-1-FUGUE_WORD_SIZE_LOG2 downto 0), output=>cnt_val_tmp);
	cnt_val_inter <= cnt_val_tmp & "00000";


	cnt_lt_in <= '1' when cnt_val_inter+x"20"<cnt_val else --output 1 if counter less than value
		'0';	
	
	cnt_dff : d_ff port map (clk=>clk, rst=>rst, ena=>VCC, d=>cnt_lt_in, q=>cnt_lt);
		
		
		
	pad_half <= '1' when cnt_val_inter = X"00000020" else '0'; --tells which half of 64 bit length to output during padding

	--padq <= cnt_val(4 downto 0) when (cnt_val_inter > cnt_val) else "11111"; --gives address in padding ROM for how many padding bits to be added to last word
	padq <= "11111";
	
	
	
	--pad data to pad to next word size
	pad_data: fugue_padding port MAP(input => PadQ, output => padding );
	
	--value sent into hash, either padded input word, or extra two words of padding w/ message length
	Curr_P <= total_msg_len(63 downto 32) when (pad_n = '0') AND pad_half='0' else
				 total_msg_len(w-1 downto 0) when (pad_n = '0') AND pad_half='1' else
				 din AND padding;
	
	cnt224: if hashsize = FUGUE_HASH_SIZE_224 generate --counter values for modes in 224 bit hash, counter counts by 32
		cnt_val <= X"00000340" when (mode4_n = '0') OR (final_n = '0') else --7 counts to clock out hash
					  X"00000280" when mode3_n = '0' else --13 counts for G2
					  X"000000E0" when mode2_n = '0' else --5 counts for G1
					  X"00000040" when pad_n = '0' else --2 counts for padding
					  data_cnt; --segment length
	end generate;
	cnt256: if hashsize = FUGUE_HASH_SIZE_256 generate --counter values for modes in 256 bit hash, counter counts by 32
		cnt_val <= X"00000360" when (mode4_n = '0') OR (final_n = '0') else --8 counts to clock out hash
					  X"00000280" when mode3_n = '0' else --13 counts for G2
					  X"000000E0" when mode2_n = '0' else --5 counts for G1
					  X"00000040" when pad_n = '0' else --2 counts for padding
					  data_cnt; --segment length
	end generate;

	--Fugue state
	fs: fugue_state
	generic MAP (hashsize => hashsize)
	port MAP( input=>i, rst => rst, clk => clk, en => fb_sel, output=>s);
	
	--enables state register writing if not idle
	fb_sel<=not (load_seg_len OR idle);
	
	
	fr:  fugue_round generic map( hashsize =>hashsize, w=>w)
	port map(	output => i, clk=>clk, mode1_n => mode1_n, mode3_n => mode3_n, pad_n => pad_n, input => s, curr_p=>curr_p );


	--final output stage

	out_en<= not mode4_n;
	
	out224: if hashsize = FUGUE_HASH_SIZE_224 generate --output columns 1, 2, 3, 4, 15, 16, 17 for 224 bit hash
		outsig<=S(1)&S(2)&S(3)&(S(0) XOR S(4))&(S(0) XOR S(15))&S(16)&S(17);
	end generate;
	out256: if hashsize = FUGUE_HASH_SIZE_256 generate --output columns 1, 2, 3, 4, 15, 16, 17, 18 for 256 bit hash
		outsig<=S(1)&S(2)&S(3)&(S(0) XOR S(4))&(S(0) XOR S(15))&S(16)&S(17)&S(18);
	end generate;
	
	 
	en_piso <= shiftout or out_en;

	out_latch : piso 
	generic map( N=>hashsize, M=>FUGUE_WORD_SIZE)
	port map(clk=>clk, en =>en_piso, sel=>out_en, input=>outsig, output=>piso_out); 	   	
	
	--fix endian-ness	
	dout <= switch_endian_word(x=>piso_out, width=>FUGUE_WORD_SIZE, w=>8);
		
end Behavioral;
