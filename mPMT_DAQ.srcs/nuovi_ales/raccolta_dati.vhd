----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Alessandro Di Nola  
-- 
-- scheda x Nexis4
--
-- Module Name:    raccolta_dati - Behavioral 
-- Revision  Module 1.0 
-- Ultima modifica 21/05/2023
--
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use UNISIM.vcomponents.all;
use work.instruction_buffer_type.all;

entity raccolta_dati is
    generic (n_channel : integer:= 2); -- number of PMT channels
    Port ( 
        -- IN    
        din        : in Data32_ARRAY;
		clk 	   : in STD_LOGIC;
        reset 	   : in STD_LOGIC;
        empty 	   : in STD_LOGIC_VECTOR(n_channel downto 0);  -- emptys of the small FIFOs
        wr_done	   : in STD_LOGIC_VECTOR(n_channel downto 0);  -- a apackage has been written in the FIFO
		HF_FIFO    : in STD_LOGIC;                             -- HF of the big FIFO
		count_tm   : in STD_LOGIC_vector(8 downto 0);          -- value to count to timeout the raead
		-- OUT
		reset_ch   : out STD_LOGIC_VECTOR(n_channel downto 0); -- reset the sc FSM if timeout
        wr_en      : out STD_LOGIC;                            -- write_enable of the big FIFO 
        rd_done	   : out STD_LOGIC_VECTOR(n_channel downto 0); -- package has been read from the rr
        rd_en 	   : out STD_LOGIC_VECTOR(n_channel downto 0); -- read enable to the small FIFOs
        dout       : out STD_LOGIC_VECTOR(31 downto 0)
        );
end raccolta_dati;

architecture Behavioral of raccolta_dati is

--===================================================================================
-- 						Signals
--===================================================================================
signal enable : std_logic;
----TIMEOUT----
signal en_timeout : std_logic;
signal timeout    : std_logic;
----TRANSFER---
signal idx           : integer range 0 to n_channel:=0;
signal transfer_done : std_logic;
signal wr_ens        : std_logic;
signal msg_read      : std_logic;
signal head_ok       : std_logic;
----FSM--------
type state is (RESET_MUX, CHECK_EMPTY, WAIT_PACKAGE, WAIT_TRANSFER, INCREMENT);
signal present_state, next_state : state;
attribute fsm_encoding : string;
attribute fsm_encoding of present_state : signal is "sequential";

begin

--===================================================================================
-- 						FSM to round robin
--===================================================================================
enable <= not HF_FIFO;

FSM_sync_proc: process(clk, reset, present_state, next_state, idx, din, timeout)
begin
  if rising_edge(clk) then
     if reset = '1' or enable = '0' then
        present_state <= RESET_MUX;
        wr_ens        <= '0';
        rd_en         <= (OTHERS => '0');
        dout          <= (OTHERS => '1');
        head_ok       <= '0';
     else
        present_state <= next_state;
        wr_en         <= wr_ens and (not empty(idx));
        
        if present_state = INCREMENT then
            if idx = n_channel then
                idx <= 0;
            else
                idx <= idx + 1;
            end if;
        end if;
        
        if present_state = WAIT_TRANSFER then
           dout <= din(idx);
           if din(idx)(31 downto 30) = "10" then
               wr_ens     <= '1';
               rd_en(idx) <= '1';
               msg_read   <= '0';
               head_ok    <= '1';
           elsif din(idx)(31 downto 30) = "11" and head_ok = '1' then
               wr_ens     <= '0';
               rd_en(idx) <= '0';
               msg_read   <= '1';
               head_ok    <= '0';
           end if;   
        else
           msg_read   <= '0';
           wr_en      <= '0';
           rd_en(idx) <= '0';
           head_ok    <= '0';
        end if;       
     
     end if;
  end if;
end process;

FSM_state_decode: process(present_state, next_state, timeout, empty)
begin

    next_state <= present_state;

    case present_state is
    
    when RESET_MUX =>
        next_state <= CHECK_EMPTY;
        en_timeout <= '0';
        reset_ch   <= (OTHERS => '0');
        rd_done    <= (OTHERS => '0');
        
    when CHECK_EMPTY => 
        en_timeout <= '0';
        if empty(idx) = '1' then
            next_state <= INCREMENT;
        else
            next_state <= WAIT_PACKAGE; 
            en_timeout <= '1';
       end if;
    
    when WAIT_PACKAGE =>
        en_timeout <= '1';
        if wr_done(idx) = '1' then
            next_state <= WAIT_TRANSFER;
            reset_ch   <= (OTHERS => '0');
            rd_done    <= (OTHERS => '0');
        elsif timeout = '1' then
            next_state    <= RESET_MUX;
            en_timeout    <= '0';
            reset_ch(idx) <= '1';
            rd_done       <= (OTHERS => '0');
        end if;
        
    when WAIT_TRANSFER =>
        en_timeout <= '1';
        reset_ch   <= (OTHERS => '0');
        if msg_read = '1' then
            next_state <= INCREMENT;
        elsif timeout = '1' then
            next_state    <= RESET_MUX;
            reset_ch(idx) <= '1';
        end if;
    
    when INCREMENT => 
        next_state <= CHECK_EMPTY;
            
    when others =>
        en_timeout <= '0';
        rd_done    <= (OTHERS => '0');
        reset_ch   <= (OTHERS => '0');
        next_state <= RESET_MUX;
        
    end case;
end process;

--===================================================================================
-- 						Timeout counter
--===================================================================================
timeout_proc:process(clk, reset, en_timeout)
variable count : STD_LOGIC_VECTOR(8 downto 0);
begin
    if rising_edge(clk) then
        if reset = '1' then
            timeout <= '0';
            count   := (OTHERS => '0');
        elsif en_timeout = '1' then
            count := count + 1;
            if count = count_tm then
                timeout <= '1';
                count := (OTHERS => '0');
            else
                timeout <= '0';
            end if;
        else
            timeout <= '0';
            count   := (OTHERS => '0');            
        end if;
    end if;
end process;

end Behavioral;
