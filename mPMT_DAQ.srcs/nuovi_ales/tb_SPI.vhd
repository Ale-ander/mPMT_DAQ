library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_SPI is
end tb_SPI;

architecture Behavioral of tb_SPI is

component SPI_buono is
    Port ( clk : in  STD_LOGIC;
           enable : in  STD_LOGIC;
		   calibrazione : in STD_LOGIC;
		   pow_up : in STD_LOGIC;
           miso : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           
           
           chip_select : out STD_LOGIC;
           scrivi : out STD_LOGIC;
           sclk : out  STD_LOGIC;
           data_out : out  STD_LOGIC_VECTOR (12 downto 0));
end component;

signal clk: STD_LOGIC;
signal enable: STD_LOGIC;
signal sclk: STD_LOGIC;
signal calibrazione: STD_LOGIC;
signal pow_up: STD_LOGIC;
signal miso: STD_LOGIC;
signal chip_select: STD_LOGIC;
signal scrivi: STD_LOGIC;
signal reset: STD_LOGIC;
signal data_out: STD_LOGIC_VECTOR(12 downto 0);

begin

uut:SPI_buono
    port map(
        clk => clk,
        enable => enable,
        sclk => sclk,
		calibrazione => calibrazione,
		pow_up => pow_up,
        miso => miso,
        chip_select => chip_select,
        scrivi => scrivi,
        reset => reset,
        data_out => data_out);
        
clk_proc:process
begin
    clk <= '1';
    wait for 2.5 ns;
    clk <= '0';
    wait for 2.5 ns;
end process clk_proc;

main_proc:process
begin
    reset <= '1';
    enable <= '0';
    calibrazione <= '0';
    pow_up <= '0';
    miso <= '1';
    wait for 10 ns;
    reset <= '0';
    wait for 500 ns;
    enable <= '1';
    
    wait;
    
end process main_proc;



end Behavioral;
