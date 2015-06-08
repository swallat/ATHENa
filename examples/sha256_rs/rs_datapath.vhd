-- =============================================
-- SHA2 source code
-- Copyright © 2008-2010 CERG at George Mason University <cryptography.gmu.edu>.
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
use work.sha2_pkg.all;

entity rs_datapath is
generic( n : integer :=ARCH_32; s :integer:=LOG_2_8; flag: integer:=HASH_BLOCKS_256; a :integer:=LOG_2_64; r:integer:=ROUNDS_64; cs: integer := LOG_2_1024 );
port(	
	clk							: in std_logic;
	rst							: in std_logic;
	wr_state					: in std_logic;
	wr_result					: in std_logic;
	wr_data						: in std_logic;
	kw_wr						: in std_logic;
	wr_len						: in std_logic;
	sel							: in std_logic;	  
	sel2						: in std_logic;
	sel_gh						: in std_logic;		
	sel_gh2						: in std_logic;
	ctr_ena						: in std_logic;
	z16							: out std_logic;
	zlast						: out std_logic;
	skip_word					: out std_logic;
	o8							: out std_logic;
	dst_write					: in std_logic;
	ainit						: in std_logic_vector(n-1 downto 0);
	binit						: in std_logic_vector(n-1 downto 0);
	cinit						: in std_logic_vector(n-1 downto 0);
	dinit						: in std_logic_vector(n-1 downto 0);
	einit						: in std_logic_vector(n-1 downto 0);
	finit						: in std_logic_vector(n-1 downto 0);
	ginit						: in std_logic_vector(n-1 downto 0);
	hinit						: in std_logic_vector(n-1 downto 0);
	data						: in std_logic_vector(n-1 downto 0);
	dataout						: out std_logic_vector(n-1 downto 0); 
	wr_lb						: in std_logic;
	wr_md						: in std_logic;	
	wr_chctr					: in std_logic;		
	last_block					: out std_logic;
	msg_done					: out std_logic;	
	rst_flags					: in std_logic);

end rs_datapath;

architecture rs_datapath of rs_datapath is	 

type matrix 	is array (0 to STATE_REG_NUM-1) of std_logic_vector(n-1 downto 0);
signal from_round			:matrix;
signal to_round				:matrix;
signal from_final_add		:matrix;
signal from_mux				:matrix;
signal result				:matrix;
signal to_result			:matrix;
signal iv					:matrix;  
signal wwire				:std_logic_vector(n-1 downto 0);
signal kwire				:std_logic_vector(n-1 downto 0);
signal h_exception			:std_logic_vector(n-1 downto 0);
signal rd_num				:std_logic_vector(a-1 downto 0);
signal lb_reg				:std_logic;
signal md_reg				:std_logic;
signal z16_reg				:std_logic;	 
signal ena_reg				:std_logic;
signal zero					:std_logic_vector(n-1 downto 0);
signal kwhwire				:std_logic_vector(n-1 downto 0);
signal kwhreg				:std_logic_vector(n-1 downto 0);
signal chunk_ctr1			:std_logic_vector(n-1-cs downto 0);---- change	 
signal chunk_ctr2			:std_logic_vector(cs-1 downto 0);----- change	 
signal chunk_ctr			:std_logic_vector(n-1 downto 0);
signal chunk_len			:std_logic_vector(n-1 downto 0);
signal out_ctr				:std_logic_vector(s downto 0);
signal gh					:std_logic_vector(1 downto 0);


begin		 

	zero <= (others=>'0');		
	
	iv(0) <= ainit;	
	iv(1) <= binit;	
	iv(2) <= cinit;	
	iv(3) <= dinit;	
	iv(4) <= einit;	
	iv(5) <= finit;	
	iv(6) <= ginit;	
	iv(7) <= hinit;	

sr_gen: for i in 0 to STATE_REG_NUM-1 generate	
sr0			: regn 	generic map (n=>n) 
					port map (clk=>clk, ena=>wr_state, rst=>rst, init =>iv(i), d=>from_mux(i), q=>to_round(i));	
end generate;

		
kwh_reg		: regn 	generic map (n=>n) 
					port map (clk=>clk, ena=>kw_wr, rst=>rst, init =>zero, d=>kwhwire, q=>kwhreg);	

gh <= (sel_gh, sel_gh2);

