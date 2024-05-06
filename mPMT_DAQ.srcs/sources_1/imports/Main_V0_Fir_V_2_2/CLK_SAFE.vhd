----------------------------------------------------------------------------------
-- Company: INFN Napoli
-- Engineer: AB
-- 
-- Create Date:    12:41:11 18/08/2020 
-- Design Name: 
-- Module Name:    CLK_SAFE - Behavioral 
-- Project Name: 

-- Description: Rivela la presenza del Ref_CLK dal cavo
--  commuta il BUFGMUX automaticamente
--  lo segnala al RunControl ( Anche le transizioni avvenute tra 2 letture )

----------------------------------------------------------------------------------
library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use UNISIM.vcomponents.all;
use work.instruction_buffer_type.all;


entity CLK_SAFE is
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
end CLK_SAFE;

architecture Behavioral of CLK_SAFE is

signal Conta25M_PS			: std_logic_vector (4 downto 0);
signal ContaRef25M_1		: std_logic_vector (4 downto 0);
signal ContaRef25M_2		: std_logic_vector (4 downto 0);

signal EN_Sync				: std_logic;
signal EN_Sync2				: std_logic;

signal Res_Conta			: std_logic := '1';
signal EN_Conta				: std_logic;

signal Sel_MUX_master       : std_logic;
signal Sel_MUX				: std_logic;

signal RefCLK_Mux           : std_logic;
signal AND_SelMux			: std_logic;
signal AND_SelMux_ref_CLK   : std_logic;

signal CLK_1_ok_int         : std_logic;
signal CLK_1_perso_int      : std_logic;
signal CLK_1_ritrovato_int  : std_logic;
signal CLK_2_ok_int         : std_logic;
signal CLK_2_perso_int      : std_logic;
signal CLK_2_ritrovato_int  : std_logic;
signal CLK_Automatico       : std_logic;
signal CLK_int_ext          : std_logic;
signal ContTimeOK_1		    : std_logic_vector (13 downto 0);
signal ContTimeOK_2			: std_logic_vector (13 downto 0);


attribute keep : string;  
attribute keep of Conta25M_PS   : signal is "true"; 
attribute keep of ContaRef25M_1 : signal is "true"; 
attribute keep of ContaRef25M_2 : signal is "true"; 

begin

quartz_count:process(XCLK, RESET)
begin
	if RESET = '1'then
		Conta25M_PS         <= (others => '0');
		EN_Conta 	        <= '0';
		Res_Conta	        <= '1';
		Sel_MUX		        <= '0';
        Sel_MUX_master      <= '0';
		CLK_1_ok_int        <= '0';
		CLK_2_ok_int        <= '0';
        CLK_1_perso_int	    <= '0';
        CLK_2_perso_int	    <= '0';
        CLK_1_ritrovato_int <= '0';
        CLK_2_ritrovato_int <= '0';
		ContTimeOK_1        <= (others => '0');
		ContTimeOK_2        <= (others => '0');

	elsif rising_edge(XCLK) then
	    -- Increase counter
    	Conta25M_PS <= Conta25M_PS +1;
	    -- Enable frequency meter
		if Conta25M_PS < 25 then 
	        EN_Conta <= '1';
		else		
            EN_Conta <= '0';
		end if;
		-- Reset frequency meter
		if (Conta25M_PS > 27) and (Conta25M_PS < 30) then
			Res_Conta <= '1';
		else		
			Res_Conta <= '0';
		end if;
		-- Handshaking with RC
		if  Rst_CLK_reg = '1' then
            CLK_1_ritrovato_int <= '0';
            CLK_2_ritrovato_int <= '0';
            CLK_1_perso_int     <= '0';
            CLK_2_perso_int     <= '0';     
		end if;	
		-- Check frequency 
		if Conta25M_PS = 27 then
    		if ContaRef25M_1 > 23 and ContaRef25M_1 < 27 then -- Frequecy is right
	       	    if ContTimeOK_1 < MaxTime_OK then
			     	ContTimeOK_1 <= ContTimeOK_1 + 1 ;
				end if;	
			else	                                            -- Frequency is wrong
			    ContTimeOK_1 <= (others => '0');
		    end if;	   
			if ContaRef25M_2 > 23 and ContaRef25M_2 < 27 then -- Frequency is right
				if ContTimeOK_2 < MaxTime_OK then
				    ContTimeOK_2 <= ContTimeOK_2 + 1 ;
                end if;			  
			else	                                            -- Frequency is wrong
				ContTimeOK_2 <= (others => '0');
            end if;
		end if;	
		-- Check stability period and generate lost and found flags
		if ContTimeOK_1 >= MaxTime_OK then	
			CLK_1_ok_int  <= '1';
            if CLK_1_ok_int  = '0' then
                CLK_1_ritrovato_int <= '1';	
            end if;
		else
            CLK_1_ok_int <= '0';
            if CLK_1_ok_int  = '1' then
                CLK_1_perso_int <= '1';
            end if;
		end if;
		-- Check stability period and generate lost and found flags		
		if ContTimeOK_2 >= MaxTime_OK then	
            CLK_2_ok_int  <= '1';
            if CLK_2_ok_int  = '0' then  
                CLK_2_ritrovato_int <= '1';	
            end if;
		else
            CLK_2_ok_int  <= '0';
            if CLK_2_ok_int  = '1' then
                CLK_2_perso_int <= '1';
            end if;
		end if;
		-- Generate selection signal for multiplexers
        if 	CLK_1_ok_int = '1' then
            Sel_MUX <= '0';
            Sel_MUX_master <= '0';
        elsif CLK_2_ok_int = '1' then
            Sel_MUX <= '1';
            Sel_MUX_master <= '0';
        else
            Sel_MUX_master  <= '1';
        end if;
		
    end if;	
