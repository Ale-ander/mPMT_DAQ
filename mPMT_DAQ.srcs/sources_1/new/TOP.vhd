library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.instruction_buffer_type.all;

library UNISIM;
use UNISIM.VComponents.all;

entity TOP is
  Port ( 
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    --PS PORTS TOP MODULE
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    --PL PORTS TOP MODULE FOR LOGIC
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    
    -----------------------------------------------------------------------
    --TRG from channels SECTION
    -----------------------------------------------------------------------
    OUT_TIME_P          : in      STD_LOGIC_VECTOR(18 downto 0);
    OUT_TIME_N          : in      STD_LOGIC_VECTOR(18 downto 0);
    
    -----------------------------------------------------------------------
    --CLK SECTION
    -----------------------------------------------------------------------
    -- Oscillator CLOCK
    Quartz25            :       in      STD_LOGIC;
    --CABLE CLOCK 25 MHZ
    REF_CLK_P           :       in      STD_LOGIC;
    REF_CLK_N           :       in      STD_LOGIC;
    REF_CLK2_P          :       in      STD_LOGIC;
    REF_CLK2_N          :       in      STD_LOGIC;
    
    -----------------------------------------------------------------------
    --TRIGGER from CABLE SECTION
    -----------------------------------------------------------------------
    EXT_TRG_P           :       out      STD_LOGIC;
    EXT_TRG_N           :       out      STD_LOGIC;
    EXT_TRG2_P          :       out      STD_LOGIC;
    EXT_TRG2_N          :       out      STD_LOGIC;
    
    -----------------------------------------------------------------------
    --UART TO CHANNELs SECTION
    -----------------------------------------------------------------------    
    TX_OUT              :       out     STD_LOGIC;
    RX_IN               :       in      STD_LOGIC_VECTOR(18 downto 0);
    
    -----------------------------------------------------------------------
    --ADC and POWER, OVC for CHANNELS SECTION
    -----------------------------------------------------------------------
    --ADC
    ADC_SCL              :       out     STD_LOGIC_VECTOR(18 downto 0);
    ADC_CS               :       out     STD_LOGIC_VECTOR(18 downto 0);
    ADC_SDATA            :       in      STD_LOGIC_VECTOR(18 downto 0);
    
    --PowerEnable
    PWR_EN               :       out     STD_LOGIC_VECTOR(18 downto 0);
    
    --OverCurrent
    OVC_CH               :       in      STD_LOGIC_VECTOR(18 downto 0);
    
    -----------------------------------------------------------------------
    --I2C for system monitoring to EMIO SECTION
    -----------------------------------------------------------------------    
    I2C_SDA              :      inout       STD_LOGIC;
    I2C_SCL              :      inout       STD_LOGIC;
    
    -----------------------------------------------------------------------
    --UART for SAMA5D27 boot monitoring to EMIO SECTION
    -----------------------------------------------------------------------    
    SAMA_RX             :       in          STD_LOGIC;
    SAMA_TX             :       out         STD_LOGIC
    -----------------------------------------------------------------------
    --UART FOR DAQ
    -----------------------------------------------------------------------
    --UART_RX_ACQ         :       in          STD_LOGIC;
    --UART_TX_ACQ         :       out         STD_LOGIC
  );
end TOP;

architecture Behavioral of TOP is

component TOP_block_wrapper is
  port (
    AXI_STR_RXD_0_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI_STR_RXD_0_tlast : in STD_LOGIC;
    AXI_STR_RXD_0_tready : out STD_LOGIC;
    AXI_STR_RXD_0_tvalid : in STD_LOGIC;
    CLK_200_main : in STD_LOGIC;
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    FCLK_25 : out STD_LOGIC;
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    I2C_SCL_I : in STD_LOGIC;
    I2C_SCL_O : out STD_LOGIC;
    I2C_SCL_T : out STD_LOGIC;
    I2C_SDA_I : in STD_LOGIC;
    I2C_SDA_O : out STD_LOGIC;
    I2C_SDA_T : out STD_LOGIC;
    M00_AXI_0_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_0_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M00_AXI_0_arready : in STD_LOGIC;
    M00_AXI_0_arvalid : out STD_LOGIC;
    M00_AXI_0_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_0_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M00_AXI_0_awready : in STD_LOGIC;
    M00_AXI_0_awvalid : out STD_LOGIC;
    M00_AXI_0_bready : out STD_LOGIC;
    M00_AXI_0_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M00_AXI_0_bvalid : in STD_LOGIC;
    M00_AXI_0_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_0_rready : out STD_LOGIC;
    M00_AXI_0_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M00_AXI_0_rvalid : in STD_LOGIC;
    M00_AXI_0_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_0_wready : in STD_LOGIC;
    M00_AXI_0_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M00_AXI_0_wvalid : out STD_LOGIC;
    UART1_RX : in STD_LOGIC;
    UART1_TX : out STD_LOGIC;
    peripheral_aresetn : out STD_LOGIC_VECTOR ( 0 to 0 );
    peripheral_aresetn_0 : out STD_LOGIC_VECTOR ( 0 to 0 );
    uart_Sama_boot_rxd : in STD_LOGIC;
    uart_Sama_boot_txd : out STD_LOGIC
  );
