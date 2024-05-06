// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Thu Feb 15 12:21:02 2024
// Host        : PC_Alessandro running 64-bit major release  (build 9200)
// Command     : write_verilog -mode timesim -nolib -sdf_anno true -force -file
//               C:/Users/alexa/OneDrive/Desktop/Vivado_projects/mPMT_DAQ/mPMT_DAQ.sim/sim_1/impl/timing/xsim/TB_SPI_MS_time_impl.v
// Design      : SPI_ADC_MS
// Purpose     : This verilog netlist is a timing simulation representation of the design and should not be modified or
//               synthesized. Please ensure that this netlist is used with the corresponding SDF file.
// Device      : xc7z014sclg484-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps
`define XIL_TIMING

(* ECO_CHECKSUM = "eca9624b" *) 
(* NotValidForBitStream *)
module SPI_ADC_MS
   (CLK200,
    CLK25,
    RESET,
    Start,
    Reset_SPI,
    Pulse_count,
    SDI,
    SCLK,
    CS,
    DATA_out,
    D_Valid,
    Busy);
  input CLK200;
  input CLK25;
  input RESET;
  input Start;
  input Reset_SPI;
  input [5:0]Pulse_count;
  input SDI;
  output SCLK;
  output CS;
  output [11:0]DATA_out;
  output D_Valid;
  output Busy;

  wire Busy;
  wire Busy_OBUF;
  wire CLK200;
  wire CLK200_IBUF;
  wire CLK200_IBUF_BUFG;
  wire CLK25;
  wire CS;
  wire CS_OBUF;
  wire [11:0]DATA_out;
  wire [11:0]DATA_out_OBUF;
  wire D_Valid;
  wire D_Valid_OBUF;
  wire D_Valid_OBUF_inst_i_2_n_0;
  wire D_Valid_OBUF_inst_i_3_n_0;
  wire [0:0]Data_out_int;
  wire \Data_out_int[12]_i_1_n_0 ;
  wire \Data_out_int_reg[10]_lopt_replica_1 ;
  wire \Data_out_int_reg[11]_lopt_replica_1 ;
  wire \Data_out_int_reg[1]_lopt_replica_1 ;
  wire \Data_out_int_reg[2]_lopt_replica_1 ;
  wire \Data_out_int_reg[3]_lopt_replica_1 ;
  wire \Data_out_int_reg[4]_lopt_replica_1 ;
  wire \Data_out_int_reg[5]_lopt_replica_1 ;
  wire \Data_out_int_reg[6]_lopt_replica_1 ;
  wire \Data_out_int_reg[7]_lopt_replica_1 ;
  wire \Data_out_int_reg[8]_lopt_replica_1 ;
  wire \Data_out_int_reg[9]_lopt_replica_1 ;
  wire \FSM_sequential_present_state[0]_i_1_n_0 ;
  wire \FSM_sequential_present_state[0]_i_2_n_0 ;
  wire \FSM_sequential_present_state[1]_i_1_n_0 ;
  wire [5:0]Pulse_count;
  wire [5:0]Pulse_count_IBUF;
  wire RESET;
  wire RESET_IBUF;
  wire Reset_SPI;
  wire Reset_SPI_IBUF;
  wire SCLK;
  wire SCLK_OBUF;
  wire SCLK_OBUF_BUFG;
  wire SDI;
  wire SDI_IBUF;
  wire Start;
  wire Start_IBUF;
  wire Start_r;
  wire Start_rr;
  wire Start_rr_i_1_n_0;
  wire \count[5]_i_1_n_0 ;
  wire \count[5]_i_2_n_0 ;
  wire [5:0]count_reg;
  wire p_0_in;
  wire [5:0]plusOp;
  wire [1:0]present_state;

initial begin
 $sdf_annotate("TB_SPI_MS_time_impl.sdf",,,,"tool_control");
end
  OBUF Busy_OBUF_inst
       (.I(Busy_OBUF),
        .O(Busy));
  (* SOFT_HLUTNM = "soft_lutpair1" *) 
  LUT4 #(
    .INIT(16'h0FF2)) 
    Busy_OBUF_inst_i_1
       (.I0(Start_r),
        .I1(Start_rr),
        .I2(present_state[1]),
        .I3(present_state[0]),
        .O(Busy_OBUF));
  BUFG CLK200_IBUF_BUFG_inst
       (.I(CLK200_IBUF),
        .O(CLK200_IBUF_BUFG));
  IBUF CLK200_IBUF_inst
       (.I(CLK200),
        .O(CLK200_IBUF));
  IBUF CLK25_IBUF_inst
       (.I(CLK25),
        .O(SCLK_OBUF));
  OBUF CS_OBUF_inst
       (.I(CS_OBUF),
        .O(CS));
  (* SOFT_HLUTNM = "soft_lutpair1" *) 
  LUT5 #(
    .INIT(32'h00009899)) 
    CS_OBUF_inst_i_1
       (.I0(present_state[0]),
        .I1(present_state[1]),
        .I2(Start_rr),
        .I3(Start_r),
        .I4(Start_IBUF),
        .O(CS_OBUF));
  (* OPT_MODIFIED = "SWEEP" *) 
  OBUF \DATA_out_OBUF[0]_inst 
       (.I(\Data_out_int_reg[1]_lopt_replica_1 ),
        .O(DATA_out[0]));
  (* OPT_MODIFIED = "SWEEP" *) 
  OBUF \DATA_out_OBUF[10]_inst 
       (.I(\Data_out_int_reg[11]_lopt_replica_1 ),
        .O(DATA_out[10]));
  OBUF \DATA_out_OBUF[11]_inst 
       (.I(DATA_out_OBUF[11]),
        .O(DATA_out[11]));
  (* OPT_MODIFIED = "SWEEP" *) 
  OBUF \DATA_out_OBUF[1]_inst 
       (.I(\Data_out_int_reg[2]_lopt_replica_1 ),
        .O(DATA_out[1]));
  (* OPT_MODIFIED = "SWEEP" *) 
  OBUF \DATA_out_OBUF[2]_inst 
       (.I(\Data_out_int_reg[3]_lopt_replica_1 ),
        .O(DATA_out[2]));
  (* OPT_MODIFIED = "SWEEP" *) 
  OBUF \DATA_out_OBUF[3]_inst 
       (.I(\Data_out_int_reg[4]_lopt_replica_1 ),
        .O(DATA_out[3]));
  (* OPT_MODIFIED = "SWEEP" *) 
  OBUF \DATA_out_OBUF[4]_inst 
       (.I(\Data_out_int_reg[5]_lopt_replica_1 ),
        .O(DATA_out[4]));
  (* OPT_MODIFIED = "SWEEP" *) 
  OBUF \DATA_out_OBUF[5]_inst 
       (.I(\Data_out_int_reg[6]_lopt_replica_1 ),
        .O(DATA_out[5]));
  (* OPT_MODIFIED = "SWEEP" *) 
  OBUF \DATA_out_OBUF[6]_inst 
       (.I(\Data_out_int_reg[7]_lopt_replica_1 ),
        .O(DATA_out[6]));
  (* OPT_MODIFIED = "SWEEP" *) 
  OBUF \DATA_out_OBUF[7]_inst 
       (.I(\Data_out_int_reg[8]_lopt_replica_1 ),
        .O(DATA_out[7]));
  (* OPT_MODIFIED = "SWEEP" *) 
  OBUF \DATA_out_OBUF[8]_inst 
       (.I(\Data_out_int_reg[9]_lopt_replica_1 ),
        .O(DATA_out[8]));
  (* OPT_MODIFIED = "SWEEP" *) 
  OBUF \DATA_out_OBUF[9]_inst 
       (.I(\Data_out_int_reg[10]_lopt_replica_1 ),
        .O(DATA_out[9]));
  OBUF D_Valid_OBUF_inst
       (.I(D_Valid_OBUF),
        .O(D_Valid));
  LUT4 #(
    .INIT(16'h0F80)) 
    D_Valid_OBUF_inst_i_1
       (.I0(D_Valid_OBUF_inst_i_2_n_0),
        .I1(D_Valid_OBUF_inst_i_3_n_0),
        .I2(present_state[0]),
        .I3(present_state[1]),
        .O(D_Valid_OBUF));
  LUT6 #(
    .INIT(64'h9009000000009009)) 
    D_Valid_OBUF_inst_i_2
       (.I0(count_reg[3]),
        .I1(Pulse_count_IBUF[3]),
        .I2(Pulse_count_IBUF[5]),
        .I3(count_reg[5]),
        .I4(Pulse_count_IBUF[4]),
        .I5(count_reg[4]),
        .O(D_Valid_OBUF_inst_i_2_n_0));
  LUT6 #(
    .INIT(64'h9009000000009009)) 
    D_Valid_OBUF_inst_i_3
       (.I0(count_reg[0]),
        .I1(Pulse_count_IBUF[0]),
        .I2(Pulse_count_IBUF[2]),
        .I3(count_reg[2]),
        .I4(Pulse_count_IBUF[1]),
        .I5(count_reg[1]),
        .O(D_Valid_OBUF_inst_i_3_n_0));
  LUT2 #(
    .INIT(4'h2)) 
    \Data_out_int[12]_i_1 
       (.I0(present_state[0]),
        .I1(present_state[1]),
        .O(\Data_out_int[12]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[0] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(SDI_IBUF),
        .Q(Data_out_int),
        .R(RESET_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[10] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[8]),
        .Q(DATA_out_OBUF[9]),
        .R(RESET_IBUF));
  (* OPT_INSERTED_REPDRIVER *) 
  (* OPT_MODIFIED = "SWEEP" *) 
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[10]_lopt_replica 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[8]),
        .Q(\Data_out_int_reg[10]_lopt_replica_1 ),
        .R(RESET_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[11] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[9]),
        .Q(DATA_out_OBUF[10]),
        .R(RESET_IBUF));
  (* OPT_INSERTED_REPDRIVER *) 
  (* OPT_MODIFIED = "SWEEP" *) 
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[11]_lopt_replica 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[9]),
        .Q(\Data_out_int_reg[11]_lopt_replica_1 ),
        .R(RESET_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[12] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[10]),
        .Q(DATA_out_OBUF[11]),
        .R(RESET_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[1] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(Data_out_int),
        .Q(DATA_out_OBUF[0]),
        .R(RESET_IBUF));
  (* OPT_INSERTED_REPDRIVER *) 
  (* OPT_MODIFIED = "SWEEP" *) 
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[1]_lopt_replica 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(Data_out_int),
        .Q(\Data_out_int_reg[1]_lopt_replica_1 ),
        .R(RESET_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[2] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[0]),
        .Q(DATA_out_OBUF[1]),
        .R(RESET_IBUF));
  (* OPT_INSERTED_REPDRIVER *) 
  (* OPT_MODIFIED = "SWEEP" *) 
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[2]_lopt_replica 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[0]),
        .Q(\Data_out_int_reg[2]_lopt_replica_1 ),
        .R(RESET_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[3] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[1]),
        .Q(DATA_out_OBUF[2]),
        .R(RESET_IBUF));
  (* OPT_INSERTED_REPDRIVER *) 
  (* OPT_MODIFIED = "SWEEP" *) 
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[3]_lopt_replica 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[1]),
        .Q(\Data_out_int_reg[3]_lopt_replica_1 ),
        .R(RESET_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[4] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[2]),
        .Q(DATA_out_OBUF[3]),
        .R(RESET_IBUF));
  (* OPT_INSERTED_REPDRIVER *) 
  (* OPT_MODIFIED = "SWEEP" *) 
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[4]_lopt_replica 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[2]),
        .Q(\Data_out_int_reg[4]_lopt_replica_1 ),
        .R(RESET_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[5] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[3]),
        .Q(DATA_out_OBUF[4]),
        .R(RESET_IBUF));
  (* OPT_INSERTED_REPDRIVER *) 
  (* OPT_MODIFIED = "SWEEP" *) 
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[5]_lopt_replica 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[3]),
        .Q(\Data_out_int_reg[5]_lopt_replica_1 ),
        .R(RESET_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[6] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[4]),
        .Q(DATA_out_OBUF[5]),
        .R(RESET_IBUF));
  (* OPT_INSERTED_REPDRIVER *) 
  (* OPT_MODIFIED = "SWEEP" *) 
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[6]_lopt_replica 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[4]),
        .Q(\Data_out_int_reg[6]_lopt_replica_1 ),
        .R(RESET_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[7] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[5]),
        .Q(DATA_out_OBUF[6]),
        .R(RESET_IBUF));
  (* OPT_INSERTED_REPDRIVER *) 
  (* OPT_MODIFIED = "SWEEP" *) 
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[7]_lopt_replica 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[5]),
        .Q(\Data_out_int_reg[7]_lopt_replica_1 ),
        .R(RESET_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[8] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[6]),
        .Q(DATA_out_OBUF[7]),
        .R(RESET_IBUF));
  (* OPT_INSERTED_REPDRIVER *) 
  (* OPT_MODIFIED = "SWEEP" *) 
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[8]_lopt_replica 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[6]),
        .Q(\Data_out_int_reg[8]_lopt_replica_1 ),
        .R(RESET_IBUF));
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[9] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[7]),
        .Q(DATA_out_OBUF[8]),
        .R(RESET_IBUF));
  (* OPT_INSERTED_REPDRIVER *) 
  (* OPT_MODIFIED = "SWEEP" *) 
  FDRE #(
    .INIT(1'b0)) 
    \Data_out_int_reg[9]_lopt_replica 
       (.C(SCLK_OBUF_BUFG),
        .CE(\Data_out_int[12]_i_1_n_0 ),
        .D(DATA_out_OBUF[7]),
        .Q(\Data_out_int_reg[9]_lopt_replica_1 ),
        .R(RESET_IBUF));
  LUT6 #(
    .INIT(64'h000000009DDD8CCC)) 
    \FSM_sequential_present_state[0]_i_1 
       (.I0(present_state[1]),
        .I1(present_state[0]),
        .I2(D_Valid_OBUF_inst_i_2_n_0),
        .I3(D_Valid_OBUF_inst_i_3_n_0),
        .I4(\FSM_sequential_present_state[0]_i_2_n_0 ),
        .I5(RESET_IBUF),
        .O(\FSM_sequential_present_state[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair2" *) 
  LUT2 #(
    .INIT(4'h2)) 
    \FSM_sequential_present_state[0]_i_2 
       (.I0(Start_r),
        .I1(Start_rr),
        .O(\FSM_sequential_present_state[0]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'h00000000CE8A8A8A)) 
    \FSM_sequential_present_state[1]_i_1 
       (.I0(present_state[1]),
        .I1(present_state[0]),
        .I2(Reset_SPI_IBUF),
        .I3(D_Valid_OBUF_inst_i_3_n_0),
        .I4(D_Valid_OBUF_inst_i_2_n_0),
        .I5(RESET_IBUF),
        .O(\FSM_sequential_present_state[1]_i_1_n_0 ));
  (* FSM_ENCODED_STATES = "receive:01,data_ready:10,idle:00" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_sequential_present_state_reg[0] 
       (.C(CLK200_IBUF_BUFG),
        .CE(1'b1),
        .D(\FSM_sequential_present_state[0]_i_1_n_0 ),
        .Q(present_state[0]),
        .R(1'b0));
  (* FSM_ENCODED_STATES = "receive:01,data_ready:10,idle:00" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_sequential_present_state_reg[1] 
       (.C(CLK200_IBUF_BUFG),
        .CE(1'b1),
        .D(\FSM_sequential_present_state[1]_i_1_n_0 ),
        .Q(present_state[1]),
        .R(1'b0));
  IBUF \Pulse_count_IBUF[0]_inst 
       (.I(Pulse_count[0]),
        .O(Pulse_count_IBUF[0]));
  IBUF \Pulse_count_IBUF[1]_inst 
       (.I(Pulse_count[1]),
        .O(Pulse_count_IBUF[1]));
  IBUF \Pulse_count_IBUF[2]_inst 
       (.I(Pulse_count[2]),
        .O(Pulse_count_IBUF[2]));
  IBUF \Pulse_count_IBUF[3]_inst 
       (.I(Pulse_count[3]),
        .O(Pulse_count_IBUF[3]));
  IBUF \Pulse_count_IBUF[4]_inst 
       (.I(Pulse_count[4]),
        .O(Pulse_count_IBUF[4]));
  IBUF \Pulse_count_IBUF[5]_inst 
       (.I(Pulse_count[5]),
        .O(Pulse_count_IBUF[5]));
  IBUF RESET_IBUF_inst
       (.I(RESET),
        .O(RESET_IBUF));
  IBUF Reset_SPI_IBUF_inst
       (.I(Reset_SPI),
        .O(Reset_SPI_IBUF));
  BUFG SCLK_OBUF_BUFG_inst
       (.I(SCLK_OBUF),
        .O(SCLK_OBUF_BUFG));
  OBUF SCLK_OBUF_inst
       (.I(SCLK_OBUF_BUFG),
        .O(SCLK));
  IBUF SDI_IBUF_inst
       (.I(SDI),
        .O(SDI_IBUF));
  IBUF Start_IBUF_inst
       (.I(Start),
        .O(Start_IBUF));
  LUT1 #(
    .INIT(2'h1)) 
    Start_r_i_1
       (.I0(RESET_IBUF),
        .O(p_0_in));
  FDRE #(
    .INIT(1'b0)) 
    Start_r_reg
       (.C(CLK200_IBUF_BUFG),
        .CE(p_0_in),
        .D(Start_IBUF),
        .Q(Start_r),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair2" *) 
  LUT3 #(
    .INIT(8'hE2)) 
    Start_rr_i_1
       (.I0(Start_r),
        .I1(RESET_IBUF),
        .I2(Start_rr),
        .O(Start_rr_i_1_n_0));
  FDRE #(
    .INIT(1'b0)) 
    Start_rr_reg
       (.C(CLK200_IBUF_BUFG),
        .CE(1'b1),
        .D(Start_rr_i_1_n_0),
        .Q(Start_rr),
        .R(1'b0));
  LUT1 #(
    .INIT(2'h1)) 
    \count[0]_i_1 
       (.I0(count_reg[0]),
        .O(plusOp[0]));
  (* SOFT_HLUTNM = "soft_lutpair3" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \count[1]_i_1 
       (.I0(count_reg[0]),
        .I1(count_reg[1]),
        .O(plusOp[1]));
  (* SOFT_HLUTNM = "soft_lutpair3" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \count[2]_i_1 
       (.I0(count_reg[0]),
        .I1(count_reg[1]),
        .I2(count_reg[2]),
        .O(plusOp[2]));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \count[3]_i_1 
       (.I0(count_reg[1]),
        .I1(count_reg[0]),
        .I2(count_reg[2]),
        .I3(count_reg[3]),
        .O(plusOp[3]));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \count[4]_i_1 
       (.I0(count_reg[2]),
        .I1(count_reg[0]),
        .I2(count_reg[1]),
        .I3(count_reg[3]),
        .I4(count_reg[4]),
        .O(plusOp[4]));
  LUT3 #(
    .INIT(8'hF8)) 
    \count[5]_i_1 
       (.I0(D_Valid_OBUF_inst_i_2_n_0),
        .I1(D_Valid_OBUF_inst_i_3_n_0),
        .I2(RESET_IBUF),
        .O(\count[5]_i_1_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \count[5]_i_2 
       (.I0(present_state[0]),
        .I1(present_state[1]),
        .O(\count[5]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \count[5]_i_3 
       (.I0(count_reg[3]),
        .I1(count_reg[1]),
        .I2(count_reg[0]),
        .I3(count_reg[2]),
        .I4(count_reg[4]),
        .I5(count_reg[5]),
        .O(plusOp[5]));
  FDRE #(
    .INIT(1'b0)) 
    \count_reg[0] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\count[5]_i_2_n_0 ),
        .D(plusOp[0]),
        .Q(count_reg[0]),
        .R(\count[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \count_reg[1] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\count[5]_i_2_n_0 ),
        .D(plusOp[1]),
        .Q(count_reg[1]),
        .R(\count[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \count_reg[2] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\count[5]_i_2_n_0 ),
        .D(plusOp[2]),
        .Q(count_reg[2]),
        .R(\count[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \count_reg[3] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\count[5]_i_2_n_0 ),
        .D(plusOp[3]),
        .Q(count_reg[3]),
        .R(\count[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \count_reg[4] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\count[5]_i_2_n_0 ),
        .D(plusOp[4]),
        .Q(count_reg[4]),
        .R(\count[5]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \count_reg[5] 
       (.C(SCLK_OBUF_BUFG),
        .CE(\count[5]_i_2_n_0 ),
        .D(plusOp[5]),
        .Q(count_reg[5]),
        .R(\count[5]_i_1_n_0 ));
endmodule
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

endmodule
`endif
