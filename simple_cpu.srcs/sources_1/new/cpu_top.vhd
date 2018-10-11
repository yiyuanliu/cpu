library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common.all;

entity cpu_top is
	port (
		clk_50M : in std_logic;
		reset_btn, clock_btn : in std_logic;

		txd : out std_logic;
		rxd : in std_logic;
		leds : out std_logic_vector(15 downto 0);

		ext_ram_addr : out std_logic_vector(19 downto 0);
		ext_ram_data : inout std_logic_vector(31 downto 0);
		ext_ram_be_n : out std_logic_vector(3 downto 0);
		ext_ram_ce_n : out std_logic;
		ext_ram_oe_n : out std_logic;
		ext_ram_we_n : out std_logic;

		base_ram_addr : out std_logic_vector(19 downto 0);
		base_ram_data : inout std_logic_vector(31 downto 0);
		base_ram_be_n : out std_logic_vector(3 downto 0);
		base_ram_ce_n : out std_logic;
		base_ram_oe_n : out std_logic;
		base_ram_we_n : out std_logic;
		
		dpy1, dpy0 : out std_logic_vector(7 downto 0)
		
		-- uart_wrn : out std_logic;
		-- uart_rdn : out std_logic
	);
end cpu_top;

architecture behavioral of cpu_top is
	-- pc
	component pc is
		port (
	        clk_i, rst_i : in std_logic;
	        if_stall_i, if_finish_i : in std_logic;
	        jaddr_i : in std_logic_vector(31 downto 0);
	        jump_i : in std_logic;
	        addr_o : out std_logic_vector(31 downto 0)
	    ) ;
	end component pc;

	-- if_state
	component if_stage is
		port (
			clk_i : in std_logic;
	        rst_i : in std_logic;
	        pc_addr_i : in std_logic_vector(31 downto 0);
	        stall_i : in std_logic;
	        finished_o : out std_logic;
	        ins_data_o : out std_logic_vector(31 downto 0);
	        ins_addr_o : out std_logic_vector(31 downto 0);

	        data_i : in std_logic_vector(31 downto 0);
	        ack_i : in std_logic;
	        addr_o : out std_logic_vector(31 downto 0);
	        req_o : out std_logic
		);
	end component if_stage;

	-- id_stage
	component id_stage is
		port (
			-- input from pipeline
			clk_i : in std_logic;
			rst_i : in std_logic;
			stall_i : in std_logic;
			pc_addr_i : in std_logic_vector(31 downto 0);
			ins_addr_i : in std_logic_vector(31 downto 0);
			ins_data_i : in std_logic_vector(31 downto 0);
			-- dataforward signal
			ex_mem_op_i : in mem_op_type;
			ex_wb_dst_i : in std_logic_vector(4 downto 0);
			ex_data_i : in std_logic_vector(31 downto 0);
			mem_wb_dst_i : in std_logic_vector(4 downto 0);
			mem_data_i : in std_logic_vector(31 downto 0);
			-- output to pipeline
			jump_o : out std_logic;
			jaddr_o : out std_logic_vector(31 downto 0);
			finish_o : out std_logic;
			ex_opnum1_o : out std_logic_vector(31 downto 0);
			ex_opnum2_o : out std_logic_vector(31 downto 0);
			ex_op_o : out ex_op_type;
			mem_op_o : out mem_op_type;
			mem_mode_o : out mem_mode_type;
			mem_we_data_o : out std_logic_vector(31 downto 0);
			wb_dst_o : out std_logic_vector(4 downto 0);
			-- output to reg_file
			reg_rd1_addr_o : out std_logic_vector(4 downto 0);
			reg_rd2_addr_o : out std_logic_vector(4 downto 0);
			-- input from reg_file
			reg_rd1_data_i : in std_logic_vector(31 downto 0);
			reg_rd2_data_i : in std_logic_vector(31 downto 0)
		);
	end component id_stage; 
	
	-- ex_stage
	component ex_stage is
		port (
			rst_i : in std_logic;
			clk_i : in std_logic;
			stall_i : in std_logic;
			finish_o : out std_logic;

			ex_opnum1_i : in std_logic_vector(31 downto 0);
			ex_opnum2_i : in std_logic_vector(31 downto 0);
			ex_op_i : in ex_op_type;
			mem_op_i : in mem_op_type;
			mem_mode_i : in mem_mode_type;
			mem_we_data_i : in std_logic_vector(31 downto 0);
			wb_dst_i : in std_logic_vector(4 downto 0);

			ex_data_o : out std_logic_vector(31 downto 0);

			mem_op_o : out mem_op_type;
			mem_mode_o : out mem_mode_type;
			mem_we_data_o : out std_logic_vector(31 downto 0);

			wb_dst_o : out std_logic_vector(4 downto 0)
		);
	end component ex_stage;

	component mem_stage is
		port (
			clk_i : in std_logic;
			rst_i : in std_logic;
			stall_i : in std_logic;
			finish_o : out std_logic;

			ex_data_i : in std_logic_vector(31 downto 0);
			mem_op_i : in mem_op_type;
			mem_mode_i : in mem_mode_type;
			mem_we_data_i : in std_logic_vector(31 downto 0);
			wb_dst_i : in std_logic_vector(4 downto 0);

			mem_data_o : out std_logic_vector(31 downto 0);
			wb_dst_o : out std_logic_vector(4 downto 0);

			mem_addr_o : out std_logic_vector(31 downto 0);
			mem_we_data_o : out std_logic_vector(31 downto 0);
			mem_req_o : out std_logic;
			mem_we_o : out std_logic;
			mem_mode_o : out mem_mode_type;
			mem_rd_data_i : in std_logic_vector(31 downto 0);
			mem_ack_i : in std_logic
		);
	end component mem_stage;

	component wb_stage is
		port (
			clk_i : in std_logic;
			rst_i : in std_logic;
			stall_i : in std_logic;
			finish_o : out std_logic;

			wb_dst_i : in std_logic_vector(4 downto 0);
			mem_data_i : in std_logic_vector(31 downto 0);

			-- to reg_file
			reg_we_o : out std_logic;
			reg_we_data_o : out std_logic_vector(31 downto 0);
			reg_we_addr_o : out std_logic_vector(4 downto 0)
		);
	end component wb_stage;

	component reg_file is
		port (
			clk_i, rst_i : in std_logic;
			rd_1_addr_i, rd_2_addr_i, we_addr_i : in std_logic_vector(4 downto 0);
			rd_1_data_o, rd_2_data_o : out std_logic_vector(31 downto 0);
			we_data_i : in std_logic_vector(31 downto 0);
			we_i : in std_logic
		);
	end component reg_file;

	component smmu is
		port (
			-- if 阶段信号
			pc_req_i : in std_logic;
			pc_addr_i : in std_logic_vector(31 downto 0);
			pc_ack_o : out std_logic;
			pc_data_o : out std_logic_vector(31 downto 0);

			-- mem 阶段信号
			mem_req_i : in std_logic;
			mem_we_i : in std_logic;
			mem_mode_i : in mem_mode_type;
			mem_addr_i : in std_logic_vector(31 downto 0);
			mem_we_data_i : in std_logic_vector(31 downto 0);

			mem_ack_o : out std_logic;
			mem_rd_data_o : out std_logic_vector(31 downto 0);

			-- ram_ctrl1 的信?
			ram1_req_o : out std_logic;
			ram1_we_o : out std_logic;
			ram1_mode_o : out mem_mode_type;
			ram1_addr_o : out std_logic_vector(21 downto 0);
			ram1_we_data_o : out std_logic_vector(31 downto 0);

			ram1_ack_i : in std_logic;
			ram1_rd_data_i : in std_logic_vector(31 downto 0);

			-- ram_ctrl2 的信?
			ram2_req_o : out std_logic;
			ram2_we_o : out std_logic;
			ram2_mode_o : out mem_mode_type;
			ram2_addr_o : out std_logic_vector(21 downto 0);
			ram2_we_data_o : out std_logic_vector(31 downto 0);

			ram2_ack_i : in std_logic;
			ram2_rd_data_i : in std_logic_vector(31 downto 0);

			-- 串口信号
			uart_req_o : out std_logic;
			uart_we_o : out std_logic;
			uart_mode_data_o : out std_logic;
			uart_we_data_o : out std_logic_vector(7 downto 0);

			uart_ack_i : in std_logic;
			uart_rd_data_i : in std_logic_vector(7 downto 0)
		);
	end component smmu;

	component ram_ctrl is
		port (
			clk_i : in std_logic;
			rst_i : in std_logic;
			we_data_i : in std_logic_vector(31 downto 0);
			addr_i : in std_logic_vector(21 downto 0);
			we_i : in std_logic;
			req_i : in std_logic;
			mode_i : in mem_mode_type;

			rd_data_o : out std_logic_vector(31 downto 0);
			ack_o : out std_logic;

			ram_addr_o : out std_logic_vector(19 downto 0);
			ram_data_io : inout std_logic_vector(31 downto 0);
			ram_be_o : out std_logic_vector(3 downto 0);
			ram_oe_o : out std_logic;
			ram_we_o : out std_logic;
			ram_ce_o : out std_logic
		);
	end component ram_ctrl;

	component uart_ctrl is
		port (
			clk_i, rst_i : in std_logic;
			req_i : in std_logic;
			we_i : in std_logic;
			mode_data_i : in std_logic;
			data_i : in std_logic_vector(7 downto 0);

			data_o : out std_logic_vector(7 downto 0);
			ack_o : out std_logic;

			rxd_i : in std_logic;
			txd_o : out std_logic
		);
	end component uart_ctrl;

	signal clk, rst : std_logic;
	signal stall_1, stall_2 : std_logic;

	signal pc_addr : std_logic_vector(31 downto 0);

	signal if_finish : std_logic;
	signal if_ins_data : std_logic_vector(31 downto 0);
	signal if_ins_addr : std_logic_vector(31 downto 0);
	signal if_smmu_addr : std_logic_vector(31 downto 0);
	signal if_smmu_req : std_logic;

	signal id_jump : std_logic;
	signal id_jaddr : std_logic_vector(31 downto 0);
	signal id_finish : std_logic;
	signal id_ex_opnum1, id_ex_opnum2 : std_logic_vector(31 downto 0);
	signal id_ex_op : ex_op_type;
	signal id_mem_op : mem_op_type;
	signal id_mem_mode : mem_mode_type;
	signal id_mem_we_data : std_logic_vector(31 downto 0);
	signal id_wb_dst : std_logic_vector(4 downto 0);

	signal ex_finish : std_logic;
	signal ex_data : std_logic_vector(31 downto 0);
	signal ex_mem_op : mem_op_type;
	signal ex_mem_mode : mem_mode_type;
	signal ex_mem_we_data : std_logic_vector(31 downto 0);
	signal ex_wb_dst : std_logic_vector(4 downto 0);

	signal mem_finish : std_logic;
	signal mem_data : std_logic_vector(31 downto 0);
	signal mem_wb_dst : std_logic_vector(4 downto 0);
	
	signal mem_smmu_addr : std_logic_vector(31 downto 0);
	signal mem_smmu_we_data : std_logic_vector(31 downto 0);
	signal mem_smmu_req : std_logic;
	signal mem_smmu_we : std_logic;
	signal mem_smmu_mode : mem_mode_type;

	signal wb_finish : std_logic;

	signal reg_rd1_addr, reg_rd2_addr, reg_we_addr : std_logic_vector(4 downto 0);
	signal reg_we_data, reg_rd1_data, reg_rd2_data : std_logic_vector(31 downto 0);
	signal reg_we : std_logic;

	signal smmu_pc_ack : std_logic;
	signal smmu_pc_data : std_logic_vector(31 downto 0);
	signal smmu_mem_ack : std_logic;
	signal smmu_mem_rd_data : std_logic_vector(31 downto 0);

	signal smmu_ram1_req : std_logic;
	signal smmu_ram1_we : std_logic;
	signal smmu_ram1_mode : mem_mode_type;
	signal smmu_ram1_addr : std_logic_vector(21 downto 0);
	signal smmu_ram1_we_data : std_logic_vector(31 downto 0);

	signal smmu_ram2_req : std_logic;
	signal smmu_ram2_we : std_logic;
	signal smmu_ram2_mode : mem_mode_type;
	signal smmu_ram2_addr : std_logic_vector(21 downto 0);
	signal smmu_ram2_we_data : std_logic_vector(31 downto 0);

	signal smmu_uart_req : std_logic;
	signal smmu_uart_we : std_logic;
	signal smmu_uart_mode_data : std_logic;
	signal smmu_uart_we_data : std_logic_vector(7 downto 0);
	
	signal ram1_smmu_rd_data : std_logic_vector(31 downto 0);
	signal ram1_smmu_ack : std_logic;
	signal ram2_smmu_rd_data : std_logic_vector(31 downto 0);
	signal ram2_smmu_ack : std_logic;

	signal uart_smmu_rd_data : std_logic_vector(7 downto 0);
	signal uart_smmu_ack : std_logic;
	
	signal mem_illegal_addr : std_logic_vector(31 downto 0);
	type target_dev is (ram1, ram2, uart, illegal_addr);
	signal mem_target : target_dev;

	signal we_cnt, state_cnt : std_logic_vector(3 downto 0);
