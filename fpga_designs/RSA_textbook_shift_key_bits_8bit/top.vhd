library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real."floor";
use IEEE.math_real."log2";

entity top is
  generic(bitLen : integer := 3072);
  port(
    clk		: in  std_logic;
    reset	: in  std_logic;
    i_rs232_rxd : in  std_logic;
    o_rs232_txd : out std_logic
    );
end top;

architecture rtl of top is

  signal x	  : std_logic_vector(bitLen-1 downto 0);
  signal d	  : std_logic_vector(bitLen-1 downto 0);
  signal N, pre_M : std_logic_vector(bitLen-1 downto 0) := (others => '0');

  -- sig = x^d mod N
  signal sig : std_logic_vector(bitLen-1 downto 0) := (others => '0');

  signal ds_sig	   : std_logic := '0';
  signal ready_sig : std_logic := '0';

  constant receiveBytes	 : integer := bitLen/8;
  constant transmitBytes : integer := bitLen/8;

  constant receive_cnt_bits  : integer := integer(floor(log2(real(receiveBytes-1))))+1;
  constant transmit_cnt_bits : integer := integer(floor(log2(real(transmitBytes-1))))+1;

  signal i_rs232_tra_en	   : std_logic			  := '0';
  signal i_rs232_dat	   : std_logic_vector(7 downto 0) := (others => '0');
  signal o_rs232_rec_en	   : std_logic			  := '0';
  signal o_rs232_txd_busy  : std_logic			  := '0';
  signal o_rs232_dat	   : std_logic_vector(7 downto 0) := (others => '0');
  signal s_transfer_enable : std_logic			  := '0';

  signal s_receive_cnt, s_receive_cnt_next   : unsigned(receive_cnt_bits-1 downto 0)  := (others => '0');
  signal s_transfer_cnt, s_transfer_cnt_next : unsigned(transmit_cnt_bits-1 downto 0) := (others => '0');

  signal s_key_in, s_key_in_next     : std_logic_vector(receiveBytes*8-1 downto 0)  := (others => '0');
  signal s_data_in, s_data_in_next   : std_logic_vector(receiveBytes*8-1 downto 0)  := (others => '0');
  signal s_data_out, s_data_out_next : std_logic_vector(transmitBytes*8-1 downto 0) := (others => '0');

  type t_state is (
    receive_key,
    receive,
    transmit,
    get_sig
    );

  signal s_state, s_state_next, s_start_state : t_state := receive_key;
  
