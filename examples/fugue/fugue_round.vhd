-- =============================================
-- SHA3 source code
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;  
use work.sha3_pkg.all;
use work.fugue_pkg.all;

ENTITY fugue_round IS
GENERIC ( hashsize : INTEGER := FUGUE_HASH_SIZE_256; w:integer :=FUGUE_WORD_SIZE );
PORT (			
		output : out	 	state;										  
		curr_p	:in std_logic_vector(w-1 downto 0);
		clk, mode1_n,mode3_n, pad_n : IN 		STD_LOGIC;
		input : in 	state );
END fugue_round;

architecture a1 of fugue_round	is

signal  S1p, S1pp, S2p, S2pp, S3p, S4p, S4pp, S5p, St1p, St2p  : state; 


begin
	
	--input into state comes from S5p
	fb: for j in 0 to 29 generate
			output(j) <= S5p(j);
	end generate fb;

	--TIX in round transformation R
	R_TIX: fugue_tix port MAP(
		P => Curr_P,
		I0 => input(0),
		I1 => input(1),
		I8 => input(8),
		I10 => input(10),
		I24 => input(24),
		O0 => S1p(3),
		O1 => S1p(4),
		O8 => S1p(11),
		O10 => S1p(13)
	);
	--connect rest of S1p to S (with rotation >>>3)
	rot1: for j in 0 to 29 generate
		cond1: if (j/=3) and (j/=4) and (j/=11) and (j/=13) generate
			S1p(j)<=input((30+j-3)mod 30);
		end generate cond1;
	end generate rot1;

	--tap in mode 2 (G1)
	sw1: for j in 0 to 29 generate
			S1pp(j)<=S1p(j) when (mode1_n = '0') OR (pad_n = '0') else input((30+j-3)mod 30);
	end generate sw1;

	--CMIX in round transformation R (first iteration)
	R_CMIX1: fugue_cmix port MAP(
		I0 => S1pp(0),
		I1 => S1pp(1),
		I2 => S1pp(2),
		I4 => S1pp(4),
		I5 => S1pp(5),
		I6 => S1pp(6),
		I15 => S1pp(15),
		I16 => S1pp(16),
		I17 => S1pp(17),
		O0 => S2p(0),
		O1 => S2p(1),
		O2 => S2p(2),
		O15 => S2p(15),
		O16 => S2p(16),
		O17 => S2p(17)
	);
	--connect rest of S2p to S1p
	con1: for j in 0 to 29 generate
		cond_1: if ((j>=3) and (j<=14)) OR (j>=18) generate
			S2p(j)<=S1pp(j);
		end generate cond_1;
	end generate con1;
	
	--add S0 to S4 and S15 and rotate >>>15
	St1p(19)<=input(0) xor input(4);
	St1p(0)<=input(0) xor input(15);
	--connect rest of St1p to S (with rotation >>>15)
	rot4: for j in 0 to 29 generate
		cond4: if (j/=0) and (j/=19) generate
			St1p(j)<=input((30+j-15)mod 30);
		end generate cond4;
	end generate rot4;
	
	--tap in mode 3 (G2) to SMIX
	sw2: for j in 0 to 29 generate
		S2pp(j)<=S2p(j) when mode3_n /= '0' else St1p(j);
	end generate sw2;

	--SMIX in round transformation R (first iteration)
	R_SMIX1: fugue_smix port MAP(
		clk=>clk,
		I0 => S2pp(0),
		I1 => S2pp(1),
		I2 => S2pp(2),
		I3 => S2pp(3),
		O0 => S3p(3),
		O1 => S3p(4),
		O2 => S3p(5),
		O3 => S3p(6)
	);
	--connect rest of S3p to S2pp (with rotation >>>3)
	rot2: for j in 0 to 29 generate
		cond2: if (j<=2) OR (j>=7) generate
			S3p(j)<=S2pp((30+j-3)mod 30);
		end generate cond2;
	end generate rot2;
	
	--CMIX in round transformation R (second iteration)
	R_CMIX2: fugue_cmix port MAP(
		I0 => S3p(0),
		I1 => S3p(1),
		I2 => S3p(2),
		I4 => S3p(4),
		I5 => S3p(5),
		I6 => S3p(6),
		I15 => S3p(15),
		I16 => S3p(16),
		I17 => S3p(17),
		O0 => S4p(0),
		O1 => S4p(1),
		O2 => S4p(2),
		O15 => S4p(15),
		O16 => S4p(16),
		O17 => S4p(17)
	);
	--connect rest of S4p to S3p
	con2: for j in 0 to 29 generate
		cond_2: if ((j>=3) and (j<=14)) OR (j>=18) generate
			S4p(j)<=S3p(j);
		end generate cond_2;
	end generate con2;

	--add S0 to S4 and S16 and rotate <<<3 and >>>14 (<<<3 to undo auto rotation out of SMIX)
	St2p(18)<=S3p(3) xor S3p(7);
	St2p(0)<=S3p(3) xor S3p(19);
	--connect rest of St2p to S3p (with rotation >>>11)
	rot5: for j in 0 to 29 generate
		cond5: if (j/=0) and (j/=18) generate
			St2p(j)<=S3p((30+j-11)mod 30);
		end generate cond5;
	end generate rot5;

	--connect first SMIX to second SMIX for mode 3 (G2)
	sw3: for j in 0 to 29 generate
		S4pp(j)<=S4p(j) when mode3_n /= '0' else St2p(j);
	end generate sw3;

	--SMIX in round transformation R (second iteration)
	R_SMIX2: fugue_smix port MAP(
			clk=>clk,
		I0 => S4pp(0),
		I1 => S4pp(1),
		I2 => S4pp(2),
		I3 => S4pp(3),
		O0 => S5p(0),
		O1 => S5p(1),
		O2 => S5p(2),
		O3 => S5p(3)
	);
	--connect rest of S5p to S4p
	con3: for j in 0 to 29 generate
		cond_3: if (j>=4) generate
			S5p(j)<=S4pp(j);
		end generate cond_3;
	end generate con3;

end a1;