-- =====================================================================
-- Copyright © 2009 - 2014 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.

-- n (Number of Stages) can be of any value
-- Depth of Memory block is fixed to 256 bits
-- Width of Memory block is fixed to 8 bits
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
             n : integer := 32							                -- Number of Stages
          );	  
end test_circuit_TB;

architecture top of test_circuit_TB is

-- ====================== 
-- COMPONENTS DECLARATION 
-- ====================== 

component test_circuit is
  generic 
  (
        n : integer := 8;							                -- Number of Stages
        mem_type :integer:= BLOCK_BASED; 			    -- DISTRIBUTED or BRAM_BASED
        adder_type : integer:= DEFAULT_ADDER;			-- SCCA_BASED or DSP_BASED
        multiply_type : integer:= DSP_MULT;   		-- LOGIC_BASED or DSP_BASED
        vendor : integer:= XILINX				           -- XILINX or ALTERA
  );
  port
  (
      clk 		   : in std_logic;
      reset 	 	: in std_logic;
      enai 		  : in std_logic;
      enaj     : in std_logic;
      ld_prng 	: in std_logic;
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
FILE ain8_txt : TEXT OPEN READ_MODE is "a8.txt";	
FILE output_file : TEXT OPEN WRITE_MODE is "athena_test_result.txt";  --OPEN WRITE_MODE is "TEST_PASS";

begin
  
-- ====================== 
-- Port Map
-- ======================   
        
UUT1: test_circuit    -- Default settings (All logic)
generic map 
  (
        n => n,				    			               -- Number of Stages
        mem_type      => 0, 			           -- DISTRIBUTED    = 0 or BRAM_BASED = 1
        adder_type    => 0,			            -- DEFAULT_ADDER  = 0 or DSP_BASED  = 1
        multiply_type => 0,   		          -- COMB_MULT      = 0 or DSP_MULT   = 1
        vendor        => 0                -- XILINX         = 0 or ALTERA     = 1
  )
  port map
  (
      clk 		   => clk,
      reset 	  => reset,
      enai 		  => enai,
      enaj     => enaj,
      ld_prng 	=> load,
      a 			   => data_in,
      s 			   => d_out_1
  );
  
UUT2: test_circuit     -- All embedded resources setting
generic map 
  (
        n => n,				    			               -- Number of Stages
        mem_type      => 1, 			           -- DISTRIBUTED    = 0 or BRAM_BASED = 1
        adder_type    => 1,			            -- DEFAULT_ADDER  = 0 or DSP_BASED  = 1
        multiply_type => 1,   		          -- COMB_MULT      = 0 or DSP_MULT   = 1
        vendor        => 1                -- XILINX         = 0 or ALTERA     = 1
  )
  port map
  (
      clk 		   => clk,
      reset 	  => reset,
      enai 		  => enai,
      enaj     => enaj,
      ld_prng 	=> load,
      a 			   => data_in,
      s 			   => d_out_2
  );
  
  -- Output value to text file
  get_input_a: PROCESS 
       
    variable errorMSG: LINE;
    
    begin
             
      for i in 1 to 2*n loop
            wait for clk_period; 
            
            if ( d_out_1 /= d_out_2 ) then		
             
             simulation_pass <= '0'; 
             write(errorMsg, string'("Simulation pass at time ==>  "));
             write(errorMsg, clk_period * i);
             write(errorMsg, string'(" -- Output of UUT1 ==>  "));
             write(errorMsg, d_out_1);
             write(errorMsg, string'(" -- Output of UUT2 ==>  "));
             write(errorMsg, d_out_1);
             error_check <= '1';
                 
             
            else
            
             simulation_pass <= '1';  
             write(errorMsg, string'("Simulation pass at time ==>  "));
             write(errorMsg, clk_period * i);
             write(errorMsg, string'(" -- Output of UUT1 ==>  "));
             write(errorMsg, d_out_1);
             write(errorMsg, string'(" -- Output of UUT2 ==>  "));
             write(errorMsg, d_out_1);

            end if;
          
          writeline(output_file,errorMsg);      
       
       end loop;
 
       
          if (error_check /= '1') then
            write(errorMsg, string'(" ==============================  "));
            writeline(output_file, errorMsg);
            write(errorMsg, string'("       Simulation passed "));
            writeline(output_file,errorMsg);
            write(errorMsg, string'(" ==============================  "));
            writeline(output_file, errorMsg);
          else
            write(errorMsg, string'(" ==============================  "));
            writeline(output_file, errorMsg);
            write(errorMsg, string'("       Simulation failed "));
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
  wait;
end process;

eni_gen: process  -- Enable for the last register
begin 
  enaj <= '0'; 
  wait for n * clk_period;
  enaj <= '1';
  wait;
end process;

data_in_gen: process  -- Input a to design
begin
  data_in <= data_val;  wait for clk_period;

wait;
end process;

end top;



