library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.STD_LOGIC_arith.ALL;

entity SPI_handler is
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
end SPI_handler;

architecture Behavioral of SPI_handler is

component SPI_ADC_MS is
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
end component;

component OSCILLATORE is
    generic (add : STD_LOGIC_vector(4 downto 0));
    Port ( EN 		: in  STD_LOGIC;
           FREQ 	: out  STD_LOGIC);
end component;

signal Pulse_count   : STD_LOGIC_VECTOR(5 downto 0);
signal DATA_out_SPI : STD_LOGIC_VECTOR(11 downto 0);

signal D_Valid_SPI   : STD_LOGIC;
signal D_Valid_SPI_r : STD_LOGIC;
signal Busy_SPI      : STD_LOGIC;
signal enable_SPI    : STD_LOGIC;
signal enable_osc    : STD_LOGIC;
signal Reset_SPI     : STD_LOGIC;
signal osc_out       : STD_LOGIC;
signal Reset_Ring    : STD_LOGIC;
signal Calibration_r : STD_LOGIC;
signal Do_calib      : STD_LOGIC;
signal Calib_done    : STD_LOGIC;

signal ttp_counter   : integer range 0 to 4096;

type state is (RESET_s, IDLE, PW_ON, WAIT_CALIB, WAIT_DATA, END_SPI);
signal present_state, next_state : state;
attribute fsm_encoding : string;
attribute fsm_encoding of present_state : signal is "sequential";

begin

--===========================================
--              SPI FSM
--===========================================
SPI: SPI_ADC_MS
    port map(
        CLK200      => CLK,
        Reset       => Reset,
        Start       => enable_SPI,
        Reset_SPI   => Reset_SPI,
        Pulse_count => Pulse_count,
        SDI         => SDI,
        SCLK        => SCLK,
        CS          => CS,
        DATA_out    => DATA_out_SPI,
        D_Valid     => D_Valid_SPI,
        Busy        => Busy_SPI       
    );

--===========================================
--              Oscillator
--===========================================
Oscillator: OSCILLATORE
    generic map( add => add)
    port map(
        EN   => enable_osc,
        FREQ => osc_out
        );

FSM_sync_proc: process(CLK)
begin
    if rising_edge(CLK) then
        if Reset = '1' then 
            Do_calib      <= '0';
            present_state <= Reset_s;
            DATA_out      <= (others => '0');
            
        else
            
            D_Valid_SPI_r <= D_valid_SPI;
            Calibration_r <= Calibration;
            present_state <= next_state;
            
            if Calibration = '1' and Calibration_r = '0' then
                Do_calib <= '1';
            elsif Calib_done = '1' then 
                Do_calib <= '0';
            end if;    
        
            if D_Valid_SPI = '1' and D_Valid_SPI_r = '0' then
                DATA_out <= DATA_out_SPI;
            end if;
        
        end if;
    end if;
end process;


FSM_state_decode: process(present_state, next_state, Busy_SPI, Do_calib)
begin

      next_state <= present_state;
       
      case present_state is
      
        when Reset_s =>
            reset_SPI <= '0';
            Pulse_count <= "010000"; -- 16 clock counts
            Calib_done <= '0';
            if Busy_SPI = '1' then
                next_state <= PW_ON;
            else
                next_state <= Reset_s;
            end if;
            
        when PW_ON =>
            reset_SPI   <= '0';
            Pulse_count <= "010000"; -- 16 clock counts
            Calib_done <= '0';
            if Busy_SPI = '0' then
                next_state <= IDLE;
                reset_SPI  <= '1';
            else
                next_state <= PW_ON;
            end if;
        
        when IDLE =>
            reset_SPI   <= '0';
            Pulse_count <= "001110"; -- 14 clock counts
            Calib_done <= '0';
            if Busy_SPI = '1' then
                if Do_calib = '1' then
                    next_state <= WAIT_CALIB;
                else 
                    next_state <= WAIT_DATA;
                end if;
            else
                next_state <= IDLE;
            end if;
            
        when WAIT_CALIB =>
            reset_SPI   <= '0';
            Pulse_count <= "100000"; -- 32 clock counts
            Calib_done <= '0';
            if Busy_SPI = '0' then
                next_state <= IDLE;
                reset_SPI  <= '1';
                Calib_done <= '1';
            else
                next_state <= WAIT_CALIB;
            end if;
            
        when WAIT_DATA =>
            reset_SPI <= '0';
            Calib_done <= '0';
            if Busy_SPI = '0' then
                next_state <= IDLE;
                reset_SPI  <= '1';
            else
                next_state <= WAIT_DATA;
           end if;
            
        when others => 
            reset_SPI   <= '0';
            Pulse_count <= "010000"; -- 16 clock counts
            Calib_done <= '0';
            
      end case;
end process;


-------------------------------
--        Trigger
-------------------------------
trigger_capture:process(Reset_Ring, Reset, trigger)
begin
	if Reset_Ring = '1' or reset = '1' then
	   enable_osc   <= '0';
	elsif rising_edge(trigger) then
       enable_osc   <= '1';
	end if;
end process;

-------------------------------
--        Time to peak
-------------------------------
peak_finder:process(enable_osc, reset, osc_out)
begin
    if enable_osc = '0' or reset = '1' then
        ttp_counter <= 0;
        enable_SPI  <= '0';
        Reset_Ring  <= '0';
        
    elsif rising_edge(osc_out) then
        ttp_counter <= ttp_counter + 1;
        
        if ttp_counter < Time_to_peak then
            enable_SPI <= '0';
            Reset_Ring <= '0';
        elsif ttp_counter = Time_to_peak + 10 then
            Reset_Ring <= '1';
            enable_SPI <= '1';
        else
            enable_SPI <= '1';
            Reset_Ring <= '0';
        end if;
        
    end if;
end process;

Busy <= Busy_SPI;

end Behavioral;
