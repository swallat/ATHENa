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
use work.fugue_pkg.all;

entity fugue_state is
generic ( hashsize : integer := FUGUE_HASH_SIZE_256; w:integer :=FUGUE_WORD_SIZE );
port (	
	input 			: in	state;
	rst, clk, en 	: in 	std_logic;
	output 			: out 	state);
end fugue_state;

architecture fugue_state of fugue_state is	

signal low_din, low_dout : std_logic_vector((30*8*4)-hashsize-1 downto 0);
signal high_din, high_dout : std_logic_vector(hashsize-1 downto 0);
constant zero	: std_logic_vector((30*8*4)-hashsize-1 downto 0):=(others=>'0');

begin							  
	

	state_low: regn
	generic map (n=>((30*4*8)-hashsize), init=>zero)
	port map ( clk=>clk, rst=>rst, en=>en, input=>low_din, output=>low_dout);	
	
	gen_iv_224: if hashsize=FUGUE_HASH_SIZE_224 generate
		state_high: regn generic map(n=>hashsize, init=>FUGUE_INIT_224) port map( clk=>clk, rst=>rst, en=>en, input=>high_din, output=>high_dout);			
	end generate;		
	
	gen_iv_256: if hashsize=FUGUE_HASH_SIZE_256 generate
		state_high: regn generic map(n=>hashsize, init=>FUGUE_INIT_256) port map( clk=>clk, rst=>rst, en=>en, input=>high_din, output=>high_dout);			
	end generate;		

	state224: if hashsize = FUGUE_HASH_SIZE_224 generate 
				  		
		ldo: for i in 0 to 22 generate	
			output(i) <= low_dout((22-i+1)*FUGUE_WORD_SIZE-1 downto (22-i)*FUGUE_WORD_SIZE);
			low_din((22-i+1)*FUGUE_WORD_SIZE-1 downto (22-i)*FUGUE_WORD_SIZE) <= input(i);			
		end generate;	  
		
		hdo: for i in 23 to 29 generate	   
			output(i) <= high_dout((29-i+1)*FUGUE_WORD_SIZE-1 downto (29-i)*FUGUE_WORD_SIZE);
			high_din((29-i+1)*FUGUE_WORD_SIZE-1 downto (29-i)*FUGUE_WORD_SIZE) <= input(i);
		end generate;
		
	end generate;

	
	state256: if hashsize = FUGUE_HASH_SIZE_256 generate  
		
  		ldo: for i in 0 to 21 generate	
			output(i) <= low_dout((21-i+1)*FUGUE_WORD_SIZE-1 downto (21-i)*FUGUE_WORD_SIZE);
			low_din((21-i+1)*FUGUE_WORD_SIZE-1 downto (21-i)*FUGUE_WORD_SIZE) <= input(i);		
		end generate;	  
		
		hdo: for i in 22 to 29 generate	   
			output(i) <= high_dout((29-i+1)*FUGUE_WORD_SIZE-1 downto (29-i)*FUGUE_WORD_SIZE); 
			high_din((29-i+1)*FUGUE_WORD_SIZE-1 downto (29-i)*FUGUE_WORD_SIZE) <= input(i);
		end generate;
				
	end generate;

end fugue_state;
