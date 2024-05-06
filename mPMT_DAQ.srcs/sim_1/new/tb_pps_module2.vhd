library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_pps_module2 is
end tb_pps_module2;

architecture Behavioral of tb_pps_module2 is

component pps_module2 is
	generic (C_MAX       : integer:= 199_999_999 ); -- Counts to 1 second at 200MHz
    Port ( 
           -- IN
           CLK_25MHZ 		  : in STD_LOGIC; -- CLK with Tags
		   CLK_200MHZ 		  : in STD_LOGIC; -- Main CLK
		   CLK_200MHZ_1 	  : in STD_LOGIC; -- Main CLK out of phase for metastability problems
		   RESET 			  : in STD_LOGIC; -- Reset component
		   RunC_Res_FLG  	  : in STD_LOGIC; -- Handshaking with RC
		   Runc_Val_Tag0	  : in STD_LOGIC_VECTOR(15 downto 0); -- latency (insert value + 3)
		   UnixTime_ARM 	  : in STD_LOGIC_VECTOR(31 downto 0); -- Unix from ARM
		   Rst_Unix_Time      : in STD_LOGIC;                     -- Reset Unix_Time_na register
		   -- OUT
		   PPS_OUT 		      : out STD_LOGIC;                     -- Pulse Per Second (PPS)
		   RunC_PPS_na		  : out STD_LOGIC;                     -- 0 = PPS not aligned, 1 = PPS aligned
		   RunC_PPS_nr		  : out STD_LOGIC;                     -- 0 = PPS not received, 1 = PPS received 
		   CONTA 			  : out STD_LOGIC_VECTOR(27 downto 0); -- 200MHz clock counter
		   COUNTA_sec 		  : out STD_LOGIC_VECTOR(31 downto 0); -- PPS counter
		   Unix_Time_na       : out STD_LOGIC                      -- unixtime not aligned
	    ); 
end component;

signal CLK25, CLK200, CLK200_1, reset, RunC_reset_reg, RunC_reset_unix, PPS, Unix_time_na, PPS_na, PPS_nr :  std_logic;
signal Unixtime, Counta_sec : std_logic_vector(31 downto 0); 
signal Runc_tag0 : std_logic_vector(15 downto 0); 
signal Conta : std_logic_vector(27 downto 0); 

begin

uut: pps_module2
    generic map(C_MAX => 263)
    port map(
        CLK_25MHZ     => CLK25,
        CLK_200MHZ 	  => CLK200,
        CLK_200MHZ_1  => CLK200_1,
        RESET         => reset,
        RunC_Res_FLG  => RunC_reset_reg,
        Runc_Val_Tag0 => Runc_tag0,
        UnixTime_ARM  => Unixtime,
        Rst_Unix_Time => RunC_reset_unix,
        PPS_OUT 	  => PPS,	  
        RunC_PPS_na	  => PPS_na,
        RunC_PPS_nr	  => PPS_nr,
        CONTA 		  => Conta,
        COUNTA_sec 	  => Counta_Sec,
        Unix_Time_na  => Unix_time_na
        );


clk_25: process
variable i : integer := 0;
begin 
    if i = 31 then
        i := 0;
        CLK25 <= '1';
        wait for 10 ns;
        CLK25 <= '0';
        wait for 30 ns;
        CLK25 <= '1';
        wait for 30 ns;
        CLK25 <= '0';
        wait for 10 ns;
    else
        i := i + 1;
        CLK25 <= '1';
        wait for 20 ns;
        CLK25 <= '0';
        wait for 20 ns;
    end if;
end process;

clk_200: process
begin
    CLK200   <= '1';
    CLK200_1 <= '0';
    wait for 2.5 ns;
    CLK200   <= '0';
    CLK200_1 <= '1';
    wait for 2.5 ns;
end process;

main_proc: process
begin
    reset <= '1';
    RunC_reset_reg <= '0';
    RunC_reset_unix <= '0';
    Runc_tag0 <= X"000" & "1111";
    Unixtime <= (others => '1');
    wait for 20 ns;
    reset <= '0';
    wait for 570 ns;
    RunC_reset_reg <= '1';
    RunC_reset_unix <= '1';
    wait for 5 ns;
    RunC_reset_reg <= '0';
    RunC_reset_unix <= '0';
    
    wait;
end process;

end Behavioral;
