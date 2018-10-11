library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common.all;

-- smmu 负责�?单的地址转换(直接进行映射)，并负责解决if阶段和mem阶段的结构冲�?
entity smmu is
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
end entity smmu;

architecture behavioral of smmu is
	-- ram1 : 0x80000000 - 0x803FFFFF
	-- ram2 : 0x80400000 - 0x807FFFFF
	-- uart : 0xBFD003F8 - 0xBFD003FD (data: 0xBFD003F8, state: 0xBFD003FC)
	-- ram 只需要判断地�?位高 10 位， 
	-- ram1 => 0x800 - 0x803 => b1000_0000_0000 - b1000_0000_0011 => addr(31 downto 22) = "1000000000"
	-- ram2 => 0x804 - 0x807 => b1000_0000_0100 - b1000_0000_0111 => addr(31 downto 22) = "1000000001"
	type target_dev is (ram1, ram2, uart, illegal_addr);
	signal pc_target : target_dev;
	signal mem_target : target_dev;

	type src_type is (pc, mem, no_src);
	signal ram1_src : src_type;
	signal ram2_src : src_type;
	signal uart_src : src_type;
begin
	pc_target <= ram1 when (pc_addr_i(31 downto 22) = "1000000000") else
				 ram2 when (pc_addr_i(31 downto 22) = "1000000001") else
				 uart when (pc_addr_i(31 downto 3) = "10111111110100000000001111111") else
				 illegal_addr;

	mem_target <= ram1 when (mem_addr_i(31 downto 22) = "1000000000") else
				  ram2 when (mem_addr_i(31 downto 22) = "1000000001") else
				  uart when (mem_addr_i(31 downto 3) = "10111111110100000000001111111") else
				  illegal_addr;

	ram2_src <= pc when (pc_target = ram2 and pc_req_i = '1') else
				mem when (mem_target = ram2 and mem_req_i = '1') else
				no_src;
	ram1_src <= pc when (pc_target = ram1 and pc_req_i = '1') else
				mem when (mem_target = ram1 and mem_req_i = '1') else
				no_src;
	uart_src <= pc when (pc_target = uart and pc_req_i = '1') else
				mem when (mem_target = uart and mem_req_i = '1') else
				no_src;

	ram2_req_o  <= '1' 			when ram2_src /= no_src else '0';
	ram2_we_o   <= mem_we_i 	when (ram2_src = mem) 	else '0';
	ram2_mode_o <= mem_mode_i	when (ram2_src = mem) 	else mem_mode_word;
	ram2_addr_o <= pc_addr_i(21 downto 0)  when (ram2_src = pc)  else
				   mem_addr_i(21 downto 0);
	ram2_we_data_o <= mem_we_data_i;

	ram1_req_o	<= '1' 			when ram1_src /= no_src else '0';
	ram1_we_o	<= mem_we_i 	when (ram1_src = mem) 	else '0';
	ram1_mode_o	<= mem_mode_i 	when (ram1_src = mem) 	else mem_mode_word;
	ram1_addr_o	<= pc_addr_i(21 downto 0)  when (ram1_src = pc)  else
				   mem_addr_i(21 downto 0);
	ram1_we_data_o <= mem_we_data_i;

	uart_req_o <= '1' when uart_src /= no_src else '0';
	uart_we_o <= mem_we_i when uart_src = mem else '0';
	uart_mode_data_o <= '1' when (uart_src = mem and mem_addr_i = "10111111110100000000001111111000")
							or (uart_src = pc and pc_addr_i = "10111111110100000000001111111000")
						else '0';
	uart_we_data_o <= mem_we_data_i(7 downto 0);

	pc_ack_o <= ram2_ack_i when (pc_target = ram2 and ram2_src = pc) else
				ram1_ack_i when (pc_target = ram1 and ram1_src = pc) else
				uart_ack_i when (pc_target = uart and uart_src = pc) else
				'0'		   when (pc_target = illegal_addr)			 else
				'0';
	with pc_target select
		pc_data_o <= ram2_rd_data_i when ram2,
					 ram1_rd_data_i when ram1,
					 std_logic_vector(to_unsigned(0, 24)) & uart_rd_data_i when uart,
					 (others => '0') when others;

	mem_ack_o <= ram2_ack_i when (mem_target = ram2 and ram2_src = mem) else
				 ram1_ack_i when (mem_target = ram1 and ram1_src = mem) else
				 uart_ack_i when (mem_target = uart and uart_src = mem) else
				 '0'		when (mem_target = illegal_addr)			else
				 '0';
	with mem_target select
		mem_rd_data_o <= ram2_rd_data_i when ram2,
					 	 ram1_rd_data_i when ram1,
					 	 std_logic_vector(to_unsigned(0, 24)) & uart_rd_data_i when uart,
					 	 (others => '0') when others;
end architecture behavioral;
