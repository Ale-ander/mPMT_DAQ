library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.instruction_buffer_type.all;

entity tb_roundrobin is
end tb_roundrobin;

architecture Behavioral of tb_roundrobin is

component raccolta_dati is
    generic (n_channel : integer:= 19); -- number of PMT channels
    Port ( 
        -- IN    
        din        : in Data32_ARRAY;
		clk 	   : in STD_LOGIC;
        reset 	   : in STD_LOGIC;
        empty 	   : in STD_LOGIC_VECTOR(n_channel downto 0);  -- emptys of the small FIFOs
        wr_done	   : in STD_LOGIC_VECTOR(n_channel downto 0);  -- a apackage has been written in the FIFO
		HF_FIFO    : in STD_LOGIC;                             -- HF of the big FIFO
        wr_busy    : in STD_LOGIC;  	
		-- OUT
		reset_ch   : out STD_LOGIC_VECTOR(n_channel downto 0); -- reset the sc FSM if timeout
        wr_en      : out STD_LOGIC;                            -- write_enable of the big FIFO 
        rd_done	   : out STD_LOGIC_VECTOR(n_channel downto 0); -- package has been read from the rr
        rd_en 	   : out STD_LOGIC_VECTOR(n_channel downto 0); -- read enable to the small FIFOs
        dout       : out STD_LOGIC_VECTOR(31 downto 0)
        );
end component;

COMPONENT FIFO_single_channel
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full : OUT STD_LOGIC;
    wr_ack : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT fifo_generator_0
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC;
    wr_rst_busy : OUT STD_LOGIC;
    rd_rst_busy : OUT STD_LOGIC
  );
END COMPONENT;

constant n_channel : integer := 6;
signal wr_busy, clk, reset_rr, reset, HF_FIFO, wr_en, rd_big : std_logic;
signal empty, wr_done, rd_done, rd_en, wr_FIFO, reset_ch, reset_FIFO : std_logic_vector(n_channel downto 0);
signal dout : std_logic_vector(31 downto 0);
signal dout_big : std_logic_vector(15 downto 0);
signal din, word_to_FIFO : Data32_ARRAY:=(OTHERS => X"00000000");

begin

reset_gen:process(reset, reset_ch)
begin
    for i in 0 to n_channel loop
        reset_FIFO(i) <= reset or reset_ch(i);
    end loop;
end process;

UUT: raccolta_dati
        GENERIC MAP(n_channel => 6)
        PORT MAP(
                -- IN    
                din     => din, 
                clk 	=> clk,
                reset 	=> reset_rr,
                empty 	=> empty,
                wr_done	=> wr_done,
                HF_FIFO => HF_FIFO,
                wr_busy => wr_busy, 
                -- OUT
                reset_ch => reset_ch,
                wr_en    => wr_en,
                rd_done	 => rd_done,
                rd_en 	 => rd_en,
                dout     => dout
                );
        
FIFOs: for i in 0 to n_channel generate
begin

FIFO_sc: FIFO_single_channel
        PORT MAP (
            clk       => clk,
            srst      => reset_FIFO(i),
            din       => word_to_FIFO(i),
            wr_en     => wr_FIFO(i),
            rd_en     => rd_en(i),
            dout      => din(i),
            full      => open,
            wr_ack    => open,
            empty     => empty(i),
            prog_full => open
        );
end generate;

FIFO_BIG : fifo_generator_0
  PORT MAP (
    rst => reset,
    wr_clk => clk,
    rd_clk => clk,
    din => dout,
    wr_en => wr_en,
    rd_en => rd_big,
    dout => dout_big,
    full => open,
    empty => open,
    prog_full => open,
    wr_rst_busy => wr_busy,
    rd_rst_busy => open
  );

clocka:process
begin
    clk <= '1';
    wait for 2.5 ns;
    clk <= '0';
    wait for 2.5 ns;
end process;

main_proc:process
begin
    rd_big <= '0';
    HF_FIFO <= '0';
    reset <= '1';
    reset_rr <= '1';
    wr_FIFO <= (OTHERS => '0');
    wr_done <= (OTHERS => '0');
    word_to_FIFO <= (OTHERS => X"00000000");
    wait for 50 ns;
    reset <= '0';
    wait for 5 ns;
    word_to_FIFO(0) <= X"8000AAAA";
    word_to_FIFO(1) <= X"8000BBBB";
    wr_FIFO(0) <= '1';
    wr_FIFO(1) <= '1';
    wait for 5 ns;
    word_to_FIFO(0) <= X"0000CCCC";
    word_to_FIFO(1) <= X"0000DDDD";
    wait for 5 ns;
    word_to_FIFO(0) <= X"0000EEEE";
    word_to_FIFO(1) <= X"0000FFFF";
    wait for 5 ns;
    word_to_FIFO(0) <= X"C0000000";
    word_to_FIFO(1) <= X"C0001111";
    wait for 5 ns;
    wr_FIFO(0) <= '0';
    wr_FIFO(1) <= '0';
    wr_done(0) <= '1';
    wr_done(1) <= '1';
    wait for 10 ns;
    
    reset_rr <= '0';
    
--    HF_FIFO <= '0';
--    wait for 200 ns;
--    HF_FIFO <= '1';
--    wait for 100 ns;
--    HF_FIFO <= '0';
    
    wait for 1.5 us;
    word_to_FIFO(0) <= X"8000FFFF";
    wr_FIFO(0) <= '1';
    wait for 5 ns;
    word_to_FIFO(0) <= X"00008888";
    wait for 5 ns;
    word_to_FIFO(0) <= X"00009999";
    wait for 5 ns;
    word_to_FIFO(0) <= X"C000AAAA";
    wait for 5 ns;
    wr_FIFO(0) <= '0';
    wr_done(0) <= '1';
    rd_big <= '1';
    
    wait;
end process;

end Behavioral;