end component;

component clk_wiz_0
port
 (-- Clock in ports
  -- Clock out ports
  clk_out1          : out    STD_LOGIC;
  clk_out2          : out    STD_LOGIC;
  clk_out3          : out    STD_LOGIC;
  clk_out4          : out    STD_LOGIC;
  clk_out5          : out    STD_LOGIC;
  clk_out6          : out    STD_LOGIC;
  clk_out7          : out    STD_LOGIC;
  -- Status and control signals
  reset             : in     STD_LOGIC;
  locked            : out    STD_LOGIC;
  CLK_IN1           : in     STD_LOGIC
 );
end component;

COMPONENT fifo_generator_0
  PORT (
    clk           : IN STD_LOGIC;
    rst           : IN STD_LOGIC;
    din           : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en         : IN STD_LOGIC;
    rd_en         : IN STD_LOGIC;
    dout          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full          : OUT STD_LOGIC;
    empty         : OUT STD_LOGIC;
    valid         : OUT STD_LOGIC;
    data_count    : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
    prog_full     : OUT STD_LOGIC
  );
  END COMPONENT;

component Multychannel_V2
    generic (n_channel  : integer:= 19);                                -- number of PMTs channels
    Port ( 
        Multiclk 		: in  STD_LOGIC_VECTOR(6 downto 0);             -- multiphase		   
        RESET 			: in  STD_LOGIC;                                -- external reset
		COUNTER200M 	: in  STD_LOGIC_VECTOR(27 downto 0);            -- 200MHz counter
        -- PPS channel		  
		PPS				: in  STD_LOGIC;                                -- PPS from pulser
		COUNTA_sec	    : in  STD_LOGIC_VECTOR(27 downto 0);            -- PPS counter
        -- From/To runControl		  
        delay           : in  Delay_ARRAY;                              -- additional delay set by runcontrol    
		massimo 		: in  Peak_ARRAY;                               -- time to peak for each channel
		ch_enable       : in  STD_LOGIC_VECTOR(n_channel - 1 downto 0); -- enable for each channel
        calibrazione    : in  STD_LOGIC;                                -- calibration flag
        PPS_ch_en 	    : in  STD_LOGIC;                                -- PPS channel enable	  
		Pulser 		    : in  STD_LOGIC;                                -- pedestal generator
		count_tm        : in STD_LOGIC_VECTOR(8 downto 0);              -- value to count to timeout the raead
		dead_time       : out STD_LOGIC_VECTOR(31 downto 0);            -- dead time read through RC
		ratemeters      : out Freq_ARRAY;
	    -- PPS channel
	    unixtime        : in STD_LOGIC_VECTOR(31 downto  0);	   
	    -- To channels	  
        time_p 		    : in  STD_LOGIC_VECTOR(n_channel - 1 downto 0); -- trigger positive
        time_n 		    : in  STD_LOGIC_VECTOR(n_channel - 1 downto 0); -- trigger negative
		sdi 			: in  STD_LOGIC_VECTOR(n_channel - 1 downto 0); -- SPI
        sclk 			: out STD_LOGIC_VECTOR(n_channel - 1 downto 0); -- SPI
        chip_select 	: out STD_LOGIC_VECTOR(n_channel - 1 downto 0); -- SPI
        -- To big FIFO
        HF_FIFO         : in STD_LOGIC;                                 -- HF big FIFO
        wr_en_o         : out STD_LOGIC;                                -- wr_en big FIFO
        dout_to_FIFO    : out STD_LOGIC_VECTOR(31 downto 0)             -- data to big FIFOSim_ARRAY
        );       
end component;

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

