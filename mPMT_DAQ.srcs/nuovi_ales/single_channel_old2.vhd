library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.STD_LOGIC_arith.ALL;
use IEEE.std_logic_unsigned.all;
use work.instruction_buffer_type.all;
library UNISIM;
use UNISIM.VComponents.all;

entity single_channel_old2 is
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

end single_channel_old2;

architecture Behavioral of single_channel_old2 is

component SPI_handler is
    Generic( add    : STD_LOGIC_VECTOR(4 downto 0));
    Port ( CLK      : in STD_LOGIC;
           Reset    : in STD_LOGIC;
           
           -- IN
           Calibration  : in STD_LOGIC;
           Trigger      : in STD_LOGIC;
           Time_to_peak : in STD_LOGIC_VECTOR(11 downto 0);
           
           -- SPI 
           SDI      : in STD_LOGIC;
           SCLK     : out STD_LOGIC;
           CS       : out STD_LOGIC;
           
           Busy     : out STD_LOGIC;
           DATA_out : out STD_LOGIC_VECTOR (11 downto 0));
end component;

component blocco_time is
    generic( posizione_y       : integer:=55;
             posizione_x       : integer:=103);
    Port(   
         -- IN
         time_sig      : in std_logic;
         samp_clk      : in std_logic_vector(6 downto 0);
         reset         : in std_logic;
         reset_TDC     : in std_logic;
         coarse_hit    : in std_logic_vector(27 downto 0);
         measureType   : in std_logic; -- '0' HIT '1' SUBHIT
         HF_FIFO       : in std_logic;
         enable        : in std_logic;
         -- OUT
         rst_done      : out std_logic;
         valid_measure : out std_logic;
         final_measure : out std_logic_vector(43 downto 0)
         );
end component;

-- Function to calculate the CRC from a 32 bit array -- 
function CRC32(signal arr: in std_logic_vector(31 downto 0)) 
                
                return std_logic_vector is variable CRC : std_logic_vector(3 downto 0);
                
    variable step_1 : std_logic_vector(15 downto 0);
    variable step_2 : std_logic_vector(7 downto 0); 
                
    begin
        step_1 := arr(31 downto 16) xor arr(15 downto 0);
        step_2 := step_1(15 downto 8) xor step_1(7 downto 0);
        CRC := step_2(7 downto 4) xor step_2(3 downto 0);
        return CRC;
 end CRC32;

--===================================================================================
-- 						COSTANTI & SEGNALI
--===================================================================================
----TRG--------
signal Trigger           : std_logic;
signal Trg_r             : std_logic;
signal Trg_o_Pulser 	 : std_logic;
signal buf_disable   	 : std_logic;
----Energy-----
signal ADC_ok            : std_logic;	
signal ADC_busy          : std_logic;
signal energy_data       : std_logic_vector(11 downto 0);
----TDC--------
signal TDC_measure       : std_logic_vector(43 downto 0);
signal TDC_valid         : std_logic;
signal TDC_validr        : std_logic;
signal measureType   	 : std_logic;
signal free_TDC     	 : std_logic;
signal rst_done      	 : std_logic;
----Ratemeter--
signal eventi_letti      : std_logic_vector(15 downto 0);
signal Durata_H_TRG      : std_logic_vector(7 downto 0);
----FIFO-------
signal word_to_FIFO_s    : std_logic_vector(31 downto 0):=(OTHERS => '0');
signal HF_FIFO_reg       : std_logic; -- register to write the HF FIFO
signal read_done_r       : std_logic;
signal read_done_sync    : std_logic;
----DELAY------
signal delay_r           : std_logic_vector(7 downto 0);
signal delay_en          : std_logic;
signal delay_count       : std_logic_vector(7 downto 0);
----CRC--------
signal CRC               : std_logic_vector(3 downto 0):=(OTHERS => '0');
----FSM--------
type state is (IDLE, MEM_1, MEM_2, IDLE_NOADC, SUBHIT, CRC_s, HIT);
signal present_state, next_state : state;
attribute keep : string;
attribute keep of present_state : signal is "true";

begin

--===================================================================================
-- 						Differntial buffer
--===================================================================================
IBUFDS_IBUFDISABLE_inst : IBUFDS_IBUFDISABLE
    generic map (
        DIFF_TERM       => "TRUE",
        IBUF_LOW_PWR    => "FALSE",
        USE_IBUFDISABLE => "FALSE",
        SIM_DEVICE      => "7SERIES")
    port map (
        O           => Trigger,
        I           => Trigger_p,
        IB          => Trigger_n,
        IBUFDISABLE => buf_disable
    );

