library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real."floor";
use IEEE.math_real."log2";

entity textbookRSA is
  generic (KEYSIZE : integer);
  port (indata	 : in  std_logic_vector(KEYSIZE-1 downto 0);
	inExp	 : in  std_logic_vector(KEYSIZE-1 downto 0);
	inMod	 : in  std_logic_vector(KEYSIZE-1 downto 0);
	pre_M	 : in  std_logic_vector(KEYSIZE-1 downto 0);
	cypher	 : out std_logic_vector(KEYSIZE-1 downto 0);
	clk	 : in  std_logic;
	RSA_ds	 : in  std_logic;
	reset	 : in  std_logic;
	RSA_done : out std_logic
	);
end textbookRSA;

architecture Behavioral of textbookRSA is

  signal in_A, in_A_next : std_logic_vector(KEYSIZE-1 downto 0) := (others => '0');
  signal in_B, in_B_next : std_logic_vector(KEYSIZE-1 downto 0) := (others => '0');

  signal product : std_logic_vector(KEYSIZE-1 downto 0) := (others => '0');

  signal ds_modmult    : std_logic := '0';
  signal ready_modmult : std_logic := '0';

  signal s_exp_cnt, s_exp_cnt_next : unsigned(10 downto 0)		  := "00000000001";
  signal key, key_next		   : std_logic_vector(KEYSIZE-1 downto 0) := (others => '0');

  signal reset_modmult : std_logic := '0';

  -- add new states here
  type t_state is (
    s_idle,
    s_prepare_SQ,
    s_eval_SQ,
    s_prepare_MUL,
    s_eval_MUL,
    s_increment
    );
  signal s_state, s_state_next, s_start_state : t_state := s_idle;
begin
  
  prc_state_2 : process(clk, reset)
  begin
    if (rising_edge(clk)) then
      if (reset = '1') then
	s_exp_cnt <= (others => '0');
	s_state	  <= s_start_state;
	in_A	  <= (others => '0');
	in_B	  <= (others => '0');
	key	  <= (others => '0');
      else
	s_exp_cnt <= s_exp_cnt_next;
	s_state	  <= s_state_next;
	in_A	  <= in_A_next;
	in_B	  <= in_B_next;
	key	  <= key_next;
      end if;
    end if;
  end process;

  cypher <= in_A;
  
  combinatorial : process(
    s_exp_cnt,
    s_state,
    ready_modmult,
    RSA_ds,
    inExp,
    indata,
    key,
    ready_modmult,
    product,
    in_A,
    in_B
    )
  begin
    s_exp_cnt_next <= s_exp_cnt;
    s_state_next   <= s_state;
    key_next	   <= key;
    in_A_next	   <= in_A;
    in_B_next	   <= in_B;
    ds_modmult	   <= '0';
    reset_modmult  <= '0';
    RSA_done	   <= '0';

    case s_state is
      when s_idle =>
	if RSA_ds = '1' then
	  key_next     <= inExp;
	  s_state_next <= s_prepare_SQ;
	end if;

      when s_prepare_SQ =>
	if (to_integer(s_exp_cnt) = 1) then
	  in_A_next <= indata;
	  in_B_next <= indata;
	end if;
	key_next     <= key(KEYSIZE-2 downto 0) & '0';
	ds_modmult   <= '1';
	s_state_next <= s_eval_SQ;

      when s_eval_SQ =>
	if (ready_modmult = '1') then
	  --reset_modmult <= '1';
	  if(key(KEYSIZE-1) = '1') then
	    in_A_next	 <= indata;
	    in_B_next	 <= product;
	    s_state_next <= s_prepare_MUL;
	  else
	    in_A_next	 <= product;
	    in_B_next	 <= product;
	    s_state_next <= s_increment;
	  end if;
	end if;

      when s_prepare_MUL =>
	ds_modmult   <= '1';
	s_state_next <= s_eval_MUL;

      when s_eval_MUL =>
	if (ready_modmult = '1') then
	  in_A_next    <= product;
	  in_B_next    <= product;
	  s_state_next <= s_increment;
	end if;

      when s_increment =>
	s_exp_cnt_next <= s_exp_cnt + 1;
	if (to_integer(s_exp_cnt) = KEYSIZE-1) then
	  s_exp_cnt_next <= "00000000001";
	  RSA_done	 <= '1';
	  s_state_next	 <= s_idle;
	else
	  s_state_next <= s_prepare_SQ;
	end if;
	
    end case;
  end process;

  instance_modmult : entity work.modmult
    generic map (
      MPWID => KEYSIZE)
    port map (
      mpand   => in_A,
      mplier  => in_B,
      modulus => inmod,
      pre_M   => pre_M,
      product => product,
      clk     => clk,
      ds      => ds_modmult,
      ready   => ready_modmult);
end Behavioral;
