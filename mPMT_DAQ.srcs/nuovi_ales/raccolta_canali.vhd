----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Alessandro Di Nola  
-- 
-- scheda x Nexis4
--
-- Module Name:    raccolta_canali - Behavioral 
-- Revision  Module 3.0 
-- Ultima modifica 21/05/2023
--
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.STD_LOGIC_arith.ALL;
use IEEE.std_logic_unsigned.all;
use work.instruction_buffer_type.all;

entity raccolta_canali is
    generic (n_channel  : integer:= 19);                                -- number of PMTs channels
    Port ( 
        Multiclk 		: in  STD_LOGIC_VECTOR(6 downto 0);             -- multiphase		   
        RESET 			: in  STD_LOGIC;                                -- external reset
		COUNTER200M 	: in  STD_LOGIC_VECTOR(27 downto 0);            -- 200MHz counter
        -- PPS channel		  
		PPS				: in  STD_LOGIC;                                -- PPS from pulser
        -- From/To RunControl		  
        delay           : in  Delay_ARRAY;                              -- additional delay set by runcontrol    
		massimo 		: in  Peak_ARRAY;                               -- time to peak for each channel
		ch_enable       : in  STD_LOGIC_VECTOR(n_channel - 1 downto 0); -- enable for each channel
        calibrazione    : in  STD_LOGIC;                                -- calibration flag
        PPS_ch_en 	    : in  STD_LOGIC;                                -- PPS channel enable	  
		Pulser 		    : in  STD_LOGIC;                                -- pedestal generator
		count_tm        : in STD_LOGIC_VECTOR(8 downto 0);              -- value to count to timeout the raead
		dead_time       : out STD_LOGIC_VECTOR(15 downto 0);            -- dead time read through RC
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
           
end raccolta_canali;

architecture Behavioral of raccolta_canali is

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

component Canale_secondi is
    Port ( 
        clk 	     : in STD_LOGIC;
        reset 		 : in STD_LOGIC;
		PPS_ch_en    : in STD_LOGIC;
        PPS 		 : in STD_LOGIC;
        wr_ack 		 : in STD_LOGIC;
        humidity     : in STD_LOGIC_VECTOR(11 DOWNTO 0);
        temperature  : in STD_LOGIC_VECTOR(11 DOWNTO 0);
        unixtime     : in STD_LOGIC_VECTOR(31 DOWNTO 0);
        ratemeter    : in Freq_ARRAY:=(OTHERS => (OTHERS => '0'));
        read_done    : in STD_LOGIC;
        COUNTER200M  : in STD_LOGIC_VECTOR(27 downto 0);
        HF_FIFO      : in STD_LOGIC;
        empty        : in STD_LOGIC;
        -- STATO mPMT
        extclk0status: in STD_LOGIC; 
        extclk1status: in STD_LOGIC;
        PLL_locked   : in STD_LOGIC;
        pow_cons_ok  : in STD_LOGIC;
        voltage_ok   : in STD_LOGIC;
        unix_error   : in STD_LOGIC;
        -- STATO CH
        
	    -- OUT		  
        word_to_fifo : out STD_LOGIC_VECTOR(31 downto 0);
        dead_time    : out STD_LOGIC_VECTOR(15 downto 0);
        wr_en 	     : out STD_LOGIC;
        wr_done	     : out STD_LOGIC
        );
end component;

component raccolta_dati is
    generic (n_channel : integer:= 2); -- number of PMT channels
    Port ( 
        -- IN    
        din        : in Data32_ARRAY;
		clk 	   : in STD_LOGIC;
        reset 	   : in STD_LOGIC;
        empty 	   : in STD_LOGIC_VECTOR(n_channel downto 0);  -- emptys of the small FIFOs
        wr_done	   : in STD_LOGIC_VECTOR(n_channel downto 0);  -- a apackage has been written in the FIFO
		HF_FIFO    : in STD_LOGIC;                             -- HF of the big FIFO
		count_tm   : in STD_LOGIC_vector(8 downto 0);          -- value to count to timeout the raead
		-- OUT
		reset_ch   : out STD_LOGIC_VECTOR(n_channel downto 0); -- reset the sc FSM if timeout
        wr_en      : out STD_LOGIC;                            -- write_enable of the big FIFO 
        rd_done	   : out STD_LOGIC_VECTOR(n_channel downto 0); -- package has been read from the rr
        rd_en 	   : out STD_LOGIC_VECTOR(n_channel downto 0); -- read enable to the small FIFOs
        dout       : out STD_LOGIC_VECTOR(31 downto 0)
        );
end component;

--===================================================================================
-- 						COSTANTI & SEGNALI
--===================================================================================
----From SC to FIFO-------
signal word_to_FIFO : Data32_ARRAY; -- from channel to FIFO
signal wr_en     	: STD_LOGIC_VECTOR(n_channel downto 0);
signal wr_done     	: STD_LOGIC_VECTOR(n_channel downto 0);
signal wr_ack     	: STD_LOGIC_VECTOR(n_channel downto 0);
signal prog_full    : STD_LOGIC_VECTOR(n_channel downto 0);
----RESET-----------------
signal reset_all : STD_LOGIC_VECTOR(n_channel downto 0); -- single reset signal for the channels
signal reset_ch  : STD_LOGIC_VECTOR(n_channel downto 0); -- sc reset from rr
----From fifo to RR-------
signal dout      : Data32_ARRAY;
signal rd_en     : STD_LOGIC_VECTOR(n_channel downto 0);
signal empty     : STD_LOGIC_VECTOR(n_channel downto 0);
signal read_done : STD_LOGIC_VECTOR(n_channel downto 0);
----PPS channel-----------
signal eventi_freq  : Freq_ARRAY;
signal ratemeters_s : Freq_ARRAY;

ATTRIBUTE keep_hierarchy 				: string;
ATTRIBUTE keep_hierarchy OF Behavioral	: ARCHITECTURE IS "true";

begin

--===================================================================================
-- 						Assign ratemeters to out
--===================================================================================
ratemeters_ass:process(eventi_freq)
begin
    for i in 0 to 18 loop
        if i < n_channel then
            ratemeters_s(i) <= eventi_freq(i);
        else
            ratemeters_s(i) <= (OTHERS =>'0');
        end if;
    end loop;
end process;

ratemeters <= ratemeters_s;

--===================================================================================
-- 						Channels declaration
--===================================================================================
channel: for i in 0 to (n_channel - 1) generate
begin
    single_channel_inst: single_channel
        GENERIC MAP(
            add          => CONV_STD_LOGIC_VECTOR(i,5),
            posizione_y  => 55,
            posizione_x  => 103)
        PORT MAP(
            -- IN
            Multiclk 		=> Multiclk,
            reset   		=> reset_all(i),
            Trigger_p 		=> time_p(i),
            Trigger_n   	=> time_n(i),
            Time_to_peak	=> massimo(i),
            corse_hit		=> COUNTER200M,
            Pulser 			=> Pulser,
            ch_enable		=> ch_enable(i),
            pps				=> PPS,
            calibration   	=> calibrazione,
            channel_sdi 	=> sdi(i),
            HF_FIFO         => prog_full(i),
            wr_ack          => wr_ack(i), 
            read_done       => read_done(i),
            delay           => delay(i),
            empty           => empty(i),
            -- OUT
            ratemeter       => eventi_freq(i),
            channel_sclk 	=> sclk(i),
            channel_cs 		=> chip_select(i),
            word_to_FIFO    => word_to_FIFO(i),
            wr_en           => wr_en(i),
            wr_done         => wr_done(i)
        );
        
    FIFO: FIFO_single_channel
        PORT MAP (
            clk       => Multiclk(0),
            srst      => reset_all(i),
            din       => word_to_FIFO(i),
            wr_en     => wr_en(i),
            rd_en     => rd_en(i),
            dout      => dout(i),
            full      => open,
            wr_ack    => wr_ack(i),
            empty     => empty(i),
            prog_full => prog_full(i)
        );
               
end generate;
------------------------------------
--  PPS channel 
------------------------------------
PPS_channel: Canale_secondi 
	   PORT MAP(
	        -- IN
            clk     	=> Multiclk(0),
            reset 		=> reset_all(n_channel),
            PPS_ch_en 	=> PPS_ch_en,
            PPS 		=> PPS,
            wr_ack      => wr_ack(n_channel),
            humidity    => (OTHERS => '0'),
            temperature => (OTHERS => '0'),
            unixtime    => unixtime,
            ratemeter   => ratemeters_s,
            read_done   => read_done(n_channel),
            HF_FIFO     => prog_full(n_channel),
            COUNTER200M => COUNTER200M,
            empty       => empty(n_channel),
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
            wr_done 	 => wr_done(n_channel),
            dead_time    => dead_time
	   );
	
    FIFO_PPS : FIFO_single_channel
        PORT MAP (
            clk       => Multiclk(0),
            srst      => reset_all(n_channel),
            din       => word_to_FIFO(n_channel),
            wr_en     => wr_en(n_channel),
            rd_en     => rd_en(n_channel),
            dout      => dout(n_channel),
            full      => open,
            wr_ack    => wr_ack(n_channel),
            empty     => empty(n_channel),
            prog_full => prog_full(n_channel)
        );
        
reset_gen:process(reset, reset_ch)
begin
    for i in 0 to n_channel loop
        reset_all(i) <= reset or reset_ch(i);
    end loop;
end process;
        
--===================================================================================
-- 						Data round robin
--===================================================================================
Round_robin: raccolta_dati
        GENERIC MAP(n_channel => n_channel)
        PORT MAP(
                -- IN    
                din      => dout, 
                clk 	 => Multiclk(0),
                reset 	 => reset,
                empty 	 => empty,
                wr_done	 => wr_done,
                HF_FIFO  => HF_FIFO,
                count_tm => count_tm,
                -- OUT
                reset_ch => reset_ch,
                wr_en    => wr_en_o,
                rd_done	 => read_done,
                rd_en 	 => rd_en,
                dout     => dout_to_FIFO
                );

end Behavioral;