buf_disable <= not ch_enable;

--===================================================================================
-- 						ADC SPI
--===================================================================================
Trg_o_Pulser <= Trigger or pulser; 

ADC: SPI_handler
    generic map( add => add)
    port map(
        CLK          => Multiclk(0),
        Reset        => Reset,
        calibration  => calibration,
        trigger      => Trg_o_pulser,
        Time_to_peak => Time_to_peak,
        SDI          => channel_sdi,
        SCLK         => channel_sclk,
        CS           => channel_cs,
        Busy         => ADC_busy,
        DATA_out     => energy_data
    );

--===================================================================================
-- 						TDC
--===================================================================================
Time_block: blocco_time
    GENERIC MAP(
        posizione_x => posizione_x,
        posizione_y => posizione_y)
     PORT MAP(
         -- IN
         time_sig      => Trg_o_Pulser,
         samp_clk      => Multiclk,
         reset         => RESET,
         reset_TDC     => free_TDC,
         coarse_hit    => corse_hit,
         measureType   => measureType,
         HF_FIFO       => HF_FIFO,
         enable        => ch_enable,
         -- OUT
         rst_done      => rst_done,
         final_measure => TDC_measure,
         valid_measure => TDC_valid
         );
         
--===================================================================================
-- 						FSM multi-ToT
--===================================================================================
FSM_sync_proc: process(Multiclk(0))
begin
  if rising_edge(Multiclk(0)) then
     if Reset = '1' or ch_enable = '0' then
        present_state <= IDLE;
        ADC_ok        <= '0';
        wr_done       <= '0';
     else
        present_state <= next_state;
        
        TDC_validr    <= TDC_valid;
        read_done_r   <= read_done;
        delay_r       <= delay;
        
        -- create ADC_ok flag only while FSM is waiting
        if ADC_busy = '0' and delay_count >= delay_r then 
            ADC_ok <= '1';
        else
            ADC_ok <= '0';
        end if;
        
        -- calcuate CRC
        if present_state = MEM_1 and next_state = MEM_2 then
            CRC <= CRC32(arr => word_to_FIFO_s);
        elsif present_state = MEM_2 and next_state = MEM_2 then
            CRC <= CRC32(arr => word_to_FIFO_s) xor CRC;
        elsif present_state = IDLE_NOADC and next_state = SUBHIT then
            CRC <= CRC32(arr => word_to_FIFO_s) xor CRC;
        elsif present_state = IDLE_NOADC and next_state = CRC_s then
            CRC <= CRC32(arr => word_to_FIFO_s) xor CRC;
        end if;
        
        -- handshaking with the RR
        if read_done = '1' and read_done_r = '0' then
            read_done_sync <= '1';
        else
            read_done_sync <= '0';
        end if;    
        
        if present_state = HIT and next_state = IDLE then
            wr_done <= '1';
        elsif read_done_sync = '1' and empty = '1' then
            wr_done <= '0';
        end if;
        
     end if;
  end if;
end process;

