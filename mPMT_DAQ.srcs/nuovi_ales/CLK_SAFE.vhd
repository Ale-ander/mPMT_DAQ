----------------------------------------------------------------------------------
-- Company: INFN Napoli
-- Engineer: AB
-- 
-- Create Date:    12:41:11 18/08/2020 
-- Design Name: 
-- Module Name:    CLK_SAFE - Behavioral 
-- Project Name: 

-- Description: 
-- Rivela la presenza del REF_CLK dal cavo
-- Commuta il BUGMUX automaticamente
-- Lo segnala al RunControl ( anche le transizioni avvenute tra 2 letture )

----------------------------------------------------------------------------------
library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use UNISIM.vcomponents.all;
use work.instruction_buffer_type.all;


entity CLK_SAFE is
    generic (MaxTime_OK     : integer:= 10000 ); -- Time for which the RefCLK freq must be at 25MHz (Step 1.33uS)
        Port ( 
               -- IN
               Ref_CLK 				: in  STD_LOGIC; -- ref_CLK from cable
               XCLK 				: in  STD_LOGIC; -- Quartz at 25MHz 
               USB48M 				: in  STD_LOGIC; -- CLK of USB from PLL
               RESET 				: in  STD_LOGIC;
               RunC_CLK_est_int	    : in  STD_LOGIC; -- 1 = External   0 = Internal <---| 
               RunC_CLK_Automat	    : in  STD_LOGIC; -- 1 = Automatic  0 = Manual   <---|
               Runc_ClkSafe_Rflag	: in  STD_LOGIC; -- Handshaking per resettare le flag
               -- OUT
               RunC_Ref_CLK_OK 	    : out STD_LOGIC; -- Frequenzimetro ok
               Runc_Ref_CLK_Perso	: out STD_LOGIC; -- clock perso da frequenzimetro per almeno maxtime_ok
               Runc_Ref_CLK_ritrov  : out STD_LOGIC; -- clock rirovato dopo perso 
               Mast_CLK25MHz 		: out STD_LOGIC  -- Master CLK to all the FPGA
               );
end CLK_SAFE;

architecture Behavioral of CLK_SAFE is

signal Conta48M	   : std_logic_vector (5 downto 0);
signal ContaRef25M : std_logic_vector (4 downto 0);
signal EN_Conta	   : std_logic;
signal EN_Sync	   : std_logic;
signal Res_Conta   : std_logic := '1';
signal Sel_MUX	   : std_logic;
signal int_ResFlgR : std_logic;
signal AND_SelMux  : std_logic;
signal ContTimeOK  : std_logic_vector (13 downto 0);

begin

process(USB48M, RESET)
begin
	if RESET = '1' then
		Conta48M 	        <= (OTHERS => '0');
		ContTimeOK 	        <= (OTHERS => '0');
		EN_Conta 	        <= '0';
		Res_Conta	        <= '1';
		Sel_MUX		        <= '0';
        Runc_Ref_CLK_ritrov	<= '0';
        Runc_Ref_CLK_Perso	<= '0';
        int_ResFlgR			<= '0';
			
	elsif rising_edge(USB48M) then
	
		Conta48M    <= Conta48M +1;
		int_ResFlgR <= Runc_ClkSafe_Rflag;
	
		if Conta48M < 48 then -- Abilita il contatore per frequenzimetro
			EN_Conta <= '1';
		else		
			EN_Conta <= '0';
		end if;
		
		if (Conta48M > 53 and Conta48M < 59 )then -- reset contatore
			Res_Conta <= '1';
		else	
			Res_Conta <= '0';
		end if;
		
		if Runc_ClkSafe_Rflag = '0' and int_ResFlgR = '1' then -- Resetta i FLAG RunC
			Runc_Ref_CLK_ritrov		<= '0';
			Runc_Ref_CLK_Perso		<= '0';
		end if;		
		
		if Conta48M = 52 then --  controlla la frequenza
            if (ContaRef25M > 23 and ContaRef25M < 27) then -- Frequenza GIUSTA
                if ContTimeOK < MaxTime_OK then
                    ContTimeOK <= ContTimeOK + 1 ;
                end if;	  
            else	                                        -- Frequenza SBAGLIATA
                ContTimeOK <= ( others => '0');					
            end if;	
		end if;	


		if ContTimeOK >= MaxTime_OK then	
            Sel_MUX  <= '1';
            if Sel_MUX  = '0' then  -- FLAG x RunC
                Runc_Ref_CLK_ritrov <= '1';	
            end if;
		else
			Sel_MUX  <= '0';
			if (Sel_MUX  = '1') then -- FLAG x RunC
			    Runc_Ref_CLK_Perso <= '1';
			end if;
		end if;
			
    end if;	
end process;

--  Frequenzimetro
process(Ref_CLK, Res_Conta)
begin
	if Res_Conta = '1' then
		ContaRef25M <= (OTHERS => '0');
		EN_Sync 	<= '0';
			
	elsif rising_edge(Ref_CLK) then
	
	   EN_Sync <= EN_Conta;
		
	   if (ContaRef25M < 31 and EN_Sync = '1') then -- abilita il conteggio
	       ContaRef25M <= ContaRef25M + 1;		 
	   end if;
			
    end if;	
end process;

RunC_Ref_CLK_OK <= Sel_MUX ;

AND_SelMux <= (Sel_MUX and RunC_CLK_Automat) or (RunC_CLK_est_int and not RunC_CLK_Automat ); 

BUFGMUX_inst : BUFGMUX
    port map (
        O  => Mast_CLK25MHz, -- 1-bit output: Clock output
        I0 => XCLK,          -- Quarzo          (S=0)
        I1 => Ref_CLK,       -- refCLK dal cavo (S=1)
        S  => AND_SelMux     -- 1 = RefCLK presente
    );

end Behavioral;