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
use ieee.std_logic_unsigned.all;
use work.sha3_pkg.all;

entity fugue_control is
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

end fugue_control;


architecture fsm of fugue_control is 

type State_type is (reset, start, mode1, pad, mode2, mode3, mode4); --state type
signal cstate, nstate : State_type; --current and next state signals
signal p_cnt_lt, m2_cnt_lt, m3_cnt_lt, m4_cnt_lt : std_logic; --less than signals for various modes
signal mode1_n_wire, pad_n_wire, mode2_n_wire, mode3_n_wire, mode4_n_wire, final_n_wire : std_logic; --active low mode enables
signal dst_write_wire : std_logic;

signal pad_delay_in, pad_delay_out : std_logic;	 
signal mode3_n_wire_in, mode3_n_reg : std_logic;
signal mode2_n_wire_in, mode2_n_reg : std_logic;
signal mode3_delay		:std_logic_vector(11 downto 0);
signal mode2_delay		:std_logic_vector(3 downto 0);
begin

	--sets current state to next state on rising edge of clock
	cstate_proc : process ( clk )
	begin
		if (clk'event and clk = '1') then 
			if rst = '1' then
				cstate <= reset;
			else
				cstate <= nstate;
			end if;
		end if;
	end process;

	--determines next state and sets control signals according to ASM chart
	process ( rst, cstate , src_ready, len_zero, cnt_lt, p_cnt_lt, m2_cnt_lt, m3_cnt_lt, m4_cnt_lt, dst_ready )
	begin
		

			case cstate is
				when reset => --in reset state
					if src_ready = '0' then --check for source ready
						nstate <= start; --go to start state if source ready
					else
						nstate <= reset; --stay in reset
					end if ;
				when start =>
					if len_zero = '0' then --check for segment len = 0
						if src_ready = '0' then --check for source ready
							nstate <= mode1; --go to mode 1 if segment length is not 0 and source is ready
						else
							nstate <= start; --go back to start if source is not ready
						end if ;
					else
						nstate <= pad; --go to pad stage if segment length is 0 (end of message)
					end if ;
				when mode1 =>
					if src_ready = '0' then --check for source ready
						if cnt_lt = '1' then --i<seglen
							nstate <= mode1; --keep going in mode 1
						else
							nstate <= start; --go to start if at end of segment
						end if ;
					else
						nstate <= mode1; --go back to mode 1 if source is not ready (all paths from mode 1 require data read)
					end if ;
				when pad =>
					if p_cnt_lt = '1' then --i<pad clocks
						nstate <= pad; --do another loop of padding
					else
						nstate <= mode2; --padding done, go on to mode 2 (G1)
					end if ;
				when mode2 =>
					if m2_cnt_lt = '1' then --i<mode 2 clocks
						nstate <= mode2; --do another loop of mode 2
					else
						nstate <= mode3; --mode 2 done , go to mode 3 (G2)
					end if ;
				when mode3 =>
					if m3_cnt_lt = '1' then --i<mode 3 clocks
						nstate <= mode3; --do another loop of mode 3
					else
						nstate <= mode4; --mode 3 done, generate output in mode 4
						if dst_ready = '0' then --write data if destination ready
						end if ;
					end if ;
				when mode4 =>
					if dst_ready = '0' then --check for destination ready
						if m4_cnt_lt = '1' then --i<mode 4 clocks
							nstate <= mode4; --if less than mode 4 count, continue clocking out data
						else
							if src_ready = '0' then --check for source ready
								nstate <= start; --if source is ready, go to start and start reading
							else
								nstate <= reset; --if source isn't ready, go to reset
							end if ;
						end if ;
					else
						nstate <= mode4; --if destination isn't ready, stay at mode 4
					end if ;
			end case ;
	
	end process ;

	--interpret counter depending on active mode (otherwise will cause oscillation between states)
	p_cnt_lt <= cnt_lt when pad_n_wire = '0' else '0';	 	
		

	m2_cnt_lt <= cnt_lt when mode2_n_wire = '0' else '0';
	m3_cnt_lt <= cnt_lt when mode3_n_wire = '0' else '0';
	m4_cnt_lt <= cnt_lt when (mode4_n_wire = '0') OR (final_n_wire = '0') else '0';

	mode1_n	<= mode1_n_wire;
	pad_n <= pad_n_wire;
	mode2_n <= mode2_n_wire;
	mode3_n <= mode3_n_wire;
	mode4_n <= mode4_n_wire;
	final_n <= final_n_wire;

	dst_write_wire <= '1' when (cstate=mode3 and m3_cnt_lt='0') or (cstate=mode4 and dst_ready='0') else '0';
	dw : d_ff port map (clk=>clk, rst=>rst, ena=>VCC, d=>dst_write_wire, q=>dst_write);

	src_read <= '1' when (cstate=reset and src_ready='0') or (cstate=start and len_zero='0' and src_ready='0') or 
						(cstate=mode1 and src_ready='0') or (cstate=mode4 and m4_cnt_lt='0' and src_ready='0' and dst_ready='0') else '0';
	
	shiftout <= '1' when (cstate=mode4 and dst_ready='0') else '0';	
		
	dp_rst <= '1' when (rst='1') or (cstate=reset and src_ready='0') or (cstate=mode4 and dst_ready='0' and m4_cnt_lt='0') else '0';  
		
	cnt_en <= '1' when (cstate=start and len_zero='0' and src_ready='0') or(cstate=start and len_zero='1') or (cstate=mode1 and cnt_lt='1' and src_ready='0') 
			or (cstate=pad) or (cstate=mode2) or (cstate=mode3 or m3_cnt_lt='1') or (cstate=mode3 and m3_cnt_lt='0' and dst_ready='0') or (cstate=mode4 and dst_ready='0' and m4_cnt_lt='1') else '0'; 	
		   
	cnt_rst <= '1' when (cstate=reset and src_ready='0') or (cstate=mode1 and src_ready='0' and cnt_lt='0') or (cstate=mode4 and dst_ready='0' and m4_cnt_lt='0' and src_ready='0') else '0';			
		
	load_seg_len <= '1' when (cstate=reset and src_ready='0') or (cstate=mode1 and src_ready='0' and cnt_lt='0') or (cstate=mode4 and dst_ready='0' and m4_cnt_lt='0' and src_ready='0') else '0';	
		
	final_n_wire <= '0' when (cstate=mode4 and dst_ready='0') else '1';	 

	mode1_n_wire <= '0' when (cstate=start and len_zero='0' and src_ready='0') or (cstate=mode1 and src_ready='0' and cnt_lt='1') else '1';	
		
		
	-- I will replace this by counter in datapath and flag. 	

	pad_delay_in<= '1' when (cstate=start and len_zero='1') else '0';	
	pad_dff: d_ff port map (clk=>clk, rst=>rst, ena=>VCC, d=>pad_delay_in, q=>pad_delay_out);
	pad_n_wire <= '0' when pad_delay_in = '1' or pad_delay_out='1' else '1';
	

	mode2_delay(0)<= '1' when (cstate=pad and p_cnt_lt='0')else '0'; 
	m2d: for i in 0 to 2 generate
	m2dr : d_ff port map (clk=>clk, rst=>rst, ena=>VCC, d=>mode2_delay(i), q=> mode2_delay(i+1));
	end generate;		  
	
 	mode2_n_wire_in <= '0' when (mode2_delay(0)='1') or (mode2_delay(1)='1') or (mode2_delay(2)='1') or (mode2_delay(3)='1') else '1';
			                                                                         
	mm2: d_ff port map(clk=>clk, rst=>rst, ena=>VCC, d=>mode2_n_wire_in, q=>mode2_n_reg);
	mode2_n_wire <= '0' when (mode2_delay(0)='1') or (mode2_n_reg='0') else '1'; 
	
		
	mode3_delay(0) <= '1' when (cstate=mode2 and m2_cnt_lt='0') else '0';

	m3d: for i in 0 to 10 generate 
	m3dr	: d_ff port map (clk=>clk, rst=>rst, ena=>VCC, d=>mode3_delay(i), q=>mode3_delay(i+1));
	end generate;	
											
	mode3_n_wire_in <= '0' when (mode3_delay(0)='1') or (mode3_delay(1)='1') or (mode3_delay(2)='1') or (mode3_delay(3)='1') or (mode3_delay(4)='1')
	or (mode3_delay(5)='1')	or (mode3_delay(6)='1')	or (mode3_delay(7)='1')	or (mode3_delay(8)='1')	or (mode3_delay(9)='1')	or (mode3_delay(10)='1')
	or (mode3_delay(11)='1')else '1';
	
	mm: d_ff port map(clk=>clk, rst=>rst, ena=>VCC, d=>mode3_n_wire_in, q=>mode3_n_reg);		
	                                                                            		
	mode3_n_wire <= '0' when (mode3_delay(0)='1') or (mode3_n_reg='0') else '1';		
		
		
	mode4_n_wire <= '0' when (cstate=mode3 and m3_cnt_lt='0') else '1';
		
end fsm;