library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use UNISIM.vcomponents.all;
use work.instruction_buffer_type.all;

entity Canale_secondi is
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
end Canale_secondi;

architecture Behavioral of Canale_secondi is

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

signal PPS_r : std_logic;
----DEADTIME-----
signal dead_time_s    : std_logic_vector(15 downto 0);
signal dead_counter : std_logic_vector(15 downto 0);
----CRC----------
signal CRC : std_logic_vector(3 downto 0);
----FIFO---------
signal read_done_r    : std_logic;
signal read_done_sync : std_logic;
signal word_to_fifo_s : std_logic_vector(31 downto 0);
----RATEMETER----
signal unix_reg     : std_logic_vector(31 downto 0); --unix?
signal partial0_3   : std_logic_vector(17 downto 0):=(OTHERS => '0');
signal partial4_7   : std_logic_vector(17 downto 0):=(OTHERS => '0');
signal partial8_11  : std_logic_vector(17 downto 0):=(OTHERS => '0');
signal partial12_15 : std_logic_vector(17 downto 0):=(OTHERS => '0');
signal partial16_18 : std_logic_vector(17 downto 0):=(OTHERS => '0');
signal partial_a    : std_logic_vector(19 downto 0):=(OTHERS => '0');
signal partial_b    : std_logic_vector(19 downto 0):=(OTHERS => '0');
signal Shifter      : std_logic_vector(5 downto 0):=(OTHERS => '0');
signal Flag_int     : std_logic;
signal sum_done     : std_logic;
signal Flg_clean    : std_logic;
signal rate_sum     : std_logic_vector(23 downto 0):=(OTHERS => '0');
----FSM----------
type state is (IDLE, ROW_1, ROW_2, ROW_3, ROW_4, CRC_s, WAIT_RATEMETER);
signal present_state, next_state : state;
attribute keep : string;
attribute keep of present_state : signal is "true";


begin

--=============================================
-- 				   Ratemeter 
--=============================================
ratemeter_sum:process(clk, reset)
begin
	if reset = '1' then
		unix_reg 	 <= (others => '0');
		Shifter 	 <= (others => '0');
		sum_done	 <= '0';
		Flag_int     <= '0';
		partial0_3   <= (others => '0');
		partial4_7   <= (others => '0');
		partial8_11  <= (others => '0');
		partial12_15 <= (others => '0');
		partial16_18 <= (others => '0');
		partial_a    <= (others => '0');
		partial_b    <= (others => '0');
		rate_sum     <= (others => '0');
		
	elsif rising_edge(clk) then
        if Flg_clean = '1' then
            Flag_int <= '0';
            Shifter  <= (others => '0');
        elsif  PPS = '1' and  PPS_ch_en  = '1' then
            unix_reg  	<= unixtime;
            Flag_int 	<= '1';
        else
            --shifter for delay
            Shifter   <= Shifter(4 downto 0) & Flag_int;
        end if;	 
        
        --sommatore ratemeter in pipeline
        partial0_3   <= ("00" & ratemeter(0))  + ("00" & ratemeter(1))  + ("00" & ratemeter(2))  + ("00" & ratemeter(3));
        partial4_7   <= ("00" & ratemeter(4))  + ("00" & ratemeter(5))  + ("00" & ratemeter(6))  + ("00" & ratemeter(7));
        partial8_11  <= ("00" & ratemeter(8))  + ("00" & ratemeter(9))  + ("00" & ratemeter(10)) + ("00" & ratemeter(11));
        partial12_15 <= ("00" & ratemeter(12)) + ("00" & ratemeter(13)) + ("00" & ratemeter(14)) + ("00" & ratemeter(15));
        partial16_18 <= ("00" & ratemeter(16)) + ("00" & ratemeter(17)) + ("00" & ratemeter(18));
        partial_a    <= ("00" & partial0_3)    + ("00" & partial4_7)    + ("00" & partial8_11);
        partial_b    <= ("00" & partial12_15)  + ("00" & partial16_18);
        rate_sum     <= "000" & ('0' & partial_a) + ('0' & partial_b);

        sum_done  <= Shifter(5);
	end if;
end process;