FSM_state_decode: process(present_state, Trg_o_Pulser, TDC_validr, wr_ack, HF_FIFO, ADC_ok, rst_done)
begin

    next_state <= present_state;

    case present_state is
    
    when IDLE =>
        measureType    <= '0';
        free_TDC       <= '0';
        word_to_FIFO_s <= (OTHERS => '0');
        wr_en          <= '0';
        delay_en       <= '0';
        if Trg_o_Pulser = '1' and TDC_validr = '0' and HF_FIFO = '0' then
            next_state <= MEM_1;
            delay_en   <= '1';
        else
            next_state <= IDLE;
        end if;
      
    when MEM_1 => 
        delay_en <= '1';
        if TDC_validr = '1' then
            word_to_FIFO_s  <= "10" & "0000" & add & "0000000" & TDC_measure(43 downto 30); -- 10+tipo(4)+channel(5)+unix(7)+coarse(14)
            wr_en           <= '1';
        end if;
        if wr_ack = '1' then
            next_state <= MEM_2;
            wr_en      <= '0';       
        else
            next_state <= MEM_1;      
        end if;
        
    when MEM_2 => 
        delay_en       <= '1';
        word_to_FIFO_s <= "00" & TDC_measure(29 downto 0); -- 00+coarse(14)+fineStart(5)+duration(6)+fineStop(5)
        wr_en          <= '1';
        free_TDC       <= '1';
        if rst_done = '1' and wr_ack = '1' then
            next_state  <= IDLE_NOADC;
            wr_en       <= '0';
            measureType <= '1';       
        else
            next_state <= MEM_2;      
        end if;

    when IDLE_NOADC => 
        delay_en       <= '1';
        free_TDC       <= '0';
        wr_en          <= '0';
        word_to_FIFO_s <= (OTHERS => '0');
        if ADC_ok = '1' then 
            next_state     <= CRC_s;
            HF_FIFO_reg    <= HF_FIFO;
            word_to_FIFO_s <= "11" & "0000" & "11" & HF_FIFO & "11111111111" & energy_data; -- 11+CRC(4)+stato(3)+unix(11)+ADC(12)
        elsif TDC_validr = '1' then
            next_state     <= SUBHIT;
            word_to_FIFO_s <= "01" & TDC_measure(29 downto 0); -- 01+coarse(14)+fineStart(5)+duration(6)+fineStop(5)
        else
            next_state     <= IDLE_NOADC;
        end if;
        
     when SUBHIT =>
        delay_en       <= '1';
        wr_en          <= '1';
        word_to_FIFO_s <= "01" & TDC_measure(29 downto 0); -- 01+coarse(14)+fineStart(5)+duration(6)+fineStop(5)
        if wr_ack = '1' then
            next_state <= IDLE_NOADC;
            free_TDC   <= '1'; 
            wr_en      <= '0';        
        else
            next_state <= SUBHIT;                  
        end if;
        
    when CRC_s =>
        next_state     <= HIT;
        word_to_FIFO_s <= "11" & "0000" & "11" & HF_FIFO & "11111111111" & energy_data; -- 11+CRC(4)+stato(3)+unix(11)+ADC(12)
        delay_en       <= '0';
        wr_en          <= '0';
    
    when HIT =>
        word_to_FIFO_s <= "11" & CRC & "11" & HF_FIFO_reg & "11111111111" & energy_data; -- 11+CRC(4)+stato(3)+unix(11)+ADC(12)
        measureType <= '0';
        wr_en       <= '1'; 
        delay_en    <= '0'; 
        if wr_ack = '1' then
            wr_en      <= '0';
            next_state <= IDLE;            
        else
            next_state <= HIT;      
        end if;
        
    when others =>
        measureType    <= '0';
        next_state     <= IDLE;
        free_TDC       <= '0';
        delay_en       <= '0';
        word_to_FIFO_s <= (OTHERS => '0');
        wr_en          <= '0';
        
    end case;
end process;

--===================================================================================
-- 						Delay counter
--===================================================================================
delay_counter: process(Multiclk(0))
begin
    if rising_edge(Multiclk(0)) then
        if reset = '1' or delay_en = '0' then
            delay_count <= (others => '0');
        else
            delay_count <= delay_count + '1';            
        end if;
    end if;
end process;

--===================================================================================
-- 						Event counter
--===================================================================================
contatore_eventi : process(Multiclk(0), reset)
begin
	if reset = '1' then
		eventi_letti   <= (OTHERS => '0');
		ratemeter      <= (OTHERS => '0');
		Durata_H_TRG   <= (OTHERS => '0');
		Trg_r          <= '0';
	elsif rising_edge(Multiclk(0)) then
	    Trg_r          <= Trg_o_Pulser;
		  
		if pps = '1' then
			ratemeter    <= eventi_letti;
			eventi_letti <= (OTHERS => '0');
        elsif TDC_valid = '1' and  eventi_letti < X"FFFE" then
			eventi_letti <= eventi_letti + 1;
		elsif Durata_H_TRG = 255 then -- Se sempre alto
		    eventi_letti <= (OTHERS => '1');
		end if;	
		
-- Comparator always high set to FFFF
		if Trg_r = '0' then
		      Durata_H_TRG <= (OTHERS => '0');
		elsif Durata_H_TRG < 255 then 
	          Durata_H_TRG <= Durata_H_TRG + 1;
		end if;			
		
	end if;
end process;

word_to_FIFO <= word_to_FIFO_s;

end Behavioral;