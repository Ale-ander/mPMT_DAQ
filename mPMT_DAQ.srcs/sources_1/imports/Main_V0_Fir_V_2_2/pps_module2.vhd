----------------------------------------------------------------------------------
--  Description: Riceve il Tag0 e second tag, 
--  tra i due passano max 32 colpi di clock
-- 
--  Tag0 	 = sincronizza il contatore a 200MHz ogni 1sec
--  Tag_ResT = inutilizzato
--
--  TAG0     = ____----____--______------__----____----
--  TAG_ResT = ____----____------__--______----____----
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pps_module2 is
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
end pps_module2;

architecture Behavioral of pps_module2 is

signal int_Conta 		   : STD_LOGIC_VECTOR(27 downto 0);
signal int_Conta_r 		   : STD_LOGIC_VECTOR(27 downto 0);
signal int_COUNTA_sec	   : STD_LOGIC_VECTOR(31 downto 0);
signal Width_H_R0		   : STD_LOGIC_VECTOR(2 downto 0);
signal Width_H_R1		   : STD_LOGIC_VECTOR(2 downto 0);
signal CLK_25R			   : STD_LOGIC;
signal CLK_25R_0		   : STD_LOGIC;
signal int_RunC_Res_FLG	   : STD_LOGIC;
--signal int_RunC_Res_FLGr   : STD_LOGIC;
signal buio				   : STD_LOGIC_VECTOR(4 downto 0);
signal Conta_Delay		   : STD_LOGIC_VECTOR(2 downto 0);

signal PPS_not_Aligned     : STD_LOGIC;
signal intFLG_TAG0_OK      : STD_LOGIC;
signal PPS_OUT_int         : STD_LOGIC;
signal UnixTime_ARM_r	   : STD_LOGIC_VECTOR(31 downto 0);

attribute keep : string;
attribute keep of UnixTime_ARM_r : signal is "true";

begin

CONTA 	   <= int_Conta;
COUNTA_sec <= int_COUNTA_sec;
PPS_OUT    <= PPS_OUT_int;

metastability:process(CLK_200MHZ_1, RESET)
begin
	if RESET = '1' then
	   CLK_25R_0 <= '0';
	elsif rising_edge(CLK_200MHZ_1) then 
	   CLK_25R_0 <= CLK_25MHZ;
	end if;
end process metastability;	
	 
main_proc:process(CLK_200MHZ, RESET)
begin
	if RESET = '1' then
	   Width_H_R0          <= (others => '0');
	   Width_H_R1          <= (others => '0');
	   CLK_25R             <= '0';
	   int_Conta           <= (others => '0');
	   int_COUNTA_sec      <= X"56355600"; --01/11/2015 00:00:00 Nobel Kajita
	   RunC_PPS_na         <= '0';
	   RunC_PPS_nr         <= '0';
	   int_RunC_Res_FLG    <= '0';
--	   int_RunC_Res_FLGr   <= '0';
	   PPS_OUT_int		   <= '0';
	   buio				   <= (others => '0');
	   int_Conta_r		   <= (others => '0');
	   Conta_Delay		   <= (others => '0');
	   UnixTime_ARM_r	   <= (others => '0');
	   PPS_not_Aligned     <= '0';
       intFLG_TAG0_OK      <= '0';
       Unix_time_na        <= '0';
     
	elsif rising_edge(CLK_200MHZ) then
        CLK_25R 		  <= CLK_25R_0;
		int_RunC_Res_FLG  <= RunC_Res_FLG;
--		int_RunC_Res_FLGr <= int_RunC_Res_FLG;
		int_Conta_r       <= int_Conta; 
		UnixTime_ARM_r    <= UnixTime_ARM;
		--- Count high period
		if CLK_25R = '1' then
            Width_H_R0 <= Width_H_R0 + 1;
		end if;
		-- At rising edge reset high count and memorize it
		if CLK_25R = '0' and CLK_25R_0 = '1' then
            Width_H_R0 <= (others => '0');
			Width_H_R1 <= Width_H_R0;     
			if buio > 0 then
			    buio <= buio - 1 ;
			end if;
		end if;
	    -- Tag0: PPS arrived		
		if (CLK_25R = '0' and CLK_25R_0 = '1' and buio = 0 and ((Width_H_R1 <= 2 and Width_H_R0 >= 5) or (Width_H_R1 <= 3 and Width_H_R0 >= 6 ))) then
            int_Conta <= X"000" & Runc_Val_Tag0;
            if int_Conta /= ((X"000" & Runc_Val_Tag0) - 1) then  -- PPS not aligned   
                RunC_PPS_na <= '1'; -- PPS not aligned
            end if;
            intFLG_TAG0_OK <= '1';
            buio <= (others => '1');
        elsif int_Conta = C_MAX  then  -- 1 second passed without PPS --> PPS lost
            int_Conta <= (others => '0');
		    if intFLG_TAG0_OK = '0' then
                RunC_PPS_nr <= '1'; -- PPS not received
		    end if; 
			intFLG_TAG0_OK <= '0';	   
		else
		    int_Conta <= int_Conta + 1;
		end if;
		-- PPS generation
		if int_Conta <= int_Conta_r  then -- Counter in overflow
		    PPS_OUT_int	   <= '1';
		    int_COUNTA_sec <= int_COUNTA_sec +1;
		else
			PPS_OUT_int	   <= '0';
		end if;		
        -- TagRESET: reset PPS counter		
		if (CLK_25R = '0' and CLK_25R_0 = '1' and buio > 0 and  Width_H_R1 > 4 and Width_H_R0 < 4 ) then
		    int_COUNTA_sec <= (others => '0');
        end if;
		-- Verify Unixtime from ARM 
		if UnixTime_ARM_r /= UnixTime_ARM then
		    Unix_Time_na   <= '1';
		    int_COUNTA_sec <= UnixTime_ARM;
		end if;
		-- Reset wirte unix time flag
		if Rst_Unix_Time = '1' then
		    Unix_Time_na <= '0';
		end if;
		-- Generate RunControl flags
		if int_RunC_Res_FLG = '0' and RunC_Res_FLG = '1' and Conta_Delay = 0 then
		    Conta_Delay <= Conta_Delay + 1;
		elsif Conta_Delay > 0 and PPS_OUT_int = '1' and Conta_Delay < 4 then
		    Conta_Delay <= Conta_Delay + 1;
		elsif Conta_Delay = 4 then
		    RunC_PPS_nr <= '0'; -- normalmente PPS non ricevuto
		    RunC_PPS_na <= '0'; -- normalmente PPS allineato
            Conta_Delay <= (others => '0'); 
		end if;
		 				
    end if;	
end process main_proc;

end Behavioral;

