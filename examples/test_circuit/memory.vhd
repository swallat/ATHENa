-----------------------------------------------------------------------------------------
-- Memory (BLOCKRAM in Xilinx/MEMORYBLOCK in ALTERA) or (Memory Implemented using LUT's)
-----------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

library work;
use work.pack.all;

entity mem is
	generic (
				vendor   : integer:= XILINX;          -- vendor 		: XILINX=0, ALTERA=1
            mem_type : integer:= MEM_EMBEDDED; 	  -- mem_type 		: MEM_DISTRIBUTED=0, MEM_EMBEDDED=1 
				mem_block_size : integer:= M9K		  -- mem_block_size : M512=0,M4K=1,M9K=2,M20K=3,MLAB=4,MRAM=5,M144K=6
		     );
	port( 
			clk      : in std_logic;
			we			: in std_logic;
			addr    	: in std_logic_vector(7 downto 0);
			din		: in std_logic_vector(7 downto 0);
			dout    	: out std_logic_vector (7 downto 0)
		 );
end mem;

architecture mem of mem is

begin

mem1_gen : if (mem_type=MEM_EMBEDDED and vendor=XILINX) generate
	mem1:	entity work.mem(xil_embedded) port map (clk=>clk, we=>we, addr=>addr,din=>din, dout=>dout);
	end generate; 	
	
mem2_gen : if (mem_type=MEM_DISTRIBUTED and vendor=XILINX) generate
	mem2:	entity work.mem(xil_distributed) port map (clk=>clk, we=>we, addr=>addr,din=>din, dout=>dout);
end generate; 

mem3_gen : if (mem_type=MEM_EMBEDDED and vendor=ALTERA) generate
	mem3:	entity work.mem(alt_embedded) generic map (mem_block_size => mem_block_size) port map (clk=>clk, we=>we, addr=>addr,din=>din, dout=>dout);
	end generate; 	
	
mem4_gen : if (mem_type=MEM_DISTRIBUTED and vendor=ALTERA) generate
	mem4:	entity work.mem(alt_distributed) port map (clk=>clk, we=>we, addr=>addr,din=>din, dout=>dout);
end generate; 

end mem;
-- =======================================================

architecture xil_embedded of mem is	
	signal RAM : ram_type := RAM1;

	attribute ram_style : string ;
	attribute ram_style of RAM : signal is "block";
	begin 
		process (clk)
		begin
			if (clk'event and clk = '1') then
				if (we = '1') then
					RAM(conv_integer(addr)) <= din;
				end if;
				dout <= RAM(conv_integer(unsigned(addr)));		
			end if;			
		end process;
end xil_embedded;
-- =======================================================

architecture xil_distributed of mem is	
	signal RAM : ram_type := RAM1;
	 
	attribute ram_style : string ;
	attribute ram_style of RAM : signal is "distributed";
	begin
		process (clk)
			begin	  
			  if (clk'event and clk = '1') then	
				 dout <= RAM(conv_integer(unsigned(addr)));			
				if (we = '1') then
				 RAM(conv_integer(addr)) <= din;
				end if;	
			end if;
		end process;
end xil_distributed;
-- =======================================================

architecture alt_embedded of mem is	
begin

	mem_M512_gen : if (mem_block_size = M512) generate
		mem1:	entity work.mem(alt_embedded_M512) generic map (mem_block_size => mem_block_size) port map (clk=>clk, we=>we, addr=>addr,din=>din, dout=>dout);
	end generate; 	
		
	mem_M4K_gen : if (mem_block_size = M4K) generate
		mem2:	entity work.mem(alt_embedded_M4K) generic map (mem_block_size => mem_block_size) port map (clk=>clk, we=>we, addr=>addr,din=>din, dout=>dout);
	end generate; 

	mem_M9K_gen : if (mem_block_size = M9K) generate
		mem3:	entity work.mem(alt_embedded_M9K) generic map (mem_block_size => mem_block_size) port map (clk=>clk, we=>we, addr=>addr,din=>din, dout=>dout);
		end generate; 	
		
	mem_M20K_gen : if (mem_block_size = M20K) generate
		mem4:	entity work.mem(alt_embedded_M20K) generic map (mem_block_size => mem_block_size) port map (clk=>clk, we=>we, addr=>addr,din=>din, dout=>dout);
	end generate; 

	mem_M144K_gen : if (mem_block_size = MLAB) generate
		mem4:	entity work.mem(alt_embedded_MLAB) generic map (mem_block_size => mem_block_size) port map (clk=>clk, we=>we, addr=>addr,din=>din, dout=>dout);
	end generate; 

	mem_MLAB_gen : if (mem_block_size = MRAM) generate
		mem4:	entity work.mem(alt_embedded_MRAM) generic map (mem_block_size => mem_block_size) port map (clk=>clk, we=>we, addr=>addr,din=>din, dout=>dout);
	end generate; 

	mem_MRAM_gen : if (mem_block_size = M144K) generate
		mem4:	entity work.mem(alt_embedded_M144K) generic map (mem_block_size => mem_block_size) port map (clk=>clk, we=>we, addr=>addr,din=>din, dout=>dout);
	end generate; 

end alt_embedded;

-- =======================================================

architecture alt_embedded_M512 of mem is	
	signal RAM : ram_type := RAM1;
	signal data_wire, tmp : std_logic_vector(7 downto 0);

	attribute ramstyle : string ;
	attribute ramstyle of RAM : signal is "M512";
	begin
		process (clk)
			begin
			if (clk'event and clk = '1') then
			  dout <= RAM(conv_integer(unsigned(addr)));
				if (we = '1') then
					RAM(conv_integer(addr)) <= din;
				end if;	
			end if;
			
		end process;
end alt_embedded_M512;
-- =======================================================

architecture alt_embedded_M4K of mem is	
	signal RAM : ram_type := RAM1;
	signal data_wire, tmp : std_logic_vector(7 downto 0);

	attribute ramstyle : string ;
	attribute ramstyle of RAM : signal is "M4K";
	begin
		process (clk)
			begin
			if (clk'event and clk = '1') then
			  dout <= RAM(conv_integer(unsigned(addr)));
				if (we = '1') then
					RAM(conv_integer(addr)) <= din;
				end if;	
			end if;
			
		end process;
end alt_embedded_M4K;
-- =======================================================

architecture alt_embedded_M9K of mem is	
	signal RAM : ram_type := RAM1;
	signal data_wire, tmp : std_logic_vector(7 downto 0);

	attribute ramstyle : string ;
	attribute ramstyle of RAM : signal is "M9K";
	begin
		process (clk)
			begin
			if (clk'event and clk = '1') then
			  dout <= RAM(conv_integer(unsigned(addr)));
				if (we = '1') then
					RAM(conv_integer(addr)) <= din;
				end if;	
			end if;
			
		end process;
end alt_embedded_M9K;
-- =======================================================

architecture alt_embedded_M20K of mem is	
	signal RAM : ram_type := RAM1;
	signal data_wire, tmp : std_logic_vector(7 downto 0);

	attribute ramstyle : string ;
	attribute ramstyle of RAM : signal is "M20K";
	begin
		process (clk)
			begin
			if (clk'event and clk = '1') then
			  dout <= RAM(conv_integer(unsigned(addr)));
				if (we = '1') then
					RAM(conv_integer(addr)) <= din;
				end if;	
			end if;
			
		end process;
end alt_embedded_M20K;
-- =======================================================

architecture alt_embedded_MLAB of mem is	
	signal RAM : ram_type := RAM1;
	signal data_wire, tmp : std_logic_vector(7 downto 0);

	attribute ramstyle : string ;
	attribute ramstyle of RAM : signal is "MLAB";
	begin
		process (clk)
			begin
			if (clk'event and clk = '1') then
			  dout <= RAM(conv_integer(unsigned(addr)));
				if (we = '1') then
					RAM(conv_integer(addr)) <= din;
				end if;	
			end if;
			
		end process;
end alt_embedded_MLAB;
-- =======================================================

architecture alt_embedded_MRAM of mem is	
	signal RAM : ram_type := RAM1;
	signal data_wire, tmp : std_logic_vector(7 downto 0);

	attribute ramstyle : string ;
	attribute ramstyle of RAM : signal is "MRAM";
	begin
		process (clk)
			begin
			if (clk'event and clk = '1') then
			  dout <= RAM(conv_integer(unsigned(addr)));
				if (we = '1') then
					RAM(conv_integer(addr)) <= din;
				end if;	
			end if;
			
		end process;
end alt_embedded_MRAM;
-- =======================================================

architecture alt_embedded_M144K of mem is	
	signal RAM : ram_type := RAM1;
	signal data_wire, tmp : std_logic_vector(7 downto 0);

	attribute ramstyle : string ;
	attribute ramstyle of RAM : signal is "M144K";
	begin
		process (clk)
			begin
			if (clk'event and clk = '1') then
			  dout <= RAM(conv_integer(unsigned(addr)));
				if (we = '1') then
					RAM(conv_integer(addr)) <= din;
				end if;	
			end if;
			
		end process;
end alt_embedded_M144K;
-- =======================================================

architecture alt_distributed of mem is	
	signal RAM : ram_type := RAM1;
	signal data_wire, tmp : std_logic_vector(7 downto 0);

	attribute ramstyle : string ;
	attribute ramstyle of RAM : signal is "logic";
	begin
		process (clk)
			begin
			if (clk'event and clk = '1') then
			  dout <= RAM(conv_integer(unsigned(addr)));
				if (we = '1') then
					RAM(conv_integer(addr)) <= din;
				end if;	
			end if;
			
		end process;
end alt_distributed;
-- =======================================================