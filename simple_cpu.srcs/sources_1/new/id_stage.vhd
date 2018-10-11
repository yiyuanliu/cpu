library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common.all;

entity id_stage is
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
end id_stage;

architecture behavioral of id_stage is
	signal ins_data_r : std_logic_vector(31 downto 0);
	signal ins_addr_r : std_logic_vector(31 downto 0);
	signal pc_addr_r : std_logic_vector(31 downto 0);

	alias opcode : std_logic_vector(5 downto 0) is ins_data_r(31 downto 26); 
	alias rs : std_logic_vector(4 downto 0) is ins_data_r(25 downto 21); 
	alias rt : std_logic_vector(4 downto 0) is ins_data_r(20 downto 16);
	alias rd : std_logic_vector(4 downto 0) is ins_data_r(15 downto 11);
	alias sa : std_logic_vector(4 downto 0) is ins_data_r(10 downto 6);
	alias func : std_logic_vector(5 downto 0) is ins_data_r(5 downto 0);
	alias imme : std_logic_vector(15 downto 0) is ins_data_r(15 downto 0);
	alias ins_index : std_logic_vector(25 downto 0) is ins_data_r(25 downto 0);

	signal rs_ready, rt_ready : std_logic;
	signal rs_data, rt_data : std_logic_vector(31 downto 0);
	signal finish_t : std_logic;
	signal wb_dst_t : std_logic_vector(4 downto 0);
	signal mem_op_t : mem_op_type;