h_exception <= 	to_round(6) when gh="00" else
		to_round(6) when gh="01" else
		to_round(7) when gh="10" else
		result(6);	

round: 	rs_round 
		generic map (n=>n)		
		port map (
		sel_gh=>sel_gh, 	
		kw=>kwhreg,
		kwire=>kwire,
		wwire=>wwire,	
		ain=>to_round(0),	
		bin=>to_round(1), 
		cin=>to_round(2), 
		din=>to_round(3), 
		ein=>to_round(4), 
		fin=>to_round(5), 
		gin=>to_round(6), 
		hin=>h_exception,
		kwhwire=>kwhwire, 
		aout=>from_round(0),
		bout=>from_round(1),	
		cout=>from_round(2),	
		dout=>from_round(3),	
		eout=>from_round(4),	
		fout=>from_round(5),	
		gout=>from_round(6),	
		hout=>from_round(7));  	  
		
		
--add0 		: addn 		generic map (n=>n)	
--				port map (a=>to_round(0), b=>result(3), o=>from_final_add(0));	
--
--add1 		: addn 		generic map (n=>n)	
--				port map (a=>to_round(4), b=>result(7), o=>from_final_add(4));

from_final_add(0)	<= to_round(0) +  result(3);
from_final_add(4)	<= to_round(4) +  result(7);
		
mux0_gen: for i in 0 to STATE_REG_NUM-1 generate
mux0		: muxn		generic map (n=>n)	
						port map (sel=>sel, a=>from_round(i), b=>from_final_add(i), o=>from_mux(i));
end generate; 

from_final_add(1) <= result(0);
from_final_add(2) <= result(1);
from_final_add(3) <= result(2);
from_final_add(5) <= result(4);
from_final_add(6) <= result(5);
from_final_add(7) <= result(6);

ena_reg <=wr_result or dst_write;

mux1_gen: for i in 0 to STATE_REG_NUM-2 generate
mux1		: muxn 		generic map (n=>n) 
				port map (sel=>wr_result, a=> result(i+1), b=>from_final_add(i), o=>to_result(i));
end generate;	  

to_result(7) <= from_final_add(7);

				
rr_gen: for i in 0 to STATE_REG_NUM-1 generate
rr			: regn 		generic map (n=>n) 
						port map (clk=>clk, ena=>ena_reg, rst=>rst, init =>iv(i), d=>to_result(i), q=>result(i));	
end generate;
												
dc			: msg_scheduler 
						generic map (n=>n)	
						port map (clk=>clk, sel=>sel2, wr_data=>wr_data, data=>data, w=>wwire);		
	  
rd_ctr 		:counter 	generic map (s=>a, r=>r-1, step=>1) 
						port map (clk=>clk, reset=>rst, ena=>ctr_ena, ctr=>rd_num);

bf			:bl_flags 	generic map (n=>n, a=>a, r=>r, s=>s, flag=>flag)
						port map (clk=>clk, rd_num=>rd_num, exam_block=>data, chunk_len=>chunk_len, chunk_ctr=>chunk_ctr, out_ctr=>out_ctr, wr_lb=>wr_lb, wr_md=> wr_md, rst=>rst, rst_flags=>rst_flags, z16=>z16_reg, lb=>lb_reg, md=>md_reg, zlast=>zlast, skip_word=>skip_word, o8=>o8 );

o_ctr		:counter 	generic map (s=>s+1, r=>flag+1) 
						port map (clk=>clk, reset=>rst, ena=>dst_write, ctr=>out_ctr);

const		:cons 		generic map (n=>n, a=>a)
						port map (clk=> clk, address=>rd_num, output=>kwire);	  

ch_len		:regn		generic map (n=>n) 
						port map (clk=>clk, ena=>wr_len, rst=>rst, init=>zero(n-1 downto 0), d=>data(n-1 downto 0), q=>chunk_len);	

ch_ctr 		:counter 	generic map (s=>(n-cs), r=>(2**(n-cs))-1, step=>1) 
						port map (clk=>clk, reset=>rst, ena=>wr_chctr, ctr=>chunk_ctr1);

chunk_ctr2 <= (others=>'0');

chunk_ctr <= chunk_ctr1 & chunk_ctr2;

z16 <= z16_reg;	
last_block <= lb_reg;
msg_done <= md_reg;		

dataout <=result(0);

	
end rs_datapath;