--=============================================
-- 						FSM 
--=============================================
FSM_sync_proc: process(clk, present_state, next_state)
begin
  if rising_edge(clk) then
     if reset = '1' or PPS_ch_en = '0' then
        present_state <= IDLE;
        CRC           <= (OTHERS => '0');
     else
        present_state <= next_state;
        
        read_done_r <= read_done;
        PPS_r       <= PPS;

     -- calcuate CRC
    if present_state = ROW_1 and next_state = ROW_2 then
        CRC <= CRC32(arr => word_to_FIFO_s);
    elsif present_state = ROW_2 and next_state = ROW_3 then
        CRC <= CRC32(arr => word_to_FIFO_s) xor CRC;
    elsif present_state = ROW_3 and next_state = CRC_s then
        CRC <= CRC32(arr => word_to_FIFO_s) xor CRC;
    elsif present_state = CRC_s and next_state = ROW_4 then
        CRC <= CRC32(arr => word_to_FIFO_s) xor CRC;
    end if;
        
     -- write_done signal
     if read_done = '1' and read_done_r = '0' then
         read_done_sync <= '1';
     else
         read_done_sync <= '0';
     end if;    
    
     if present_state = ROW_4 and next_state = IDLE then
         wr_done <= '1';
     elsif read_done_sync = '1' and empty = '1' then
         wr_done <= '0';
     end if;
        
     end if;
  end if;
end process;

FSM_state_decode: process(present_state, pps_r, wr_ack, sum_done, HF_FIFO)
begin

    next_state <= present_state;

    case present_state is
    
    when IDLE =>
        Flg_clean      <= '0';
        wr_en          <= '0';
        word_to_fifo_s <= (OTHERS => '1');
        if pps_r = '1' and HF_FIFO = '0'  then
            next_state <= WAIT_RATEMETER;
        end if;  
        
    when WAIT_RATEMETER =>
        wr_en <= '0';
        if sum_done = '1' then
            next_state <= ROW_1;
        end if;    
        
    when ROW_1 =>
        wr_en          <= '1';
        word_to_fifo_s <= "10" & "1111" & unix_reg(25 downto 0); -- 10+PPSevent(4)+unixtime(26)
        if wr_ack = '1' then
            wr_en      <= '0';
            Flg_clean  <= '1';
            next_state <= ROW_2;
        end if;
        
    when ROW_2 =>
        wr_en          <= '1';
        Flg_clean      <= '0';
        word_to_fifo_s <= "00" & unix_reg(31 downto 26) & rate_sum; -- 00+unixtime(6)+ratemeter(24)
        if wr_ack = '1' then
            wr_en      <= '0';
            next_State <= ROW_3;
        end if;
        
    when ROW_3 =>
        wr_en          <= '1';
        word_to_fifo_s <= "01" & extclk0status & extclk1status & PLL_locked & pow_cons_ok & voltage_ok & unix_error & humidity & temperature; -- 01+statemPMT(6)+humidity(12)+temperature(12)
        if wr_ack = '1' then
            wr_en      <= '0';
            next_state <= CRC_s;
        end if;
        
   when CRC_s =>
        next_state     <= ROW_4; 
        word_to_fifo_s <= "11" & "0000" & "1111111111" & dead_time_s; -- 11+CRC(4)+stateCH(11)+dead_time(16)

              
    when ROW_4 =>
        wr_en          <= '1';
        word_to_fifo_s <= "11" & CRC & "1111111111" & dead_time_s; -- 11+CRC(4)+stateCH(11)+dead_time(16)
        if wr_ack = '1' then
            wr_en          <= '0';
            next_state     <= IDLE; 
            word_to_fifo_s <= (OTHERS => '1');
        end if; 
           
    when others =>
        wr_en          <= '0';
        word_to_fifo_s <= (OTHERS => '1');
        next_state     <= IDLE;
        
    end case;
end process;

--==================================================================
--  					Dead time
--==================================================================
DadTime_proc: process(clk, reset, HF_FIFO)
begin
	if reset = '1' then
		dead_time_s  <= (OTHERS => '0');
        dead_counter <= (OTHERS => '0');
	elsif rising_edge(clk) then
	
        if pps = '1' then
            dead_time_s  <= dead_counter;
            dead_counter <= (OTHERS => '0');
        elsif (COUNTER200M(11 downto 0) = 0 ) and (dead_counter < X"FFFF") and (HF_FIFO = '0') then
            dead_counter <=	dead_counter + 1;
        end if;				
		
	end if;
end process;

word_to_fifo <= word_to_fifo_s;
dead_time    <= dead_time_s;

end Behavioral;