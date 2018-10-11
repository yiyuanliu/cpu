library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common.all;

entity ex_stage is
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
end ex_stage;

architecture behavioral of ex_stage is
	signal ex_opnum1_r, ex_opnum2_r : std_logic_vector(31 downto 0);
	signal ex_op_r : ex_op_type;
begin
	process(rst_i, clk_i)
	begin
		if (rst_i = '0') then
			mem_op_o <= mem_op_no;
			mem_mode_o <= mem_mode_word;
			mem_we_data_o <= (others => '0');
			wb_dst_o <= "00000";
		elsif (clk_i'event and clk_i = '1') then
			if (stall_i = '0') then
				ex_opnum1_r <= ex_opnum1_i;
				ex_opnum2_r <= ex_opnum2_i;
				ex_op_r <= ex_op_i;
				mem_op_o <= mem_op_i;
				mem_mode_o <= mem_mode_i;
				mem_we_data_o <= mem_we_data_i;
				wb_dst_o <= wb_dst_i;
			end if;
		end if;
	end process;

	finish_o <= '1';
	with ex_op_r select
		ex_data_o <= std_logic_vector(unsigned(ex_opnum1_r) + unsigned(ex_opnum2_r)) when ex_op_add,
					 ex_opnum1_r and ex_opnum2_r when ex_op_and,
					 ex_opnum1_r or ex_opnum2_r when ex_op_or,
					 std_logic_vector(unsigned(ex_opnum1_r) sll to_integer(unsigned(ex_opnum2_r))) when ex_op_sll,
					 std_logic_vector(unsigned(ex_opnum1_r) srl to_integer(unsigned(ex_opnum2_r))) when ex_op_srl,
					 ex_opnum1_r xor ex_opnum2_r when ex_op_xor;
end behavioral;
