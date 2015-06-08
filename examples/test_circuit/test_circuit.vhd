-- =====================================================================
-- Copyright © 2009 - 2014 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.pack.all;

-- Possible generics values: 
--		vendor = {XILINX, ALTERA}
--		n = Number of Stages, can be of any value. 
-- Note: n should be equal to or less than the number of available resourses (memory/adder/multiplier) in the chosen device of Xilinx/Altera  
--		mem_type   = {MEM_DISTRIBUTED, MEM_EMBEDDED}
--		mem_block_size = {M512,M4K,M9K,M20K,MLAB,MRAM,M144K}
-- Note: mem_block_size is only applicable to Altera families. User must specify appropriate memory block size available in a particular Altera family
--   		(i.e CycloneII devices have only M4K blocks whereas StratixIII devices have the option of M9K, M144K, MLAB and MRAM) 			
--		adder_type = {ADD_SCCA_BASED, ADD_DSP_BASED}
--		multiplier_type = {MUL_LOGIC_BASED, MUL_DEDICATED}
-- Note: selection of multiplier_type as MUL_DEDICATED will infer dedicated multiplier in spartan3/cycloneII family and dsp multiplier in high throughput families (spartan6/virtex/stratix/arria)

-- 		Depth of Memory block is fixed to 256
-- 		WIDTH = Width of Memory block is fixed to 8
-- Note: any changes in Depth and Width of memory block will require changes in pseudo random number generator (prng.vhd) 

entity test_circuit is
	generic 
	(
			n 				: integer := 8;						
			mem_type 		: integer := MEM_EMBEDDED; 			-- {MEM_DISTRIBUTED, MEM_EMBEDDED}
			mem_block_size	: integer := M9K;							-- {M512,M4K,M9K,M20K,MLAB,MRAM,M144K}
			adder_type 		: integer := ADD_DSP_BASED;			-- {ADD_SCCA_BASED, ADD_DSP_BASED}	
			multiplier_type	: integer := MUL_DEDICATED;			--	{MUL_LOGIC_BASED, MUL_DEDICATED}
			vendor 			: integer := XILINX  				
	);
	port
	(
			clk 		   : in std_logic;
			reset 	 	   : in std_logic;
			enai 		   : in std_logic;
			enaj 		   : in std_logic;
			ld_prng 	   : in std_logic;
			a 			   : in std_logic_vector(7 downto 0);
			s 			   : out std_logic_vector(7 downto 0)
	);
end test_circuit;

architecture top of test_circuit is

	type reg_array is array (n-1 downto 0) of std_logic_vector(7 downto 0);
	type reg_array2 is array (n downto 0) of std_logic_vector(7 downto 0);
	
	signal add_in1, mult_in, const, add_in2, addr_in  : reg_array;
	signal reg_in: reg_array2;
	constant zero	: std_logic_vector(7 downto 0)	:= (others=>'0');
	signal s_regin, s_temp: std_logic_vector(7 downto 0);
	
	begin	
	reg_in(0) <= a;
	
		unit_gen : for i in 0 to (n-1) generate
	
			const(i) <=std_logic_vector(to_unsigned(i+1, 8));
			prng00 : entity work.prng(arch_prng) port map(D => const(i), Q => addr_in(i), clk => clk, reset => reset, load => ld_prng, en => enai );
			mem00  : entity work.rom(rom) generic map (vendor => vendor, mem_type => mem_type, mem_block_size => mem_block_size) port map (clk => clk,addr => addr_in(i),dout => mult_in(i));
			mult00 : entity work.mult(mult) 
			generic map (vendor => vendor, multiplier_type => multiplier_type, WIDTH => 8) 
			port map (A => mult_in(i), B => const(i), S => add_in2(i) );
			reg00  : entity work.reg1(struc) generic map (WIDTH => 8) port map ( clk => clk, reset => reset, ena => enai, d => reg_in(i), q => add_in1(i));
			add00  : entity work.adder(adder) generic map (vendor => vendor, adder_type => adder_type, WIDTH => 8) port map (A => add_in1(i), B => add_in2(i), S => reg_in(i+1) );
			
		end generate;
		
		add01  : entity work.adder(adder) generic map (vendor => vendor, adder_type => adder_type, WIDTH => 8) port map (A => reg_in(n), B => s_temp, S => s_regin );
		reg01  : entity work.reg1(struc) generic map (WIDTH => 8) port map ( clk => clk, reset => reset, ena => enaj, d => s_regin, q => s_temp);
		s <= s_temp;
end top;