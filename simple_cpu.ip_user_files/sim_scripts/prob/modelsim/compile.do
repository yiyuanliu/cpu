vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib
vlib modelsim_lib/msim/xpm

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib
vmap xpm modelsim_lib/msim/xpm

vlog -work xil_defaultlib -64 -incr -sv "+incdir+../../../../simple_cpu.srcs/sources_1/ip/prob/hdl/verilog" "+incdir+../../../../simple_cpu.srcs/sources_1/ip/prob/hdl/verilog" \
"C:/Xilinx/Vivado/2018.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Xilinx/Vivado/2018.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93 \
"C:/Xilinx/Vivado/2018.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib -64 -incr "+incdir+../../../../simple_cpu.srcs/sources_1/ip/prob/hdl/verilog" "+incdir+../../../../simple_cpu.srcs/sources_1/ip/prob/hdl/verilog" \
"../../../../simple_cpu.srcs/sources_1/ip/prob/sim/prob.v" \

vlog -work xil_defaultlib \
"glbl.v"

