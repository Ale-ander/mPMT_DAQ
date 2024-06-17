library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.instruction_buffer_type.all; 

entity RunControl_AXI is
generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 8
	);
	port (
		-- Users to add ports here
		
		RESET_IN            : in  std_logic;    -- board reset
		
		-- From reset module
		
		-- From clk_safe module   
        CLK_OK_1     	    : in std_logic;    -- CLK OK flag (1)
		CLK_Lost_1          : in std_logic;    -- CLK lost flag (1) 
		CLK_Found_1         : in std_logic;    -- CLK found flag (1)
        CLK_OK_2     	    : in std_logic;    -- CLK OK flag (2)
		CLK_Lost_2          : in std_logic;    -- CLK lost flag (2)
		CLK_Found_2         : in std_logic;    -- CLK found flag (2)
		CLK_OK_flg          : in std_logic;    -- CLK OK flag frome cables
        -- From multichannel
		Dead_Time           : in std_logic_vector(31 downto 0); -- Acquisition dead time
		Ratemeters          : in Freq_ARRAY;                     -- Single channel ratemeters
        -- From PPS recovery module 
        PPS_contati 	    : in std_logic_vector(31 downto 0); -- PPS counter 
		PPS_na              : in std_logic;                     -- 0 = PPS not aligned, 1 = PPS aligned  
		PPS_nr              : in std_logic;                     -- 0 = PPS not received, 1= PPS received 
		Unixtime_na         : in std_logic;                     -- unix correction happened
        -- From outside
        Overcurrent         : in std_logic_vector(18 downto 0); -- Single channel overcurrent
        -- From FIFO
		HF_FIFO		        : in std_logic;                     -- FIFO data half-full
		FIFO_DATA_COUNT     : in std_logic_vector(13 downto 0); -- FIFO data counter
        -- From PLL
	    PLL_locked		    : in std_logic;                     -- Locked signal from PLL
        
        -- To reset module
        
        -- To clk_safe module
        CLK_ext_int         : out std_logic;           -- Mux for clk internal or external
        CLK_aut_man         : out std_logic;           -- Mux for clk automatic or manual
        CLK_aut_man_ref     : out std_logic;           -- Mux for clk automatic or manual (ref)
        CLK_1_2             : out std_logic;           -- Mux for clk from cable 1 or 2
        Rst_CLKSafe         : out std_logic;           -- Reset clk_safe module (handshaking)
        -- To multichannel
        Enable_PPS          : out std_logic;                      -- Enable PPS event each second 
        Calibrate_ADC       : out std_logic;                      -- Start ADC automatic calibrations procedure
        Rst_multichannel    : out std_logic;                      -- Reset multichannel module
        UnixTime_ARM 	    : out std_logic_vector(31 downto 0);  -- Unixtime
        Time_to_peaks       : out Peak_ARRAY;                     -- Single channel time to peaks
        TDC_delay 		    : out Delay_ARRAY;                    -- Single channel TDC programmable delay
        Timeout             : out STD_LOGIC_VECTOR(8 downto 0);   -- value to count to timeout the raead
        -- To PPS recovery module
        Res_TagFlg	        : out std_logic;                      -- Reset Tag flag (handshaking)
		Val_Tag0            : out std_logic_vector(15 downto 0);  -- Valore Contatore tempo @200Mhz al TAG0
        Res_Unixtime_flag   : out std_logic;                      -- Reset Unixtime flag (handshaking)
        -- To pulser
		Pulser_period       : out std_logic_vector(13 downto 0);  -- Pulser frequency in ms
        -- To outside
        CH_ENABLE           : out std_logic_vector(18 downto 0);  -- Single channel enable (also STM32 boot mode)
        PWR_EN              : out std_logic_vector(18 downto 0);  -- Single channel power enable (turn on)
        -- To FIFO
        RST_FIFO            : out std_logic;  -- Reset data FIFO
            

	
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end RunControl_AXI;

architecture Behavioral of RunControl_AXI is
    
    	-- AXI4LITE signals
	signal axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant OPT_MEM_ADDR_BITS : integer := 5;
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
    signal slv_reg0:  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg1:  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_reg2:  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg3:  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg4:  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg5:  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg6:  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg7:  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg8:  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg9:  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg10: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg11: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg12: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg13: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg14: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg15: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg16: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg17: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg18: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg19: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg20: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg21: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg22: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg23: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg24: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg25: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg26: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg27: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg28: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg29: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg30: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg31: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg32: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg33: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg34: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg35: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg36: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg37: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg38: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg39: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg40: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg41: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg42: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	        
	signal slv_reg_rden	: std_logic;
	signal slv_reg_wren	: std_logic;
	signal reg_data_out	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal byte_index	: integer;
	signal aw_en	: std_logic;
		
	signal count: integer;
	signal count_to_200: integer;

begin
	-- I/O Connections assignments

	S_AXI_AWREADY <= axi_awready;
	S_AXI_WREADY  <= axi_wready;
	S_AXI_BRESP	  <= axi_bresp;
	S_AXI_BVALID  <= axi_bvalid;
	S_AXI_ARREADY <= axi_arready;
	S_AXI_RDATA	  <= axi_rdata;
	S_AXI_RRESP	  <= axi_rresp;
	S_AXI_RVALID  <= axi_rvalid;
	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awready <= '0';
	      aw_en <= '1';
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- slave is ready to accept write address when
	        -- there is a valid write address and write data
	        -- on the write address and data bus. This design 
	        -- expects no outstanding transactions. 
	           axi_awready <= '1';
	           aw_en <= '0';
	        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
	           aw_en <= '1';
	           axi_awready <= '0';
	      else
	        axi_awready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both 
	-- S_AXI_AWVALID and S_AXI_WVALID are valid. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awaddr <= (others => '0');
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- Write Address latching
	        axi_awaddr <= S_AXI_AWADDR;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_wready generation
	-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	-- de-asserted when reset is low. 
    --
    
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
	          -- slave is ready to accept write data when 
	          -- there is a valid write address and write data
	          -- on the write address and data bus. This design 
	          -- expects no outstanding transactions.           
	          axi_wready <= '1';
	      else
	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process; 

	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;


    -- insert mux for write and read registers
    process (S_AXI_ACLK)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0); 
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      slv_reg0               <= (others => '0');   -- Enable acquisition
	      slv_reg1               <= (others => '0');   -- Power enable