begin
	mem_target <= ram1 when (mem_smmu_addr(31 downto 22) = "1000000000") else
				ram2 when (mem_smmu_addr(31 downto 22) = "1000000001") else
				uart when (mem_smmu_addr(31 downto 3) = "10111111110100000000001111111") else
				illegal_addr;
	process(clk, rst)
	begin
		if rst = '0' then
			mem_illegal_addr <= (others => '0');
			we_cnt <= (others => '0');
			state_cnt <= (others => '0');
		elsif clk'event and clk = '1' then
			if (mem_smmu_req = '1') and mem_target = illegal_addr then
				mem_illegal_addr <= mem_smmu_addr;
			end if;

			if (smmu_uart_mode_data = '1' and smmu_uart_req = '1' and smmu_uart_we = '1') then
				we_cnt <= std_logic_vector(unsigned(we_cnt) + 1);
			end if;

			if smmu_uart_mode_data = '0' and smmu_uart_req = '1' and smmu_uart_we = '0' then
				state_cnt <= std_logic_vector(unsigned(state_cnt) + 1);
			end if;
		end if;
	end process;

	-- '1000 0000 1000 0000 1111 1111 1111 1111' => '8080ffff'
	leds(3 downto 0) <= we_cnt;
	leds(11 downto 8) <= state_cnt;

	pc_ins : pc
	port map (
		clk_i => clk,
		rst_i => rst,
        if_stall_i => stall_1,
        if_finish_i => if_finish,
        jaddr_i => id_jaddr,
        jump_i => id_jump,
        addr_o => pc_addr
	);

	if_ins : if_stage
	port map (
		clk_i => clk,
        rst_i => rst,
        pc_addr_i => pc_addr,
        stall_i => stall_1,
        finished_o => if_finish,
        ins_data_o => if_ins_data,
        ins_addr_o => if_ins_addr,

        data_i => smmu_pc_data,
        ack_i => smmu_pc_ack,
        addr_o => if_smmu_addr,
        req_o => if_smmu_req
	);

	id_ins : id_stage
	port map (
		-- input from pipeline
		clk_i => clk,
		rst_i => rst,
		stall_i => stall_1,
		pc_addr_i => pc_addr,
		ins_addr_i => if_ins_addr,
		ins_data_i => if_ins_data,
		-- dataforward signal
		ex_mem_op_i => ex_mem_op,
		ex_wb_dst_i => ex_wb_dst,
		ex_data_i => ex_data,
		mem_wb_dst_i => mem_wb_dst,
		mem_data_i => mem_data,
		-- output to pipeline
		jump_o => id_jump,
		jaddr_o => id_jaddr,
		finish_o => id_finish,
		ex_opnum1_o => id_ex_opnum1,
		ex_opnum2_o => id_ex_opnum2,
		ex_op_o => id_ex_op,
		mem_op_o => id_mem_op,
		mem_mode_o => id_mem_mode,
		mem_we_data_o => id_mem_we_data,
		wb_dst_o => id_wb_dst,
		-- output to reg_file
		reg_rd1_addr_o => reg_rd1_addr,
		reg_rd2_addr_o => reg_rd2_addr,
		-- input from reg_file
		reg_rd1_data_i => reg_rd1_data,
		reg_rd2_data_i => reg_rd2_data
	);

	ex_ins : ex_stage
	port map (
		rst_i => rst,
		clk_i => clk,
		stall_i => stall_2,
		finish_o => ex_finish,
		ex_opnum1_i => id_ex_opnum1,
		ex_opnum2_i => id_ex_opnum2,
		ex_op_i => id_ex_op,
		mem_op_i => id_mem_op,
		mem_mode_i => id_mem_mode,
		mem_we_data_i => id_mem_we_data,
		wb_dst_i => id_wb_dst,
		ex_data_o => ex_data,
		mem_op_o => ex_mem_op,
		mem_mode_o => ex_mem_mode,
		mem_we_data_o => ex_mem_we_data,
		wb_dst_o => ex_wb_dst
	);

	mem_ins : mem_stage
	port map (
		clk_i => clk,
		rst_i => rst,
		stall_i => stall_2,
		finish_o => mem_finish,
		ex_data_i => ex_data,
		mem_op_i => ex_mem_op,
		mem_mode_i => ex_mem_mode,
		mem_we_data_i => ex_mem_we_data,
		wb_dst_i => ex_wb_dst,
		mem_data_o => mem_data,
		wb_dst_o => mem_wb_dst,
		mem_addr_o => mem_smmu_addr,
		mem_we_data_o => mem_smmu_we_data,
		mem_req_o => mem_smmu_req,
		mem_we_o => mem_smmu_we,
		mem_mode_o => mem_smmu_mode,
		mem_rd_data_i => smmu_mem_rd_data,
		mem_ack_i => smmu_mem_ack
	);

	wb_ins : wb_stage
	port map (
		clk_i => clk,
		rst_i => rst,
		stall_i => stall_2,
		finish_o => wb_finish,
		wb_dst_i => mem_wb_dst,
		mem_data_i => mem_data,
		reg_we_o => reg_we,
		reg_we_data_o => reg_we_data,
		reg_we_addr_o => reg_we_addr
	);

	reg_ins : reg_file
	port map (
		clk_i => clk,
		rst_i => rst,
		rd_1_addr_i => reg_rd1_addr,
		rd_2_addr_i => reg_rd2_addr,
		we_addr_i => reg_we_addr,
		rd_1_data_o => reg_rd1_data,
		rd_2_data_o => reg_rd2_data,
		we_data_i => reg_we_data,
		we_i => reg_we
	);

	smmu_ins : smmu
	port map (
		-- if 阶段信号
		pc_req_i => if_smmu_req,
		pc_addr_i => if_smmu_addr,
		pc_ack_o => smmu_pc_ack,
		pc_data_o => smmu_pc_data,

		-- mem 阶段信号
		mem_req_i => mem_smmu_req,
		mem_we_i => mem_smmu_we,
		mem_mode_i => mem_smmu_mode,
		mem_addr_i => mem_smmu_addr,
		mem_we_data_i => mem_smmu_we_data,

		mem_ack_o => smmu_mem_ack,
		mem_rd_data_o => smmu_mem_rd_data,

		-- ram_ctrl1 的信?
		ram1_req_o => smmu_ram1_req,
		ram1_we_o => smmu_ram1_we,
		ram1_mode_o => smmu_ram1_mode,
		ram1_addr_o => smmu_ram1_addr,
		ram1_we_data_o => smmu_ram1_we_data,

		ram1_ack_i => ram1_smmu_ack,
		ram1_rd_data_i => ram1_smmu_rd_data,

		-- ram_ctrl2 的信?
		ram2_req_o => smmu_ram2_req,
		ram2_we_o => smmu_ram2_we,
		ram2_mode_o => smmu_ram2_mode,
		ram2_addr_o => smmu_ram2_addr,
		ram2_we_data_o => smmu_ram2_we_data,

		ram2_ack_i => ram2_smmu_ack,
		ram2_rd_data_i => ram2_smmu_rd_data,

		-- 串口信号
		uart_req_o => smmu_uart_req,
		uart_we_o => smmu_uart_we,
		uart_mode_data_o => smmu_uart_mode_data,
		uart_we_data_o => smmu_uart_we_data,

		uart_ack_i => uart_smmu_ack,
		uart_rd_data_i => uart_smmu_rd_data
	);

	base_ram : ram_ctrl
	port map (
		clk_i => clk,
		rst_i => rst,
		we_data_i => smmu_ram1_we_data,
		addr_i => smmu_ram1_addr,
		we_i => smmu_ram1_we,
		req_i => smmu_ram1_req,
		mode_i => smmu_ram1_mode,
		rd_data_o => ram1_smmu_rd_data,
		ack_o => ram1_smmu_ack,
		ram_addr_o => base_ram_addr,
		ram_data_io => base_ram_data,
		ram_be_o => base_ram_be_n,
		ram_oe_o => base_ram_oe_n,
		ram_we_o => base_ram_we_n,
		ram_ce_o => base_ram_ce_n
	);

	ext_ram : ram_ctrl
	port map (
		clk_i => clk,
		rst_i => rst,
		we_data_i => smmu_ram2_we_data,
		addr_i => smmu_ram2_addr,
		we_i => smmu_ram2_we,
		req_i => smmu_ram2_req,
		mode_i => smmu_ram2_mode,
		rd_data_o => ram2_smmu_rd_data,
		ack_o => ram2_smmu_ack,
		ram_addr_o => ext_ram_addr,
		ram_data_io => ext_ram_data,
		ram_be_o => ext_ram_be_n,
		ram_oe_o => ext_ram_oe_n,
		ram_we_o => ext_ram_we_n,
		ram_ce_o => ext_ram_ce_n
	);

	uart_ins : uart_ctrl
	port map (
		clk_i => clk,
		rst_i => rst,
		req_i => smmu_uart_req,
		we_i => smmu_uart_we,
		mode_data_i => smmu_uart_mode_data,
		data_i => smmu_uart_we_data,
		data_o => uart_smmu_rd_data,
		ack_o => uart_smmu_ack,
		rxd_i => rxd,
		txd_o => txd
	);
	
	clk <= clk_50M;
	process (clk, reset_btn)
	begin
		if reset_btn = '1' then
			rst <= '0';
		elsif clk'event and clk = '1' then
			rst <= '1';
		end if;
	end process;
	
	stall_1 <= not (if_finish and id_finish and ex_finish and mem_finish and wb_finish);
	stall_2 <= not (if_finish and ex_finish and mem_finish and wb_finish);
end behavioral;
