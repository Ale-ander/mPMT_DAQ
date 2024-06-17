library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.STD_LOGIC_arith.ALL;
use IEEE.std_logic_unsigned.all;
use work.instruction_buffer_type.all;

entity Multychannel_V2 is
    generic (n_channel  : integer:= 19);                                -- number of PMTs channels
    Port ( 
        Multiclk 		: in  STD_LOGIC_VECTOR(6 downto 0);             -- multiphase		   
        RESET 			: in  STD_LOGIC;                                -- external reset
		COUNTER200M 	: in  STD_LOGIC_VECTOR(27 downto 0);            -- 200MHz counter
        -- PPS channel		  
		PPS				: in  STD_LOGIC;                                -- PPS from pulser
		COUNTA_sec	    : in  STD_LOGIC_VECTOR(27 downto 0);            -- PPS counter
        -- From/To runControl		  
        delay           : in  Delay_ARRAY;                              -- additional delay set by runcontrol    
		massimo 		: in  Peak_ARRAY;                               -- time to peak for each channel
		ch_enable       : in  STD_LOGIC_VECTOR(n_channel - 1 downto 0); -- enable for each channel
        calibrazione    : in  STD_LOGIC;                                -- calibration flag
        PPS_ch_en 	    : in  STD_LOGIC;                                -- PPS channel enable	  
		Pulser 		    : in  STD_LOGIC;                                -- pedestal generator
		count_tm        : in STD_LOGIC_VECTOR(8 downto 0);              -- value to count to timeout the raead
		dead_time       : out STD_LOGIC_VECTOR(31 downto 0);            -- dead time read through RC
		ratemeters      : out Freq_ARRAY;
	    -- PPS channel
	    unixtime        : in STD_LOGIC_VECTOR(31 downto  0);	   
	    -- To channels	  
        time_p 		    : in  STD_LOGIC_VECTOR(n_channel - 1 downto 0); -- trigger positive
        time_n 		    : in  STD_LOGIC_VECTOR(n_channel - 1 downto 0); -- trigger negative
		sdi 			: in  STD_LOGIC_VECTOR(n_channel - 1 downto 0); -- SPI
        sclk 			: out STD_LOGIC_VECTOR(n_channel - 1 downto 0); -- SPI
        chip_select 	: out STD_LOGIC_VECTOR(n_channel - 1 downto 0); -- SPI
        -- To big FIFO
        HF_FIFO         : in STD_LOGIC;                                 -- HF big FIFO
        wr_en_o         : out STD_LOGIC;                                -- wr_en big FIFO
        dout_to_FIFO    : out STD_LOGIC_VECTOR(31 downto 0)             -- data to big FIFOSim_ARRAY
        );       
end Multychannel_V2;

architecture Behavioral of Multychannel_V2 is

COMPONENT FIFO_single_channel
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
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

component data_shifter_SM
    Port ( 
       -- IN
       clk       : in STD_LOGIC;
       reset     : in STD_LOGIC;
       din_FIFO  : in STD_LOGIC_VECTOR(31 downto 0);
       din_shift : in STD_LOGIC_VECTOR(31 downto 0);
       Ren_in    : in STD_LOGIC; 
       wr_en_in  : in  STD_LOGIC;
       count_tm  : in STD_LOGIC_vector(8 downto 0);
       empty     : in STD_LOGIC;
       
       -- OUT
       Ren_out   : out STD_LOGIC;
       wr_en_out : out STD_LOGIC;
       rd_en     : out STD_LOGIC;
       dout      : out STD_LOGIC_VECTOR (31 downto 0)
       );
end component;

component single_channel is
    generic (add : STD_LOGIC_vector(4 downto 0) := "00000";
             posizione_y       : integer;
             posizione_x       : integer);
    Port (
        -- IN 
        Multiclk 		: in STD_LOGIC_vector(6 downto 0);
        reset          	: in STD_LOGIC;
	    time_p 			: in STD_LOGIC;
	    time_n 			: in STD_LOGIC;
	    massimo 		: in STD_LOGIC_vector(11 downto 0);
        corse_hit		: in STD_LOGIC_vector(27 downto 0);
	    pps				: in STD_LOGIC;
	    calibrator     	: in STD_LOGIC;
	    pulser			: in STD_LOGIC;
        channel_sdi 	: in STD_LOGIC;
        ch_enable 		: in STD_LOGIC;
        HF_FIFO         : in STD_LOGIC;
        wr_ack          : in STD_LOGIC; -- wr_ack from the FIFO
        delay           : in STD_LOGIC_VECTOR(7 downto 0);
        -- OUT
        eventi_contati 	: out STD_LOGIC_vector(15 downto 0);
        word_to_FIFO 	: out STD_LOGIC_vector(31 downto 0);
        channel_sclk 	: out STD_LOGIC;
        channel_cs 		: out STD_LOGIC;
        wr_en           : out STD_LOGIC
    );

end component;

--===================================================================================
-- 						COSTANTI & SEGNALI
--===================================================================================
constant emptyC : STD_LOGIC_VECTOR(n_channel downto 0) := (others => '1');
----From SC to FIFO-------
signal word_to_FIFO : Data32_ARRAY; -- from channel to FIFO
signal wr_en     	: STD_LOGIC_VECTOR(n_channel downto 0);
signal wr_ack     	: STD_LOGIC_VECTOR(n_channel downto 0);
signal prog_full    : STD_LOGIC_VECTOR(n_channel downto 0);
---------FIFO SC----------
signal dout  : Data32_ARRAY; -- from FIFO SC to data shifter 
signal rd_en : STD_LOGIC_VECTOR(n_channel downto 0);
signal empty : STD_LOGIC_VECTOR(n_channel downto 0);
------DATA SHIFTER--------
signal Ren         : STD_LOGIC_VECTOR(n_channel+1 downto 0); 
signal enable_ren  : STD_LOGIC; 
signal wr_en_shift : STD_LOGIC_VECTOR(n_channel+1 downto 0); 
signal data_shift  : Data32_Array; -- Data shift from a shifter to another
------PPS channel---------
signal eventi_freq  : Freq_ARRAY;
signal ratemeters_s : Freq_ARRAY;

