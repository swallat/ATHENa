-- =============================================
-- SHA2 source code
-- Copyright � 2009 - 2014 CERG at George Mason University <cryptography.gmu.edu>.
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

library ieee ;
use ieee.std_logic_1164.all;   
use work.sha2_pkg.all;

entity rs_controller is	
generic (fifo_mode	:integer :=ZERO_WAIT_STATE);	
port(	
	clk					:in std_logic;
	rst						:in std_logic;
	z16						:in std_logic;
	zlast					:in std_logic;
	o8						:in std_logic;
	skip_word				:in std_logic; 
	sel2					:out std_logic;
	sel						:out std_logic;
	sel_gh					:out std_logic;
	sel_gh2					:out std_logic;
	src_read				:out std_logic;
	src_ready				:in std_logic;
	dst_write				:out std_logic;
	dst_ready				:in std_logic;
	wr_data					:out std_logic;
	kw_wr					:out std_logic;
	wr_state				:out std_logic;
	wr_result				:out std_logic;
	wr_len					:out std_logic;
	last_block				:in std_logic;
	msg_done				:in std_logic;
	ctr_ena					:out std_logic;
	ctrl_rst				:out std_logic;	
	wr_lb					:out std_logic;
	wr_md					:out std_logic;
	wr_chctr				:out std_logic;
	rst_flags				:out std_logic 
);
end rs_controller;

architecture rs_controller of rs_controller is 
begin

one_ws:		if fifo_mode=ONE_WAIT_STATE generate
aa: 	entity work.rs_controller(one_wait_state)	
		generic map (fifo_mode=>fifo_mode)
		port map( 
		clk=>clk,	
		rst=>rst,
		z16=>z16,						
		zlast=>zlast,	
		o8=>o8,	
		skip_word=>skip_word,					
		sel2=>sel2,	
		sel=>sel,	
		sel_gh=>sel_gh,
		sel_gh2=>sel_gh2,				
    	src_read=>src_read,				
    	src_ready=>src_ready,		
    	dst_write=>dst_write,				
    	dst_ready=>dst_ready,		
		wr_data=>wr_data,	
		kw_wr=> kw_wr,				
		wr_state=>wr_state,				
		wr_result=>wr_result,	
		wr_len=>wr_len,	
		last_block=>last_block,	
		msg_done=>msg_done,
		ctr_ena=>ctr_ena,
		ctrl_rst=>ctrl_rst,	   
		wr_lb=>wr_lb,	
		wr_md=>wr_md,  
		wr_chctr=>wr_chctr,
		rst_flags=>rst_flags);

end generate;

zero_ws:	if (fifo_mode=ZERO_WAIT_STATE)generate
aa: 	entity work.rs_controller(zero_wait_state)	
		generic map (fifo_mode=>fifo_mode)
		port map( 
		clk=>clk,	
		rst=>rst,
		z16=>z16,						
		zlast=>zlast,	
		o8=>o8,	
		skip_word=>skip_word,										
		sel2=>sel2,	
		sel=>sel,	
		sel_gh=>sel_gh,
		sel_gh2=>sel_gh2,				
    		src_read=>src_read,				
    		src_ready=>src_ready,		
    		dst_write=>dst_write,				
    		dst_ready=>dst_ready,		
		wr_data=>wr_data,	
		kw_wr=> kw_wr,				
		wr_state=>wr_state,				
		wr_result=>wr_result,	
		wr_len=>wr_len,	
		last_block=>last_block,	
		msg_done=>msg_done,
		ctr_ena=>ctr_ena,
		ctrl_rst=>ctrl_rst,	   
		wr_lb=>wr_lb,	
		wr_md=>wr_md,  
		wr_chctr=>wr_chctr,
		rst_flags=>rst_flags);

end generate;


end;


