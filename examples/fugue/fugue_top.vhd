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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.fugue_pkg.all;

entity fugue_top is
generic( hashsize : integer := FUGUE_HASH_SIZE_256; w: integer:=FUGUE_WORD_SIZE);
port ( 
	clk 		: in std_logic;
        rst 		: in std_logic;
        din 		: in std_logic_vector (w-1 downto 0);
        src_ready 	: in std_logic;
        src_read 	: out std_logic;
        dout 		: out std_logic_vector (w-1 downto 0);
        dst_ready 	: in  std_logic;
        dst_write 	: out std_logic);
end fugue_top;

architecture bl_arch of fugue_top is



	--type State_type is (reset, start, mode1, pad, mode2, mode3, mode4);
	--signal cstate, nstate : State_type; --current and next state signals

	signal load_seg_len, cnt_rst, cnt_en : std_logic; --counter signals
	signal mode1_n, pad_n, mode2_n, mode3_n, mode4_n, final_n : std_logic; 
	signal shiftout : std_logic; --enables shifting data out of hash
	signal cnt_lt, len_zero : std_logic; --counter status signals
	signal dp_rst : std_logic; --datapath reset
	signal p_cnt_lt, m2_cnt_lt, m3_cnt_lt, m4_cnt_lt : std_logic; 
	
begin

fugue_dp: fugue_datapath
	generic map (hashsize => hashsize)
	port map( din => din, clk => clk, rst => dp_rst, load_seg_len => load_seg_len,
	 cnt_rst => cnt_rst, cnt_en => cnt_en, mode1_n => mode1_n, pad_n => pad_n,
	 mode2_n => mode2_n, mode3_n => mode3_n, mode4_n => mode4_n, final_n => final_n,
	 shiftout => shiftout, cnt_lt => cnt_lt, len_zero => len_zero, dout => dout);	
	
fc : fugue_control
	port map(clk => clk, rst => rst, mode1_n => mode1_n, pad_n => pad_n,
	mode2_n => mode2_n, mode3_n => mode3_n, mode4_n	=> mode4_n,
	final_n => final_n, src_ready =>src_ready, len_zero =>len_zero, 
	cnt_lt =>cnt_lt, dst_ready => dst_ready, load_seg_len => load_seg_len, 
	cnt_rst => cnt_rst, cnt_en =>cnt_en, src_read =>src_read,  dst_write => dst_write,
	shiftout => shiftout, dp_rst => dp_rst);



end bl_arch;

