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
use work.pack.all;

entity arraymult is    						  
	generic (
		k : integer := 8
    );
	port ( 
		a : in std_logic_vector(K-1 downto 0);
		x : in std_logic_vector(K-1 downto 0);
		p : out std_logic_vector((2*K)-1 downto 0)
	);
end arraymult;

architecture arraymult of arraymult is 											   
	type sc_type is array ( 0 to K-1 ) of std_logic_vector(K-1 downto 0);
	signal sumout : sc_type;
	signal cout : sc_type;	
	signal cout_cpa : std_logic_vector(K-2 downto 0);
	
	signal ptemp : std_logic_vector((2*K)-1 downto 0);
begin 
	

	row_gen : for i in 0 to K-1 generate
		col_gen : for j in 0 to K-1 generate
			row_0 : if ( i = 0 ) generate			 
				col_last : if ( j = K-1 ) generate
					mfa_gen : mfa generic map ( not_and => '1' ) port map ( a => a(j), x => x(i), s => '0', c => '0', cout => cout(i)(j),sumout => sumout(i)(j) );
				end generate;
				col_x : if ( j /= K-1 ) generate																					
					mfa_gen : mfa generic map ( not_and => '0' ) port map ( a => a(j), x => x(i), s => '0', c => '0', cout => cout(i)(j),sumout => sumout(i)(j) );
				end generate;					
			end generate;
			row_x : if (( i > 0 ) and ( i < K-1 ))generate	  
				col_last : if ( j = K-1 ) generate
					mfa_gen : mfa generic map ( not_and => '1' ) port map ( a => a(j), x => x(i), s => '0', c => cout(i-1)(j), cout => cout(i)(j),sumout => sumout(i)(j) );
				end generate;
				col_x : if ( j /= K-1 ) generate
					mfa_gen : mfa generic map ( not_and => '0' ) port map ( a => a(j), x => x(i), s => sumout(i-1)(j+1), c => cout(i-1)(j), cout => cout(i)(j),sumout => sumout(i)(j) );
				end generate;
			end generate;
			row_last : if ( i = K-1 ) generate	  
				col_last : if ( j = K-1 ) generate
					mfa_gen : mfa generic map ( not_and => '0' ) port map ( a => a(j), x => x(i), s => '0', c => cout(i-1)(j), cout => cout(i)(j),sumout => sumout(i)(j) );
				end generate;
				col_x : if ( j /= K-1 ) generate
					mfa_gen : mfa generic map ( not_and => '1' ) port map ( a => a(j), x => x(i), s => sumout(i-1)(j+1), c => cout(i-1)(j), cout => cout(i)(j),sumout => sumout(i)(j) );
				end generate;
			end generate;									 			
		end generate;
		ptemp(i) <= sumout(i)(0);
	end generate;	 
	
	cpa_gen : for m in 0 to K-2 generate								
		cpa_0 : if ( m = 0 ) generate
			fa_gen : fa port map ( a => cout(K-1)(m), b => sumout(K-1)(m+1), c => '1',cout => cout_cpa(m), sumout => ptemp(m + K) );
		end generate;
		cpa_x : if ( m /= 0 ) generate
			fa_gen : fa port map ( a => cout(K-1)(m), b => sumout(K-1)(m+1), c => cout_cpa(m-1),cout => cout_cpa(m), sumout => ptemp(m + K) );
		end generate;
	end generate;							 
	
	ptemp((2*K)-1) <= not cout_cpa(K-2);

	p <= ptemp;
end arraymult;
		
	