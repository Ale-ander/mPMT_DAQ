library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.STD_LOGIC_arith.ALL;
use IEEE.std_logic_unsigned.all;
use work.instruction_buffer_type.all;
library UNISIM;
use UNISIM.VComponents.all;

entity single_channel is
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
        eventi_contati 	: out STD_LOGIC_vector(24 downto 0);
        word_to_FIFO 	: out STD_LOGIC_vector(31 downto 0);
        channel_sclk 	: out STD_LOGIC;
        channel_cs 		: out STD_LOGIC;
        wr_en           : out STD_LOGIC
    );

end single_channel;

architecture Behavioral of single_channel is

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

-- Function to calculate the CRC from a 32 bit array -- 
function CRC32(
    arr: in std_logic_vector(31 downto 0))             
    return std_logic_vector is 
    
    variable CRC : std_logic_vector(3 downto 0);            
    variable step_1 : std_logic_vector(15 downto 0);
    variable step_2 : std_logic_vector(7 downto 0); 
                
    begin
        step_1 := arr(31 downto 16) xor arr(15 downto 0);
        step_2 := step_1(15 downto 8) xor step_1(7 downto 0);
        CRC    := step_2(7 downto 4) xor step_2(3 downto 0);
        return CRC;
 end CRC32;

--===================================================================================
-- 						COSTANTI & SEGNALI
--===================================================================================
----TRG--------
signal time_t            : std_logic;
signal Trg_INr           : std_logic;
signal Time_o_Pulser 	 : std_logic;
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
----Ratemeter--
signal eventi_letti      : std_logic_vector(24 downto 0);
signal Durata_H_TRG      : std_logic_vector(7 downto 0);
----FIFO-------
signal word_to_FIFO_s    : std_logic_vector(31 downto 0):=(OTHERS => '0');
signal HF_FIFO_reg       : std_logic; -- register to write the HF FIFO
----DELAY------
signal delay_r           : std_logic_vector(7 downto 0);
signal delay_en          : std_logic;
signal delay_count       : integer range 0 to 255:=0;
----CRC--------
signal CRC               : std_logic_vector(3 downto 0):=(OTHERS => '0');
----FSM--------
type state is (IDLE, MEM_1, MEM_2, IDLE_NOADC, SUBHIT, CRC_s, HIT);
signal present_state, next_state : state;
attribute fsm_encoding : string;
attribute fsm_encoding of present_state : signal is "sequential";

begin

--===================================================================================
-- 						Differntial buffer
--===================================================================================
IBUFDS_inst : IBUFDS
    generic map (
        DIFF_TERM    => FALSE,
        IBUF_LOW_PWR => FALSE)
    port map (
        O  => time_t,
        I  => time_p,
        IB => time_n 
    );

--===================================================================================
-- 						ADC SPI
--===================================================================================
Time_o_Pulser <= time_t or pulser; 

ADC: SPI_handler
    GENERIC MAP( add => add)
    PORT MAP(
        CLK          => Multiclk(0),
        Reset        => Reset,   
        
        -- IN
        Calibration  => Calibrator,
        Trigger      => Time_o_Pulser,
        Time_to_peak => massimo,
        
        -- SPI 
        SDI          => channel_sdi,
        SCLK         => channel_sclk,
        CS           => channel_cs,
        
        Busy         => ADC_busy,
        DATA_out     => energy_data
        );

