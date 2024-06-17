----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Alessandro Di Nola  
-- 
-- scheda x Nexis4
--
-- Module Name:    canale_tempo - Behavioral 
-- Revision  Module 2.0 
-- Ultima modifica 21/05/2023
--
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.STD_LOGIC_arith.ALL;

entity blocco_time is
    generic( posizione_y       : integer:=55;
             posizione_x       : integer:=103);
    Port(   
         -- IN
         time_sig      : in std_logic;
         samp_clk      : in std_logic_vector(6 downto 0);
         reset         : in std_logic;
         reset_TDC     : in std_logic;
         coarse_hit    : in std_logic_vector(27 downto 0);
         measureType   : in std_logic; -- '0' HIT '1' SUBHIT
         enable        : in std_logic;
         -- OUT
         rst_done      : out std_logic;
         valid_measure : out std_logic;
         final_measure : out std_logic_vector(43 downto 0)
         );
end blocco_time;

architecture Behavioral of blocco_time is

component flip_flop is
--generic(	sys_x       : integer:= 6;
--			sys_y       : integer:= 118);
    Port ( d : in  STD_LOGIC;
           RESET : in  STD_LOGIC;
           data_valid_rise : out  STD_LOGIC;
           data_valid_fall : out  STD_LOGIC;
           q_rise : out  STD_LOGIC_VECTOR (4 downto 0);
           q_fall : out  STD_LOGIC_VECTOR (4 downto 0);
		   Multiclk : in  STD_LOGIC_VECTOR(7 downto 1)
			  );
end component;

component counter_subhit is
    Port ( clk    : in STD_LOGIC;
           reset  : in STD_LOGIC;
           enable : in STD_LOGIC;
           count  : out STD_LOGIC_VECTOR (13 downto 0));
end component;


--===================================================================================
-- 						COSTANTI & SEGNALI
--===================================================================================
-----fsm--------
type stato is (idle, conta, valid_measureS, wait_reset);
signal state, next_state : stato;
------TDC-------
signal comp_rise    : STD_LOGIC_VECTOR(4 downto 0);
signal tdc_al_rise  : STD_LOGIC_VECTOR(4 downto 0);
signal comp_fall    : STD_LOGIC_VECTOR(4 downto 0);
signal tdc_al_fall  : STD_LOGIC_VECTOR(4 downto 0);
-----enable-----
signal valid_rise   : std_logic;
signal valid_fall   : std_logic;
----counters----
signal corse_subhit : std_logic_vector(13 downto 0);
signal conta_alto   : STD_LOGIC_VECTOR(5 downto 0);
----------------
attribute keep : string;
attribute keep of state : signal is "true";

begin

--===================================================================================
-- 						FSM gestione TDC e Corse
--===================================================================================
clked : process (samp_clk(0), reset, enable)
begin
    if rising_edge(samp_clk(0)) then
	   if reset = '1' or enable = '0' then
            state <= idle;
	   else
            state <= next_state;
            
            if (state = conta or next_state = conta) and conta_alto < 63 then
                conta_alto <= conta_alto + 1;	
            elsif state = valid_measureS then
                conta_alto <= conta_alto;
            else
                conta_alto <= (OTHERS => '0'); 
            end if;
            
            if(valid_rise = '1')then
                tdc_al_rise <= comp_rise;
            end if;
            if(valid_fall = '1')then
                tdc_al_fall <= comp_fall;
            end if;	

	   end if;	   
	end if;
end process;


fsm : process(valid_rise, valid_fall, state, reset_TDC, conta_alto, measureType, coarse_hit, corse_subhit, tdc_al_rise, tdc_al_fall)
begin

    next_state <= state;

	case state is

		when idle =>
            valid_measure   <= '0';
            rst_done        <= '1';
            final_measure   <= (OTHERS => '0');
            if (valid_rise = '1' and valid_fall = '0') then
                next_state <= conta;
                rst_done   <= '0';
            elsif (valid_rise = '1' and valid_fall = '1') then
                next_state <= valid_measureS;
                rst_done   <= '0';
            else 
                next_state <= idle;
            end if;

		when conta =>
            if valid_fall = '1' then
                next_state <= valid_measureS;
            else 
                next_state <= conta;
            end if;		
			
		when valid_measureS =>
            valid_measure <= '1';
            if measureType = '0' then
               final_measure <= coarse_hit & tdc_al_rise & conta_alto & tdc_al_fall; -- 28 5 6 5
            else
               final_measure <= "00000000000000" & corse_subhit & tdc_al_rise & conta_alto & tdc_al_fall; -- 14 14 5 6 5            
            end if;
    		next_state <= wait_reset;
				
		when wait_reset => 
            valid_measure <= '0';
            if reset_TDC = '1' then
                rst_done   <= '1';	
                next_state <= idle;
            end if;			
				
	    when others => 
	        next_state    <= IDLE;
	        rst_done      <= '0';
            valid_measure <= '0';
            final_measure <= (OTHERS => '0'); 

	end case;			
end process;

--===================================================================================
-- 						TDC
--===================================================================================
Inst_flip_flop_time: flip_flop
--GENERIC MAP(
--	sys_x => posizione_x,
--	sys_y => posizione_y)
PORT MAP(
	d               => time_sig,
	reset           => reset,
	data_valid_rise => valid_rise,
	data_valid_fall => valid_fall,
	q_rise          => comp_rise,
	q_fall          => comp_fall,
	Multiclk        => samp_clk
);

--===================================================================================
-- 						COUNTER
--===================================================================================
counterSubhit: entity work.counter_subhit
    Port map( 
             clk    => samp_clk(0),
             reset  => reset,
             enable => measureType,
             count  => corse_subhit
             );

end Behavioral;