component pps_module2 is
	generic (C_MAX       : integer:= 199_999_999 ); -- Counts to 1 second at 200MHz
    Port ( 
           -- IN
           CLK_25MHZ 		  : in STD_LOGIC; -- CLK with Tag0
		   CLK_200MHZ 		  : in STD_LOGIC; -- Main CLK
		   CLK_200MHZ_1 	  : in STD_LOGIC; -- Main CLK out of phase for metastability problems
		   RESET 			  : in STD_LOGIC; -- Reset component
		   RunC_Res_FLG  	  : in STD_LOGIC; -- Handshaking with RC
		   Runc_Val_Tag0	  : in STD_LOGIC_VECTOR(15 downto 0); -- latency (insert value + 3)
		   UnixTime_ARM 	  : in STD_LOGIC_VECTOR(31 downto 0); -- Unix from ARM
		   Rst_Unix_Time      : in STD_LOGIC;
		   -- OUT
		   PPS_OUT 		      : out STD_LOGIC;                     -- Pulse Per Second (PPS)
		   RunC_PPS_na    	  : out STD_LOGIC;                     -- 0 = PPS not aligned, 1 = PPS aligned
		   runC_PPS_nr    	  : out STD_LOGIC;                     -- 0 = PPS not received, 1 = PPS received		   CONTA 			  : out STD_LOGIC_VECTOR(27 downto 0); -- 200MHz clock counter
		   COUNTA_sec 		  : out STD_LOGIC_VECTOR(31 downto 0); -- PPS counter
		   Unix_Time_na       : out STD_LOGIC                      -- unixtime not aligned
	    ); 
end component;

component RESET_MODULE is
    Port ( reset_in       : in  STD_LOGIC;
           reset_out 	  : out STD_LOGIC;
           locked_fasi 	  : in  STD_LOGIC;
           CLK_IN_USB 	  : in  STD_LOGIC;
		   clk_failed 	  : out STD_LOGIC;
           clk_is_not_wrk : in  STD_LOGIC);
end component;

component Pulser is
    Port ( CLK  		: in  STD_LOGIC;
           RESET 	    : in  STD_LOGIC;
           Periodo_ms 	: in  STD_LOGIC_VECTOR (13 downto 0); -- 0 = OFF
           PULSER_OUT 	: out  STD_LOGIC);
end component;

component RunControl_AXI is
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
		PPS_na              : in std_logic;                     -- 1 = PPS aligned, 0 = Tag0_OK   
		PPS_nr              : in std_logic;                     -- 1 = PPS aligned, 0 = Tag0_OK   
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
        CALIBRAZIONE	    : out std_logic;                      -- Start ADC automatic calibrations procedure        
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
end component;

--===========================================
--                  Segnali
--===========================================
--Block design--
signal RX_IN_ps     :   std_logic;
signal I2C_SCL_I  : STD_LOGIC;
signal I2C_SCL_O  : STD_LOGIC;
signal I2C_SCL_T  : STD_LOGIC;
signal I2C_SDA_I  : STD_LOGIC;
signal I2C_SDA_O  : STD_LOGIC;
signal I2C_SDA_T  : STD_LOGIC;
signal FCLK_25    : STD_LOGIC;

signal M00_AXI_0_araddr   : STD_LOGIC_VECTOR(31 downto 0);
signal M00_AXI_0_arprot   : STD_LOGIC_VECTOR(2 downto 0);
signal M00_AXI_0_arready  : STD_LOGIC_VECTOR(0 downto 0);
signal M00_AXI_0_arvalid  : STD_LOGIC_VECTOR(0 downto 0);
signal M00_AXI_0_awaddr   : STD_LOGIC_VECTOR(31 downto 0);
signal M00_AXI_0_awprot   : STD_LOGIC_VECTOR(2 downto 0);
signal M00_AXI_0_awready  : STD_LOGIC_VECTOR(0 downto 0);
signal M00_AXI_0_awvalid  : STD_LOGIC_VECTOR(0 downto 0);
signal M00_AXI_0_bready   : STD_LOGIC_VECTOR(0 downto 0);
signal M00_AXI_0_bresp    : STD_LOGIC_VECTOR(1 downto 0);
signal M00_AXI_0_bvalid   : STD_LOGIC_VECTOR(0 downto 0);
signal M00_AXI_0_rdata    : STD_LOGIC_VECTOR(31 downto 0);
signal M00_AXI_0_rready   : STD_LOGIC_VECTOR(0 downto 0);
signal M00_AXI_0_rresp    : STD_LOGIC_VECTOR(1 downto 0);
signal M00_AXI_0_rvalid   : STD_LOGIC_VECTOR(0 downto 0);
signal M00_AXI_0_wdata    : STD_LOGIC_VECTOR(31 downto 0);
signal M00_AXI_0_wready   : STD_LOGIC_VECTOR(0 downto 0);
signal M00_AXI_0_wstrb    : STD_LOGIC_VECTOR(3 downto 0);
signal M00_AXI_0_wvalid   : STD_LOGIC_VECTOR(0 downto 0);
signal peripheral_aresetn : STD_LOGIC_VECTOR(0 downto 0);
--signal RD_EN_FIFO         : STD_LOGIC;
signal din_to_AXI_le              : STD_LOGIC_VECTOR(31 downto 0);
signal AXI_STR_RXD_0_tlast_int    : STD_LOGIC;
signal AXI_STR_RXD_0_tready	      : STD_LOGIC;
signal FIFO_nEmpty_32		      : STD_LOGIC;

