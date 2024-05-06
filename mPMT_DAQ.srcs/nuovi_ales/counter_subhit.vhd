library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_subhit is
    Port ( clk    : in STD_LOGIC;
           reset  : in STD_LOGIC;
           enable : in STD_LOGIC;
           count  : out STD_LOGIC_VECTOR (13 downto 0));
end counter_subhit;

architecture Behavioral of counter_subhit is

signal count_s : std_logic_vector(13 downto 0);

begin

conta:process(clk, reset, enable)
begin
    if rising_edge(clk) then
        if reset = '1' or enable = '0' then
            count_s <= (OTHERS => '0');
        else
            count_s <= std_logic_vector(unsigned(count_s) + 1 );
        end if;
    end if;
end process conta;

count <= count_s;

end Behavioral;
