library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity mem_stage is
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
end entity mem_stage;

architecture behavioral of mem_stage is
	signal finish, finish_r : std_logic;
	signal rd_data, rd_data_r : std_logic_vector(31 downto 0);
	signal ex_data_r : std_logic_vector(31 downto 0);
	signal mem_op_r : mem_op_type;
	signal mem_mode_r : mem_mode_type;
	signal mem_we_data_r : std_logic_vector(31 downto 0);
begin
	finish <= mem_ack_i or finish_r;
	finish_o <= finish;

	rd_data <= rd_data_r when finish_r = '1' else mem_rd_data_i;
	mem_data_o <= rd_data when mem_op_r = mem_op_read else ex_data_r;

	mem_addr_o <= ex_data_r;
	mem_we_data_o <= mem_we_data_r;
	mem_we_o <= '1' when mem_op_r = mem_op_write else '0';
	mem_mode_o <= mem_mode_r;

	process (clk_i, rst_i)
	begin
		if (rst_i = '0') then
			finish_r <= '1';
			rd_data_r <= (others => '0');
			mem_req_o <= '0';
			ex_data_r <= (others => '0');
			mem_op_r <= mem_op_no;
			mem_mode_r <= mem_mode_word;
			mem_we_data_r <= (others => '0');
			wb_dst_o <= "00000";
		elsif (clk_i'event and clk_i = '1') then
			if (finish = '1') then
				if (stall_i = '1') then
					finish_r <= '1';
					rd_data_r <= rd_data;
					mem_req_o <= '0';
				else
					if (mem_op_i = mem_op_no) then
						finish_r <= '1';
						mem_req_o <= '0';
					else
						finish_r <= '0';
						mem_req_o <= '1';
					end if;
					ex_data_r <= ex_data_i;
					mem_we_data_r <= mem_we_data_i;
					mem_op_r <= mem_op_i;
					mem_mode_r <= mem_mode_i;
					wb_dst_o <= wb_dst_i;
				end if;
			else
				-- keep all signals until finish
			end if;
		end if;
	end process;
end architecture behavioral;