----PLL----
signal Multiclk   : STD_LOGIC_VECTOR(6 downto 0);
signal PLL_locked : STD_LOGIC; 
--Multychannel--
signal PWR_EN_int         : STD_LOGIC_VECTOR(18 downto 0);
signal CH_ENABLE          : STD_LOGIC_VECTOR(18 downto 0);
signal chip_select        : STD_LOGIC_VECTOR(18 downto 0);
signal Dead_Time          : STD_LOGIC_VECTOR(31 downto 0);
signal Ratemeters         : Freq_ARRAY; 
signal PPS_contati        : STD_LOGIC_VECTOR(31 downto 0);
signal Enable_PPS         : STD_LOGIC;
signal Calibrate_ADC      : STD_LOGIC;
signal Rst_multychannel   : STD_LOGIC;
signal Rst_multychannel_s : STD_LOGIC;
signal Time_to_peaks      : Peak_ARRAY;
signal TDC_delay          : Delay_ARRAY;
signal Timeout_shifter    : STD_LOGIC_VECTOR(8 downto 0);
----CLKs----
signal Master_CLK25 : STD_LOGIC;
signal CLK_Cable_1  : STD_LOGIC;
signal CLK_Cable_2  : STD_LOGIC;
---Pulser---
signal Pulser_period : STD_LOGIC_VECTOR(13 downto 0);
signal Pulser_sig    : STD_LOGIC;
----PPS----
signal PPS               : STD_LOGIC;
signal RunC_PPS_na       : STD_LOGIC;
signal RunC_PPS_nr       : STD_LOGIC;
signal Unixtime_na       : STD_LOGIC;
signal Unixtime          : STD_LOGIC_VECTOR(31 downto 0);
signal Res_TagFlg        : STD_LOGIC;
signal Val_Tag0          : STD_LOGIC_VECTOR(15 downto 0);
signal Res_Unixtime_flag : STD_LOGIC;
signal COUNTER200M	     : STD_LOGIC_VECTOR(27 downto 0);
---FIFO---
signal HF_FIFO         : STD_LOGIC;
signal FIFO_data_count : STD_LOGIC_VECTOR(13 downto 0);
signal din_BIG         : STD_LOGIC_VECTOR(31 downto 0);
signal dout_BIG        : STD_LOGIC_VECTOR(31 downto 0);
signal RST_FIFO        : STD_LOGIC;
signal RD_EN_FIFO      : STD_LOGIC;
signal wr_en_fifo      : STD_LOGIC;
signal valid           : STD_LOGIC;
signal empty_Big       : STD_LOGIC;
--CLK SAFE--
signal CLK_ext_int     : STD_LOGIC;
signal CLK_aut_man     : STD_LOGIC;
signal CLK_aut_man_ref : STD_LOGIC;
signal CLK_1_2         : STD_LOGIC;
signal Rst_CLKSafe     : STD_LOGIC;
signal Rst_CLK_reg     : STD_LOGIC;
signal CLK_OK_1        : STD_LOGIC;
signal CLK_Lost_1      : STD_LOGIC;
signal CLK_Found_1     : STD_LOGIC;
signal CLK_OK_2        : STD_LOGIC;
signal CLK_Lost_2      : STD_LOGIC;
signal CLK_Found_2     : STD_LOGIC;
signal CLK_OK_flg      : STD_LOGIC;
--Reset module--
signal reset         : STD_LOGIC;
signal not_EOS_reset : STD_LOGIC;
signal EOS_reset     : STD_LOGIC;
------DMA-------
constant PKT_SIZE : positive := 8192;
signal tlast_cnt  : natural range 0 to PKT_SIZE-1 := 0;