begin
	process (clk_i, rst_i)
	begin
		if (rst_i = '0') then
			ins_data_r <= (others => '0');
			ins_addr_r <= (others => '0');
			pc_addr_r <= (others => '0');
		elsif (clk_i'event and clk_i = '1') then
			if (stall_i = '0') then
				ins_addr_r <= ins_addr_i;
				ins_data_r <= ins_data_i;
				pc_addr_r <= pc_addr_i;
			end if;
		end if;
	end process;

	reg_rd1_addr_o <= rs;
	reg_rd2_addr_o <= rt;
	rs_data <= ex_data_i when (ex_wb_dst_i = rs and rs /= "00000") else
			   mem_data_i when (mem_wb_dst_i = rs and rs /= "00000") else
			   reg_rd1_data_i;
	rt_data <= ex_data_i when (ex_wb_dst_i = rt and rt /= "00000") else
			   mem_data_i when (mem_wb_dst_i = rt and rt /= "00000") else
			   reg_rd2_data_i;
	rs_ready <= '0' when (ex_wb_dst_i = rs and rs /= "00000" and ex_mem_op_i = mem_op_read)
				else '1';
	rt_ready <= '0' when (ex_wb_dst_i = rt and rt /= "00000" and ex_mem_op_i = mem_op_read)
				else '1';
				
	finish_o <= finish_t;
	wb_dst_o <= wb_dst_t when finish_t = '1' else "00000";
	mem_op_o <= mem_op_t when finish_t = '1' else mem_op_no;

	process(ins_data_r, ins_addr_r, pc_addr_r, rs_ready, rt_ready, rs_data, rt_data)
	begin
		jump_o <= '0';
		jaddr_o <= (others => '0');
		finish_t <= '1';
		ex_opnum1_o <= rs_data;
		ex_opnum2_o <= rt_data;
		ex_op_o <= ex_op_add;
		mem_op_t <= mem_op_no;
		mem_mode_o <= mem_mode_word;
		wb_dst_t <= (others => '0');
		mem_we_data_o <= (others => '0');

		if (opcode = "000000") then
			ex_opnum1_o <= rs_data;
			ex_opnum2_o <= rt_data;
			wb_dst_t <= rd;
			finish_t <= rs_ready and rt_ready;
			case (func) is
				when "100001" =>
					-- addu 000000ssssstttttddddd00000100001
					ex_op_o <= ex_op_add;
				when "100100" =>
					-- and 000000ssssstttttddddd00000100100
					ex_op_o <= ex_op_and;
				when "001000" =>
					-- jr 000000sssss0000000000hhhhh001000
					jump_o <= rs_ready;
					jaddr_o <= rs_data;
					finish_t <= rs_ready;
					wb_dst_t <= "00000";
				when "100101" =>
					-- or 000000ssssstttttddddd00000100101
					ex_op_o <= ex_op_or;
				when "000000" =>
					-- sll 00000000000tttttdddddaaaaa000000
					ex_opnum1_o <= rt_data;
					ex_opnum2_o <= std_logic_vector(resize(unsigned(sa), 32));
					ex_op_o <= ex_op_sll;
					finish_t <= rt_ready;
				when "000010" =>
					-- srl 00000000000tttttdddddaaaaa000010
					ex_opnum1_o <= rt_data;
					ex_opnum2_o <= std_logic_vector(resize(unsigned(sa), 32));
					ex_op_o <= ex_op_srl;
					finish_t <= rt_ready;
				when "100110" =>
					-- xor 000000ssssstttttddddd00000100110
					ex_op_o <= ex_op_xor;
				when others =>
					finish_t <= '1';
			end case;
		elsif (opcode = "001001") then
			-- addiu 001001ssssstttttiiiiiiiiiiiiiiii
			wb_dst_t <= rt;
			ex_opnum1_o <= rs_data;
			ex_opnum2_o <= std_logic_vector(resize(signed(imme), 32));
			ex_op_o <= ex_op_add;
			finish_t <= rs_ready;
		elsif (opcode = "001100") then
			-- andi 001100ssssstttttiiiiiiiiiiiiiiii
			wb_dst_t <= rt;
			ex_opnum1_o <= rs_data;
			ex_opnum2_o <= std_logic_vector(resize(unsigned(imme), 32));
			ex_op_o <= ex_op_and;
			finish_t <= rs_ready;
		elsif (opcode = "000100") then
			-- beq 000100ssssstttttoooooooooooooooo
			if (rs_ready = '1' and rt_ready = '1' and (rs_data = rt_data)) then
				jump_o <= '1';
			else
				jump_o <= '0';
			end if;
			jaddr_o <= std_logic_vector(unsigned(pc_addr_r) + unsigned(resize(signed(imme & "00"), 32)));
			finish_t <= rs_ready and rt_ready;
		elsif (opcode = "000111") then
			-- bgtz 000111sssss00000oooooooooooooooo
			if (rs_ready = '1' and (signed(rs_data) > 0)) then
				jump_o <= '1';
			else
				jump_o <= '0';
			end if;
			jaddr_o <= std_logic_vector(unsigned(pc_addr_r) + unsigned(resize(signed(imme & "00"), 32)));
			finish_t <= rs_ready;
		elsif (opcode = "000101") then
			-- bne 000101ssssstttttoooooooooooooooo
			if (rs_ready = '1' and rt_ready = '1' and (rs_data /= rt_data)) then
				jump_o <= '1';
			else
				jump_o <= '0';
			end if;
			jaddr_o <= std_logic_vector(unsigned(pc_addr_r) + unsigned(resize(signed(imme & "00"), 32)));
			finish_t <= rs_ready and rt_ready;
		elsif (opcode = "000010") then
			-- j 000010iiiiiiiiiiiiiiiiiiiiiiiiii
			jump_o <= '1';
			finish_t <= '1';
			jaddr_o <= pc_addr_r(31 downto 28) & ins_index & "00";
		elsif (opcode = "000011") then
			-- jal 000011iiiiiiiiiiiiiiiiiiiiiiiiii
			jump_o <= '1';
			finish_t <= '1';
			jaddr_o <= pc_addr_r(31 downto 28) & ins_index & "00";
			ex_opnum1_o <= pc_addr_r;
			ex_opnum2_o <= std_logic_vector(to_unsigned(4, 32));
			ex_op_o <= ex_op_add;
			wb_dst_t <= "11111";
		elsif (opcode = "100000") then
			-- lb 100000bbbbbtttttoooooooooooooooo
			finish_t <= rs_ready;
			wb_dst_t <= rt;
			ex_opnum1_o <= rs_data;
			ex_opnum2_o <= std_logic_vector(resize(signed(imme), 32));
			ex_op_o <= ex_op_add;
			mem_op_t <= mem_op_read;
			mem_mode_o <= mem_mode_byte;
		elsif (opcode = "001111") then
			-- lui 00111100000tttttiiiiiiiiiiiiiiii
			finish_t <= '1';
			wb_dst_t <= rt;
			ex_opnum1_o <= imme & std_logic_vector(to_unsigned(0, 16));
			ex_opnum2_o <= (others => '0');
			ex_op_o <= ex_op_add;
		elsif (opcode = "100011") then
			-- lw 100011bbbbbtttttoooooooooooooooo
			finish_t <= rs_ready;
			wb_dst_t <= rt;
			ex_opnum1_o <= rs_data;
			ex_opnum2_o <= std_logic_vector(resize(signed(imme), 32));
			ex_op_o <= ex_op_add;
			mem_op_t <= mem_op_read;
			mem_mode_o <= mem_mode_word;
		elsif (opcode = "001101") then
			-- ori 001101ssssstttttiiiiiiiiiiiiiiii
			finish_t <= rs_ready;
			wb_dst_t <= rt;
			ex_opnum1_o <= rs_data;
			ex_opnum2_o <= std_logic_vector(resize(unsigned(imme), 32));
			ex_op_o <= ex_op_or;
		elsif (opcode = "101000") then
			-- sb 101000bbbbbtttttoooooooooooooooo
			finish_t <= rs_ready and rt_ready;
			wb_dst_t <= "00000";
			ex_opnum1_o <= rs_data;
			ex_opnum2_o <= std_logic_vector(resize(signed(imme), 32));
			ex_op_o <= ex_op_add;
			mem_mode_o <= mem_mode_byte;
			mem_op_t <= mem_op_write;
			mem_we_data_o <= rt_data;
		elsif (opcode = "101011") then
			-- sw 101011bbbbbtttttoooooooooooooooo
			finish_t <= rs_ready and rt_ready;
			wb_dst_t <= "00000";
			ex_opnum1_o <= rs_data;
			ex_opnum2_o <= std_logic_vector(resize(signed(imme), 32));
			ex_op_o <= ex_op_add;
			mem_op_t <= mem_op_write;
			mem_mode_o <= mem_mode_word;
			mem_we_data_o <= rt_data;
		elsif (opcode = "001110") then
			-- xori 001110ssssstttttiiiiiiiiiiiiiiii
			finish_t <= rs_ready;
			wb_dst_t <= rt;
			ex_opnum1_o <= rs_data;
			ex_opnum2_o <= std_logic_vector(resize(unsigned(imme), 32));
			ex_op_o <= ex_op_xor;
		else
			finish_t <= '1';
			wb_dst_t <= "00000";
			mem_op_t <= mem_op_no;
		end if;
	end process;
end behavioral;
