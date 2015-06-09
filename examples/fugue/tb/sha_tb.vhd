-- ========================================================
-- Fugue source code.
-- Copyright © 2009 - 2014 CERG at George Mason University 
-- <http://cryptography.gmu.edu>.
-- author: Ekawat Homsirikamol
-- contacts: CERG faculty members: Dr. Kaps <jkaps@gmu.edu>
-- and <kgaj@gmu.edu> Dr. Gaj
-- ========================================================

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.ALL;
use ieee.std_logic_textio.all;
use work.sha3_pkg.all;
use work.fugue_pkg.all;
use work.tb_pkg.all;	

LIBRARY std;
use std.textio.all;				 
					
ENTITY sha_tb IS	
	--++++++++++++++++++++++++--
	--++++++ EDIT BELOW ++++++--																							   
	GENERIC (			  
	-- Testbench PARAMETERS	 
		fifo_mode			: integer := ZERO_WAIT_STATE; -- ZERO_WAIT_STATE, ONE_WAIT_STATE
		fifo_style			: integer := BRAM; -- BRAM, DISTRIBUTED
	
		clk_period 		: time := 50 ns;	-- clock speed
		clk_period_mult : integer := 1; 	-- this value will be used for io_clk where io_clk_period = clk_period/clk_period_mult; (in ns)
					
		-- CORE PARAMETERS
		depth 		: integer	:= 256;		-- depth of FIFO
	  	log2depth 	: integer 	:= 8;		-- 2^X = depth, where X = log2depth
	  	w 			: integer 	:= 32		-- DESIGN WIDTH		  
	);			
	--++++++ END OF EDIT +++++--
	--++++++++++++++++++++++++--
END sha_tb;

ARCHITECTURE behavior OF sha_tb IS 

	-- ====================== --
	-- COMPONENTS DECLARATION -- 
	-- ====================== --
	
	--++++++++++++++++++++++++--
	--++++++ EDIT BELOW ++++++--

COMPONENT fugue_top is		
	generic( HASHSIZE : integer := FUGUE_HASH_SIZE_256);-- size of hash
	port (		
		-- global
		rst 	: in std_logic;
		clk 	: in std_logic;
		--io_clk 	: in std_logic;
		
		--fifo
		src_ready : in std_logic;
		src_read  : out std_logic;
		dst_ready : in std_logic;
		dst_write : out std_logic;		
		din		: in std_logic_vector(w-1 downto 0);
		dout	: out std_logic_vector(w-1 downto 0)
	);	   
end COMPONENT;

	--++++++ END OF EDIT +++++--
	--++++++++++++++++++++++++--

			  													
	-- =================== --
	-- SIGNALS DECLARATION --
	-- =================== --
	
	-- simulation signals (used by ATHENa script, ignore if not used)
	signal simulation_pass : std_logic := '0'; 	  	-- '0' signifies a pass at the end of simulation, '1' is fail
	signal stop_clock : boolean := false;		-- '1' signifies a completed simulation, '0' otherwise
	signal force_exit : boolean := false;
	
	-- globals
	SIGNAL clk :  std_logic := '0';	  
	signal io_clk : std_logic := '0';
	SIGNAL rst :  std_logic := '0';
	
	--Inputs
	SIGNAL fifoin_write : std_logic := '0';
	signal fifoout_read : std_logic := '0';
	SIGNAL ext_idata :  std_logic_vector(w-1 downto 0) := (others=>'0');
	
	--Outputs
	SIGNAL fifoout_empty :  std_logic;
	SIGNAL fifoin_full :  std_logic;    
	SIGNAL ext_odata :  std_logic_vector(w-1 downto 0);
	
	-- Internals
	SIGNAL fifoin_empty :  std_logic;    
	SIGNAL fifoin_read 	:  std_logic;
	SIGNAL fifoout_full :  std_logic;	
	SIGNAL fifoout_write :  std_logic;
	SIGNAL odata 		:  std_logic_vector(w-1 downto 0);	   
	SIGNAL idata 		:  std_logic_vector(w-1 downto 0);	   
	
	------------- clock constant ------------------
	constant io_clk_period : time := clk_period/clk_period_mult;
	----------- end of clock constant -------------	  
	
	------------- string constant ------------------
   	constant cons_len 	: string(1 to 6) := "Len = ";
	constant cons_msg 	: string(1 to 6) := "Msg = ";		   
	constant cons_md 	: string(1 to 5) := "MD = ";	
	constant cons_eof 	: string(1 to 5) := "#EOF#";
	----------- end of string constant -------------		 

	------------- debug constant ------------------
   	constant debug_input : boolean := false;
	constant debug_output : boolean := false;
	----------- end of clock constant -------------

	-- ================= --
	-- FILES DECLARATION -- 
	-- ================= --
    
	--------------- input / output files -------------------
	FILE datain_file	: TEXT OPEN READ_MODE   is  "random_split_nopad_fugue_datain_h256_w32.txt";
	FILE dataout_file	: TEXT OPEN READ_MODE   is  "random_split_nopad_fugue_dataout_h256_w32.txt";  
	
	FILE log_file : TEXT OPEN WRITE_MODE is "athena_test_log.txt";  
	FILE result_file : TEXT OPEN WRITE_MODE is "athena_test_result.txt";  
	------------- end of input files --------------------
	