begin
------------------------------------------------------------------------------------
--Wrapper instantiation! Do not modify!
------------------------------------------------------------------------------------
TOP_block_i: TOP_block_wrapper
    port map (
    -------------------------------------------
    --Stream AXI FIFO
    ----------------------------------------------
    AXI_STR_RXD_0_tdata(31 downto 0) => din_to_AXI_le,
    AXI_STR_RXD_0_tlast => AXI_STR_RXD_0_tlast_int,
    AXI_STR_RXD_0_tready => AXI_STR_RXD_0_tready,
    AXI_STR_RXD_0_tvalid => FIFO_nEmpty_32,
    ------------------------------------------------
    --PS PORTS
    -------------------------------------------------
    DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
    DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
    DDR_cas_n => DDR_cas_n,
    DDR_ck_n => DDR_ck_n,
    DDR_ck_p => DDR_ck_p,
    DDR_cke => DDR_cke,
    DDR_cs_n => DDR_cs_n,
    DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
    DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
    DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
    DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
    DDR_odt => DDR_odt,
    DDR_ras_n => DDR_ras_n,
    DDR_reset_n => DDR_reset_n,
    DDR_we_n => DDR_we_n,
    CLK_200_main => Multiclk(0),
    FCLK_25 => FCLK_25,
    FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
    FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
    FIXED_IO_ps_clk => FIXED_IO_ps_clk,
    FIXED_IO_ps_porb => FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
    I2C_SCL_I => I2C_SCL_I,
    I2C_SCL_O => I2C_SCL_O,
    I2C_SCL_T => I2C_SCL_T,
    I2C_SDA_I => I2C_SDA_I,
    I2C_SDA_O => I2C_SDA_O,
    I2C_SDA_T => I2C_SDA_T,
    peripheral_aresetn => peripheral_aresetn,
    M00_AXI_0_araddr(31 downto 0)     => M00_AXI_0_araddr(31 downto 0),
    M00_AXI_0_arprot(2 downto 0)      => M00_AXI_0_arprot(2 downto 0),
    M00_AXI_0_arready                 => M00_AXI_0_arready(0),
    M00_AXI_0_arvalid                 => M00_AXI_0_arvalid(0),
    M00_AXI_0_awaddr(31 downto 0)     => M00_AXI_0_awaddr(31 downto 0),
    M00_AXI_0_awprot(2 downto 0)      => M00_AXI_0_awprot(2 downto 0),
    M00_AXI_0_awready                 => M00_AXI_0_awready(0),
    M00_AXI_0_awvalid                 => M00_AXI_0_awvalid(0),
    M00_AXI_0_bready                  => M00_AXI_0_bready(0),
    M00_AXI_0_bresp(1 downto 0)       => M00_AXI_0_bresp(1 downto 0),
    M00_AXI_0_bvalid                  => M00_AXI_0_bvalid(0),
    M00_AXI_0_rdata(31 downto 0)      => M00_AXI_0_rdata(31 downto 0),
    M00_AXI_0_rready                  => M00_AXI_0_rready(0),
    M00_AXI_0_rresp(1 downto 0)       => M00_AXI_0_rresp(1 downto 0),
    M00_AXI_0_rvalid                  => M00_AXI_0_rvalid(0),
    M00_AXI_0_wdata(31 downto 0)      => M00_AXI_0_wdata(31 downto 0),
    M00_AXI_0_wready                  => M00_AXI_0_wready(0),
    M00_AXI_0_wstrb(3 downto 0)       => M00_AXI_0_wstrb(3 downto 0),
    M00_AXI_0_wvalid                  => M00_AXI_0_wvalid(0),
    UART1_RX => RX_IN_ps,  
    UART1_TX => TX_OUT,
    uart_Sama_boot_rxd => SAMA_RX, 
    uart_Sama_boot_txd => SAMA_TX
    );
    
RX_IN_ps <= '1' when (RX_IN or not PWR_EN_int)=(X"FFFF" & "111") else '0';
    
I2C_SCL <= I2C_SCL_O when (I2C_SCL_T = '0') else 'Z';
I2C_SCL_I <= I2C_SCL; 
I2C_SDA <= I2C_SDA_O when (I2C_SDA_T = '0') else 'Z';
I2C_SDA_I <= I2C_SDA;
    
