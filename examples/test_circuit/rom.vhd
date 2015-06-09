-----------------------------------------------------------------------------------------
-- Memory (BLOCKRAM in Xilinx/MEMORYBLOCK in ALTERA) or (Memory Implemented using LUT's)
-----------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

library work;
use work.pack.all;

entity rom is
	generic (
				vendor   : integer:= XILINX;          -- vendor 		: XILINX=0, ALTERA=1
            mem_type : integer:= MEM_EMBEDDED; 	  -- mem_type 		: MEM_DISTRIBUTED=0, MEM_EMBEDDED=1 
				mem_block_size : integer:= M9K		  -- mem_block_size : M512=0,M4K=1,M9K=2,M20K=3,MLAB=4,MRAM=5,M144K=6
		     );
	port( 
			clk      : in std_logic;
			addr    	: in std_logic_vector(7 downto 0);
			dout    	: out std_logic_vector (7 downto 0)
		 );
end rom;

architecture rom of rom is
begin

memory_gen: entity work.mem(mem) generic map (vendor => vendor, mem_type => mem_type, mem_block_size => mem_block_size) 
											port map (clk => clk, we => GND, addr => addr, din => x"01", dout => dout);	


end rom;