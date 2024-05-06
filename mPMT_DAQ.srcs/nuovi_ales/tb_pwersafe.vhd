library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_pwersafe is
--  Port ( );
end tb_pwersafe;

architecture Behavioral of tb_pwersafe is

component safe_poweron is
    Port ( CLK : in STD_LOGIC;
           RST : in STD_LOGIC;
           Pen_in : in STD_LOGIC_VECTOR (18 downto 0);
           Pen_out : out STD_LOGIC_VECTOR (18 downto 0));
end component;

signal clk: STD_LOGIC;
signal rst: STD_LOGIC;
signal pen_in: STD_LOGIC_VECTOR(18 downto 0);
signal pen_out: STD_LOGIC_VECTOR(18 downto 0);

begin

uut:safe_poweron
    port map(
            CLK     => clk,
            RST     => rst,
            Pen_in  => pen_in,
            Pen_out => pen_out
            );

clk_proc:process
begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
end process clk_proc;

main_proc:process
begin
    rst <= '1';
    wait for 20 ns;
    rst <= '0';
    wait for 80 ns;
    
    pen_in <= "111" & X"66C7";
    wait for 200 ns;
    pen_in <= (others => '0');
    wait for 200 ns;
    pen_in <= "000" & X"AAD5";
    wait;
    
end process main_proc;


end Behavioral;