RunControl: RunControl_AXI
	generic map (
	C_S_AXI_DATA_WIDTH	=> 32,
	C_S_AXI_ADDR_WIDTH	=> 32
	)
	port map (

    RESET_IN => reset,
    -- From reset module
    --//--
    -- From clk_safe module   
    CLK_OK_1     	  => CLK_OK_1,
    CLK_Lost_1        => CLK_Lost_1,
    CLK_Found_1       => CLK_Found_1,
    CLK_OK_2     	  => CLK_OK_2,
	CLK_Lost_2        => CLK_Lost_2,
	CLK_Found_2       => CLK_Found_2,
	CLK_OK_flg        => CLK_OK_flg,
    -- From multichanne
	Dead_Time         => Dead_time,
	Ratemeters        => Ratemeters,
    -- From PPS recovery
    PPS_contati	      => PPS_contati,
	PPS_na            => RunC_PPS_na,
	PPS_nr            => RunC_PPS_nr,
	Unixtime_na       => Unixtime_na,
    -- From outside
    Overcurrent       => OVC_CH,
    -- From FIFO
	HF_FIFO		      => HF_FIFO,
	FIFO_DATA_COUNT   => FIFO_data_count,
    -- From PLL
	PLL_locked		  => PLL_locked,
   
    -- To reset module
      
    -- To clk_safe module
    CLK_ext_int       => CLK_ext_int,
    CLK_aut_man       => CLK_aut_man,
    CLK_aut_man_ref   => CLK_aut_man_ref,
    CLK_1_2           => CLK_1_2,
    Rst_CLKSafe       => Rst_CLKSafe,
    -- To multichannel
    Enable_PPS        => Enable_PPS,
    Calibrate_ADC     => Calibrate_ADC,
    Rst_multichannel  => Rst_multychannel,
    UnixTime_ARM 	  => Unixtime,
    Time_to_peaks     => Time_to_peaks,
    TDC_delay 		  => TDC_delay,
    Timeout           => Timeout_shifter,
    -- To PPS recovery module
    Res_TagFlg	      => Res_TagFlg,
	Val_Tag0          => Val_Tag0,
    Res_Unixtime_flag => Res_Unixtime_flag,
    -- To pulser
	Pulser_period     => Pulser_period,
    -- To outside
    CH_ENABLE         => CH_ENABLE,
    PWR_EN            => PWR_EN_int,
    CALIBRAZIONE	  => Calibrate_ADC,
    -- To FIFO
    RST_FIFO          => RST_FIFO,

	-- AXI signals
	S_AXI_ACLK	    => Multiclk(0),
	S_AXI_ARESETN	=> peripheral_aresetn(0),
	S_AXI_AWADDR	=> M00_AXI_0_awaddr,
	S_AXI_AWPROT	=> M00_AXI_0_awprot,
	S_AXI_AWVALID	=> M00_AXI_0_awvalid(0),
	S_AXI_AWREADY	=> M00_AXI_0_awready(0),
	S_AXI_WDATA	    => M00_AXI_0_wdata,
	S_AXI_WSTRB	    => M00_AXI_0_wstrb,--(others => '1'),
	S_AXI_WVALID	=> M00_AXI_0_wvalid(0),
	S_AXI_WREADY	=> M00_AXI_0_wready(0),
	S_AXI_BRESP	    => M00_AXI_0_bresp,
	S_AXI_BVALID	=> M00_AXI_0_bvalid(0),
	S_AXI_BREADY	=> M00_AXI_0_bready(0),
	S_AXI_ARADDR	=> M00_AXI_0_araddr,
	S_AXI_ARPROT	=> M00_AXI_0_arprot,
	S_AXI_ARVALID	=> M00_AXI_0_arvalid(0),
	S_AXI_ARREADY	=> M00_AXI_0_arready(0),
	S_AXI_RDATA	    => M00_AXI_0_rdata,
	S_AXI_RRESP	    => M00_AXI_0_rresp,
	S_AXI_RVALID	=> M00_AXI_0_rvalid(0),
	S_AXI_RREADY	=> M00_AXI_0_rready(0)
	);
	
--===========================================
-- STARTUPE2
--===========================================
STARTUPE2_inst : STARTUPE2
    generic map (
    PROG_USR      => "FALSE", -- Activate program event security feature. Requires encrypted bitstreams.
    SIM_CCLK_FREQ => 0.0      -- Set the Configuration Clock Frequency(ns) for simulation.
    )
    port map (
    CFGCLK    => open,      -- 1-bit output: Configuration main clock output
    CFGMCLK   => open,      -- 1-bit output: Configuration internal oscillator clock output
    EOS       => EOS_Reset, -- 1-bit output: Active high output signal indicating the End Of Startup.
    PREQ      => open,      -- 1-bit output: PROGRAM request to fabric output
    CLK       => '0',       -- 1-bit input: User start-up clock input
    GSR       => '0',       -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
    GTS       => '0',       -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
    KEYCLEARB => '1',       -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
    PACK      => '0',       -- 1-bit input: PROGRAM acknowledge input
    USRCCLKO  => '0',       -- 1-bit input: User CCLK input
                            -- For Zynq-7000 devices, this input must be tied to GND
    USRCCLKTS => '1',       -- 1-bit input: User CCLK 3-state enable input
                            -- For Zynq-7000 devices, this input must be tied to VCC
    USRDONEO  => '1',       -- 1-bit input: User DONE pin output control
    USRDONETS => '1'        -- 1-bit input: User DONE 3-state enable output
    );

    not_EOS_reset <= not EOS_Reset;
    