end process quartz_count;

--  Frequency meter CLK1 cable
frequency_meter_1:process(Ref_CLK1, Res_Conta)
begin
	if Res_Conta = '1' then
		ContaRef25M_1 <= ( others => '0');
		EN_Sync 	  <= '0';
	elsif rising_edge(Ref_CLK1) then
        EN_Sync <= EN_Conta;
        if (ContaRef25M_1 < 31 and EN_Sync = '1') then
            ContaRef25M_1 <= ContaRef25M_1 + 1;		 
        end if;
    end if;	
end process frequency_meter_1;

--  Frequency meter CLK2 cable
frequency_meter_2:process(Ref_CLK2, Res_Conta)
begin
	if Res_Conta = '1' then
		ContaRef25M_2 	<= (others => '0');
		EN_Sync2 		<= '0';
	elsif rising_edge(Ref_CLK2) then
        EN_Sync2 <= EN_Conta;
        if (ContaRef25M_2 < 31 and EN_Sync2 = '1') then
            ContaRef25M_2 <= ContaRef25M_2 + 1;		 
        end if;		
    end if;	
end process frequency_meter_2;


-- MUX for CLK1 or CLK2
AND_SelMux_ref_CLK <= (Sel_MUX and CLK_aut_man_ref) or (CLK_cable_1_2 and not CLK_aut_man_ref ); 
BUFGMUX_inst_refCLK : BUFGMUX
   port map (
       O  => RefCLK_Mux,         -- 1-bit output: Clock output
       I0 => Ref_CLK1,           -- 25MHz dal cavo 1 (S=0)
       I1 => Ref_CLK2,           -- 25MHz dal cavo 2 (S=1)
       S  => AND_SelMux_ref_CLK  -- 1 = RefCLK presente su cavo 1
   );

-- MUX for CLK1/CLK2 or XCLK
AND_SelMux <= (Sel_MUX_master and CLK_aut_man) or (CLK_int_ext and not CLK_aut_man); 
BUFGMUX_inst : BUFGMUX
    port map (
       O  => Mast_CLK25MHz,     -- 1-bit output: Clock output
       I0 => RefCLK_Mux,        -- clock 25MHz dal cavo (S=0)
       I1 => XCLK,              -- clock 25 da quarzo (S=1)
       S  => AND_SelMux   
    );

-- Ouptut signal assignment
CLK_OK_flg <= not Sel_MUX_master ; -- Generation OK flag for RC

CLK_OK_1     <= CLK_1_ok_int;
CLK_OK_2     <= CLK_2_ok_int;
CLK_Perso_1  <= CLK_1_perso_int;
CLK_Perso_2  <= CLK_2_perso_int;
CLK_ritrov_1 <= CLK_1_ritrovato_int;
CLK_ritrov_2 <= CLK_2_ritrovato_int;

end Behavioral;

