library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common.all;

entity pc_mem is
	port (
		-- tb_stall, tb_mem_finish : out std_logic;
		clk_50M : in std_logic;
		reset_btn : in std_logic;

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
		
		uart_wrn : out std_logic;
		uart_rdn : out std_logic
		
--		prob_clk, prob_clk_ram, prob_rst : out std_logic;
--		prob_base_ram_addr : out std_logic_vector(19 downto 0);
--		prob_base_ram_data : out std_logic_vector(31 downto 0);
--		prob_base_smmu_data : out std_logic_vector(31 downto 0);
--		prob_base_ram_ce, prob_base_ram_we, prob_base_ram_oe : out std_logic;
--		prob_base_ram_be : out std_logic_vector(3 downto 0)
	);
end pc_mem;

architecture behavioral of pc_mem is
--	component clock is
--		port (
--			clk_i : in std_logic;
--			power_down : in std_logic;
--			clk_50m_o : out std_logic;
--			clk_200m_o : out std_logic;
--			locked : out std_logic
--		);
--	end component clock;

	component pc is
	    port (
	        clk_i, rst_i : in std_logic;
	        if_stall_i, if_finish_i : in std_logic;
	        jaddr_i : in std_logic_vector(31 downto 0);
	        jump_i : in std_logic;
	        addr_o : out std_logic_vector(31 downto 0)
	    ) ;
	end component;

	component if_stage is
		port (
	        clk_i : in std_logic;
	        rst_i : in std_logic;
	        pc_addr_i : in std_logic_vector(31 downto 0);
	        stall_i : in std_logic;
	        finished_o : out std_logic;
	        pc_data_o : out std_logic_vector(31 downto 0);
	        pc_addr_o : out std_logic_vector(31 downto 0);

	        data_i : in std_logic_vector(31 downto 0);
	        ack_i : in std_logic;
	        addr_o : out std_logic_vector(31 downto 0);
	        req_o : out std_logic
    ) ;
	end component if_stage;

	component mem_stage is
		port (
			clk_i : in std_logic;
			rst_i : in std_logic;
			stall_i : in std_logic;
			finish_o : out std_logic;

			mem_op_i : in mem_op_type;
			mem_mode_i : in mem_mode_type;
			mem_addr_i : in std_logic_vector(31 downto 0);
			mem_we_data_i : in std_logic_vector(31 downto 0);
			mem_rd_data_o : out std_logic_vector(31 downto 0);

			mem_addr_o : out std_logic_vector(31 downto 0);
			mem_we_data_o : out std_logic_vector(31 downto 0);
			mem_req_o : out std_logic;
			mem_we_o : out std_logic;
			mem_mode_o : out mem_mode_type;
			mem_rd_data_i : in std_logic_vector(31 downto 0);
			mem_ack_i : in std_logic
		);
	end component;

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

			-- ram_ctrl1 的信�?
			ram1_req_o : out std_logic;
			ram1_we_o : out std_logic;
			ram1_mode_o : out mem_mode_type;
			ram1_addr_o : out std_logic_vector(21 downto 0);
			ram1_we_data_o : out std_logic_vector(31 downto 0);

			ram1_ack_i : in std_logic;
			ram1_rd_data_i : in std_logic_vector(31 downto 0);

			-- ram_ctrl2 的信�?
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
	end component;
	
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
	
	signal power_down : std_logic;
	signal clk : std_logic;
	signal rst : std_logic;
	
	signal stall, if_finish, mem_finish : std_logic;
	signal pc_addr : std_logic_vector(31 downto 0);
	
	signal if_mem_pc_data, if_mem_pc_addr : std_logic_vector(31 downto 0);
	signal if_smmu_addr, smmu_if_data : std_logic_vector(31 downto 0);
	signal if_smmu_req, smmu_if_ack : std_logic;
	signal mem_we_data : std_logic_vector(31 downto 0);
	signal mem_smmu_mode : mem_mode_type;
	signal mem_smmu_data, mem_smmu_addr, smmu_mem_data : std_logic_vector(31 downto 0);
	signal mem_smmu_req, mem_smmu_we : std_logic;
	signal smmu_mem_ack : std_logic;

	signal smmu_ram1_req : std_logic;
	signal smmu_ram1_we : std_logic;
	signal smmu_ram1_mode : mem_mode_type;
	signal smmu_ram1_addr : std_logic_vector(21 downto 0);
	signal smmu_ram1_we_data : std_logic_vector(31 downto 0);

	signal ram1_smmu_ack : std_logic;
	signal ram1_smmu_rd_data : std_logic_vector(31 downto 0);

	signal smmu_ram2_req : std_logic;
	signal smmu_ram2_we : std_logic;
	signal smmu_ram2_mode : mem_mode_type;
	signal smmu_ram2_addr : std_logic_vector(21 downto 0);
	signal smmu_ram2_we_data : std_logic_vector(31 downto 0);

	signal ram2_smmu_ack : std_logic;
	signal ram2_smmu_rd_data : std_logic_vector(31 downto 0);

	signal smmu_uart_req : std_logic;
	signal smmu_uart_we : std_logic;
	signal smmu_uart_mode_data : std_logic;
	signal smmu_uart_we_data : std_logic_vector(7 downto 0);

	signal uart_smmu_ack : std_logic;
	signal uart_smmu_rd_data : std_logic_vector(7 downto 0);
	
	signal ext_ram_addr_t : std_logic_vector(19 downto 0);
	signal ext_ram_data_t : std_logic_vector(31 downto 0);
	signal ext_ram_be_n_t : std_logic_vector(3 downto 0);
	signal ext_ram_ce_n_t : std_logic;
	signal ext_ram_oe_n_t : std_logic;
	signal ext_ram_we_n_t : std_logic;
	signal base_ram_addr_t : std_logic_vector(19 downto 0);
	signal base_ram_data_t : std_logic_vector(31 downto 0);
	signal base_ram_be_n_t : std_logic_vector(3 downto 0);
	signal base_ram_ce_n_t : std_logic;
	signal base_ram_oe_n_t : std_logic;
	signal base_ram_we_n_t : std_logic;
