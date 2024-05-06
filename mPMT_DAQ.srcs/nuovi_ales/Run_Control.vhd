library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use UNISIM.vcomponents.all;
use work.instruction_buffer_type.all;


entity Run_Control is
    GENERIC (  Base_ADDR   : STD_LOGIC_VECTOR (7  downto 0)  := X"00" ); -- Base address
 
    Port ( 
        USB_CLK 		: in  STD_LOGIC;                     -- clk @48MHz
        reset 			: in  STD_LOGIC;                     -- board reset
        
        -- Comunication
        Data_IN 		: in  STD_LOGIC_VECTOR(15 downto 0);
        Data_OUT 		: out STD_LOGIC_VECTOR(15 downto 0);
        ADDR 			: in  STD_LOGIC_VECTOR(15 downto 0);
        WR 				: in  STD_LOGIC;
        RD  			: in  STD_LOGIC;

        -- From RESET MODULE
        CLK_failed	    : in  STD_LOGIC;                     -- NOT IN USE NOW
        -- From CLK SAFE
        CLK_OK 	        : in  STD_LOGIC;                     -- CLK ok flag
        CLK_lost        : in  STD_LOGIC;                     -- CLK lost flag
        CLK_found       : in  STD_LOGIC;                     -- CLK found flag
        -- From Multychannel
        ratemeters	    : in Freq_ARRAY;                     -- ratemeters of all channels
        dead_time       : in STD_LOGIC_VECTOR(15 downto 0);  -- dead time from pps channel
        -- From PLL
        PLL_locked		: in  STD_LOGIC;                     -- locked PLL flag
        -- From Pulser        
        PPS_count    	: in  STD_LOGIC_VECTOR(15 downto 0); -- seconds counted from boot
        Tag_0res_OK		: in  STD_LOGIC_VECTOR(1 downto 0);  -- b0 = Tag0_OK, b1 = TagRes_OK (reset is not used anymore)
        -- From PCB
        overcurrent   	: in  STD_LOGIC_VECTOR(18 downto 0); -- overcurrent values  
        -- From FIFO
        HF_FIFO		    : in  STD_LOGIC;                     -- global FIFO half-full
        
        -- To FIFO
        FIFO_rst_rc     : out STD_LOGIC;                     -- internal FIFO reset/clear       
        -- To CLOCK SAFE            
        CLK_mux_autman  : out  STD_LOGIC;                    -- 1 = Automatic 0 = Manual
        CLK_mux_extint  : out  STD_LOGIC;                    -- if CLK_SEL_out = 0 --> 1 = External 0 = Internal
        Res_CLKSF       : out  STD_LOGIC;                    -- reset flag for handshaking with CLOCK SAFE
        -- To Multychannel
        reset_mchannel  : out  STD_LOGIC;                    -- reset only multychannel
        time_to_peaks   : out  Peak_ARRAY;                   -- time to peak values
        TDC_delay 		: out  Delay_ARRAY;                  -- TDC programmable delay
        ch_enable 	    : out  STD_LOGIC_VECTOR(18 downto 0);-- enable acquisition (mentre la fsm di boot/reset è in wip)
        power_en		: out  STD_LOGIC_VECTOR(18 downto 0);-- single channel power enable
        PPS_ch_en	    : out  STD_LOGIC;                    -- PPS channel enable 
        calibration 	: out  STD_LOGIC;                    -- calibration flag for the ADC 
        timeout         : out STD_LOGIC_VECTOR(8 downto 0);  -- value to count to timeout the raead
        -- To Pulser
        pulser_freq_ms  : out  STD_LOGIC_VECTOR(13 downto 0);-- pulser frequency in ms
        Res_pulser	    : out  STD_LOGIC;                    -- handshaking with pulser for reset of flags
        start_val_Tag0  : out  STD_LOGIC_VECTOR(15 downto 0) -- base value from wich the 200MHz counter starts
        );
          
end Run_Control;

architecture Behavioral of Run_Control is

--===================================================================================
-- 			                      SIGNALS
--===================================================================================
----CLK SAFE------- 
signal CLK_reg          : STD_LOGIC_VECTOR(2 downto 0);
signal CLK_mux_autman_s : STD_LOGIC;
signal CLK_mux_extint_s : STD_LOGIC;
----MULTYCHANNEL---
signal reset_mchannel_s : STD_LOGIC;
signal peaks            : Peak_ARRAY;
signal delays           : Delay_ARRAY;
signal ch_enable_s      : STD_LOGIC_VECTOR(18 downto 0);
signal power_en_s       : STD_LOGIC_VECTOR(18 downto 0);
signal chip_select_s    : STD_LOGIC_VECTOR(18 downto 0);
signal timeout_s        : STD_LOGIC_VECTOR(8 downto 0);
signal PPS_ch_en_s      : STD_LOGIC;
signal calibration_s    : STD_LOGIC; 
----PULSER--------
signal pulser_freq_ms_s : STD_LOGIC_VECTOR(13 downto 0);
signal start_val_Tag0_s : STD_LOGIC_VECTOR(15 downto 0);
----FIFO----------
signal FIFO_rst_s       : STD_LOGIC;

