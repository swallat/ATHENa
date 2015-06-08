-- =====================================================================
-- Copyright © 2009 - 2014 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

------------------------------------------------------------
----------     TestBench for test circuit      -------------
------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
USE ieee.std_logic_textio.all;


LIBRARY std;
USE std.textio.all;

library work;
use work.pack.all;

entity test_circuit_TB is
   generic(			  
            
            n 		                    : integer := 16;		             -- Number of Stages			  
            vendor                  : integer := XILINX;	         -- {0=Xilinx, 1=ALTERA}
            mem1_type               : integer := MEM_DISTRIBUTED; -- mem_type        = {0=MEM_DISTRIBUTED, 1=MEM_EMBEDDED}
			mem_block1_size			: integer := M9K;				-- mem_block_size = {0 = M512, 1 = M4K, 2 = M9K, 3 = M20K, 4 = MLAB, 5 = MRAM, 6 = M144K}
            adder1_type             : integer := ADD_SCCA_BASED;  -- adder_type      = {0=ADD_SCCA_BASED,  1=ADD_DSP_BASED}
            multiplier1_type        : integer := MUL_LOGIC_BASED; -- multiplier_type = {0=MUL_LOGIC_BASED, 1=MUL_DEDICATED}
            mem2_type               : integer := MEM_EMBEDDED;	   -- mem_type        = {0=MEM_DISTRIBUTED, 1=MEM_EMBEDDED}
            mem_block2_size			: integer := M9K;				-- mem_block_size = {0 = M512, 1 = M4K, 2 = M9K, 3 = M20K, 4 = MLAB, 5 = MRAM, 6 = M144K}
			adder2_type             : integer := ADD_DSP_BASED;   -- adder_type      = {0=ADD_SCCA_BASED,  1=ADD_DSP_BASED}
            multiplier2_type        : integer := MUL_DEDICATED   -- multiplier_type = {0=MUL_LOGIC_BASED, 1=MUL_DEDICATED}

          );	  
end test_circuit_TB;

architecture top of test_circuit_TB is

-- ====================== 
-- COMPONENTS DECLARATION 
-- ====================== 

component test_circuit is
	generic 
	(
			n 				: integer := 8;						
			mem_type 		: integer := MEM_EMBEDDED; 
			mem_block_size	: integer := M9K;
			adder_type 		: integer := ADD_DSP_BASED;				
			multiplier_type	: integer := MUL_DEDICATED;		
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
end component;


constant data_val : std_logic_vector(7 downto 0) := b"00110011"; 

-- ====================== 
-- signal declaration
-- ====================== 

signal clk      :  std_logic;	 
signal reset    :  std_logic := '0';
signal enai       : std_logic;
signal enaj      : std_logic;
signal load     : std_logic;
signal data_in  : std_logic_vector (7 downto 0); 
signal d_out_1  : std_logic_vector (7 downto 0);
signal d_out_2  : std_logic_vector (7 downto 0);
signal error_check : std_logic := '0';

signal simulation_pass : std_logic := '1';

constant clk_period 		: time := 20 ns;	-- clock speed

-- VERIFICATION FILES / SIGNALS
FILE output_file : TEXT OPEN WRITE_MODE is "athena_test_result.txt";  

begin
  
-- ====================== 
-- Port Map
-- ======================   
        
UUT1: test_circuit    -- Default settings (All logic)
generic map 
  (
        n => n,				 
        mem_type        => mem1_type, 
		mem_block_size  => mem_block1_size,
        adder_type      => adder1_type,	
        multiplier_type => multiplier1_type,
        vendor          => vendor   
  )
  port map
  (
      clk 		   => clk,
      reset 	   => reset,
      enai 		   => enai,
      enaj         => enaj,
      ld_prng 	   => load,
      a 		   => data_in,
      s 		   => d_out_1
  );
  
UUT2: test_circuit     -- All embedded resources setting
generic map 
  (
        n => n,				    
        mem_type        => mem2_type, 	
		mem_block_size  => mem_block2_size,
        adder_type      => adder2_type,			            
        multiplier_type => multiplier2_type,   		          
        vendor          => vendor                
  )
  port map
  (
      clk 		  => clk,
      reset 	  => reset,
      enai 		  => enai,
      enaj        => enaj,
      ld_prng 	  => load,
      a 		  => data_in,
      s 		  => d_out_2
  );
  
  -- Output value to text file
  get_input_a: PROCESS 
       
    variable errorMSG: LINE;
    
    begin
             
      for i in 1 to 2*n loop
            wait for clk_period; 
            
            if ( d_out_1 /= d_out_2 ) then		
             
             simulation_pass <= '0'; 
             write(errorMsg, string'("Simulation failed at time ==>  "));
             write(errorMsg, clk_period * i);
             write(errorMsg, string'(" -- Output of UUT1 ==>  "));
             write(errorMsg, d_out_1);
             write(errorMsg, string'(" -- Output of UUT2 ==>  "));
             write(errorMsg, d_out_2);
             error_check <= '1';
                 
             
            else
            
             simulation_pass <= '1';  
             write(errorMsg, string'("Simulation correct at time ==>  "));
             write(errorMsg, clk_period * i);
             write(errorMsg, string'(" -- Output of UUT1 ==>  "));
             write(errorMsg, d_out_1);
             write(errorMsg, string'(" -- Output of UUT2 ==>  "));
             write(errorMsg, d_out_2);

            end if;
          
          writeline(output_file,errorMsg);      
       
       end loop;
 
       
          if (error_check /= '1') then
            write(errorMsg, string'(" ==============================  "));
            writeline(output_file, errorMsg);
            write(errorMsg, string'("       Simulation pass "));
            writeline(output_file,errorMsg);
            write(errorMsg, string'(" ==============================  "));
            writeline(output_file, errorMsg);
          else
            write(errorMsg, string'(" ==============================  "));
            writeline(output_file, errorMsg);
            write(errorMsg, string'("       Simulation fail "));
            writeline(output_file,errorMsg);
            write(errorMsg, string'(" ==============================  "));
            writeline(output_file, errorMsg);
          end if;    
        
    wait;
    end process;	
   
-- clock generation
clk_gen: process
begin

  clk <= '0';       wait for clk_period/2;
  clk <= '1';       wait for clk_period/2;
end process;

--reset generation
reset_gen: process
begin

  reset <= '1';     wait for clk_period/4;
  reset <= '0';
  wait;
end process;

load_gen: process --Used for loading PRNG
begin
  load <= '1';        wait for clk_period;
  load <= '0';
  
wait;
end process;

en_gen: process   -- Enable other than the last register
begin 
  enai <= '1';
  wait for 2*n* clk_period;
  enai <= '0';
  wait;
end process;

eni_gen: process  -- Enable for the last register
begin 
  enaj <= '0'; 
  wait for n * clk_period;
  enaj <= '1';
  wait for n * clk_period;
  enaj <= '0';
  wait;
end process;

data_in_gen: process  -- Input a to design
begin
  data_in <= data_val;  wait for clk_period;

wait;
end process;

end top;



