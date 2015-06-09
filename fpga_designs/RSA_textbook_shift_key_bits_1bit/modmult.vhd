library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity modmult is
  generic (MPWID : integer);
  port (mpand	: in  std_logic_vector(MPWID-1 downto 0);
	mplier	: in  std_logic_vector(MPWID-1 downto 0);
	modulus : in  std_logic_vector(MPWID-1 downto 0);
	pre_M	: in  std_logic_vector(MPWID-1 downto 0);
	product : out std_logic_vector(MPWID-1 downto 0);
	clk	: in  std_logic;
	ds	: in  std_logic;
	ready	: out std_logic);
end modmult;

architecture behav of modmult is

  signal ready_adder, ds_adder : std_logic := '0';

  signal r_X_carry, r_Y_carry, r_Z_carry : std_logic			      := '0';
  signal r_X, r_Y, r_Z			 : std_logic_vector(MPWID-1 downto 0) := (others => '0');

  signal r_A_carry	       : std_logic			    := '0';
  signal r_C_carry, r_Cp_carry : std_logic			    := '0';
  signal r_A		       : std_logic_vector(MPWID-1 downto 0) := (others => '0');
  signal r_C, r_Cp	       : std_logic_vector(MPWID-1 downto 0) := (others => '0');
  signal r_B		       : std_logic_vector(MPWID-1 downto 0) := (others => '0');

  signal i_done	   : std_logic := '0';
  signal ready_add : std_logic := '0';
  
  type t_state is (
    s_start,
    s_init,
    s_step_1_in, s_step_1_out,
    s_step_2_in, s_step_2_out,
    s_step_3_in,
    s_step_4,
    s_step_5_in, s_step_5_out,
    s_step_6,
    s_check_finish
    );
  signal s_state, s_start_state : t_state := s_start;
  
begin

  product <= r_C when i_done = '1' else (others => '0');
  ready <= i_done;

  compact_mod_add : process(clk)
  begin
    if (rising_edge(clk)) then
      case s_state is
	when s_start =>
	  i_done <= '0';
	  if(ds = '1') then
	    s_state  <= s_init;
	    ds_adder <= '0';
	  end if;
	  
	when s_init =>
	  r_A <= mpand;
	  r_B <= mplier;
	  -- r_C	   <= (others => '0');

	  --r_Ap       <= (others => '0');
	  r_A_carry <= '0';
	  ----r_Ap_carry <= '0';

	  r_C <= (others => '0');

	  r_C_carry  <= '0';
	  r_Cp_carry <= '0';

	  ds_adder <= '0';

	  r_X	    <= (others => '0');
	  r_Y	    <= (others => '0');
	  r_X_carry <= '0';
	  r_Y_carry <= '0';

	  s_state <= s_step_1_in;

	when s_step_1_in =>
	  r_X_carry <= '0';
	  if(r_B(0) = '1') then
	    r_X <= r_A;
	  else
	    r_X <= (others => '0');
	  end if;
	  r_Y_carry <= '0';
	  r_Y	    <= r_C;
	  ds_adder  <= '1';
	  s_state   <= s_step_1_out;
	  
	when s_step_1_out =>
	  ds_adder <= '0';
	  if(ready_add = '1') then
	    r_Cp_carry <= r_Z_carry;
	    r_Cp       <= r_Z;
	    s_state    <= s_step_2_in;
	  end if;

	when s_step_2_in =>
	  r_X_carry <= r_Cp_carry;
	  r_X	    <= r_Cp;
	  r_Y_carry <= '0';
	  r_Y	    <= pre_M;
	  ds_adder  <= '1';
	  s_state   <= s_step_2_out;
	  
	when s_step_2_out =>
	  ds_adder <= '0';
	  if(ready_add = '1') then
	    r_C_carry <= r_Z_carry;
	    r_C	      <= r_Z;
	    s_state   <= s_step_3_in;
	  end if;
	  
	when s_step_3_in =>
	  if(r_C_carry = '0') then
	    r_C <= r_Cp;
	  end if;
	  r_C_carry  <= '0';
	  r_Cp_carry <= '0';
	  s_state    <= s_step_4;
	  
	when s_step_4 =>
	  r_Cp_carry <= r_A(MPWID-1);
	  r_Cp	     <= r_A(MPWID-2 downto 0) & '0';
	  s_state    <= s_step_5_in;

	when s_step_5_in =>
	  r_X_carry <= r_Cp_carry;
	  r_X	    <= r_Cp;
	  r_Y_carry <= '0';
	  r_Y	    <= pre_M;
	  ds_adder  <= '1';
	  s_state   <= s_step_5_out;
	  
	when s_step_5_out =>
	  ds_adder <= '0';
	  if(ready_add = '1') then
	    r_A_carry <= r_Z_carry;
	    r_A	      <= r_Z;
	    s_state   <= s_step_6;
	  end if;
	  
	when s_step_6 =>
	  if(r_A_carry = '0') then
	    r_A <= r_Cp;
	  end if;
	  r_A_carry  <= '0';
	  r_Cp_carry <= '0';
	  r_B	     <= '0' & r_B(MPWID-1 downto 1);
	  s_state    <= s_check_finish;
	  
	when s_check_finish =>
	  if(r_B = 0) then
	    i_done  <= '1';
	    s_state <= s_start;
	  else
	    s_state <= s_step_1_in;
	  end if;

      end case;

    end if;
  end process;

  instance_adder : entity work.adder
    generic map (
      bitLen => MPWID)
    port map (
      clk	  => clk,
      X		  => r_X,
      X_carry	  => r_X_carry,
      Y		  => r_Y,
      Y_carry	  => r_Y_carry,
      Z		  => r_Z,
      Z_carry	  => r_Z_carry,
      ds	  => ds_adder,
      ready_adder => ready_add);

end behav;