--	      slv_reg2               <= (others => '1');   -- Overcurrent
	      slv_reg3(31 downto 20) <= x"640";            -- see regAddress
	      slv_reg3(13 downto 9)  <= "00110";           -- CLK_safe muxes (all automatic)
	      slv_reg3(1)            <= '0';	           -- RST_FIFO
	      slv_reg6               <= X"0000000" & "0001";   -- Runc_Val_Tag0
--	      slv_reg7               <= X"0" & FIFO_DATA_COUNT & "00" & X"000";   -- FIFO data counter and Pulser period
	      slv_reg28              <= X"00013013";       -- Time to peak ch 0 and 1
	      slv_reg29              <= X"00013013";       -- Time to peak ch 2 and 3
	      slv_reg30              <= X"00013013";       -- Time to peak ch 4 and 5
	      slv_reg31              <= X"00013013";       -- Time to peak ch 6 and 7
	      slv_reg32              <= X"00013013";       -- Time to peak ch 8 and 9
	      slv_reg33              <= X"00013013";       -- Time to peak ch 10 and 11
	      slv_reg34              <= X"00013013";       -- Time to peak ch 12 and 13
	      slv_reg35              <= X"00013013";       -- Time to peak ch 14 and 15
	      slv_reg36              <= X"00013013";       -- Time to peak ch 16 and 17
	      slv_reg37              <= X"00013000";       -- Time to peak ch 18
	      slv_reg38              <= X"1E1E1E1E";       -- TDC delay ch 0, 1, 2, 3
          slv_reg39              <= X"1E1E1E1E";       -- TDC delay ch 4, 5, 6, 7
          slv_reg40              <= X"1E1E1E1E";       -- TDC delay ch 8, 9, 10, 11
          slv_reg41              <= X"1E1E1E1E";       -- TDC delay ch 12, 13, 14, 15
          slv_reg42              <= X"1E1E1E00";       -- TDC delay ch 16, 17, 18
	      
      else
	      loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	      if (slv_reg_wren = '1') then
	        case loc_addr is
	          when b"000000" =>
	              slv_reg0 <= S_AXI_WDATA;
	          when b"000001" =>
	              slv_reg1 <= S_AXI_WDATA;
	          when b"000011" =>
	              slv_reg3(31 downto 20) <= S_AXI_WDATA(31 downto 20); 
	              slv_reg3(13 downto 9)  <= S_AXI_WDATA(13 downto 9);    
	              slv_reg3(1)            <= S_AXI_WDATA(1);    
	          when b"000101" =>
	              slv_reg5 <= S_AXI_WDATA;  
	          when b"000110" =>
	              slv_reg6 <= S_AXI_WDATA;    
	          when b"000111" =>
	              slv_reg7(13 downto 0) <= S_AXI_WDATA(13 downto 0);    
	          when b"011100" =>
	              slv_reg28 <= S_AXI_WDATA;  
	          when b"011101" =>
	              slv_reg29 <= S_AXI_WDATA;    
	          when b"011110" =>
	              slv_reg30 <= S_AXI_WDATA;    
	          when b"011111" =>
	              slv_reg31 <= S_AXI_WDATA;    
	          when b"100000" =>
	              slv_reg32 <= S_AXI_WDATA;    
	          when b"100001" =>
	              slv_reg33 <= S_AXI_WDATA;    
	          when b"100010" =>
	              slv_reg34 <= S_AXI_WDATA;   
	          when b"100011" =>
	              slv_reg35 <= S_AXI_WDATA;    
	          when b"100100" =>
	              slv_reg36 <= S_AXI_WDATA;    
	          when b"100101" =>
	              slv_reg37 <= S_AXI_WDATA;    
	          when b"100110" =>
	              slv_reg38 <= S_AXI_WDATA;   
	          when b"100111" =>
	              slv_reg39 <= S_AXI_WDATA;   
	          when b"101000" =>
	              slv_reg40 <= S_AXI_WDATA;   
	          when b"101001" =>
	              slv_reg41 <= S_AXI_WDATA;   
	          when b"101010" =>
	              slv_reg42 <= S_AXI_WDATA;      
              when others =>
                NULL;
	          end case;
	      end if;
	    end if;
	    
	  end if;                   
	end process; 
	
	
		-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave 
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	-- This marks the acceptance of address and indicates the status of 
	-- write transaction.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_bvalid  <= '0';
	      axi_bresp   <= "00"; --need to work more on the responses
	    else
	      if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
	        axi_bvalid <= '1';
	        axi_bresp  <= "00"; 
	      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
	      end if;
	    end if;
	  end if;                   
	end process; 
	
		-- Implement axi_arready generation
	-- axi_arready is asserted for one S_AXI_ACLK clock cycle when
	-- S_AXI_ARVALID is asserted. axi_awready is 
	-- de-asserted when reset (active low) is asserted. 
	-- The read address is also latched when S_AXI_ARVALID is 
	-- asserted. axi_araddr is reset to zero on reset assertion.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_arready <= '0';
	      axi_araddr  <= (others => '1');
	    else
	      if (axi_arready = '0' and S_AXI_ARVALID = '1') then
	        -- indicates that the slave has acceped the valid read address
	        axi_arready <= '1';
	        -- Read Address latching 
	        axi_araddr  <= S_AXI_ARADDR;           
	      else
	        axi_arready <= '0';
	      end if;
	    end if;
	  end if;                   
	end process; 
	
	-- Implement axi_arvalid generation
	-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	-- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	-- data are available on the axi_rdata bus at this instance. The 
	-- assertion of axi_rvalid marks the validity of read data on the 
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are 
	-- cleared to zero on reset (active low).  
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_rvalid <= '0';
	      axi_rresp  <= "00";
	    else
	      if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
	        -- Valid read data is available at the read data bus
	        axi_rvalid <= '1';
	        axi_rresp  <= "00"; -- 'OKAY' response
	      elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
	        -- Read data is accepted by the master
	        axi_rvalid <= '0';
	      end if;            
	    end if;
	  end if;
	end process;

	-- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available
	-- and the slave is ready to accept the read address.
	slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;

	process (axi_araddr, S_AXI_ARESETN, slv_reg_rden)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	begin
	    -- Address decoding for reading registers
	    loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	    case loc_addr is
	          when b"000000" =>
	               reg_data_out <= slv_reg0;         -- Enable acquisition
	          when b"000001" =>
	               reg_data_out <= slv_reg1;         -- Power enable
	          when b"000010" =>
	               reg_data_out <= slv_reg2;         -- Over current
	          when b"000011" =>
	               reg_data_out <= slv_reg3;         -- See regAddress
	          when b"000100" =>
	               reg_data_out <= slv_reg4;         -- PPS counter
	          when b"000101" =>
	               reg_data_out <= slv_reg5;         -- UnixTime from ARM
	          when b"000110" =>
	               reg_data_out <= slv_reg6;         -- Val_Tag0
	          when b"000111" =>
	               reg_data_out <= slv_reg7;         -- FIFO data counter & Pulser period
	          when b"001000" =>
	               reg_data_out <= slv_reg8;         -- Ratemeter ch 0
	          when b"001001" =>
	               reg_data_out <= slv_reg9;         -- Ratemeter ch 1   
	          when b"001010" =>
	               reg_data_out <= slv_reg10;        -- Ratemeter ch 2
	          when b"001011" =>
	               reg_data_out <= slv_reg11;        -- Ratemeter ch 3
	          when b"001100" =>
	               reg_data_out <= slv_reg12;        -- Ratemeter ch 4
	          when b"001101" =>
	               reg_data_out <= slv_reg13;        -- Ratemeter ch 5
	          when b"001110" =>
	               reg_data_out <= slv_reg14;        -- Ratemeter ch 6
	          when b"001111" =>
	               reg_data_out <= slv_reg15;        -- Ratemeter ch 7
	          when b"010000" =>
	               reg_data_out <= slv_reg16;        -- Ratemeter ch 8
	          when b"010001" =>
	               reg_data_out <= slv_reg17;        -- Ratemeter ch 9
	          when b"010010" =>
	               reg_data_out <= slv_reg18;        -- Ratemeter ch 10
	          when b"010011" =>
	               reg_data_out <= slv_reg19;        -- Ratemeter ch 11
	          when b"010100" =>
	               reg_data_out <= slv_reg20;        -- Ratemeter ch 12
	          when b"010101" =>
	               reg_data_out <= slv_reg21;        -- Ratemeter ch 13
	          when b"010110" =>
	               reg_data_out <= slv_reg22;        -- Ratemeter ch 14
	          when b"010111" =>
	               reg_data_out <= slv_reg23;        -- Ratemeter ch 15
	          when b"011000" =>
	               reg_data_out <= slv_reg24;        -- Ratemeter ch 16
	          when b"011001" =>
	               reg_data_out <= slv_reg25;        -- Ratemeter ch 17
	          when b"011010" =>
	               reg_data_out <= slv_reg26;        -- Ratemeter ch 18
	          when b"011011" =>
	               reg_data_out <= slv_reg27;        -- Deadtime
	          when b"011100" =>
	               reg_data_out <= slv_reg28;        -- Time to peak ch 0 & 1
	          when b"011101" =>
	               reg_data_out <= slv_reg29;        -- Time to peak ch 2 & 3
	          when b"011110" =>
	               reg_data_out <= slv_reg30;        -- Time to peak ch 4 & 5
	          when b"011111" =>
	               reg_data_out <= slv_reg31;        -- Time to peak ch 6 & 7
	          when b"100000" =>
	               reg_data_out <= slv_reg32;        -- Time to peak ch 8 & 9
	          when b"100001" =>
	               reg_data_out <= slv_reg33;        -- Time to peak ch 10 & 11
	          when b"100010" =>
	               reg_data_out <= slv_reg34;        -- Time to peak ch 12 & 13
	          when b"100011" =>
	               reg_data_out <= slv_reg35;        -- Time to peak ch 14 & 15
	          when b"100100" =>
	               reg_data_out <= slv_reg36;        -- Time to peak ch 16 & 17
	          when b"100101" =>
	               reg_data_out <= slv_reg37;        -- Time to peak ch 18
	          when b"100110" =>
	               reg_data_out <= slv_reg38;        -- TDC delay channel 0 & 1 & 2 & 3
	          when b"100111" =>
	               reg_data_out <= slv_reg39;        -- TDC delay channel 4 & 5 & 6 & 7
	          when b"101000" =>
	               reg_data_out <= slv_reg40;        -- TDC delay channel 8 & 9 & 10 & 11
	          when b"101001" =>
	               reg_data_out <= slv_reg41;        -- TDC delay channel 12 & 13 & 14 & 15
	          when b"101010" =>
	               reg_data_out <= slv_reg42;        -- TDC delay channel 16 & 17 & 18
	          
	      when others =>
	        reg_data_out  <= (others => '0');
	    end case;
	end process; 
    
    
    -- Output register or memory read data
	process( S_AXI_ACLK ) is
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	begin
	   loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	  
	  if (rising_edge (S_AXI_ACLK)) then
	    if ( S_AXI_ARESETN = '0' ) then
	      axi_rdata         <= (others => '0');
	      Res_TagFlg        <= '0';
	      Res_Unixtime_flag <= '0';
	      Rst_CLKSafe       <= '0';
	    else
	      if (slv_reg_rden = '1') then
	        -- When there is a valid read address (S_AXI_ARVALID) with 
	        -- acceptance of read address by the slave (axi_arready), 
	        -- output the read dada 
	        -- Read address mux
	          axi_rdata <= reg_data_out;     -- register read data
	      end if;
