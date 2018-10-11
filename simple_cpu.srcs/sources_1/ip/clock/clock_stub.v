// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.1 (win64) Build 2188600 Wed Apr  4 18:40:38 MDT 2018
// Date        : Sun Oct  7 16:28:11 2018
// Host        : DESKTOP-U7JOL3T running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/Users/lyy/ise_proj/simple_cpu/simple_cpu.srcs/sources_1/ip/clock/clock_stub.v
// Design      : clock
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tfgg676-2L
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clock(clk_50m_o, clk_200m_o, power_down, locked, clk_i)
/* synthesis syn_black_box black_box_pad_pin="clk_50m_o,clk_200m_o,power_down,locked,clk_i" */;
  output clk_50m_o;
  output clk_200m_o;
  input power_down;
  output locked;
  input clk_i;
endmodule
