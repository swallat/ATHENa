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
use work.sha2_pkg.all;	  

entity sha256 is
generic( fifo_mode : integer := ZERO_WAIT_STATE; n : integer :=ARCH_32);
port (
    	clk						:in std_logic;
    	rst						:in std_logic;
    	din						:in std_logic_vector(n-1 downto 0); 
    	src_read				:out std_logic;
    	src_ready				:in std_logic;
    	dout					:out std_logic_vector(n-1 downto 0); 
    	dst_write				:out std_logic;
    	dst_ready				:in std_logic);
end sha256;

architecture rs_arch of sha256 is 		   	   

component rs_datapath is
generic( n : integer :=ARCH_32; s :integer:=LOG_2_8; flag: integer:=HASH_BLOCKS_256; a :integer:=LOG_2_64; r:integer:=ROUNDS_64; cs: integer := LOG_2_1024);
port(	
	clk						:in std_logic;
	rst						:in std_logic;
	wr_state				:in std_logic;
	wr_result				:in std_logic;
	wr_data					:in std_logic;
	kw_wr					:in std_logic;
	wr_len					:in std_logic;
	sel						:in std_logic;	  
	sel2					:in std_logic;
	sel_gh					:in std_logic;		
	sel_gh2					:in std_logic;
	ctr_ena					:in std_logic;
	z16						:out std_logic;
	zlast					:out std_logic;
	skip_word				:out std_logic;
	o8						:out std_logic;
	dst_write				:in std_logic;
	ainit					:in std_logic_vector(n-1 downto 0);
	binit					:in std_logic_vector(n-1 downto 0);
	cinit					:in std_logic_vector(n-1 downto 0);
	dinit					:in std_logic_vector(n-1 downto 0);
	einit					:in std_logic_vector(n-1 downto 0);
	finit					:in std_logic_vector(n-1 downto 0);
	ginit					:in std_logic_vector(n-1 downto 0);
	hinit					:in std_logic_vector(n-1 downto 0);
	data					:in std_logic_vector(n-1 downto 0);
	dataout					:out std_logic_vector(n-1 downto 0); 
	wr_lb					:in std_logic;
	wr_md					:in std_logic;	
	wr_chctr				:in std_logic;		
	last_block				:out std_logic;
	msg_done				:out std_logic;	
	rst_flags				:in std_logic);
end component;

component rs_controller is
generic(fifo_mode :integer:=ZERO_WAIT_STATE);
port(	
	clk						:in std_logic;
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
end component;



signal z16_reg				:std_logic;
signal zlast_reg			:std_logic;
signal sel2_reg				:std_logic;
signal sel_reg				:std_logic;
signal wr_data_reg			:std_logic;					
signal wr_state_reg			:std_logic;				
signal wr_len_reg			:std_logic;				
signal wr_result_reg			:std_logic;				
signal ctr_ena_reg			:std_logic;
signal lb_reg				:std_logic;
signal dst_write_reg			:std_logic;
signal o8_reg				:std_logic;	
signal ctrl_rst_reg			:std_logic;
signal rst_reg				:std_logic;
signal src_ready_reg			:std_logic;
signal rst_flags_reg			:std_logic;
signal kr_wr_wire			:std_logic;	 
signal wr_lb_reg			:std_logic;
signal wr_md_reg			:std_logic;	 
signal wr_chctr_reg			:std_logic;
signal msg_done_reg			:std_logic;
signal  sel_gh_reg			:std_logic;	
signal  sel_gh_reg2			:std_logic;	
signal  skip_word			:std_logic;	

	
begin

--assert (cf_arch=CF_BASIC or cf_arch=CF_CPA_BASED or cf_arch=CF_CPA_CPA_BASED or cf_arch=CF_FEDORYKA or or cf_arch=CF_PC_BASED)
--report "round architecture unspecified"
--severity error;	
--	
--assert (ms_arch=MS_BASIC or ms_arch=MS_CPA_BASED or ms_arch=MS_CPA_CPA_BASED or ms_arch=MS_MCEVOY or or ms_arch=MS_PC_BASED)
--report "message scheduler architecture unspecified"
--severity error;	


src_ready_reg <=  not src_ready;

controller: entity work.rs_controller(rs_controller)
generic map (fifo_mode=>fifo_mode) 								
port map (	
		clk=>clk,	
		rst=>rst,
		z16=>z16_reg,						
		zlast=>zlast_reg,	
		o8=>o8_reg,	
		skip_word=>skip_word,
		sel2=>sel2_reg,	
		sel=>sel_reg,	
		sel_gh=>sel_gh_reg,
		sel_gh2=>sel_gh_reg2,				
    	src_read=>src_read,				
    	src_ready=>src_ready_reg,		
    	dst_write=>dst_write_reg,				
    	dst_ready=>dst_ready,		
		wr_data=>wr_data_reg,	
		kw_wr=> kr_wr_wire,				
		wr_state=>wr_state_reg,				
		wr_result=>wr_result_reg,	
		wr_len=>wr_len_reg,	
		last_block=>lb_reg,	
		msg_done=>msg_done_reg,
		ctr_ena=>ctr_ena_reg,
		ctrl_rst=>ctrl_rst_reg,	   
		wr_lb=>wr_lb_reg,	
		wr_md=>wr_md_reg,  
		wr_chctr=>wr_chctr_reg,
		rst_flags=>rst_flags_reg);

datapath: entity work.rs_datapath(rs_datapath) 
generic map (n=>n, s=>LOG_2_8, flag=>HASH_BLOCKS_256-1, a=>LOG_2_64, r=>ROUNDS_64, cs=>LOG_2_512)
port map (	clk=>clk,
		rst=>rst_reg,
		wr_state=>wr_state_reg,	
		wr_result=>wr_result_reg,	
		wr_data=>wr_data_reg,	
		kw_wr=> kr_wr_wire,				
		wr_len=>wr_len_reg,	
		sel=>sel_reg,				  
		sel2=>sel2_reg,	
		sel_gh=>sel_gh_reg,
		sel_gh2=>sel_gh_reg2,					
		ctr_ena=>ctr_ena_reg,		
		z16=>z16_reg,			
		zlast=>zlast_reg,
		skip_word=>skip_word,
		o8=>o8_reg,
		dst_write=>dst_write_reg,	
		ainit=>SHA256_AINIT,
		binit=>SHA256_BINIT,
		cinit=>SHA256_CINIT,
		dinit=>SHA256_DINIT,
		einit=>SHA256_EINIT,
		finit=>SHA256_FINIT,
		ginit=>SHA256_GINIT,
		hinit=>SHA256_HINIT,
		data=>din,		
		dataout=>dout,	
		wr_lb=>wr_lb_reg,
		wr_md=>wr_md_reg,
		wr_chctr=>wr_chctr_reg,
		last_block=>lb_reg,
		msg_done=>msg_done_reg,
		rst_flags=>rst_flags_reg);

rst_reg <= ctrl_rst_reg or rst;
dst_write <= dst_write_reg;

end rs_arch;