architecture zero_wait_state of rs_controller is


    type state_type is (idle, 
						get_len, 
						get_len_idle, 
						get_len_delay,
						get_len_delay2,
						get_len_delay3,
						get_len_delay4,
						get_main_delay,
						get_data, 
						get_data_idle,
						wr_get_len, 
						wr_get_len_idle, 
						wr_get_data, 
						wr_get_data_idle,
						
						kw_compute, 
						kw_compute_idle,
						data, 
						data_idle, 
						data_end, 
						data_end_idle, 
						dummy, 
						computation, 
						computation_end, 
						result_delay, 
						result_delay_idle,
						result_delay2, 
						result_delay2_idle,
						result_delay3, 
						mb_result_delay2,
						mb_result_delay3, 
						
						mb_result,						
						result, 
						result_idle,
						mux_gh,
						mux_gh_idle, 
						send_data, 
						send_data_idle, 
						done);

signal next_state, current_state: state_type;
attribute enum_encoding : string;
	
--signal wr_data_wire		:std_logic;
--signal wr_len_wire		:std_logic;
signal skip_word_reg	:std_logic;

begin
    
    state_reg: process(clk, rst)
    begin

	if (rst='1') then
            current_state <= idle;
	elsif (clk'event and clk='1') then
	    current_state <= next_state;
	end if;

    end process;						  

    comb_logic: process(current_state,src_ready, z16, zlast,o8,last_block, msg_done, skip_word, skip_word_reg, next_state, dst_ready)
    begin


	case current_state is

	    when idle =>	
			if src_ready='1' then
			    next_state <= get_len;
			else
			    next_state <= idle;
			end if;
						
	    when get_len =>	
			if skip_word='1' then 
					next_state <= get_len;
			elsif skip_word_reg='1' and skip_word ='0' then
					next_state <= get_len_delay;
			else	
				if src_ready='1' then
			    	next_state <= get_data;
				else
			    	next_state <= get_len_idle;
				end if;
			end if;	 
		
		when get_len_delay =>
			next_state <= get_len_delay2;
				
		when get_len_delay2 =>
			next_state <= get_len_delay3;

		when get_len_delay3 =>
			next_state <= get_len_delay4;

		when get_len_delay4 =>
			next_state <= kw_compute;--get_data;
			
			when get_len_idle =>	
			if src_ready='1' then
			    next_state <= get_data;
			else
			    next_state <= get_len_idle;
			end if;								 
			
		--when get_main_delay =>
		--	next_state <= get_data;

	    when get_data =>	
			if src_ready='1' then
			    next_state <= wr_get_len;
			else
			    next_state <= get_data_idle;
			end if;


	    when get_data_idle =>	
			if src_ready='1' then
			    next_state <= wr_get_len;
			else
			    next_state <= get_data_idle;
			end if;

	    when wr_get_len =>	
			if src_ready='1' then
			    next_state <= wr_get_data;
			else
			    next_state <= wr_get_len_idle;
			end if;

	    when wr_get_len_idle =>	
			if src_ready='1' then
			    next_state <= wr_get_data;
			else
			    next_state <= wr_get_len_idle;
			end if;

	    when wr_get_data =>	
			if src_ready='1' then
			    next_state <= kw_compute;
			else
			    next_state <= wr_get_data_idle;
			end if;


	    when wr_get_data_idle =>	
			if src_ready='1' then
			    next_state <= kw_compute;
			else
			    next_state <= wr_get_data_idle;
			end if;
			
			
			
	    when kw_compute =>	
			if src_ready='1' then
			    next_state <= data;
			else
			    next_state <= kw_compute_idle;
			end if;


	    when kw_compute_idle =>	
			if src_ready='1' then
			    next_state <= data;
			else
			    next_state <= kw_compute_idle;
			end if;

	    when data =>	
			if src_ready='1' then
					if z16='1' then 
			 	   		next_state <= data_end;
					else
						next_state <= data;
					end if;
			else
			    next_state <= data_idle;
			end if;


	    when data_idle =>	
			if src_ready='1' then
			    next_state <= data;
			else
			    next_state <= data_idle;
			end if;

	    when data_end =>	
			if src_ready='1' then
		 	   		next_state <= dummy;
			else
			    next_state <= data_end_idle;
			end if;


	    when data_end_idle =>	
			if src_ready='1' then
			    next_state <= dummy;
			else
			    next_state <= data_end_idle;
			end if;


		when dummy =>
				next_state <= computation;
				

	    when computation =>	
			if zlast='1' then
			    next_state <= computation_end;
			else
			    next_state <= computation;
			end if;


		when computation_end=>
			if last_block='1' then
					next_state <= result_delay;
			else
				if src_ready='1' then
					next_state <= result_delay;
				else
					next_state <= result_delay_idle;
				end if;
			end if;

		when result_delay=>	
			if last_block='0' and msg_done='0' then 
				next_state <= mb_result_delay2;
			elsif last_block='1' and msg_done='1' then
				next_state <= result_delay2;
				
			else
				if src_ready='1' then
					next_state <= result_delay2;
				else
					next_state <= result_idle;
				end if;
			 end if;
		when result_delay_idle =>
				if src_ready='1' then
					next_state <= result_delay;
				else
					next_state <= result_delay_idle;
				end if;

		when result_delay2=>
				if src_ready='1' then
					next_state <= result_delay3;
				else
					next_state <= result_delay2_idle;
				end if;

		when result_delay2_idle =>
				if src_ready='1' then
					next_state <= result_delay2;
				else
					next_state <= result_delay2_idle;
				end if;

		when result_delay3=>
					next_state <= result;
				
	    when result =>	
			if msg_done='1' then
				next_state <= send_data;
			else
				if src_ready='1' then
					next_state <= mux_gh;
				else
					next_state <= result_idle;
				end if;

			end if;

		when result_idle =>	   
			if msg_done='1' then
				next_state <=send_data;

			else	
				if src_ready='1' then
					next_state <= result;
				else
					next_state <= result_idle;
				end if;
			end if;		
	
		when mux_gh =>
			if src_ready='1' then 
				next_state <= data;
			else
				next_state <= mux_gh_idle;
			end if;
		
		when mux_gh_idle => 
			if src_ready = '1' then 
				next_state <= mux_gh;
			else
				next_state <= mux_gh_idle;
			end if;	

									  
			
		when mb_result_delay2 =>
			next_state <= mb_result_delay3; --mb_result_delay3;

		when mb_result_delay3 =>
			next_state <= mb_result;



		when mb_result =>
			next_state <= data;
			
			
			
	    when send_data =>	

			if dst_ready='0' then
				if o8='1' then
			    	next_state <= done;
				else
			    	next_state <= send_data;
				end if;
			else
			    next_state <= send_data_idle;
			end if;

    when send_data_idle =>	

			if dst_ready='0' then
			    	next_state <= send_data;
			else
			    next_state <= send_data_idle;
			end if;


		when done =>
			next_state <=idle; 
		
		when others => 
			next_state <= idle;

	end case;

    end process;
	
	swr: reg1 port map (clk=>clk, rst=>rst, ena=>VCC, d=>skip_word, q=>skip_word_reg);

	
	wr_len<= '1' when (current_state= get_len) else '0';
	
	--wld1: reg1 port map (clk=>clk, rst=>rst, ena=>VCC, d=>wr_len_wire, q=>wr_len);

	wr_data <= '1' when (( (current_state=wr_get_len) or (current_state=get_len_delay2) or (current_state=get_len_delay3) or (current_state=get_len_delay4) or (current_state=wr_get_data) or (current_state=kw_compute)or (current_state=data) or 
	(current_state=data_end)) ) or (current_state=dummy) or (current_state=computation) or (current_state=computation_end) or (current_state=result_delay)
	or((current_state=result_delay2 or  current_state=result) and (last_block='0') and (msg_done='0'))  or (current_state=mux_gh) or (current_state=mb_result_delay2) or (current_state=mb_result_delay3) or (current_state=mb_result) 
	else '0'; --or((current_state=result_delay2) and (last_block='0') and (msg_done='0'))or (current_state=result_delay2) or (current_state=result) or (current_state=mux_gh) else '0';
	--current_state=result_delay3 or or (current_state=result_delay3)

 	--wdd1: reg1 port map (clk=>clk, rst=>rst, ena=>VCC, d=>wr_data_wire, q=>wr_data);

						
	--wr_result<= '1' when ((current_state=computation) and (zlast='1')) or (current_state=computation_end) or (current_state=dummy) or (current_state= result) or (current_state=mb_result) else '0';
	wr_result<= '1' when  (current_state= result_delay) or (current_state= mb_result_delay2) or (current_state= mb_result_delay3) or (current_state=mb_result) 
	or (current_state= result_delay2)or (current_state= result_delay3)  or (current_state=result) else '0';

		
	--!!!!or (current_state=get_data)	
	src_read <= '1' when ( (current_state=get_len_delay2) or (current_state=get_len_delay3) or (current_state=get_len_delay4) 
	or(current_state=get_len)   or (current_state=wr_get_len)  or (current_state=wr_get_data)
	or (current_state=kw_compute)  or (current_state=data) or (current_state=data_end) or (current_state=dummy) or (current_state=mb_result) or (current_state=mux_gh)
	or (current_state=result_delay and (last_block='1') and (msg_done='0'))  or (current_state=mb_result_delay3))  else '0';
											  								   --or (current_state=result_delay)   or (current_state=mb_result_delay2)or (current_state=mb_result_delay3)
	--or (current_state=result_delay3)

	wr_state <= '1' when (  (current_state=get_len_delay4)or (current_state=kw_compute) or(current_state=data) or (current_state=data_end))  or (current_state=dummy) or (current_state=computation) or 
					(current_state=computation_end) or (current_state=result_delay) or (current_state=result_delay2)or (current_state=result_delay3) or (current_state=mb_result_delay2) or (current_state=mb_result_delay3) or (current_state=result)  or (current_state=mb_result) or (current_state=mux_gh) else '0';
						  --(current_state=get_data) or --

	ctr_ena <= '1' when ((  (current_state=get_len_delay)or (current_state=get_len_delay2)or (current_state=get_len_delay3)or (current_state=get_len_delay4)or (current_state=get_data)or(current_state=wr_get_len)  or (current_state=wr_get_data) or (current_state=kw_compute)or (current_state=data) or 
				(current_state=data_end)) )  or (current_state=dummy) or ((current_state=computation))
				or (current_state=dummy)or (current_state=computation_end)  or (current_state=mux_gh)
				or (current_state=mb_result_delay2) or (current_state=mb_result_delay3) or(current_state=mb_result) else '0';
				 
				--or (current_state=result)
				
	sel	<= '1' when (current_state=result) or (current_state=mb_result) else '0';

	sel2 <='1' when  (current_state=computation) or (current_state=computation_end) or (current_state=result_delay)  else '0';-- or (current_state=dummy2)

--	sel_gh <= '1' when (current_state=wr_get_data)or (current_state=mb_result)or (current_state=result)  else '0';	--or (current_state=mux_gh)
	sel_gh <= '1' when (current_state=get_len_delay3)  or(current_state=wr_get_data)or (current_state=mb_result)or (current_state=result)  else '0';	--or (current_state=mux_gh)

	sel_gh2 <= '1' when  (current_state=mb_result)or (current_state=result) else '0';

	dst_write <= '1' when ((current_state=send_data) ) else '0';

	ctrl_rst <= '1' when (current_state=done) else '0';

	rst_flags  <= '0'; --when (current_state=mb_result) else '0';

	kw_wr <='1' when ( (current_state=get_len_delay3)or (current_state=get_len_delay4)or (current_state=wr_get_data)or (current_state=kw_compute)or (current_state=data) or (current_state=data_end)  or (current_state=dummy)
		 or (current_state=computation) or (current_state=computation_end)  or (current_state=result_delay) or (current_state=result_delay2)  or (current_state=mux_gh) or (current_state=mb_result_delay2) or (current_state=mb_result)) else '0';
		 --
		 
	wr_lb <= '1' when (current_state=dummy) else '0';	
	wr_chctr <= '1' when (current_state=data_end)else '0';	
	wr_md <='1' when (current_state=result_delay) else '0';
	
			 
end zero_wait_state;




architecture one_wait_state of rs_controller is


    type state_type is (idle, 
						get_len, 
						get_len_idle, 
						get_len_delay,
						get_len_delay2,
						get_len_delay3,
						get_len_delay4,
						get_main_delay,
						get_data, 
						get_data_idle,
						wr_get_len, 
						wr_get_len_idle, 
						wr_get_data, 
						wr_get_data_idle,
						
						kw_compute, 
						kw_compute_idle,
						data, 
						data_idle, 
						data_end, 
						data_end_idle, 
						dummy, 
						computation, 
						computation_end, 
						result_delay, 
						result_delay_idle,
						result_delay2, 
						result_delay2_idle,
						result_delay3, 
						mb_result_delay2,
						mb_result_delay3, 
						
						mb_result,						
						result, 
						result_idle,
						mux_gh,
						mux_gh_idle, 
						send_data, 
						send_data_idle, 
						done);

signal next_state, current_state: state_type;
attribute enum_encoding : string;
	
--signal wr_data_wire		:std_logic;
--signal wr_len_wire		:std_logic;
signal skip_word_reg	:std_logic;

begin
    
    state_reg: process(clk, rst)
    begin

	if (rst='1') then
            current_state <= idle;
	elsif (clk'event and clk='1') then
	    current_state <= next_state;
	end if;

    end process;						  

    comb_logic: process(current_state,src_ready, z16, zlast,o8,last_block, msg_done, skip_word, skip_word_reg, next_state, dst_ready)
    begin


	case current_state is

	    when idle =>	
			if src_ready='1' then
			    next_state <= get_len;
			else
			    next_state <= idle;
			end if;
						
	    when get_len =>	
			if skip_word='1' then 
					next_state <= get_len;
			elsif skip_word_reg='1' and skip_word ='0' then
					next_state <= get_len_delay;
			else	
				if src_ready='1' then
			    	next_state <= get_main_delay;--get_data;
				else
			    	next_state <= get_len_idle;
				end if;
			end if;	 
		
		when get_len_delay =>
			next_state <= get_len_delay2;
				
		when get_len_delay2 =>
			next_state <= get_len_delay3;

		when get_len_delay3 =>
			next_state <= get_len_delay4;

		when get_len_delay4 =>
			next_state <= kw_compute;--get_data;
			
			when get_len_idle =>	
			if src_ready='1' then
			    next_state <= get_data;
			else
			    next_state <= get_len_idle;
			end if;								 
			
		when get_main_delay =>
			next_state <= get_data;

	    when get_data =>	
			if src_ready='1' then
			    next_state <= wr_get_len;
			else
			    next_state <= get_data_idle;
			end if;


	    when get_data_idle =>	
			if src_ready='1' then
			    next_state <= wr_get_len;
			else
			    next_state <= get_data_idle;
			end if;

	    when wr_get_len =>	
			if src_ready='1' then
			    next_state <= wr_get_data;
			else
			    next_state <= wr_get_len_idle;
			end if;

	    when wr_get_len_idle =>	
			if src_ready='1' then
			    next_state <= wr_get_data;
			else
			    next_state <= wr_get_len_idle;
			end if;

	    when wr_get_data =>	
			if src_ready='1' then
			    next_state <= kw_compute;
			else
			    next_state <= wr_get_data_idle;
			end if;


	    when wr_get_data_idle =>	
			if src_ready='1' then
			    next_state <= kw_compute;
			else
			    next_state <= wr_get_data_idle;
			end if;
			
			
			
	    when kw_compute =>	
			if src_ready='1' then
			    next_state <= data;
			else
			    next_state <= kw_compute_idle;
			end if;


	    when kw_compute_idle =>	
			if src_ready='1' then
			    next_state <= data;
			else
			    next_state <= kw_compute_idle;
			end if;

	    when data =>	
			if src_ready='1' then
					if z16='1' then 
			 	   		next_state <= data_end;
					else
						next_state <= data;
					end if;
			else
			    next_state <= data_idle;
			end if;


	    when data_idle =>	
			if src_ready='1' then
			    next_state <= data;
			else
			    next_state <= data_idle;
			end if;

	    when data_end =>	
			if src_ready='1' then
		 	   		next_state <= dummy;
			else
			    next_state <= data_end_idle;
			end if;


	    when data_end_idle =>	
			if src_ready='1' then
			    next_state <= dummy;
			else
			    next_state <= data_end_idle;
			end if;


		when dummy =>
				next_state <= computation;
				

	    when computation =>	
			if zlast='1' then
			    next_state <= computation_end;
			else
			    next_state <= computation;
			end if;


		when computation_end=>
			if last_block='1' then
					next_state <= result_delay;
			else
				if src_ready='1' then
					next_state <= result_delay;
				else
					next_state <= result_delay_idle;
				end if;
			end if;

		when result_delay=>	
			if last_block='0' and msg_done='0' then 
				next_state <= mb_result_delay2;
			elsif last_block='1' and msg_done='1' then
				next_state <= result_delay2;
				
			else
				if src_ready='1' then
					next_state <= result_delay2;
				else
					next_state <= result_idle;
				end if;
			 end if;
		when result_delay_idle =>
				if src_ready='1' then
					next_state <= result_delay;
				else
					next_state <= result_delay_idle;
				end if;

		when result_delay2=>
				if src_ready='1' then
					next_state <= result_delay3;
				else
					next_state <= result_delay2_idle;
				end if;

		when result_delay2_idle =>
				if src_ready='1' then
					next_state <= result_delay2;
				else
					next_state <= result_delay2_idle;
				end if;

		when result_delay3=>
					next_state <= result;
				
	    when result =>	
			if msg_done='1' then
				next_state <= send_data;
			else
				if src_ready='1' then
					next_state <= mux_gh;
				else
					next_state <= result_idle;
				end if;

			end if;

		when result_idle =>	   
			if msg_done='1' then
				next_state <=send_data;

			else	
				if src_ready='1' then
					next_state <= result;
				else
					next_state <= result_idle;
				end if;
			end if;		
	
		when mux_gh =>
			if src_ready='1' then 
				next_state <= data;
			else
				next_state <= mux_gh_idle;
			end if;
		
		when mux_gh_idle => 
			if src_ready = '1' then 
				next_state <= mux_gh;
			else
				next_state <= mux_gh_idle;
			end if;	

									  
			
		when mb_result_delay2 =>
			next_state <= mb_result_delay3; --mb_result_delay3;

		when mb_result_delay3 =>
			next_state <= mb_result;



		when mb_result =>
			next_state <= data;
			
			
			
	    when send_data =>	

			if dst_ready='0' then
				if o8='1' then
			    	next_state <= done;
				else
			    	next_state <= send_data;
				end if;
			else
			    next_state <= send_data_idle;
			end if;

    when send_data_idle =>	

			if dst_ready='0' then
			    	next_state <= send_data;
			else
			    next_state <= send_data_idle;
			end if;


		when done =>
			next_state <=idle; 
		
		when others => 
			next_state <= idle;

	end case;

    end process;
	
	swr: reg1 port map (clk=>clk, rst=>rst, ena=>VCC, d=>skip_word, q=>skip_word_reg);

	
	wr_len<= '1' when (current_state= get_len) else '0';
	
	--wld1: reg1 port map (clk=>clk, rst=>rst, ena=>VCC, d=>wr_len_wire, q=>wr_len);

	wr_data <= '1' when (( (current_state=wr_get_len) or (current_state=get_len_delay3) or (current_state=get_len_delay4) or (current_state=wr_get_data) or (current_state=kw_compute)or (current_state=data) or 
	(current_state=data_end)) ) or (current_state=dummy) or (current_state=computation) or (current_state=computation_end) or (current_state=result_delay)
	or((current_state=result_delay2 or  current_state=result) and (last_block='0') and (msg_done='0'))  or (current_state=mux_gh) or (current_state=mb_result_delay2) or (current_state=mb_result_delay3) or (current_state=mb_result) 
	or (current_state=get_len_delay)
	else '0'; --or((current_state=result_delay2) and (last_block='0') and (msg_done='0'))or (current_state=result_delay2) or (current_state=result) or (current_state=mux_gh) else '0';
	--current_state=result_delay3 or or (current_state=result_delay3)

 	--wdd1: reg1 port map (clk=>clk, rst=>rst, ena=>VCC, d=>wr_data_wire, q=>wr_data);

						
	--wr_result<= '1' when ((current_state=computation) and (zlast='1')) or (current_state=computation_end) or (current_state=dummy) or (current_state= result) or (current_state=mb_result) else '0';
	wr_result<= '1' when  (current_state= result_delay) or (current_state= mb_result_delay2) or (current_state= mb_result_delay3) or (current_state=mb_result) 
	or (current_state= result_delay2)or (current_state= result_delay3)  or (current_state=result) else '0';


	src_read <= '1' when ( (current_state=get_len_delay2) or (current_state=get_len_delay3) or (current_state=get_len_delay4) or(current_state=get_len)  or (current_state=get_data) or (current_state=wr_get_len)  or (current_state=wr_get_data)
	or (current_state=kw_compute)  or (current_state=data) or (current_state=data_end) or (current_state=mb_result) or (current_state=mux_gh)
	or (current_state=result_delay and (last_block='1') and (msg_done='0'))  or (current_state=mb_result_delay2)or (current_state=mb_result_delay3))  else '0';
											  								   --or (current_state=result_delay)   or (current_state=mb_result_delay2)or (current_state=mb_result_delay3)
	--or (current_state=result_delay3)

	wr_state <= '1' when ( (current_state=get_len_delay3)or (current_state=kw_compute) or(current_state=data) or (current_state=data_end))  or (current_state=dummy) or (current_state=computation) or 
					(current_state=computation_end) or (current_state=result_delay) or (current_state=result_delay2)or (current_state=result_delay3) or (current_state=mb_result_delay2) or (current_state=mb_result_delay3) or (current_state=result)  or (current_state=mb_result) or (current_state=mux_gh) else '0';
						  --(current_state=get_data) or --

	ctr_ena <= '1' when ((  (current_state=get_len_delay)or (current_state=get_len_delay2)or (current_state=get_len_delay3)or (current_state=get_len_delay4)or (current_state=get_data)or(current_state=wr_get_len)  or (current_state=wr_get_data) or (current_state=kw_compute)or (current_state=data) or 
				(current_state=data_end)) )  or (current_state=dummy) or ((current_state=computation))
				or (current_state=dummy)or (current_state=computation_end)  or (current_state=mux_gh)
				or (current_state=mb_result_delay2) or (current_state=mb_result_delay3) or(current_state=mb_result) else '0';
				 
				--or (current_state=result)
				
	sel	<= '1' when (current_state=result) or (current_state=mb_result) else '0';

	sel2 <='1' when  (current_state=computation) or (current_state=computation_end) or (current_state=result_delay)  else '0';-- or (current_state=dummy2)

--	sel_gh <= '1' when (current_state=wr_get_data)or (current_state=mb_result)or (current_state=result)  else '0';	--or (current_state=mux_gh)
	sel_gh <= '1' when (current_state=get_len_delay2) or (current_state=get_len_delay4) or(current_state=wr_get_data)or (current_state=mb_result)or (current_state=result)  else '0';	--or (current_state=mux_gh)

	sel_gh2 <= '1' when  (current_state=mb_result)or (current_state=result) else '0';

	dst_write <= '1' when ((current_state=send_data) ) else '0';

	ctrl_rst <= '1' when (current_state=done) else '0';

	rst_flags  <= '0'; --when (current_state=mb_result) else '0';

	kw_wr <='1' when ((current_state=get_len_delay2)or (current_state=get_len_delay4)or (current_state=wr_get_data)or (current_state=kw_compute)or (current_state=data) or (current_state=data_end)  or (current_state=dummy)
		 or (current_state=computation) or (current_state=computation_end)  or (current_state=result_delay) or (current_state=result_delay2)  or (current_state=mux_gh) or (current_state=mb_result_delay2) or (current_state=mb_result)) else '0';
		 --
		 
	wr_lb <= '1' when (current_state=dummy) else '0';	
	wr_chctr <= '1' when (current_state=data_end)else '0';	
	wr_md <='1' when (current_state=result_delay) else '0';
	
			 
end one_wait_state;