ATTRIBUTE keep_hierarchy 				: string;
ATTRIBUTE keep_hierarchy OF Behavioral	: ARCHITECTURE IS "true";

begin

--===================================================================================
-- 						Assign ratemeters to out
--===================================================================================
ratemeters <= eventi_freq;


--===================================================================================
-- 						Channels declaration
--===================================================================================
channel: for i in 0 to (n_channel - 1) generate
begin
    single_channel_inst : entity work.single_channel
        GENERIC MAP(
            add          => CONV_STD_LOGIC_VECTOR(i,5),
            posizione_y  => 55,
            posizione_x  => 103)
        PORT MAP(
            -- IN
            Multiclk 		=> Multiclk,
            reset   		=> reset,
            time_p 			=> time_p(i),
            time_n 			=> time_n(i),
            massimo 		=> massimo(i),
            corse_hit		=> COUNTER200M,
            Pulser 			=> Pulser,
            ch_enable		=> ch_enable(i),
            pps				=> PPS,
            calibrator   	=> calibrazione,
            channel_sdi 	=> sdi(i),
            HF_FIFO         => prog_full(i),
            wr_ack          => wr_ack(i), 
            delay           => delay(i),
            -- OUT
            eventi_contati  => eventi_freq(i),
            channel_sclk 	=> sclk(i),
            channel_cs 		=> chip_select(i),
            word_to_FIFO    => word_to_FIFO(i),
            wr_en           => wr_en(i)
        );
        
        
    FIFO: FIFO_single_channel
        PORT MAP (
            clk       => Multiclk(0),
            rst       => reset,
            din       => word_to_FIFO(i),
            wr_en     => wr_en(i),
            rd_en     => rd_en(i),
            dout      => dout(i),
            full      => open,
            wr_ack    => wr_ack(i),
            empty     => empty(i),
            prog_full => prog_full(i)
        );
        
    channel_data_shifter: data_shifter_SM
        port map(
            -- IN
            clk       => Multiclk(0),
            reset     => reset,
            din_FIFO  => dout(i),
            din_shift => data_shift(i+1),
            Ren_in    => Ren(i),
            wr_en_in  => wr_en_shift(i+1),
            count_tm  => count_tm,
            empty     => empty(i),
            
            -- OUT
            Ren_out   => Ren(i+1),
            wr_en_out => wr_en_shift(i),
            rd_en     => rd_en(i),
            dout      => data_shift(i)
            );
               
end generate;
 
------------------------------------
--  PPS channel 
------------------------------------
    PPS_channel: entity work.Canale_secondi 
	   PORT MAP(
	        -- IN
            clk     	=> Multiclk(0),
            reset 		=> reset,
            PPS_ch_en 	=> PPS_ch_en,
            PPS 		=> PPS,
            wr_ack      => wr_ack(n_channel),
            humidity    => (OTHERS => '0'),
            temperature => (OTHERS => '0'),
            unixtime    => unixtime,
            ratemeter   => eventi_freq,
            HF_FIFO     => prog_full(n_channel),
            COUNTER200M => COUNTER200M(11 downto 0),
            -- STATO mPMT
            extclk0status => '0', 
            extclk1status => '1', 
            PLL_locked    => '0', 
            pow_cons_ok   => '1', 
            voltage_ok    => '0', 
            unix_error    => '1', 
            -- STATO CH
            
            -- OUT
            word_to_fifo => word_to_FIFO(n_channel),
            wr_en 		 => wr_en(n_channel),
            dead_time    => dead_time
	   );
	
    FIFO_PPS : FIFO_single_channel
        PORT MAP (
            clk       => Multiclk(0),
            rst       => reset,
            din       => word_to_FIFO(n_channel),
            wr_en     => wr_en(n_channel),
            rd_en     => rd_en(n_channel),
            dout      => dout(n_channel),
            full      => open,
            wr_ack    => wr_ack(n_channel),
            empty     => empty(n_channel),
            prog_full => prog_full(n_channel)
        );
        
        
    PPS_data_shifter: data_shifter_SM
        PORT MAP(
            -- IN
            clk       => Multiclk(0),
            reset     => reset,
            din_FIFO  => dout(n_channel),
            din_shift => (others => '0'),
            Ren_in    => Ren(n_channel),
            wr_en_in  => '0',
            count_tm  => count_tm,
            empty     => empty(n_channel),
            
            -- OUT
            Ren_out   => Ren(n_channel+1),
            wr_en_out => wr_en_shift(n_channel),
            rd_en     => rd_en(n_channel),
            dout      => data_shift(n_channel)
            );
            
dout_to_FIFO <= data_shift(0);
wr_en_o      <= wr_en_shift(0);

main_logic: process(Multiclk(0), reset, empty, enable_ren, Ren(0))
begin
    if rising_edge(Multiclk(0)) then
        if reset = '1' or HF_FIFO = '1' then
           Ren(0)     <= '0'; 
           enable_ren <= '0';
        else
            if empty /= emptyC and enable_ren = '1' then
                Ren(0) <= '1';
            elsif Ren(n_channel + 1) = '1' then
                Ren(0) <= '0';
            end if;
        end if;
        
        if Ren(n_channel + 1) = '0' then
            enable_ren <= '1';
        else
            enable_ren <= '0';
        end if;
        
    end if;
end process;

end Behavioral;