begin

-- RUN CONTROL e Rate meter
process(RESET, USB_CLK)  -- Slow control interface
begin
if RESET = '1' then
    CLK_reg          <= (OTHERS =>'0');
    CLK_mux_autman_s <= '1';
    CLK_mux_extint_s <= '0';
    peaks            <= (OTHERS => "00000110000");    -- 48
    delays           <= (OTHERS => "00001010");       -- 10
    ch_enable_s      <= (OTHERS => '1');
    power_en_s       <= (OTHERS => '1');
    PPS_ch_en_s      <= '0';
    calibration_s    <= '0';
    reset_mchannel_s <= '0';
    Res_CLKSF        <= '0';
    Res_pulser       <= '0';
    pulser_freq_ms_s <= (OTHERS => '0');
    start_val_Tag0_s <= (OTHERS => '0');
	Data_OUT         <= (OTHERS => '1');
	timeout_s        <= "011001000";
	FIFO_rst_s       <= '0';
	

elsif rising_edge(USB_CLK) then 

-- Synchronize the signals				
	Data_OUT       <= (OTHERS => '0');  
	CLK_mux_autman <= CLK_mux_autman_s;
	CLK_mux_extint <= CLK_mux_extint_s;
	CLK_reg        <= CLK_ok & CLK_lost & CLK_found;
	reset_mchannel <= reset_mchannel_s;
	time_to_peaks  <= peaks;
	TDC_delay      <= delays;
	ch_enable      <= ch_enable_s;
	power_en       <= power_en_s;
	PPS_ch_en      <= PPS_ch_en_s;   
	calibration    <= calibration_s;
	pulser_freq_ms <= pulser_freq_ms_s;
	start_val_Tag0 <= start_val_Tag0_s; 
	timeout        <= timeout_s;
	FIFO_rst_rc    <= FIFO_rst_s;
	    