begin
--	tb_stall <= stall;
--	tb_mem_finish <= mem_finish;
	uart_wrn <= '1';
	uart_rdn <= '1';

--	clock_ins : clock port map (
--		clk_i => clk_50m,
--		power_down => '0',
--		clk_50m_o => clk,
--		clk_200m_o => clk_ram,
--		locked => clk_stable
--	);

	clk <= clk_50m;

	process (clk, reset_btn)
	begin
		if reset_btn = '1' then
			rst <= '0';
		elsif clk'event and clk = '1' then
			rst <= '1';
		end if;
	end process;

	stall <= not (if_finish and mem_finish);
	pc_ins : pc port map (
		clk_i => clk, rst_i => rst,
        if_stall_i => stall,
        if_finish_i => if_finish,
        jaddr_i => (others => '0'),
        jump_i => '0',
        addr_o => pc_addr
	);

	if_ins : if_stage port map (
		clk_i => clk,
        rst_i => rst,
        pc_addr_i => pc_addr,
        stall_i => stall,
        finished_o => if_finish,
        pc_data_o => if_mem_pc_data,
        pc_addr_o => if_mem_pc_addr,

        data_i => smmu_if_data,
        ack_i => smmu_if_ack,
        addr_o => if_smmu_addr,
        req_o => if_smmu_req
	);

	mem_we_data <= not if_mem_pc_data;
	mem_ins : mem_stage port map (
		clk_i => clk,
		rst_i => rst,
		stall_i => stall,
		finish_o => mem_finish,

		mem_op_i => mem_op_write,
		mem_mode_i => mem_mode_word,
		mem_addr_i => if_mem_pc_addr,
		mem_we_data_i => mem_we_data,
		-- mem_rd_data_o => 

		mem_addr_o => mem_smmu_addr,
		mem_we_data_o => mem_smmu_data,
		mem_req_o => mem_smmu_req,
		mem_we_o => mem_smmu_we,
		mem_mode_o => mem_smmu_mode,
		mem_rd_data_i => smmu_mem_data,
		mem_ack_i => smmu_mem_ack
	);

	smmu_ins : smmu port map (
		-- if 阶段信号
		pc_req_i => if_smmu_req,
		pc_addr_i => if_smmu_addr,
		pc_ack_o => smmu_if_ack,
		pc_data_o => smmu_if_data,

		-- mem 阶段信号
		mem_req_i => mem_smmu_req,
		mem_we_i => mem_smmu_we,
		mem_mode_i => mem_smmu_mode,
		mem_addr_i => mem_smmu_addr,
		mem_we_data_i => mem_smmu_data,

		mem_ack_o => smmu_mem_ack,
		mem_rd_data_o => smmu_mem_data,

		-- ram_ctrl1 的信�?
		ram1_req_o => smmu_ram1_req,
		ram1_we_o => smmu_ram1_we,
		ram1_mode_o => smmu_ram1_mode,
		ram1_addr_o => smmu_ram1_addr,
		ram1_we_data_o => smmu_ram1_we_data,

		ram1_ack_i => ram1_smmu_ack,
		ram1_rd_data_i => ram1_smmu_rd_data,

		-- ram_ctrl2 的信�?
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

	ram1_ins : ram_ctrl port map (
		clk_i => clk,
		rst_i => rst,
		we_data_i => smmu_ram1_we_data,
		addr_i => smmu_ram1_addr,
		we_i => smmu_ram1_we,
		req_i => smmu_ram1_req,
		mode_i => smmu_ram1_mode,

		rd_data_o => ram1_smmu_rd_data,
		ack_o => ram1_smmu_ack,

		ram_addr_o => ext_ram_addr_t,
		ram_data_io => ext_ram_data_t,
		ram_be_o => ext_ram_be_n_t,
		ram_oe_o => ext_ram_oe_n_t,
		ram_we_o => ext_ram_we_n_t,
		ram_ce_o => ext_ram_ce_n_t
	);

	ram2_ins : ram_ctrl port map (
		clk_i => clk,
		rst_i => rst,
		we_data_i => smmu_ram2_we_data,
		addr_i => smmu_ram2_addr,
		we_i => smmu_ram2_we,
		req_i => smmu_ram2_req,
		mode_i => smmu_ram2_mode,

		rd_data_o => ram2_smmu_rd_data,
		ack_o => ram2_smmu_ack,

		ram_addr_o => base_ram_addr_t,
		ram_data_io => base_ram_data_t,
		ram_be_o => base_ram_be_n_t,
		ram_oe_o => base_ram_oe_n_t,
		ram_we_o => base_ram_we_n_t,
		ram_ce_o => base_ram_ce_n_t
	);

	uart_ins : uart_ctrl port map (
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
	
	ext_ram_addr <= ext_ram_addr_t;
	ext_ram_data <= ext_ram_data_t;
	ext_ram_be_n <= ext_ram_be_n_t;
	ext_ram_ce_n <= ext_ram_ce_n_t or power_down;
	ext_ram_oe_n <= ext_ram_oe_n_t;
	ext_ram_we_n <= ext_ram_we_n_t;
	base_ram_addr <= base_ram_addr_t;
	base_ram_data <= base_ram_data_t;
	base_ram_be_n <= base_ram_be_n_t;
	base_ram_ce_n <= base_ram_ce_n_t or power_down;
	base_ram_oe_n <= base_ram_oe_n_t;
	base_ram_we_n <= base_ram_we_n_t;
	
	power_down <= '1' when mem_smmu_addr(31 downto 22) = "1000000010" else '0';
	leds(0) <= power_down;
	leds(1) <= not ext_ram_oe_n_t;
	leds(2) <= not ext_ram_we_n_t;
	leds(3) <= not base_ram_oe_n_t;
	leds(4) <= not base_ram_we_n_t;
	
--	prob_clk <= clk;
--	prob_clk_ram <= clk_ram;
--	prob_rst <= rst;
--	prob_base_ram_addr <= base_ram_addr_t;
--	prob_base_ram_data <= base_ram_data_t;
--	prob_base_smmu_data <= ram2_smmu_rd_data;
--	prob_base_ram_ce <= base_ram_ce_n_t;
--	prob_base_ram_we <= base_ram_we_n_t;
--	prob_base_ram_oe <= base_ram_oe_n_t;
--	prob_base_ram_be <= base_ram_be_n_t;
end behavioral;
