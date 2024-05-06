library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library unisim;
use unisim.vcomponents.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.STD_LOGIC_ARITH.ALL; 


entity tb_SPI_handler is
end tb_SPI_handler;

architecture Behavioral of tb_SPI_handler is

component SPI_handler is
    Generic( add    : STD_LOGIC_VECTOR(4 downto 0):= "00000");
    Port ( CLK      : in STD_LOGIC;
           Reset    : in STD_LOGIC;
           
           -- IN
           Calibration  : in STD_LOGIC;
           Trigger      : in STD_LOGIC;
           Time_to_peak : in STD_LOGIC_VECTOR(10 downto 0);
           
           -- SPI 
           SDI      : in STD_LOGIC;
           SCLK     : out STD_LOGIC;
           CS       : out STD_LOGIC;
          
           Busy     : out STD_LOGIC;
           DATA_out : out STD_LOGIC_VECTOR (11 downto 0));
end component;

signal CLK         : STD_LOGIC;
signal Reset       : STD_LOGIC;
signal Calibration : STD_LOGIC;
signal start       : STD_LOGIC;
signal SDI         : STD_LOGIC;
signal SCLK        : STD_LOGIC;
signal D_Valid     : STD_LOGIC;
signal CS          : STD_LOGIC;
signal Busy        : STD_LOGIC;

signal Time_to_peak : STD_LOGIC_VECTOR(10 downto 0);
signal DATA_out     : STD_LOGIC_VECTOR(11 downto 0);

type TV is array(0 to 15) of integer;
signal Vettore      : TV := (1, 2, 10, 20, 30, 40, 55, 12, 15, 33, 45, 22, 44, 88, 99, 14);
signal Indice       : integer range 0 to 15 ;
signal DAC_VAL_INT  : STD_LOGIC_VECTOR (13 downto 0);

constant MaxD       : STD_LOGIC_VECTOR (4 downto 0) := "00011";

begin

uut:SPI_handler
    generic map(add => "00000")
    port map(
        CLK          => CLK,
        Reset        => Reset,
        Calibration  => Calibration,
        Trigger      => start,
        Time_to_peak => Time_to_peak,
        SDI          => SDI,
        SCLK         => SCLK,
        CS           => CS,
        Busy         => Busy,
        DATA_out     => DATA_out
        );
        
clocking200: process -- CLK 200MHz
begin
    CLK <= '1';
    wait for 2.5 ns;
    CLK <= '0';
    wait for 2.5 ns;
end process;

main_proc: process
begin
      reset <= '1';
      start <= '0';
      Calibration <= '0';
      Time_to_peak <= "000" & X"1D"; 
      wait for 60 ns;
      reset <= '0';
  
      wait for 101 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      Indice <= Indice + 1;
      
      wait for 72 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      Indice <= Indice + 1;
      
      wait for 95 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      Indice <= Indice + 1;
      
      wait for 56 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      Indice <= Indice + 1;
      
      wait for 80 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      Indice <= Indice + 1;
      
      wait for 64 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      Indice <= Indice + 1;
            
      wait for 10 ns;
      Calibration <= '1';
      wait for 5 ns;
      Calibration <= '0';      
            
      wait for 51 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      Indice <= Indice + 1;
      
      wait for 97 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      Indice <= Indice + 1;
      
      wait for 59 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      Indice <= Indice + 1;
      
      wait for 52 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      Indice <= Indice + 1;
      
      wait for 96 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      Indice <= Indice + 1;
      
      wait for 87 ns;
      start <= '1';
      wait for 20 ns;
      reset <= '1';
      wait for 5 ns;
      reset <= '0';
      start <= '0';
      Indice <= Indice + 1;
      
      wait for 72 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      Indice <= Indice + 1;
      
      wait for 59 ns;
      start <= '1';
      wait for 800 ns;
      start <= '0';
      Indice <= Indice + 1;
      
      wait;
end process main_proc;

  
---------------------------------------------
--    Processo  l'ADC  ADS7049
---------------------------------------------
inst_ADC : process(SCLK, CS, Reset, Start)
begin
    if reset = '1' then
       DAC_VAL_INT <= (others => '0');
	elsif falling_edge(CS) then
	   DAC_VAL_INT <=  conv_std_logic_vector(Vettore(Indice), DAC_VAL_INT'length);
	elsif falling_edge(SCLK) then
	   DAC_VAL_INT <= DAC_VAL_INT(12 downto 0) & '0' ;  
    end if;
end process; 

SDI <= DAC_VAL_INT(13); -- Assegna l'uscita
 -------------------------------------------------------------- 
 ---------------------------------------------------------------                 
               

end Behavioral;