-- Read
	if ADDR(15 downto 8) = Base_ADDR then
			case ADDR (7 downto 0 ) is
				  when 	X"00"  =>   Data_OUT	<= overcurrent(15 downto 0);
				  when	X"01"  =>	Data_OUT	<= "0000000000000" & overcurrent(18 downto 16);
				  when	X"02"  =>	Data_OUT	<= power_en_s(15 downto 0);
				  when	X"03"  =>	Data_OUT	<= "0000000000000" & power_en_s(18 downto 16);
				  when 	X"04"  =>   Data_OUT 	<= ch_enable_s(15 DOWNTO 0);
				  when 	X"05"  =>   Data_OUT 	<= "0000000000000" & ch_enable_s(18 downto 16);				  
				  when	X"06"  =>   Data_OUT	<= PPS_count;
				  when  X"07"  =>   Data_OUT    <= "00" & pulser_freq_ms_s;
				  when  X"08"  =>   Data_OUT    <= start_val_Tag0_s;
				  when  X"09"  =>   Data_OUT    <= "0000000000" & HF_FIFO & calibration_s & PPS_ch_en_s & reset_mchannel_s & CLK_failed & PLL_locked;   
				  when  X"0A"  =>   Data_OUT    <= "0000" & timeout_s & CLK_reg;
				                    Res_CLKSF   <= RD;
				  when  X"0B"  =>   Data_OUT    <= "00000000000000" & CLK_mux_autman_s & CLK_mux_extint_s;
				  when  X"0C"  =>   Data_OUT    <= "00000000000000" & Tag_0res_OK; 
								    Res_pulser  <= RD ;	
				  -- Read ratemeters
				  when 	X"0D"  =>   Data_OUT	<= ratemeters(0);
                  when 	X"0E"  =>   Data_OUT	<= ratemeters(1);
                  when 	X"0F"  =>   Data_OUT	<= ratemeters(2);
                  when 	X"10"  =>   Data_OUT	<= ratemeters(3);
                  when 	X"11"  =>   Data_OUT	<= ratemeters(4);
                  when 	X"12"  =>   Data_OUT	<= ratemeters(5);
                  when 	X"13"  =>   Data_OUT	<= ratemeters(6);
                  when 	X"14"  =>   Data_OUT	<= ratemeters(7);
                  when 	X"15"  =>   Data_OUT	<= ratemeters(8);
                  when 	X"16"  =>   Data_OUT	<= ratemeters(9);
                  when 	X"17"  =>   Data_OUT	<= ratemeters(10);
                  when 	X"18"  =>   Data_OUT	<= ratemeters(11);
                  when 	X"19"  =>   Data_OUT	<= ratemeters(12);
                  when 	X"1A"  =>   Data_OUT	<= ratemeters(13);
                  when 	X"1B"  =>   Data_OUT	<= ratemeters(14);
                  when 	X"1C"  =>   Data_OUT	<= ratemeters(15);
                  when 	X"1D"  =>   Data_OUT	<= ratemeters(16);
                  when 	X"1E"  =>   Data_OUT	<= ratemeters(17);
                  when 	X"1F"  =>   Data_OUT	<= ratemeters(18);
                  when 	X"20"  =>   Data_OUT	<= dead_time;
                  -- Read time to peak
                  when 	X"21"  =>   Data_OUT(10 downto 0)	<= peaks(0);
                  when 	X"22"  =>   Data_OUT(10 downto 0)	<= peaks(1);
                  when 	X"23"  =>   Data_OUT(10 downto 0)	<= peaks(2);
                  when 	X"24"  =>   Data_OUT(10 downto 0)	<= peaks(3);
                  when 	X"25"  =>   Data_OUT(10 downto 0)	<= peaks(4);
                  when 	X"26"  =>   Data_OUT(10 downto 0)	<= peaks(5);
                  when 	X"27"  =>   Data_OUT(10 downto 0)	<= peaks(6);
                  when 	X"28"  =>   Data_OUT(10 downto 0)	<= peaks(7);
                  when 	X"29"  =>   Data_OUT(10 downto 0)	<= peaks(8);
                  when 	X"2A"  =>   Data_OUT(10 downto 0)	<= peaks(9);
                  when 	X"2B"  =>   Data_OUT(10 downto 0)	<= peaks(10);
                  when 	X"2C"  =>   Data_OUT(10 downto 0)	<= peaks(11);
                  when 	X"2D"  =>   Data_OUT(10 downto 0)	<= peaks(12);
                  when 	X"2E"  =>   Data_OUT(10 downto 0)	<= peaks(13);
                  when 	X"2F"  =>   Data_OUT(10 downto 0)	<= peaks(14);
                  when 	X"30"  =>   Data_OUT(10 downto 0)	<= peaks(15);
                  when 	X"31"  =>   Data_OUT(10 downto 0)	<= peaks(16);
                  when 	X"32"  =>   Data_OUT(10 downto 0)	<= peaks(17);
                  when 	X"33"  =>   Data_OUT(10 downto 0)	<= peaks(18);
                  -- Read TDC delays
                  when 	X"34"  =>   Data_OUT(7 downto 0)	<= delays(0);
                  when 	X"35"  =>   Data_OUT(7 downto 0)	<= delays(1);
                  when 	X"36"  =>   Data_OUT(7 downto 0)	<= delays(2);
                  when 	X"37"  =>   Data_OUT(7 downto 0)	<= delays(3);
                  when 	X"38"  =>   Data_OUT(7 downto 0)	<= delays(4);
                  when 	X"39"  =>   Data_OUT(7 downto 0)	<= delays(5);
                  when 	X"3A"  =>   Data_OUT(7 downto 0)	<= delays(6);
                  when 	X"3B"  =>   Data_OUT(7 downto 0)	<= delays(7);
                  when 	X"3C"  =>   Data_OUT(7 downto 0)	<= delays(8);
                  when 	X"3D"  =>   Data_OUT(7 downto 0)	<= delays(9);
                  when 	X"3E"  =>   Data_OUT(7 downto 0)	<= delays(10);
                  when 	X"3F"  =>   Data_OUT(7 downto 0)	<= delays(11);
                  when 	X"40"  =>   Data_OUT(7 downto 0)	<= delays(12);
                  when 	X"41"  =>   Data_OUT(7 downto 0)	<= delays(13);
                  when 	X"42"  =>   Data_OUT(7 downto 0)	<= delays(14);
                  when 	X"43"  =>   Data_OUT(7 downto 0)	<= delays(15);
                  when 	X"44"  =>   Data_OUT(7 downto 0)	<= delays(16);
                  when 	X"45"  =>   Data_OUT(7 downto 0)	<= delays(17);
                  when 	X"46"  =>   Data_OUT(7 downto 0)	<= delays(18);
                              
				  when others  =>   Data_OUT  <= (OTHERS => '1');
			 end CASE;	
			 
    else
        Res_CLKSF <= '0' ;
	end if ; 
	
