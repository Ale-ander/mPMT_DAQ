library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package instruction_buffer_type is

    TYPE Data32_ARRAY is array(0 to 19) of std_logic_vector(31 downto 0); -- data array at 32 bit (19 + 1 channels)
	TYPE Freq_ARRAY   is array(0 to 18) of std_logic_vector(24 downto 0); -- ratemeter array 25 bit (19 channels)
	TYPE Peak_ARRAY   is array(0 to 18) of std_logic_vector(11 downto 0); -- time to peak array 11 bit (19 channels)
	TYPE Delay_ARRAY  is array(0 to 18) of std_logic_vector(7 downto 0);  -- TDC delay array 8 bit (19 channels)

end package instruction_buffer_type;