BEGIN
	
	clk_gen: process  
	begin
		if (not stop_clock) then 
			clk <= '0'; 
			wait for clk_period/2; 
			clk <= '1'; 
			wait for clk_period/2; 
		else 
			wait; 
		end if; 
	end process clk_gen; 

	io_clk_gen: process  
	begin
		if (not stop_clock) then 
			io_clk <= '0'; 
			wait for io_clk_period/2; 
			io_clk <= '1'; 
			wait for io_clk_period/2; 
		else 
			wait; 
		end if; 
	end process io_clk_gen; 
	-- ============ --
	-- PORT MAPPING --
	-- ============ --		 
	
	--++++++++++++++++++++++++--
	--++++++ EDIT BELOW ++++++--
	-- SUBSTITUTE YOUR CORE HERE --
	-- NOTE : be careful of src_ready and dst_ready, these inputs have not been inverted yet (your core must invert the value yourself)	

	
	fifoin: entity work.fifo(prefetch)   
	generic map ( fifo_mode=>fifo_mode, depth => depth, log2depth => log2depth, N => W)
	port map (
	  clk=>io_clk,
	  rst=>rst,
	  write=>fifoin_write,
	  read=>fifoin_read,
	  din=>ext_idata,
	  dout=>idata,
	  full=>fifoin_full,
	  empty=>fifoin_empty
	);
	
	
	uut: fugue_top 
	--generic map (  n => w, fifo_mode=>fifo_mode )
	port map (
	    clk			=> io_clk,
	    rst			=> rst,
	    din			=> idata,
	    src_read	=> fifoin_read,
	    src_ready	=> fifoin_empty,
	    dout		=> odata,
	    dst_write	=> fifoout_write,
	    dst_ready	=> fifoout_full);
		
	
	 fifoout: entity work.fifo(prefetch) 
	 generic map ( fifo_mode=>fifo_mode, depth => depth, log2depth => log2depth, N => W)
	 port map (
	  clk=>io_clk,
	  rst=>rst,
	  write=>fifoout_write,
	  read=>fifoout_read,
	  din=>odata,
	  dout=>ext_odata,
	  full=>fifoout_full,
	  empty=>fifoout_empty
	 );
	 -- =================== --
	 -- END OF PORT MAPPING --
	 -- =================== --
 
	
    -- ===========================================================
	-- ==================== DATA POPULATION ====================== 
	tb_readdata : PROCESS
   		VARIABLE 	line_data, errorMsg	: 	LINE;
		variable 	word_block 				:  	std_logic_vector(w-1 downto 0) := (others=>'0');
		variable 	read_result				: 	boolean; 
		variable	loop_enable				: 	std_logic := '1';	   
		variable	temp_read				: 	string(1 to 6); 
		variable	valid_line				: 	boolean := true;
	BEGIN																 
	
		rst <= '1';	   		wait for 5*clk_period;
		rst <= '0';	   		wait for clk_period;	
		
		-- read header
		while ( not endfile (datain_file)) and ( loop_enable = '1' ) loop
			if endfile (datain_file) then
				loop_enable := '0';
			end if;
			
			readline(datain_file, line_data);
			read(line_data, temp_read, read_result);	 
			if (temp_read = cons_len) then
				loop_enable := '0';
			end if;
		end loop;
		
		while not endfile ( datain_file ) loop  		    
			-- if the fifo is full, wait ...				
			fifoin_write <= '1';			
			if ( fifoin_full = '1' ) then		
				fifoin_write <= '0';			
				wait until fifoin_full <= '0';
				fifoin_write <= '1';			
			end if;	  	
			
			hread( line_data, word_block, read_result );
			while (((read_result = false) or (valid_line = false)) and (not endfile( datain_file ))) loop
				readline(datain_file, line_data);
				read(line_data, temp_read, read_result);	-- read line header 
				if ( temp_read /= cons_msg and temp_read /= cons_len) then
					valid_line := false;
				else
					valid_line := true;
				end if;
				hread( line_data, word_block, read_result );-- read data 		
				report "---------din:reading new line--------" severity error;
			end loop;
			ext_idata <= word_block;
	   		wait for io_clk_period; 	   		
		end loop;   
		wait;
	END PROCESS;	 
	-- ===========================================================		
	
	
	-- ===========================================================		
	-- =================== DATA VERIFICATION =====================
	tb_verifydata : PROCESS	  
		variable 	line_data, errorMsg	: 	LINE;
		variable 	word_block 			:  	std_logic_vector(w-1 downto 0) := (others=>'0');
		variable 	read_result			: 	boolean; 
		variable	loop_enable 		: 	std_logic := '1';
		variable	temp_read			: 	string(1 to 5); 	
		variable 	valid_line			:	boolean := true;
	begin	
		wait for 6*clk_period;
		-- read header
		while ( not endfile (dataout_file)) and ( loop_enable = '1' ) loop
			if endfile (dataout_file) then
				loop_enable := '0';
			end if;
			
			readline(dataout_file, line_data);
			read(line_data, temp_read);	 
			if (temp_read = cons_md) then
				loop_enable := '0';
			end if;
		end loop;
		
		while (not endfile (dataout_file) and valid_line and (not force_exit)) loop   				
			-- get data to compare
			hread( line_data, word_block, read_result );
			while (((read_result = false) or (valid_line = false)) and (not endfile( dataout_file ))) loop		   -- if false then read new line
				readline(dataout_file, line_data);
				read(line_data, temp_read, read_result);	-- read line header  
				if ( temp_read /= cons_md ) then
					valid_line := false;
				else
					valid_line := true;
				end if;		
				if ( temp_read = cons_eof ) then
					force_exit <= true;
				end if;
				hread( line_data, word_block, read_result );-- read data 	
				report "---------finished a hash--------" severity error;
			end loop;	
			
			
			-- if the core is slow in outputing the digested message, wait ...
			if ( valid_line ) then	 				
				fifoout_read <= '1';	
				if ( fifoout_empty = '1') then	  
					fifoout_read <= '0';	
					wait until fifoout_empty = '0';	
					wait for io_clk_period;
					fifoout_read <= '1';
					wait for io_clk_period/2;
				end if;				
				
				
			if fifo_mode=ONE_WAIT_STATE then	
				wait for io_clk_period; -- wait a cycle for data to come out	   
			end if;		
					
				if ext_odata /= word_block then
					if ( simulation_pass = '0' ) then
						simulation_pass <= '1';	
					end if;
					write(errorMsg, string'("HASH FAIL at time ==========> "));
					write(errorMsg, now);
					writeline(log_file,errorMsg);
				end if;
				
			if (fifo_mode=ZERO_WAIT_STATE) then	
				wait for io_clk_period; -- wait a cycle for data to come out	   
			end if;	
				
			end if;
		end loop;  				
		
		fifoout_read <= '0';	
		
		wait for 10*io_clk_period;	   		
				   				
		
		if ( simulation_pass = '1' ) then
			report "FAIL (1): SIMULATION FINISHED" severity error;
			write(result_file, "fail");
		else 
			report "PASS (0): SIMULATION FINISHED" severity error;
			write(result_file, "pass");
		end if;
		stop_clock <= true;	
	  	wait;   
	end process;  	
	-- ===========================================================
	
	
-- ================================================================	
-- # This section is used for testing the tb without the core.  
-- # Must comment below process in order to run the core properly.
-- # Valid signals that can be manipulated in the below process are the handshake signals from a hash core.
-- # They are -- fifoin_read, fifoout_empty			   
-- ================================================================	
--	inputtest : process
--	begin	
--		fifoin_read <= '1';
--		fifoout_empty <= '0';
--		wait;
--	end process;
END;
