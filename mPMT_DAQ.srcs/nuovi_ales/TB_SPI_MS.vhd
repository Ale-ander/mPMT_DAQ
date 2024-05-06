----------------------------------------------------------------------------------
-- Company: INFN NA
-- Engineer: AB SER
 
-- Create Date: 22.09.2023 18:27:05
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library unisim;
use unisim.vcomponents.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.STD_LOGIC_ARITH.ALL; 


entity TB_SPI_MS is
--  Port ( );
end TB_SPI_MS;

architecture Behavioral of TB_SPI_MS is

  component SPI_ADC_MS
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
  
-- SEGNALI
-- IN
  signal CLK200  : STD_LOGIC;
  signal Reset   : STD_LOGIC;
  signal START   : STD_LOGIC;
  signal SDI_LG  : STD_LOGIC;
  -- OUT
  signal SCLK    : STD_LOGIC;
  signal DATA_LG : STD_LOGIC_VECTOR (11 downto 0);
  signal D_Valid : STD_LOGIC;
  signal BUSY    : STD_LOGIC;
  signal CS      : STD_LOGIC;
  
-- Segnali Per simulare ADC
  type TV is array(0 to 15) of integer;
  signal Vettore      : TV := (0, 1, 10, 20, 30, 40, 55, 12, 15, 33, 45, 22, 44, 88, 99, 14);
  signal Indice       : integer range 0 to 15 ;
  signal DAC_VAL_INT  : STD_LOGIC_VECTOR (13 downto 0);
  signal Delay        : STD_LOGIC_VECTOR (4 downto 0);
  signal FLG_start    : STD_LOGIC := '0';
  signal Aspetta_Fine : STD_LOGIC := '0';
  signal end_SPI      : STD_LOGIC := '0';
  signal pulse_count  : STD_LOGIC_VECTOR(5 downto 0):= "001110";
  signal reset_spi    : STD_LOGIC := '0';
 
  constant MaxD       : STD_LOGIC_VECTOR (4 downto 0) := "00011";


begin

uut: SPI_ADC_MS 
    port map ( 
        CLK200     => CLK200,
        Reset   => Reset,
        START   => START,
        reset_spi => reset_spi,
        pulse_count => pulse_count,
        SCLK    => SCLK,
        sdi  => SDI_LG,
        CS => CS,
        data_out => DATA_LG,
        D_Valid => D_Valid,
        BUSY    => BUSY 
        );
  
clocking200: process -- CLK 200MHz
begin
CLK200 <= '1';
wait for 2.5 ns;
CLK200 <= '0';
wait for 2.5 ns;
end process;

main_proc: process
begin
reset <= '1';
start <= '0';
  wait for 60 ns;
  reset <= '0';
  
      wait for 101 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      
      wait for 72 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      
      pulse_count <= "100000";
      
      wait for 95 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      
      wait for 56 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      
      wait for 40 ns;
      pulse_count <= "001110";
      
      wait for 40 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      
      wait for 64 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
            
      wait for 51 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      
      wait for 97 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      
      wait for 59 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      
      wait for 32 ns;
      pulse_count <= "010000";

      
      wait for 32 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      
      wait for 26 ns;
      pulse_count <= "001110";
      
      wait for 26 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      
      wait;
  end process main_proc;
  
  
-- Processo invia i dati in sequenza
MMAIN : process(Reset, CLK200)
begin
	if Reset = '1' then
  
        Indice          <= 0; 
        Delay           <= (others => '0');
        FLG_start       <= '0';
        Aspetta_Fine    <= '0';
        reset_spi       <= '0';
        
	elsif rising_edge(CLK200) then
	
        if (Delay < MaxD and FLG_start = '0') then
            Delay <= Delay +1;
        elsif  (Delay = MaxD) then
            Delay  <= (others => '0');
            FLG_start <= '1';
            
            if (Indice < 15) then
               Indice <= Indice + 1;
            else    
                Indice <= 0;
            end if;    
          
        end if;  
        
        if (FLG_start = '1' and BUSY = '1' ) then -- Aspetta che arriva busy
          Aspetta_Fine <= '1';
          
       elsif ( Aspetta_Fine = '1' and BUSY = '0') then -- Aspetta che finisce la conversione SPI
         Aspetta_Fine   <= '0';
         FLG_start      <= '0';
       
       end if;                 
       
       if busy = '0' then
         reset_spi <= '1';
       else
         reset_spi <= '0';
       end if;

  end if;
end process;
  
--START <=  FLG_start;
  
 ---------------------------------------------
 --    Processo  l'ADC  ADS7049
 ---------------------------------------------
inst_ADC : process (START, reset, SCLK)
begin
	if (START = '0' or reset = '1') then
	   DAC_VAL_INT <=  conv_std_logic_vector(Vettore(Indice), DAC_VAL_INT'length);
	elsif falling_edge(SCLK) then
	   DAC_VAL_INT <= DAC_VAL_INT(12 downto 0) & '0' ;  
    end if;
end process; 

SDI_LG <= DAC_VAL_INT(13); -- Assegna l'uscita
 -------------------------------------------------------------- 
 ---------------------------------------------------------------                 
    
    
                          

end Behavioral;

