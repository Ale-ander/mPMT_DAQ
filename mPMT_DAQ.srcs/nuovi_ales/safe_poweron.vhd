library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity safe_poweron is
    Port ( CLK : in STD_LOGIC;
           RST : in STD_LOGIC;
           Pen_in : in STD_LOGIC_VECTOR (18 downto 0);
           Pen_out : out STD_LOGIC_VECTOR (18 downto 0));
end safe_poweron;

architecture Behavioral of safe_poweron is

signal count: integer;

begin

process(CLK, RST)
begin
    if rising_edge(CLK) then
        if RST = '1' then
            count   <= 0;
            Pen_out <= (others => '0');
        elsif count = 19 then
            count <= 0;
        else
            Pen_out(count) <= Pen_in(count);            
            count <= count + 1;
        end if;
    end if;
end process;

end Behavioral;