--===========================================
--             Reset module
--===========================================
SAFE_RESET: RESET_MODULE 
	PORT MAP(
	reset_in 		=> not_EOS_reset,
	reset_out 		=> reset,
	locked_fasi 	=> PLL_locked,
	CLK_IN_USB 		=> Master_CLK25,
	clk_failed 		=> open,
	clk_is_not_wrk  => '0'
	);

--===========================================
-- Differential receiver for cable clock (1)
--===========================================
IBUFGDS_1: IBUFGDS
    generic map (
    IBUF_LOW_PWR => TRUE) -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards")
    port map (
    O  => CLK_Cable_1,    -- Clock buffer output
    I  => REF_CLK_P,      -- Diff_p clock buffer input
    IB => REF_CLK_N       -- Diff_n clock buffer input
    );

--===========================================
-- Differential receiver for cable clock (2)
--===========================================
IBUFGDS_2: IBUFGDS
    generic map (
    IBUF_LOW_PWR => TRUE) -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards")
    port map (
    O  => CLK_Cable_2,   -- Clock buffer output
    I  => REF_CLK2_P,    -- Diff_p clock buffer input
    IB => REF_CLK2_N     -- Diff_n clock buffer input
    );
   
--===========================================
--           CLK safe module
--===========================================	
CLK_SAFE_MODULE: CLK_SAFE 
    PORT MAP(
        -- IN
        Ref_CLK1 		=> CLK_Cable_1,     -- ref_CLK dal cable 1                         
        Ref_CLK2 		=> CLK_Cable_2,     -- ref_CLK dal cable 2                         
        XCLK 			=> Quartz25,        --Quartz a 25MHz                                 
        FCLK25M 		=> FCLK_25,         -- CLK from fabric                             
        RESET 			=> Reset,           -- Reset component                         
        CLK_ext_int	    => CLK_ext_int,     -- 0 = Internal, 1 = External                   
        CLK_aut_man	    => CLK_aut_man,     -- 0 = Manual,   1 = Automatic                  
        CLK_aut_man_ref => CLK_aut_man_ref, -- 0 = Manual,   1 = Automatic                 
        CLK_cable_1_2 	=> CLK_1_2,         -- 0 = cable1,   1 = cable2  
        RST_clk_reg     => Rst_CLK_reg,              
        -- OUT
        CLK_OK_flg      => CLK_OK_flg,
        CLK_OK_1        => CLK_OK_1,
        CLK_Perso_1     => CLK_Lost_1,
        CLK_ritrov_1    => CLK_Found_1,
        CLK_OK_2 	    => CLK_OK_2,     
        CLK_Perso_2     => CLK_Lost_2, 
        CLK_ritrov_2    => CLK_Found_2,
        Mast_CLK25MHz   => Master_CLK25
        );
    
--===========================================
--            7 phases generator
--===========================================
multiphase_clock : clk_wiz_0
    port map ( 
    -- Clock out ports  
    clk_out1 => Multiclk(0), -- Clocks out to multichannel
    clk_out2 => Multiclk(1),
    clk_out3 => Multiclk(2),
    clk_out4 => Multiclk(3),
    clk_out5 => Multiclk(4),
    clk_out6 => Multiclk(5),
    clk_out7 => Multiclk(6),
    -- Status and control signals                
    reset  => Reset,
    locked => PLL_locked,  -- locked signal
    -- Clock in ports
    CLK_IN1 => Master_CLK25 -- master 25MHz clock from the CLK_safe module
    ); 

--===========================================
--              Multychannel
--===========================================
MULTYCHANNEL: Multychannel_V2
    Port MAP (
        Multiclk     => Multiclk,
        Reset        => Rst_multychannel_s,
        Counter200M  => COUNTER200M,
        -- PPS channel
        PPS          => PPS,
        COUNTA_sec   => (others => '0'),
        -- From/To RunControl
        delay        => TDC_delay,
        massimo      => Time_to_peaks,
        ch_enable    => CH_ENABLE,
        calibrazione => Calibrate_ADC,
        PPS_ch_en    => Enable_PPS,
        Pulser       => Pulser_sig,
        count_tm     => Timeout_shifter,
        dead_time    => Dead_time,
        ratemeters   => Ratemeters,
        --PPS channel
        unixtime     => Unixtime,
        time_p       => OUT_TIME_P,
        time_n       => OUT_TIME_N,
        -- SPI
        sdi          => ADC_SDATA,
        sclk         => ADC_SCL,
        chip_select  => chip_select,
        -- To big FIFO
        HF_FIFO      => RD_EN_FIFO,
        wr_en_o      => wr_en_fifo,
        dout_to_FIFO => din_BIG
        );

