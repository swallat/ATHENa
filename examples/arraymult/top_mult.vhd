-- =============================================
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

-- ==============================
-- Example - Array Multiplier
-- ==============================
	
library IEEE;
use ieee.std_logic_1164.all;
use work.pack.all;	   


entity top_mult is
	generic ( 	k 	: integer := 8 );		-- n divides by x (n must be divisible by x )
	port (
		clk	:	in 	std_logic; 	
		rst : 	in  std_logic;
		enai	:	in 	std_logic;
		enao	:	in 	std_logic;
		muxsel	:	in 	std_logic;					 
		a 	: 	in 	std_logic;
		x 	: 	in 	std_logic;
		p	:	out	std_logic);
end top_mult;

architecture top_mult of top_mult is
	signal rega, regx : std_logic_vector(k-1 downto 0);
	signal regp, muxsig : std_logic_vector((2*k)-1 downto 0);
	
	signal pout : std_logic_vector((2*k)-1 downto 0);  
	
	component arraymult is    						  
		generic (
			k : integer := 128
	    );
		port ( 
			a : in std_logic_vector(K-1 downto 0);
			x : in std_logic_vector(K-1 downto 0);
			p : out std_logic_vector((2*K)-1 downto 0)
		);
	end component;	 
	
begin
	
	rega0_gen : reg1 port map ( clk => clk, ena => enai, d => a, q => rega(k-1));
	regx0_gen : reg1 port map ( clk => clk, ena => enai, d => x, q => regx(k-1));
	
	regxy_gen : for i in 0 to (k - 2) generate
		regx_gen : reg1 port map ( clk => clk, ena => enai, d => rega(i+1), q => rega(i));
		regy_gen : reg1 port map ( clk => clk, ena => enai, d => regx(i+1), q => regx(i));			
	end generate;																				   				
	
	mult_instance : arraymult generic map ( k => k ) port map ( a => rega, x => regx, p => pout );
	
	muxgen : for i in 1 to ((2*k)-1) generate
		muxsig(i) <= pout(i) when muxsel = '0' else regp(i-1);
	end generate;																											  
	
	regp_gen : for i in 0 to ((2*k)-1) generate
		regp_cond1_gen : if i = 0 generate
			regp_c1_gen : reg1 port map ( clk => clk, ena => enao, d => pout(i), q => regp(i));
		end generate;					 
		regp_cond2_gen : if i /= 0 generate
			regp_c2_gen : reg1 port map ( clk => clk, ena => enao, d => muxsig(i), q => regp(i));
		end generate;
	end generate;
	
	p <= regp((2*k)-1);
	
end top_mult;		