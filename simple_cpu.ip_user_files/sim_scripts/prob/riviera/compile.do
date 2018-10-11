vlib work
vlib riviera

vlib riviera/xil_defaultlib
vlib riviera/xpm

vmap xil_defaultlib riviera/xil_defaultlib
vmap xpm riviera/xpm

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../simple_cpu.srcs/sources_1/ip/prob/hdl/verilog" "+incdir+../../../../simple_cpu.srcs/sources_1/ip/prob/hdl/verilog" \
"C:/Xilinx/Vivado/2018.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Xilinx/Vivado/2018.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"C:/Xilinx/Vivado/2018.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../simple_cpu.srcs/sources_1/ip/prob/hdl/verilog" "+incdir+../../../../simple_cpu.srcs/sources_1/ip/prob/hdl/verilog" \
"../../../../simple_cpu.srcs/sources_1/ip/prob/sim/prob.v" \

vlog -work xil_defaultlib \
"glbl.v"

