library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity tb_clksafe is
end tb_clksafe;

architecture Behavioral of tb_clksafe is

component CLK_SAFE is
    generic (MaxTime_OK        : integer:= 10000 ); -- Tempo x il quale la freq del RefCLK deve essere 25MHz (Step 1.33uS)
    Port ( 
           -- IN
           Ref_CLK1 		   : in  STD_LOGIC; -- ref_CLK dal cable 1
           Ref_CLK2 		   : in  STD_LOGIC; -- ref_CLK dal cable 2
           XCLK 			   : in  STD_LOGIC; -- Quartz a 25MHz 
           FCLK25M 			   : in  STD_LOGIC; -- CLK from fabric
           RESET 	  		   : in  STD_LOGIC; -- Reset component
		   CLK_ext_int	       : in  STD_LOGIC; -- 0 = Internal, 1 = External    
		   CLK_aut_man	       : in  STD_LOGIC; -- 0 = Manual,   1 = Automatic  
		   CLK_aut_man_ref     : in  STD_LOGIC; -- 0 = Manual,   1 = Automatic 
		   CLK_cable_1_2       : in  STD_LOGIC; -- 0 = cable1,   1 = cable2 
		   Rst_CLK_reg         : in  STD_LOGIC; -- Reset CLk reg changed flag (handshaking)
           -- OUT
           CLK_OK_flg          : out STD_LOGIC; -- CLK OK flag for RunControl
           CLK_OK_1 	       : out STD_LOGIC; -- CLK OK (1)
		   CLK_Perso_1         : out STD_LOGIC; -- CLK Lost (1)
		   CLK_ritrov_1        : out STD_LOGIC; -- CLK Found (1)
           CLK_OK_2 	       : out STD_LOGIC; -- CLK OK (2)
		   CLK_Perso_2         : out STD_LOGIC; -- CLK Lost (2)
		   CLK_ritrov_2        : out STD_LOGIC; -- CLK Found (2)
           Mast_CLK25MHz 	   : out STD_LOGIC  -- Master CLK25MHz
           );
end component;

signal clk1, clk2, xclks, fclk, resets, clk_ext_ints, clk_aut_mans, clk_aut_man_refs, clk_cable_1_2s, rst_clk_regs : std_logic;
signal clk_ok, ok1, lost1, found1, ok2, lost2, found2, outclk : std_logic;
signal en1: std_logic;

begin

uut: CLK_SAFE
    generic map(MaxTime_OK => 3)
    port map(
         Ref_CLK1 	     => clk1,
         Ref_CLK2 	     => clk2,
         XCLK 			 => xclks,
         FCLK25M 		 => fclk,
         RESET 	  	     => resets,
         CLK_ext_int	 => clk_ext_ints,
         CLK_aut_man	 => clk_aut_mans,
         CLK_aut_man_ref => clk_aut_man_refs,
         CLK_cable_1_2   => clk_cable_1_2s,
         Rst_CLK_reg     => rst_clk_regs,
         CLK_OK_flg      => clk_ok,
         CLK_OK_1 	     => ok1,
         CLK_perso_1     => lost1,
         CLK_ritrov_1    => found1,
         CLK_OK_2 	     => ok2,
         CLK_perso_2     => lost2,
         CLK_ritrov_2    => found2,
         Mast_CLK25MHz   => outclk
         );
         
clk25: process
begin
    clk1 <= '1';
    wait for 20 ns;
    clk1 <= '0';
    wait for 20 ns;
end process;

main_proc:process
begin
    en1 <= '1';
    resets <= '1';
    clk_ext_ints <= '0';
    clk_aut_mans <= '0';
    clk_aut_man_refs <= '0';
    clk_cable_1_2s <= '0';
    rst_clk_regs <= '0';
    wait for 40 ns;
    resets <= '0';
    wait for 4 us;
    en1 <= '0';
    rst_clk_regs <= '1';
    wait for 5 ns;
    rst_clk_regs <= '0';
    wait;
end process;
        
end Behavioral;
        