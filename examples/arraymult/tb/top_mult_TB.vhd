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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
USE ieee.std_logic_textio.all;


LIBRARY std;
USE std.textio.all;

use work.pack.all;


entity top_mult_tb is
		generic(
		k : INTEGER := 8 );
end top_mult_tb;

architecture TB_ARCHITECTURE of top_mult_tb is
	-- Component declaration of the tested unit
	component top_mult
		generic(
		k : INTEGER := 128 );
	port(
		clk : in STD_LOGIC;
		rst : in STD_LOGIC;
		enai : in STD_LOGIC;
		enao : in STD_LOGIC;
		muxsel : in STD_LOGIC;
		a : in STD_LOGIC;
		x : in STD_LOGIC;
		p : out STD_LOGIC );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal clk : STD_LOGIC := '0';
	signal rst : STD_LOGIC := '0';
	signal enai : STD_LOGIC;
	signal enao : STD_LOGIC;
	signal muxsel : STD_LOGIC;
	signal a : STD_LOGIC;
	signal x : STD_LOGIC;
	-- Observed signals - signals mapped to the output ports of tested entity
	signal p : STD_LOGIC;

	-- Add your code here ...
   	-- VERIFICATION FILES / SIGNALS
	FILE ain8_txt : TEXT OPEN READ_MODE is "a8.txt";
	FILE xin8_txt : TEXT OPEN READ_MODE is "b8.txt";	
	
	FILE output_file : TEXT OPEN WRITE_MODE is "athena_test_result.txt";  --OPEN WRITE_MODE is "TEST_PASS";
	
	signal vP : std_logic;		 
	
	-- Global Signal (Used by script)
	signal simulation_pass : std_logic := '1'; 
	
	signal stop_clock : boolean := false; 
begin

	clk_gen: process  
	begin
		if (not stop_clock) then 
			clk <= '0'; 
			wait for clkperiod/2; 
			clk <= '1'; 
			wait for clkperiod/2; 
		else 	  
			clk <= '0';
			wait; 
		end if; 
	end process clk_gen; 


	-- Unit Under Test port map
	UUT : top_mult	 
		generic map (
			k => k
		)
		port map (
			clk => clk,
			rst => rst,
			enai => enai,
			enao => enao,
			muxsel => muxsel,
			a => a,
			x => x,
			p => p
		);

	-- Add your stimulus here ...
	
	testing: PROCESS  		
		VARIABLE aLine, xLine, errorMSG: LINE;
		VARIABLE vA, vX : STD_LOGIC_VECTOR(K-1 DOWNTO 0);		
		variable vMULT  : std_logic_vector((2*K)-1 downto 0 );	 
	begin
		while not endfile (xin8_txt) loop
			readline(ain8_txt, aLine);	
			readline(xin8_txt, xLine);	
			read(aLine, vA); 			
			read(xLine, vX);
			
			-- ===========================================================
			-- Loading data onto multiplier unit
			for i in 0 to k-1 loop
				enai <= '1';			   
				a <= vA(i);
				x <= vX(i);
				wait for clkperiod;	
			end loop;					  
			enai <= '0';								
			vMULT := vA*vX;	 --preparing expected result
			enao <= '1';		
			muxsel <= '0';	   											  
			-- End of loading
			-- ===========================================================
			
			wait for clkperiod;
			
			-- ===========================================================
			--	Verification Area	
			enao <= '1';		
			muxsel <= '1';	  
			for i in ((2*k)-1) downto 0 loop	
				vP <= vMULT(i);
				wait for clkperiod*1/2; 
				if ( p /= vP ) then						
					if ( simulation_pass = '1' ) then
						write( errorMsg, string'("0") );
						writeline( output_file, errorMsg );
						simulation_pass <= '0';
					end if;
					write(errorMsg, string'("MULT FAIL at time ==========> "));
					write(errorMsg, now);
					writeline(output_file,errorMsg);	 
				end if;	 					
				wait for clkperiod*1/2;
			end loop;		
			-- End of verification			
			-- ===========================================================
						
		end loop; 		  	   
		
		-- ===================================================================
		-- Write 1 to the output file to declare that the test was simulation_passful if simulation_pass still remain '1'
		if ( simulation_pass = '1' ) then
			write( output_file, "pass" );
		else 
			write( output_file, "fail" );
		end if;
		
		
		stop_clock <= true;
		wait;
	end process;

end TB_ARCHITECTURE;