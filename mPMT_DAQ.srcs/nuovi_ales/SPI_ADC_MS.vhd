library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library unisim;
use unisim.vcomponents.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;


entity SPI_ADC_MS is
    Port ( CLK200      : in STD_LOGIC;
           RESET       : in STD_LOGIC;
           Start       : in STD_LOGIC;
           Reset_SPI   : in STD_LOGIC;
           Pulse_count : in STD_LOGIC_VECTOR(5 downto 0);
           
          -- SPI 
           SDI      : in STD_LOGIC;
           SCLK     : out STD_LOGIC;
           CS       : out STD_LOGIC;
           
         -- OUT
           DATA_out : out STD_LOGIC_VECTOR (11 downto 0);
           D_Valid  : out STD_LOGIC;
           Busy     : out STD_LOGIC);
end SPI_ADC_MS;

architecture Behavioral of SPI_ADC_MS is

signal SCLK_int     : std_logic;
signal Start_r      : std_logic;
signal Start_rr     : std_logic;
signal Busy_int     : std_logic;
signal SCLKen       : std_logic;
signal Rescount_int : std_logic;

signal Data_out_int : std_logic_vector(12 downto 0);

signal count     : std_logic_vector(5 downto 0);
signal countfast : std_logic_vector(3 downto 0);

signal t_shifter : std_logic_vector(2 downto 0);

type state is (IDLE, RECEIVE, DATA_READY, T_ACQ);
signal present_state, next_state : state;
attribute fsm_encoding : string;
attribute fsm_encoding of present_state : signal is "sequential";

begin

SCLK_gen:process(CLK200, countfast, Reset, Rescount_int, Data_out_int, SDI, count, present_state, next_state)
begin
    if rising_edge(CLK200) then
        if reset = '1' then
            present_state <= IDLE;
            countfast     <= "0000";
            Start_r       <= '0';
            Start_rr      <= '0';
            DATA_out_int  <= (others => '0');
            count         <= (others => '0');
            SCLK_int      <= '0';       
            t_shifter     <= (others => '0');
        else
            present_state <= next_state;
            
            Start_r   <= Start;
            Start_rr  <= Start_r;
            
            if present_state = RECEIVE and next_state = T_ACQ then
                t_shifter <= t_shifter(1 downto 0) & '1';
            else
                t_shifter <= t_shifter(1 downto 0) & '0';
            end if; 
             
            if SCLKen = '1' then
                countfast <= countfast + '1';
                if countfast = "1001" then
                    countfast <= "0000";
                end if;
            else 
                countfast <= "0000";
            end if;        
            
            if countfast < 5 then -- 20MHz high
                SCLK_int  <= '1';
            
            elsif 5 <= countfast then  -- 20MHz low
                SCLK_int  <= '0';
            end if;
            
            if countfast = 5 then -- Rising edge 20MHz ADC sampling
                DATA_out_int <= Data_out_int(11 downto 0) & SDI;    
                count        <= count + '1';  
            elsif Rescount_int = '1' then  -- reset ADc bit counte
                count <= (others => '0');
            end if;      
        end if;
    end if;
end process;

FSM_state_decode: process (present_state, next_state, Start_r, Start_rr, count, Reset_SPI, Pulse_count, t_shifter)
begin

      next_state <= present_state;
       
      case present_state is
      
        when IDLE =>
            Busy_int     <= '0';
            D_Valid      <= '0';
            SCLKen       <= '0';
            Rescount_int <= '1';
            if Start_r = '1' and Start_rr = '0' then
                next_state <= RECEIVE; 
            else 
                next_state <= IDLE;      
            end if;
            
        when RECEIVE =>
            Busy_int     <= '1';
            SCLKen       <= '1';
            Rescount_int <= '0';
            if count = 14 then
                D_Valid <= '1';
            else
                D_Valid <= '0';
            end if;
            if count = Pulse_count then
                next_state <= T_ACQ;
            else           
                next_state <= RECEIVE;
            end if;         
            
        when T_ACQ =>
            Busy_int     <= '1';
            D_Valid      <= '0';
            SCLKen       <= '0';
            Rescount_int <= '0';
            if t_shifter(2) = '1' then
                next_state <= DATA_READY;
            else 
                next_state <= T_ACQ;
            end if; 
            
        when DATA_READY =>
            Busy_int     <= '0';
            D_Valid      <= '0';
            SCLKen       <= '0';
            Rescount_int <= '0';
            if Reset_SPI = '1' then
                next_state <= IDLE;
            else
                next_state <= DATA_READY;
            end if;      
            
        when others => 
            Busy_int     <= '0';
            D_Valid      <= '0';
            SCLKen       <= '0';
            Rescount_int <= '0';
            next_state   <= IDLE;
            
      end case;
end process;

CS       <= not (Busy_int or Start);
Busy     <= Busy_int;
Data_out <= Data_out_int(11 downto 0);
SCLK     <= SCLK_int;

end Behavioral;

