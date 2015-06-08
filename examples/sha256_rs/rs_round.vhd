-- =============================================
-- SHA2 source code
-- Copyright © 2008-2009 - 2014 CERG at George Mason University <cryptography.gmu.edu>.
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

entity rs_round is
generic( n : integer :=ARCH_32);
port(	 
	sel_gh		:in std_logic;	 
	kw		:in std_logic_vector(n-1 downto 0);
	kwire		:in std_logic_vector(n-1 downto 0);
   	wwire		:in std_logic_vector(n-1 downto 0);	
	ain		:in std_logic_vector(n-1 downto 0);
	bin		:in std_logic_vector(n-1 downto 0);
	cin		:in std_logic_vector(n-1 downto 0);
	din		:in std_logic_vector(n-1 downto 0);
	ein		:in std_logic_vector(n-1 downto 0);
	fin		:in std_logic_vector(n-1 downto 0);
	gin		:in std_logic_vector(n-1 downto 0);
	hin		:in std_logic_vector(n-1 downto 0);	  
	kwhwire		:out std_logic_vector(n-1 downto 0);
	aout		:out std_logic_vector(n-1 downto 0);
	bout		:out std_logic_vector(n-1 downto 0);
	cout		:out std_logic_vector(n-1 downto 0);
	dout		:out std_logic_vector(n-1 downto 0);
	eout		:out std_logic_vector(n-1 downto 0);
	fout		:out std_logic_vector(n-1 downto 0);
	gout		:out std_logic_vector(n-1 downto 0);
	hout		:out std_logic_vector(n-1 downto 0));
end rs_round;

architecture basic of rs_round	is	
	signal	cf0_reg	: std_logic_vector(n-1 downto 0);
	signal	cf1_reg	: std_logic_vector(n-1 downto 0);
	signal	ch_reg		: std_logic_vector(n-1 downto 0);
	signal	maj_reg		: std_logic_vector(n-1 downto 0);	
	signal g_or_h				:std_logic_vector(n-1 downto 0);	


begin 	   	

a32: if n=ARCH_32 generate	
s0		: sigma_func 	generic map (n=>n, func=>"cf", a=>ARCH32_CF0_1, b=>ARCH32_CF0_2, c=>ARCH32_CF0_3) port map (x=>ain, o=>CF0_reg);	
s1		: sigma_func 	generic map (n=>n, func=>"cf", a=>ARCH32_CF1_1, b=>ARCH32_CF1_2, c=>ARCH32_CF1_3) port map (x=>ein, o=>CF1_reg);	 
end generate;

	c1		: ch_func		generic map (n=>n) port map (x=>ein, y=>fin, z=>gin, o=>ch_reg);	
	m1		: maj_func		generic map (n=>n) port map (x=>ain, y=>bin, z=>cin, o=>maj_reg);
		
	eout <= ch_reg + cf1_reg + kw + din;

	aout <= kw + maj_reg + cf0_reg + ch_reg +cf1_reg; 	
	
	
m8		: muxn		generic map (n=>n)	port map (sel=>sel_gh, a=>gin, b=>hin, o=>g_or_h);	

	kwhwire <= g_or_h + kwire + wwire;
	 
		bout <= ain;
		cout <= bin;
		dout <= cin;
		fout <= ein;
		gout <= fin;
		hout <= gin;
		
end basic;	

