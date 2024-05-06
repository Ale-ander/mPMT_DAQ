library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library unisim;
use unisim.vcomponents.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.STD_LOGIC_ARITH.ALL; 

entity tb_singleChannel is
end tb_singleChannel;

architecture Behavioral of tb_singleChannel is

component single_channel is
    generic (add : STD_LOGIC_vector(4 downto 0) := "00000";
             posizione_y       : integer;
             posizione_x       : integer);
    Port (
        -- IN 
        Multiclk 		: in STD_LOGIC_vector(6 downto 0);
        reset          	: in STD_LOGIC;
	    Trigger_p 		: in STD_LOGIC;
	    Trigger_n 		: in STD_LOGIC;
        -- From RC
	    Time_to_peak	: in STD_LOGIC_vector(11 downto 0);
        ch_enable 		: in STD_LOGIC;
	    calibration    	: in STD_LOGIC;
        delay           : in STD_LOGIC_VECTOR(7 downto 0);
        -- From PPS
        corse_hit		: in STD_LOGIC_vector(27 downto 0);
	    pps				: in STD_LOGIC;
	    pulser			: in STD_LOGIC;
	    -- SPI
        channel_sdi 	: in STD_LOGIC;
        channel_sclk 	: out STD_LOGIC;
        channel_cs 		: out STD_LOGIC;
        -- From FIFO
        HF_FIFO         : in STD_LOGIC;
        wr_ack          : in STD_LOGIC; -- wr_ack from the sc FIFO
        empty           : in STD_LOGIC;
        read_done       : in STD_LOGIC; -- a package has been read by the RR 

        -- OUT
        ratemeter    	: out STD_LOGIC_vector(15 downto 0);
        word_to_FIFO 	: out STD_LOGIC_vector(31 downto 0);
        wr_en           : out STD_LOGIC;
        wr_done         : out STD_LOGIC  -- done writing a package in the FIFO
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

signal calibration, read_done, empty, HF_FIFO, wr_en, enable, reset, time_p, time_n, pulser, PPS, wr_ack, sclk, chip_select, miso, rd_en : std_logic;
signal write_done : std_logic:='0';
signal Multiclk : std_logic_vector(6 downto 0);
signal massimo : std_logic_vector(11 downto 0):= X"01D";
signal COUNTER200M : std_logic_vector(27 downto 0);
signal eventi_freq : std_logic_vector(15 downto 0);
signal word_to_FIFO : std_logic_vector(31 downto 0);
signal dout_FIFO : std_logic_vector(31 downto 0);
signal delay : std_logic_vector(7 downto 0);

type TV is array(0 to 15) of integer;
signal Vettore      : TV := (0, 1, 2, 10, 20, 30, 40, 55, 12, 15, 33, 45, 22, 44, 88, 99);
signal Indice       : integer range 0 to 15 ;
signal DAC_VAL_INT  : STD_LOGIC_VECTOR (13 downto 0);

begin

UUT : single_channel
        GENERIC MAP(
            add          => "10001",
            posizione_y  => 55,
            posizione_x  => 103)
        PORT MAP(
            -- IN
            Multiclk 		=> Multiclk,
            reset           => reset,
            Trigger_p 		=> time_p,
            Trigger_n 		=> time_n,
            
            Time_to_peak	=> massimo,
            ch_enable		=> enable,
            calibration   	=> calibration,
            delay           => delay,
            
            corse_hit		=> COUNTER200M,
            pps				=> PPS,
            Pulser 			=> pulser,
            
            channel_sdi 	=> miso,
            channel_sclk 	=> sclk,
            channel_cs 		=> chip_select,
            
            HF_FIFO         => HF_FIFO,
            wr_ack          => wr_ack, 
            empty           => empty,
            read_done       => read_done,

            ratemeter       => eventi_freq,
            word_to_FIFO    => word_to_FIFO,
            wr_en           => wr_en,
            wr_done         => write_done
        );
        
FIFO: FIFO_single_channel
    PORT MAP (
        clk       => Multiclk(0),
        srst      => reset,
        din       => word_to_FIFO,
        wr_en     => wr_en,
        rd_en     => rd_en,
        dout      => dout_FIFO,
        full      => open,
        wr_ack    => wr_ack,
        empty     => empty,
        prog_full => open
    );
        
Multiclk_process1 :process
   begin
		Multiclk <= "0000001";
		wait for 417 ps;
		Multiclk <= "0000011";
		wait for 417 ps;
		Multiclk <= "0000111";
		wait for 417 ps;
		Multiclk <= "0001111";
		wait for 417 ps;		
		Multiclk <= "0011111";
		wait for 417 ps;		
		Multiclk <= "0111111";
		wait for 417 ps;			
		Multiclk <= "1111110";
		wait for 417 ps;
		Multiclk <= "1111100";
		wait for 417 ps;	
		Multiclk <= "1111000";
		wait for 417 ps;	
		Multiclk <= "1110000";
		wait for 417 ps;	
		Multiclk <= "1100000";
		wait for 417 ps;	
		Multiclk <= "1000000";
		wait for 417 ps;
end process; 

process(empty)
begin
    if empty = '0' then
        rd_en <= '1';
    else
        rd_en <= '0';
    end if;
end process;

wr_ack_proc:process(Multiclk(0), wr_en, write_done)
begin
    if rising_edge(Multiclk(0)) then        
        if write_done = '1' then
            read_done <= '1';
        else
            read_done <= '0';
        end if;
    end if;
end process;

PPS_proc:process(Multiclk(0))
variable count : integer :=0;
begin
    if rising_edge(Multiclk(0)) then
        count := count + 1;   
        PPS <= '0'; 
        if count = 100 then
            PPS <= '1';
            count := 0;
        else 
            PPS <= '0';
        end if;
    end if;
end process;

main_proc:process
begin
    pulser <= '0';
    delay  <= X"1E";
    enable <= '0';
    time_p <= '0'; 
    time_n <= '1'; 
    calibration <= '0';
    COUNTER200M <= X"4A5C6D3";
    reset <= '1';
    HF_FIFO <= '0';
    wait for 10 ns;
    enable <= '1';
    reset  <= '0';
    wait for 30 ns;
    
    time_p <= '1'; 
    time_n <= '0'; 
    wait for 46 ns;
    time_p <= '0';
    time_n <= '1'; 
    Indice <= Indice + 1;

    wait for 254 ns;
    
    time_p <= '1';
    time_n <= '0'; 
    wait for 114 ns;
    time_p <= '0';
    time_n <= '1'; 
    Indice <= Indice + 1;
    
    wait for 100 ns;

    time_p <= '1';
    time_n <= '0'; 
    wait for 184 ns;
    time_p <= '0';
    time_n <= '1'; 
    wait for 421 ns;
    Indice <= Indice + 1;
    
    -- Second burst
    
    wait for 30 ns;
    
    time_p <= '1'; 
    time_n <= '0'; 
    wait for 46 ns;
    time_p <= '0';
    time_n <= '1'; 
    Indice <= Indice + 1;

    wait for 254 ns;
    
    time_p <= '1';
    time_n <= '0'; 
    wait for 114 ns;
    
    calibration <= '1';
    wait for 5 ns;
    calibration <= '0';
    
    time_p <= '0';
    time_n <= '1'; 
    Indice <= Indice + 1;
    
    wait for 100 ns;

    time_p <= '1';
    time_n <= '0'; 
    wait for 184 ns;
    time_p <= '0';
    time_n <= '1'; 
    wait for 421 ns;
    Indice <= Indice + 1;
    
    -- Third burst (with calibration)
    
    wait for 30 ns;
    
    time_p <= '1'; 
    time_n <= '0'; 
    wait for 46 ns;
    time_p <= '0';
    time_n <= '1'; 
    Indice <= Indice + 1;

    wait for 254 ns;
    
    time_p <= '1';
    time_n <= '0'; 
    wait for 114 ns;
    time_p <= '0';
    time_n <= '1'; 
    Indice <= Indice + 1;
    
    wait for 100 ns;

    time_p <= '1';
    time_n <= '0'; 
    wait for 184 ns;
    time_p <= '0';
    time_n <= '1'; 
    wait for 421 ns;
    Indice <= Indice + 1;
    
    -- Fourth burst
    
    wait for 30 ns;
    
    time_p <= '1'; 
    time_n <= '0'; 
    wait for 46 ns;
    time_p <= '0';
    time_n <= '1'; 
    Indice <= Indice + 1;

    wait for 254 ns;
    
    time_p <= '1';
    time_n <= '0'; 
    wait for 114 ns;
    time_p <= '0';
    time_n <= '1'; 
    Indice <= Indice + 1;
    
    wait for 100 ns;

    time_p <= '1';
    time_n <= '0'; 
    wait for 184 ns;
    time_p <= '0';
    time_n <= '1'; 
    wait for 421 ns;
    Indice <= Indice + 1;
    
    wait;   
end process;
        
---------------------------------------------
--    Processo  l'ADC  ADS7049
---------------------------------------------
inst_ADC : process(SCLK, Reset, chip_select)
begin
    if reset = '1' then
       DAC_VAL_INT <= (others => '0');
	elsif falling_edge(chip_select) then
	   DAC_VAL_INT <=  conv_std_logic_vector(Vettore(Indice), DAC_VAL_INT'length);
	elsif falling_edge(SCLK) then
	   DAC_VAL_INT <= DAC_VAL_INT(12 downto 0) & '0' ;  
    end if;
end process; 

miso <= DAC_VAL_INT(13); -- Assegna l'uscita
        
        
end Behavioral;