--===================================================================================
-- 						TDC
--===================================================================================
Time_block : entity work.blocco_time
    GENERIC MAP(
        posizione_x => posizione_x,
        posizione_y => posizione_y)
     PORT MAP(
         -- IN
         time_sig      => Time_o_Pulser,
         samp_clk      => Multiclk,
         reset         => RESET,
         reset_TDC     => free_TDC,
         coarse_hit    => corse_hit,
         measureType   => measureType,
         enable        => ch_enable,
         -- OUT
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
        present_state  <= IDLE;
        ADC_ok         <= '0';
        TDC_validr     <= '0';
     else
        present_state <= next_state;
        
        TDC_validr    <= TDC_valid;
        delay_r       <= delay;
        
        if ADC_busy = '0' and delay_count >= delay_r then 
            ADC_ok <= '1';
        else
            ADC_ok <= '0';
        end if;
        
        -- calcuate CRC
        if present_state = MEM_1 and next_state = MEM_2 then
            CRC <= CRC32(arr => word_to_FIFO_s);
        elsif present_state = MEM_2 and next_state = IDLE_NOADC then
            CRC <= CRC32(arr => word_to_FIFO_s) xor CRC;
        elsif present_state = SUBHIT and next_state = IDLE_NOADC then
            CRC <= CRC32(arr => word_to_FIFO_s) xor CRC;
        elsif present_state = CRC_s and next_state = HIT then
            CRC <= CRC32(arr => word_to_FIFO_s) xor CRC;
        end if;
        
     end if;
  end if;
end process;

FSM_state_decode: process(present_state, next_state, Time_o_Pulser, TDC_validr, wr_ack, ADC_ok, HF_FIFO, TDC_measure, energy_data, CRC, HF_FIFO_reg)
begin

    next_state <= present_state;

    case present_state is
    
    when IDLE =>
        measureType    <= '0';
        free_TDC       <= '1'; -- verificare se toglie il bug mem_1 + wait_reset
        word_to_FIFO_s <= (OTHERS => '0');
        wr_en          <= '0';
        delay_en       <= '0';
        if Time_o_Pulser = '1' and TDC_validr = '0' and HF_FIFO = '0' then
            next_state <= MEM_1;
            delay_en   <= '1';
        else
            next_state <= IDLE;
        end if;
      
    when MEM_1 => 
        measureType    <= '0';
        free_TDC       <= '0';
        word_to_FIFO_s <= "10" & "0000" & add & "0000000" & TDC_measure(43 downto 30);
        wr_en          <= '0';
        delay_en       <= '1';
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
        measureType    <= '0';
        free_TDC       <= '0';
        word_to_FIFO_s <= "00" & TDC_measure(29 downto 0); -- 00+coarse(14)+fineStart(5)+duration(6)+fineStop(5)
        wr_en          <= '1';
        delay_en       <= '1';
        if wr_ack = '1' then
            next_state  <= IDLE_NOADC;
            wr_en       <= '0';
            measureType <= '1';     
            free_TDC    <= '1';  
        else
            next_state <= MEM_2;      
        end if;

    when IDLE_NOADC => 
        measureType    <= '1';
        free_TDC       <= '0';
        word_to_FIFO_s <= "00" & TDC_measure(29 downto 0); -- 00+coarse(14)+fineStart(5)+duration(6)+fineStop(5)
        wr_en          <= '0';
        delay_en       <= '1';
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
        measureType    <= '1';
        free_TDC       <= '0';
        word_to_FIFO_s <= "01" & TDC_measure(29 downto 0); -- 01+coarse(14)+fineStart(5)+duration(6)+fineStop(5)
        wr_en          <= '1';
        delay_en       <= '1';
        if wr_ack = '1' then
            next_state <= IDLE_NOADC;
            free_TDC   <= '1'; 
            wr_en      <= '0';        
        else
            next_state <= SUBHIT;                  
        end if;
        
    when CRC_s =>        
        measureType    <= '0';
        free_TDC       <= '0';
        word_to_FIFO_s <= "11" & "0000" & "11" & HF_FIFO & "11111111111" & energy_data; -- 11+CRC(4)+stato(3)+unix(11)+ADC(12)
        wr_en          <= '0';
        delay_en       <= '0';
        next_state     <= HIT; 
    
    when HIT =>       
        measureType    <= '0';
        free_TDC       <= '0';
        word_to_FIFO_s <= "11" & CRC & "11" & HF_FIFO_reg & "11111111111" & energy_data; -- 11+CRC(4)+stato(3)+unix(11)+ADC(12)
        wr_en          <= '1';
        delay_en       <= '0';
        if wr_ack = '1' then
            wr_en      <= '0';
            next_state <= IDLE;            
        else
            next_state <= HIT;      
        end if;
        
    when others =>
        measureType    <= '0';
        free_TDC       <= '0';
        delay_en       <= '0';
        word_to_FIFO_s <= (OTHERS => '0');
        wr_en          <= '0';
        next_state     <= IDLE;
        
    end case;
end process;

--===================================================================================
-- 						Delay counter
--===================================================================================
delay_counter: process(Multiclk(0))
begin
    if rising_edge(Multiclk(0)) then
        if reset = '1' or delay_en = '0' then
            delay_count <= 0;
        else
            delay_count <= delay_count + 1;            
        end if;
    end if;
end process;

--===================================================================================
-- 						Event counter
--===================================================================================
contatore_eventi: process(Multiclk(0))
begin
	if rising_edge(Multiclk(0)) then
	   if reset = '1' then
	       eventi_letti   <= (OTHERS => '0');
	       eventi_contati <= (OTHERS => '0');
	       Durata_H_TRG   <= (OTHERS => '0');
	       Trg_INr        <= '0';
	   else
           Trg_INr <= Time_o_Pulser;
             
           if pps = '1' then
               eventi_contati <= eventi_letti;
               eventi_letti   <= (OTHERS => '0');
           elsif TDC_valid = '1' and  eventi_letti < ('1' & X"FFFFFE") then
               eventi_letti <= eventi_letti + 1;
           elsif Durata_H_TRG = 255 then -- Se sempre alto
               eventi_letti <= (OTHERS => '1');
           end if;	
		
-- Comparator always high set to FFFF
           if Trg_INr = '0' then
                 Durata_H_TRG <= (OTHERS => '0');
           elsif Durata_H_TRG < 255 then 
                 Durata_H_TRG <= Durata_H_TRG + 1;
           end if;			
	   end if;
	end if;
end process;

word_to_FIFO <= word_to_FIFO_s;

end Behavioral;