begin
  -- for generic synthesis only
  x <= (others => '1');
  N <= x;
  pre_M <= not N;

  -- >>>>>>>>>> bitLen=16 <<<<<<<<<<
  --x	  <= x"6c31";
  --N	  <= x"fee7";
  --pre_M <= x"0119";
  --TRANSFER e = e813
  --expected result = b9cb

  -- >>>>>>>>>> bitLen=32 <<<<<<<<<<
  --x	  <= x"6c311223";
  --N	  <= x"fee76586";
  --pre_M <= x"01189a7a";
  --TRANSFER e = e8131311
  --expected result = 75399b1f

  -- >>>>>>>>>> bitLen=64 <<<<<<<<<<
  --x	  <= x"6c31122334455667";
  --N	  <= x"7ee7658798657956";
  --pre_M <= x"81189a78679a86aa";
  --TRANSFER e = e813131231231231
  --expected result = 4134e96c7bf1bdeb

  -- >>>>>>>>>> bitLen=128 <<<<<<<<<<
  --x	  <= x"6c3112233445566778899aabbccddeef";
  --N	  <= x"fee76587986579567985687569876957";
  --pre_M <= x"01189a78679a86a9867a978a967896a9";
  --TRANSFER e = e8131312312312312398193809218309
  --expected result = 8c12afe9053a65e6600eb3a7e03faa41

  -- >>>>>>>>>> bitLen=256 <<<<<<<<<<
  --x	  <= x"6c3112233445566778899aabbccddeeff0011223344556677881311223344556";
  --N	  <= x"7ee7658798657956798568756987695789567896587956879568759678956879";
  --pre_M <= x"081189a78679a86a9867a978a967896a876a98769a786a9786a978a69876a9787";
  --TRANSFER e = e813131231231231239819380921830912912398021830128309128309120000
  --expected result = 362e44852eb1898d672eaaa70f8e821b2a0cf702cd08dff99a825c0f646fe1d6

  -- >>>>>>>>>> bitLen=512 <<<<<<<<<<
  --x	<= x"6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd";
  --N	<= x"fee76587986579567985687569876957895678965879568795687596789568795687958697568975687956879658958795699ee7658798657956798568756987";
  --pre_M <= x"01189a78679a86a9867a978a967896a876a98769a786a9786a978a69876a9786a9786a7968a9768a9786a97869a76a786a9661189a78679a86a9867a978a9679";
  --TRANSFER e = e8131312312312312398193809218309129123980218301283091283091283901283901820391283901283091280890831209813131231231231239819380921
  --expected result = 8d75cc3abb9ffad11aba0973df2be8a41f8f7ccee09f6f9f2fa8f6897105d616159ad46a77e46cc08125f770927ad6fef41dd0c12e43013d624b93a24aa84aac

  -- >>>>>>>>>> bitLen=704 <<<<<<<<<<
  --x	  <= x"6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabba";
  --N	  <= x"fee76587986579567985687569876957895678965879568795687596789568795687958697568975687956879658958795699ee7658798657956798568756987695789567896587956879568759678956879568795869756";
  --pre_M <= x"01189a78679a86a9867a978a967896a876a98769a786a9786a978a69876a9786a9786a7968a9768a9786a97869a76a786a9661189a78679a86a9867a978a967896a876a98769a786a9786a978a69876a9786a9786a7968aa";
  --TRANSFER e = e8131312312312312398193809218309129123980218301283091283091283901283901820391283901283091280890831209813131231231231239819380921830912912398021830128309128309128390128390182039
  --expected result = 7a264a6e9d1354a8612e8e8c32a1f07e8b8fcd9e91861a8a544a8b95a97f9a161857b0420acb9607074d4414af686599f404e1c32c226c7b4256959370413894f488b6d30aa03c981514c1d8532f359459da79c253e3cf16

  -- >>>>>>>>>> bitLen=1024 <<<<<<<<<<
  --x	  <= x"6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd";
  --N	  <= x"7ee76587986579567985687569876957895678965879568795687596789568795687958697568975687956879658958795699ee76587986579567985687569876c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd";
  --pre_M <= x"081189a78679a86a9867a978a967896a876a98769a786a9786a978a69876a9786a9786a7968a9768a9786a97869a76a786a9661189a78679a86a9867a978a967893ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa998877665544333";
  --TRANSFER e = e81313123123123123981938092183091291239802183012830912830912839012839018203912839012830912808908312098131312312312312398193809216c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd
  --expected result = 18f54e4638a9531c533e7205fad1bb4d124b415a9cb2ee6408f63cdafddb4a1b6721f6752356fe6ab9a7fd79e7f68f75d3afd34c6e13db74e4dff7f292f98943b56dda28ebba0aa6dca3d518aae669b8b1a10ab2175c02549feefba69b968981ad5b512b2e4759250ce5306654940e23adb437e26f0a0eee92e45750ca393939

  -- >>>>>>>>>> bitLen=2048 <<<<<<<<<<
  --x	  <= x"6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd";
  --N	  <= x"fee76587986579567985687569876957895678965879568795687596789568795687958697568975687956879658958795699ee76587986579567985687569876c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd";
  --pre_M <= x"01189a78679a86a9867a978a967896a876a98769a786a9786a978a69876a9786a9786a7968a9768a9786a97869a76a786a9661189a78679a86a9867a978a967893ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa99887766554433293ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa99887766554433293ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa998877665544333";
  --TRANSFER e = e81313123123123123981938092183091291239802183012830912830912839012839018203912839012830912808908312098131312312312312398193809216c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd
  --expected result = 245d77069012089fed541cd4867845fd7d7d8a61546be769284f8d66dba5e3537ebc49d54991eed3178f291b05671c68df3d45dc9254d8a09c4479551cb3e0a82dd8a36fc43045fad69c2f06138e7453f53e3aa8fc2db2f4206c7ae8dcc88d97ac41b767fdb1288af36fabdc1c91e5112957f484674728501f1bc378c91ea4a0ea2b182026b310df943bff5efe43f81dea803ccd41f3b5b05687a8c1a13947fb8a16caac0e9e95b4acdee25909727805c86776af8aa60764012e781530e86d7a29de38808d54e6d538c2ca74d8d9d8e367c44312910d3e2bae3c5c762fbf63779b644f1bd0671eea00fd4261c89e9d8df5ab2bae696ebb1e87b2adf667d435e7

  -- >>>>>>>>>> bitLen=3072 <<<<<<<<<<
  --x	  <= x"6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd";
  --N	  <= x"fee76587986579567985687569876957895678965879568795687596789568795687958697568975687956879658958795699ee76587986579567985687569876c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd";
  --pre_M <= x"01189a78679a86a9867a978a967896a876a98769a786a9786a978a69876a9786a9786a7968a9768a9786a97869a76a786a9661189a78679a86a9867a978a967893ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa99887766554433293ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa99887766554433293ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa99887766554433293ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa99887766554433293ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa998877665544333";
  --TRANSFER e = e81313123123123123981938092183091291239802183012830912830912839012839018203912839012830912808908312098131312312312312398193809216c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd
  --expected result = 8c6af43f46d85a85a13c8c69b19f525f463f69034d741a2b564261075a62786c9fec073fd760d774e11ec1f2377f3530a1d13008fe52831f6b0dc86763970adb764c867ad17332d0291697df2bb56fab71e0ade4854131004cd5d2132762533847f731d8d7a4ab212c2a0b9603c7b53298978a4f70b9803dc233619b3031600299ead45e2529b6513a2131d931eeec4072c2420c0aab6cb229d73890c624359a637a60c11307bd544e03f671d7394a842a8556fe9c20d4367008834205305636471829a51cba107513b7f27ac85f57b536504198bd680dbc6aab4b81a43682e7b4bec97337fcd4c1a5d0a81e089c238897d120ba34a953b5d851a8852e3c574172763be5a532686ed658e77a91bde6f5baeac5abe6d9a80b7e252f5d7461b9ac27b9ea292c030f07262e559cf3bdc33d96897ba1898badec3ace6d7b7faaac2fc6d380a64c99719a646bbb6fb959967ae5c6b51e1c55dcbde3ecefabb969e7c5bdf36c40ce335968661a6c078d55f53b11cd8fc6738fe5b89b1c4393d3438e08

  -- >>>>>>>>>> bitLen=4096 <<<<<<<<<<
  --x	  <= x"6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd";
  --N	  <= x"fee76587986579567985687569876957895678965879568795687596789568795687958697568975687956879658958795699ee76587986579567985687569876c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd";
  --pre_M <= x"01189a78679a86a9867a978a967896a876a98769a786a9786a978a69876a9786a9786a7968a9768a9786a97869a76a786a9661189a78679a86a9867a978a967893ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa99887766554433293ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa99887766554433293ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa99887766554433293ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa99887766554433293ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa99887766554433293ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa99887766554433293ceeddccbbaa99887766554433221100ffeeddccbbaa998877eceeddccbbaa99887766554433221100ffeeddccbbaa9988773ceeddccbbaa998877665544333";
  --TRANSFER e = e81313123123123123981938092183091291239802183012830912830912839012839018203912839012830912808908312098131312312312312398193809216c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd6c3112233445566778899aabbccddeeff00112233445566778813112233445566778899aabbccddeeff001122334455667788c3112233445566778899aabbccd
  --expected result = 79ed82c94027ff8e098ca5b520e8a518bd2dd7b0840ad36ee07e6dd29c8203ac1d8a4522065ecac2a5128ca9ad8d8e827200bf31eed93c7bb9f44c15d79a574315a73c17e38ca943875c22742a2108b4380cd54b088a371ee63ff9619978679016ad08a7aac9d5952275cdffacb1bad94a6c4e216b37fd2f0088cd63566f1466edc984185a96fed0f5306dd0cf7470f98416aee238a6478388f94e32961a8c01e3417fcea4d2c19b77857a697b1ea19de28888ea1126672ea988e3419913843ab4d96221e765d8efd4161ab29510c281e4c5fd04f24d7f34b274124d1919e8dd1de0c33542a4b903fdf0067ab7d0e6929b9bbba7da330215dbe1c78a56a85e7bd229f8f913e04e58fd28353a03eb083bcc9ac5fd691ebb6dadf9e83c64b4f66c51b14cfb8972385f762d141bcb240c0644443be0141bf0cf700d94a9e5dca0fc5e8d5d66f2ae7d37773fe2ac14cde3eecd778abc70b37aaba06e29574b5994ee4a7fb73fd364d9dd5e4e5d3f7a05b4f5019b98488d285f802f169d5c3d058dfbdefb67100307aacbccee0e985944256711c070bd0707e46b50018496918d7106de53be16ba843312dccb645b78bf48368b8cb87640231a4064f8d3bd44e8e9ca83e582c25651c1af14526daf0fcef3c2ca2a91d15de8d414887baa787403ec15146495a56ad1e9bf51d8d3b81055428b6e19ae384b20b49596edf3f487444fdc

  prc_state : process(clk, reset)
  begin
    if (rising_edge(clk)) then
      if (reset = '1') then
	s_receive_cnt  <= (others => '0');
	s_transfer_cnt <= (others => '0');

	s_data_in  <= (others => '0');
	s_data_out <= (others => '0');
	s_key_in   <= (others => '0');

	s_state <= s_start_state;
      else
	s_receive_cnt  <= s_receive_cnt_next;
	s_transfer_cnt <= s_transfer_cnt_next;

	s_data_in  <= s_data_in_next;
	s_data_out <= s_data_out_next;
	s_key_in   <= s_key_in_next;

	s_state <= s_state_next;
      end if;
    end if;
  end process;

  combinatorial : process(
    s_receive_cnt,
    s_transfer_cnt,

    s_key_in,
    s_data_in,
    s_data_out,

    s_state,

    o_rs232_rec_en,
    o_rs232_txd_busy,
    o_rs232_dat,

    sig, ready_sig
    )
  begin
    -- x <= s_data_in;
    d <= s_key_in;

    s_receive_cnt_next	<= s_receive_cnt;
    s_transfer_cnt_next <= s_transfer_cnt;

    s_data_in_next  <= s_data_in;
    s_data_out_next <= s_data_out;

    s_key_in_next <= s_key_in;

    s_state_next <= s_state;

    s_transfer_enable <= '0';

    case s_state is
      when receive_key =>
	if (o_rs232_rec_en = '1') then
	  -- shift key bytewise
	  s_key_in_next <= s_key_in((receiveBytes-1)*8-1 downto 0) & o_rs232_dat;

	  s_receive_cnt_next <= s_receive_cnt + 1;
	  if (to_integer(s_receive_cnt) = receiveBytes-1) then
	    s_receive_cnt_next <= (others => '0');
	    s_state_next       <= get_sig;
	  end if;
	end if;

      when receive =>
	if (o_rs232_rec_en = '1') then
	  --s_data_in_next <= s_data_in((receiveBytes-1)*8-1 downto 0) & o_rs232_dat;

	--s_receive_cnt_next <= s_receive_cnt + 1;
	--if (to_integer(s_receive_cnt) = receiveBytes-1) then
	--  s_receive_cnt_next <= (others => '0');
	--  s_state_next       <= get_sig;
	--end if;
	end if;

      when get_sig =>
	ds_sig <= '1';
	if ready_sig = '1' then
	  s_data_out_next <= sig;
	  s_state_next	  <= transmit;
	end if;

      when transmit =>
	if (o_rs232_txd_busy = '0') then
	  s_transfer_enable <= '1';
	  s_data_out_next   <= s_data_out(((transmitBytes-1)*8-1) downto 0) & x"00";

	  s_transfer_cnt_next <= s_transfer_cnt + 1;
	  if (to_integer(s_transfer_cnt) = transmitBytes-1) then
	    s_transfer_cnt_next <= (others => '0');
	    s_state_next	<= receive;
	  end if;
	end if;
    end case;
  end process;

  i_rs232_dat	 <= s_data_out((transmitBytes*8-1) downto (transmitBytes-1)*8);
  i_rs232_tra_en <= s_transfer_enable;
  instance_rs232 : entity work.rs232(Behavioral)
    port map(
      clk	     => clk,
      rs232_rxd	     => i_rs232_rxd,
      rs232_tra_en   => i_rs232_tra_en,
      rs232_dat_in   => i_rs232_dat,
      rs232_txd	     => o_rs232_txd,
      rs232_rec_en   => o_rs232_rec_en,
      rs232_txd_busy => o_rs232_txd_busy,
      rs232_dat_out  => o_rs232_dat
      );

  instance_RSA : entity work.textbookRSA
    generic map (
      KEYSIZE => bitLen)
    port map (
      indata   => x,
      inExp    => d,
      inMod    => N,
      pre_M    => pre_M,
      cypher   => sig,
      clk      => clk,
      RSA_ds   => ds_sig,
      reset    => reset,
      RSA_done => ready_sig);

end rtl;