-- Write
	if ADDR(15 downto 8) = Base_ADDR and WR ='1' then 
			case ADDR (7 downto 0 ) is			
				  when 	X"02"  =>   power_en_s(15 downto 0)     <= Data_IN;	
				  when 	X"03"  =>   power_en_s(18 downto 16)    <= Data_IN(2 downto 0);	
				  when 	X"04"  =>   ch_enable_s(15 downto 0)    <= Data_IN;
				  when 	X"05"  =>   ch_enable_s(18 downto 16)   <= Data_IN(2 downto 0);
				  when  X"07"  =>   pulser_freq_ms_s            <= Data_IN(13 downto 0);
				  when  X"08"  =>   start_val_Tag0_s            <= Data_IN;
				  when  X"09"  =>   calibration_s               <= Data_IN(4);
				                    PPS_ch_en_s                 <= Data_IN(3);
				                    reset_mchannel_s            <= Data_IN(2);
				  when  X"0A"  =>   timeout_s                   <= Data_IN(8 downto 0);
				  when  X"0B"  =>   CLK_mux_autman_s            <= Data_IN(1);
				                    CLK_mux_extint_s            <= Data_IN(0);	  
				  when  X"0C"  =>   FIFO_rst_s                  <= Data_IN(3); 
				  -- Write time to peak
				  when 	X"21"  =>   peaks(0)                    <= Data_IN(10 downto 0);	
                  when 	X"22"  =>   peaks(1)                    <= Data_IN(10 downto 0);	
                  when 	X"23"  =>   peaks(2)                    <= Data_IN(10 downto 0);	
                  when 	X"24"  =>   peaks(3)                    <= Data_IN(10 downto 0);	
                  when 	X"25"  =>   peaks(4)                    <= Data_IN(10 downto 0);	
                  when 	X"26"  =>   peaks(5)                    <= Data_IN(10 downto 0);	
                  when 	X"27"  =>   peaks(6)                    <= Data_IN(10 downto 0);	
                  when 	X"28"  =>   peaks(7)                    <= Data_IN(10 downto 0);	
                  when 	X"29"  =>   peaks(8)                    <= Data_IN(10 downto 0);	
                  when 	X"2A"  =>   peaks(9)                    <= Data_IN(10 downto 0);	
                  when 	X"2B"  =>   peaks(10)                   <= Data_IN(10 downto 0);	
                  when 	X"2C"  =>   peaks(11)                   <= Data_IN(10 downto 0);	
                  when 	X"2D"  =>   peaks(12)                   <= Data_IN(10 downto 0);	
                  when 	X"2E"  =>   peaks(13)                   <= Data_IN(10 downto 0);	
                  when 	X"2F"  =>   peaks(14)                   <= Data_IN(10 downto 0);	
                  when 	X"30"  =>   peaks(15)                   <= Data_IN(10 downto 0);	
                  when 	X"31"  =>   peaks(16)                   <= Data_IN(10 downto 0);	
                  when 	X"32"  =>   peaks(17)                   <= Data_IN(10 downto 0);	
                  when 	X"33"  =>   peaks(18)                   <= Data_IN(10 downto 0);
                  -- Write TDC delays
                  when 	X"34"  =>   delays(0)                   <= Data_IN(7 downto 0);	
                  when 	X"35"  =>   delays(1)                   <= Data_IN(7 downto 0);	
                  when 	X"36"  =>   delays(2)                   <= Data_IN(7 downto 0);	
                  when 	X"37"  =>   delays(3)                   <= Data_IN(7 downto 0);	
                  when 	X"38"  =>   delays(4)                   <= Data_IN(7 downto 0);	
                  when 	X"39"  =>   delays(5)                   <= Data_IN(7 downto 0);	
                  when 	X"3A"  =>   delays(6)                   <= Data_IN(7 downto 0);	
                  when 	X"3B"  =>   delays(7)                   <= Data_IN(7 downto 0);	
                  when 	X"3C"  =>   delays(8)                   <= Data_IN(7 downto 0);	
                  when 	X"3D"  =>   delays(9)                   <= Data_IN(7 downto 0);	
                  when 	X"3E"  =>   delays(10)                  <= Data_IN(7 downto 0);	
                  when 	X"3F"  =>   delays(11)                  <= Data_IN(7 downto 0);	
                  when 	X"40"  =>   delays(12)                  <= Data_IN(7 downto 0);	
                  when 	X"41"  =>   delays(13)                  <= Data_IN(7 downto 0);	
                  when 	X"42"  =>   delays(14)                  <= Data_IN(7 downto 0);	
                  when 	X"43"  =>   delays(15)                  <= Data_IN(7 downto 0);	
                  when 	X"44"  =>   delays(16)                  <= Data_IN(7 downto 0);	
                  when 	X"45"  =>   delays(17)                  <= Data_IN(7 downto 0);	
                  when 	X"46"  =>   delays(18)                  <= Data_IN(7 downto 0);
                   
				  when others  =>   null ;
			end CASE;
	end if;
				
-- Function power protection
    for i in 0 to 18 loop
        if overcurrent(i)= '0' then
             power_en_s(i) <= '1';
        end if;
    end loop;
        
    end if;
end process;

end Behavioral;