library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real."ceil";

use IEEE.STD_LOGIC_UNSIGNED.all;

entity adder is
  generic(bitLen : integer);
  port(
    clk		: in  std_logic;
    X		: in  std_logic_vector(bitLen-1 downto 0);
    X_carry	: in  std_logic;
    Y		: in  std_logic_vector(bitLen-1 downto 0);
    Y_carry	: in  std_logic;
    Z		: out std_logic_vector(bitLen-1 downto 0);
    Z_carry	: out std_logic;
    ds		: in  std_logic;
    ready_adder : out std_logic
    );
end adder;

architecture behav of adder is
  constant reg_w_add : integer := 16;
  constant no_adds   : integer := natural(ceil(real(bitLen)/real(reg_w_add)))-1;

  signal r_A, r_B		       : std_logic_vector(bitLen-1 downto 0);
  signal r_A_carry, r_B_carry, i_carry : std_logic := '0';

  signal temp2 : std_logic_vector(bitLen downto 0);
  signal pad   : std_logic_vector(reg_w_add-1 downto 0) := (others => '0');

  signal temp	: std_logic_vector(reg_w_add downto 0);
  signal i_done : std_logic := '0';
  
  type t_state is (
    s_start,
    s_init,
    s_add_limb,
    s_shift_result,
    s_finish
    );

  signal s_state, s_start_state : t_state		:= s_start;
  signal i_add_cnt		: unsigned(10 downto 0) := (others => '0');
begin

  Z	      <= r_A	 when i_done = '1' else (others => '0');
  Z_carry     <= i_carry when i_done = '1' else '0';
  ready_adder <= i_done;

  eval_addition : process(clk)
  begin
    if (rising_edge(clk)) then
      case s_state is
	when s_start =>
	  i_done <= '0';
	  if(ds = '1') then
	    s_state <= s_init;
	  end if;
	  
	when s_init =>
	  i_add_cnt <= (others => '0');
	  temp	    <= (others => '0');

	  r_A	  <= X;
	  r_B	  <= Y;
	  i_carry <= '0';
	  s_state <= s_add_limb;

	when s_add_limb =>
	  temp	  <= ('0' & r_A(reg_w_add-1 downto 0)) + ('0' & r_B(reg_w_add-1 downto 0)) + i_carry;
	  s_state <= s_shift_result;

	when s_shift_result =>
	  i_carry <= temp(reg_w_add);
	  r_A	  <= temp(reg_w_add-1 downto 0) & r_A(bitLen-1 downto reg_w_add);
	  r_B	  <= pad & r_B(bitLen-1 downto reg_w_add);
	  s_state <= s_finish;
	  
	when s_finish =>
	  i_add_cnt <= i_add_cnt + 1;
	  if(to_integer(i_add_cnt) = no_adds) then
	    i_carry <= i_carry or X_carry or Y_carry;
	    i_done  <= '1';
	    s_state <= s_start;
	  else
	    s_state <= s_add_limb;
	  end if;

      end case;
    end if;
  end process;
end behav;