Rst_multychannel_s <= Rst_multychannel or reset;
din_to_AXI_le      <= dout_BIG(15 downto 0) & dout_BIG(31 downto 16);    -- conversion to little endian for AXI DMA
ADC_CS             <= CH_ENABLE or chip_select;

--===========================================
--             Data FIFO
--===========================================
FIFO_DATA_32bit : fifo_generator_0
    PORT MAP (
    clk           => Multiclk(0),
    rst           => RST_FIFO,   
    din           => din_BIG,     -- DATA_event_32bits,
    wr_en         => wr_en_fifo,  -- FIFO_32_WR_EN_int,
    rd_en         => RD_EN_FIFO,  -- AXI_STR_RXD_0_tready,
    dout          => dout_BIG,
    full          => open,
    valid         => valid,
    empty         => empty_Big,
    data_count    => FIFO_data_count,
    prog_full     => HF_FIFO
    );
    
RD_EN_FIFO     <= AXI_STR_RXD_0_tready and FIFO_nEmpty_32 and valid;
RST_FIFO       <= (not peripheral_aresetn(0)) or Reset;
FIFO_nEmpty_32 <= not empty_Big;
      
--===========================================
--          TLAST Generation process 
--===========================================
Tlast_gen: process(Multiclk(0),  peripheral_aresetn)
begin
    if  peripheral_aresetn(0) = '0' then
        tlast_cnt	            <= 0;	   -- Clear counter
        AXI_STR_RXD_0_tlast_int <= '0';
    elsif rising_edge(Multiclk(0)) then
        -- read only if both valid and ready
        if (AXI_STR_RXD_0_tready = '1' and FIFO_nEmpty_32 = '1') then
            -- Set tlast every word number PKT_SIZE-1, ie every PKT_SIZE DWORD written into the fifo
            if (tlast_cnt = PKT_SIZE-2) then
                AXI_STR_RXD_0_tlast_int <= '1';
            else
                AXI_STR_RXD_0_tlast_int <= '0';									-- 
            end if; 
            -- Increment tlast counter when tready is '1'
            if tlast_cnt = PKT_SIZE-1 then
                tlast_cnt <= 0;
            else
                tlast_cnt <= tlast_cnt + 1;
            end if; 
        end if;
    end if;    
end process Tlast_gen;
	
--===========================================
--			 PPS recovery module
--===========================================
PPS_recovery: pps_module2 
    PORT MAP(
        -- IN
        CLK_25MHZ 	      => Master_CLK25,
        CLK_200MHZ 	      => Multiclk(0),
        CLK_200MHZ_1      => Multiclk(6),
        RESET 		      => RESET,
        RunC_Res_FLG      => Res_TagFlg,
        Runc_Val_Tag0     => Val_Tag0,             -- latenza 3, quindi valore più 3
        UnixTime_ARM      => UnixTime,
        Rst_Unix_Time     => Res_Unixtime_flag,
        -- OUT
        PPS_OUT 	      => PPS,
	    RunC_PPS_na		  => RunC_PPS_na,          -- 0 = PPS not aligned, 1 = PPS aligned
 	    RunC_PPS_nr		  => RunC_PPS_nr,          -- 0 = PPS not received, 1 = PPS received        CONTA 		      => COUNTER200M,
        COUNTA_sec 	      => PPS_contati,
        Unix_Time_na      => Unixtime_na
        );
	
--===========================================
--			       PULSER
--===========================================
Pulser_module: Pulser 
    PORT MAP(
	CLK 		=> Master_CLK25,
	RESET 		=> Reset,
	Periodo_ms 	=> Pulser_period,
	PULSER_OUT 	=> Pulser_sig
    );				

--===========================================
--		 Buffer for the clock output (1)
--===========================================
OBUFGDS_inst : OBUFDS
   port map (
   I  => CLK_Cable_1, -- Clock buffer output
   O  => EXT_TRG_P,   -- Diff_p clock buffer input
   OB => EXT_TRG_N    -- Diff_n clock buffer input
   );

--===========================================
--		 Buffer for the clock output (1)
--===========================================
OBUFGDS2_inst : OBUFDS
   port map (
   I  => CLK_Cable_2, -- Clock buffer output
   O  => EXT_TRG2_P,  -- Diff_p clock buffer input
   OB => EXT_TRG2_N   -- Diff_n clock buffer input
   );

--===========================================
--		     Output assignment
--===========================================
PWR_EN <= PWR_EN_int;

end Behavioral;
