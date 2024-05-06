library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use UNISIM.vcomponents.all;
use work.instruction_buffer_type.all;

entity data_shifter_SM is
    Port ( 
           -- IN
           clk       : in STD_LOGIC;
           reset     : in STD_LOGIC;
           din_FIFO  : in STD_LOGIC_VECTOR(31 downto 0);
           din_shift : in STD_LOGIC_VECTOR(31 downto 0);
           Ren_in    : in STD_LOGIC; 
           wr_en_in  : in  STD_LOGIC;
           count_tm  : in STD_LOGIC_vector(8 downto 0);
           empty     : in STD_LOGIC;
           
           -- OUT
           Ren_out   : out STD_LOGIC;
           wr_en_out : out STD_LOGIC;
           rd_en     : out STD_LOGIC;
           dout      : out STD_LOGIC_VECTOR (31 downto 0));
end data_shifter_SM;

architecture Behavioral of data_shifter_SM is

--===================================================================================
-- 						Signals
--===================================================================================
signal wr_ens  : std_logic;
signal wr_head : std_logic;
signal rd_ens  : std_logic;
----TIMEOUT----
signal en_timeout : std_logic;
signal timeout    : std_logic;
---CONTROL-----
signal head_found   : std_logic;
signal head_found_r : std_logic;
signal tail_found_r : std_logic;
signal tail_found   : std_logic;
------DATA-----
signal data_r : std_logic_vector(31 downto 0);
------FSM------
type state is (IDLE, HEAD, WAIT_TAIL, TIMEOUTS, PASS);
signal present_state, next_state : state;
attribute fsm_encoding : string;
attribute fsm_encoding of present_state : signal is "sequential";


begin

--===================================================================================
-- 						FSM to daisy chain
--===================================================================================
FSM_sync_proc: process(clk, reset, next_state, head_found, wr_head, head_found_r, tail_found, tail_found_r, present_state, din_FIFO, wr_en_in, din_shift)
begin
  if rising_edge(clk) then
     if reset = '1' then
        present_state <= IDLE;
        head_found    <= '0';
        tail_found_r  <= '0';
        tail_found    <= '0';
        wr_ens        <= '0';
        wr_head       <= '0';
        rd_ens        <= '0';
        Ren_out       <= '0';
        dout          <= (others => '0');
     else
        present_state <= next_state;
        head_found_r  <= head_found;
        tail_found_r  <= tail_found;
        
        if head_found = '1' and head_found_r = '0' then
            wr_head <= '1';
        else
            wr_head <= '0';
        end if;
                
        if present_state = IDLE then
            wr_ens     <= '0';
            rd_ens     <= '0';
            Ren_out    <= '0';
            en_timeout <= '0';
            head_found <= '0';
            tail_found <= '0';
            dout      <= (others => '0');
            
        elsif present_state = HEAD then
            wr_ens     <= '0';
            rd_ens     <= '1';
            Ren_out    <= '0';
            en_timeout <= '1';
            head_found <= '0';
            tail_found <= '0';
            dout       <= din_FIFO;
            if din_FIFO(31 downto 30) = "10" then
                head_found <= '1';
            else
                head_found <= '0';
            end if;   
           
        elsif present_state = WAIT_TAIL then
            wr_ens     <= '1' and (not empty); 
            rd_ens     <= '1';
            Ren_out    <= '0';
            en_timeout <= '1';
            head_found <= '0';
            tail_found <= '0';
            dout       <= din_FIFO;
            if din_FIFO(31 downto 30) = "11" then
                tail_found <= '1';
            else
                tail_found <= '0';
            end if;   
            
        elsif present_state = TIMEOUTS then
            wr_ens     <= '1'; 
            rd_ens     <= '0';
            Ren_out    <= '0';
            en_timeout <= '0';
            head_found <= '0';
            tail_found <= '0';
            dout       <= (31 downto 26 => '1', others => '0'); 
        
        elsif present_state = PASS then
            wr_ens     <= wr_en_in; 
            rd_ens     <= '0';
            Ren_out    <= '1';
            en_timeout <= '0';
            head_found <= '0';
            tail_found <= '0';
            dout       <= din_shift; 
        
        else
            wr_ens     <= '0'; 
            rd_ens     <= '0';
            Ren_out    <= '0';
            en_timeout <= '0';
            head_found <= '0';
            tail_found <= '0';
            dout       <= (others => '0');
        end if;     
        
     end if;
  end if;
end process;

FSM_state_decode: process(present_state, next_state, Ren_in, head_found, tail_found, timeout, empty)
begin

    next_state <= present_state;

    case present_state is
    
    when IDLE =>
        if Ren_in = '1' then
            if empty = '1' then
                next_state <= PASS;
            else
                next_state <= HEAD;
            end if;
        else
            next_state <= IDLE;
        end if;
        
    when HEAD => 
        if timeout = '1' then
            next_state <= TIMEOUTS;  
        elsif head_found = '1' then
            next_state <= WAIT_TAIL;
        else
            next_state <= HEAD;      
        end if;    
        
    when WAIT_TAIL =>
        if timeout = '1' then
            next_state <= TIMEOUTS;        
        elsif tail_found = '1' then
            next_state <= PASS;
        else
            next_state <= WAIT_TAIL;           
        end if;
            
    when TIMEOUTS =>
        next_state <= PASS;
        
    when PASS =>
        if Ren_in = '0' then
            next_state <= IDLE;
        else
            next_state <= PASS;
        end if;
    
    when others =>
        next_state <= IDLE;
        
    end case;
end process;

--===================================================================================
-- 						Timeout counter
--===================================================================================
timeout_proc:process(clk)
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

wr_en_out <= (wr_ens and (not tail_found_r)) or wr_head;
rd_en     <= rd_ens and (not (tail_found or tail_found_r));

end Behavioral;