--	      if slv_reg_rden = '1' and loc_addr = b"000011" then   VA MESSO SOPRA
--              Res_TagFlg        <= '1';
--              Res_Unixtime_flag <= '1';
--              Rst_CLKSafe       <= '1';
--          else
--              Res_TagFlg        <= '0';
--              Res_Unixtime_flag <= '0';
--              Rst_CLKSafe       <= '0';              
--	      end if;
	    end if;
	  end if;
	end process;
    	   
    -- process to safely power on all the boards 
    safe_poweron:process(S_AXI_ACLK, RESET_IN, count, count_to_200) is
	begin
	   if rising_edge(S_AXI_ACLK) then
           if RESET_IN = '1' then
               count        <= 0;
               PWR_EN       <= (others => '0');
               count_to_200 <= 0;
           else 
               count_to_200  <= count_to_200 + 1;
               PWR_EN(count) <= slv_reg1(count);
               if count_to_200 = 200 then               
                   count         <= count + 1;       
                   count_to_200  <= 0; 
               end if;
               
               if count = 19 then  
                   count <= 0;
               end if;
           end if;
	   end if;
	end process safe_poweron;
	
    -- Assign slv_reg output 
    CH_ENABLE         <= slv_reg0(18 downto 0);
--    PWR_EN            <= slv_reg1(18 downto 0);
    Timeout           <= slv_reg3(31 downto 23);
    Calibrate_ADC     <= slv_reg3(22);
    Rst_multichannel  <= slv_reg3(21);
    Enable_PPS        <= slv_reg3(20);
    Enable_PPS        <= slv_reg3(20);
    Rst_CLKSafe       <= slv_reg3(13);
    CLK_1_2           <= slv_reg3(12);
    CLK_aut_man_ref   <= slv_reg3(11);
    CLK_aut_man       <= slv_reg3(10);
    CLK_ext_int       <= slv_reg3(9);
    RST_FIFO          <= slv_reg3(1);
    UnixTime_ARM      <= slv_reg5;
    Val_Tag0          <= slv_reg6(15 downto 0);
    Pulser_period     <= slv_reg7(13 downto 0);
    Time_to_peaks(0)  <= slv_reg28(23 downto 12);
    Time_to_peaks(1)  <= slv_reg28(11 downto 0);
    Time_to_peaks(2)  <= slv_reg29(23 downto 12);
    Time_to_peaks(3)  <= slv_reg29(11 downto 0);
    Time_to_peaks(4)  <= slv_reg30(23 downto 12);
    Time_to_peaks(5)  <= slv_reg30(11 downto 0);
    Time_to_peaks(6)  <= slv_reg31(23 downto 12);
    Time_to_peaks(7)  <= slv_reg31(11 downto 0);
    Time_to_peaks(8)  <= slv_reg32(23 downto 12);
    Time_to_peaks(9)  <= slv_reg32(11 downto 0);
    Time_to_peaks(10) <= slv_reg33(23 downto 12);
    Time_to_peaks(11) <= slv_reg33(11 downto 0);
    Time_to_peaks(12) <= slv_reg34(23 downto 12);
    Time_to_peaks(13) <= slv_reg34(11 downto 0);
    Time_to_peaks(14) <= slv_reg35(23 downto 12);
    Time_to_peaks(15) <= slv_reg35(11 downto 0);
    Time_to_peaks(16) <= slv_reg36(23 downto 12);
    Time_to_peaks(17) <= slv_reg36(11 downto 0);
    Time_to_peaks(18) <= slv_reg37(23 downto 12);
    TDC_delay(0)      <= slv_reg38(31 downto 24);
    TDC_delay(1)      <= slv_reg38(23 downto 16);
    TDC_delay(2)      <= slv_reg38(15 downto 8);
    TDC_delay(3)      <= slv_reg38(7 downto 0);
    TDC_delay(4)      <= slv_reg39(31 downto 24);
    TDC_delay(5)      <= slv_reg39(23 downto 16);
    TDC_delay(6)      <= slv_reg39(15 downto 8);
    TDC_delay(7)      <= slv_reg39(7 downto 0);
    TDC_delay(8)      <= slv_reg40(31 downto 24);
    TDC_delay(9)      <= slv_reg40(23 downto 16);
    TDC_delay(10)     <= slv_reg40(15 downto 8);
    TDC_delay(11)     <= slv_reg40(7 downto 0);
    TDC_delay(12)     <= slv_reg41(31 downto 24);
    TDC_delay(13)     <= slv_reg41(23 downto 16);
    TDC_delay(14)     <= slv_reg41(15 downto 8);
    TDC_delay(15)     <= slv_reg41(7 downto 0);
    TDC_delay(16)     <= slv_reg42(31 downto 24);
    TDC_delay(17)     <= slv_reg42(23 downto 16);
    TDC_delay(18)     <= slv_reg42(15 downto 8);
    
    -- Assign slv_reg input
    slv_reg2(18 downto 0)  <= Overcurrent;
    slv_reg3(18)           <= Unixtime_na;
    slv_reg3(17)           <= CLK_OK_flg;
    slv_reg3(16)           <= PPS_nr;
    slv_reg3(15)           <= PPS_na;
    slv_reg3(8)            <= CLK_OK_1;   
    slv_reg3(7)            <= CLK_Lost_1; 
    slv_reg3(6)            <= CLK_Found_1;
    slv_reg3(5)            <= CLK_OK_2;   
    slv_reg3(4)            <= CLK_Lost_2; 
    slv_reg3(3)            <= CLK_Found_2;
    slv_reg3(2)            <= PLL_locked;
    slv_reg3(0)            <= HF_FIFO;
    slv_reg4               <= PPS_contati;
    slv_reg7(27 downto 14) <= FIFO_DATA_COUNT;
    slv_reg8(24 downto 0)  <= Ratemeters(0);
    slv_reg9(24 downto 0)  <= Ratemeters(1);
    slv_reg10(24 downto 0) <= Ratemeters(2);
    slv_reg11(24 downto 0) <= Ratemeters(3);
    slv_reg12(24 downto 0) <= Ratemeters(4);
    slv_reg13(24 downto 0) <= Ratemeters(5);
    slv_reg14(24 downto 0) <= Ratemeters(6);
    slv_reg15(24 downto 0) <= Ratemeters(7);
    slv_reg16(24 downto 0) <= Ratemeters(8);
    slv_reg17(24 downto 0) <= Ratemeters(9);
    slv_reg18(24 downto 0) <= Ratemeters(10);
    slv_reg19(24 downto 0) <= Ratemeters(11);
    slv_reg20(24 downto 0) <= Ratemeters(12);
    slv_reg21(24 downto 0) <= Ratemeters(13);
    slv_reg22(24 downto 0) <= Ratemeters(14);
    slv_reg23(24 downto 0) <= Ratemeters(15);
    slv_reg24(24 downto 0) <= Ratemeters(16);
    slv_reg25(24 downto 0) <= Ratemeters(17);
    slv_reg26(24 downto 0) <= Ratemeters(18);
    slv_reg27              <= Dead_Time;
    
end Behavioral;