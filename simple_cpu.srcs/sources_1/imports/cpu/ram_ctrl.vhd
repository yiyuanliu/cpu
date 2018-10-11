library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common.all;

entity ram_ctrl is
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
end entity ram_ctrl;

architecture behavioral of ram_ctrl is
	type state is (s0, s1);
	signal current_state : state;
	signal next_state : state;
	signal is_read : std_logic;
	signal is_write : std_logic;
	signal we_data, rd_data : std_logic_vector(31 downto 0);
	alias we_data_byte : std_logic_vector(7 downto 0) is we_data_i(7 downto 0); 
	alias we_data_half : std_logic_vector(15 downto 0) is we_data_i(15 downto 0); 
begin
	-- this is implementation for mode enable.
	is_read <= req_i and (not we_i);
	is_write <= req_i and we_i;

	with mode_i select
	we_data <= we_data_byte & we_data_byte & we_data_byte & we_data_byte when mem_mode_byte,
			   we_data_half & we_data_half when mem_mode_half,
			   we_data_i when others;

	ram_be_o <= not "1111" when (mode_i = mem_mode_word) else
				not "0011" when (mode_i = mem_mode_half and addr_i(1) = '0') else
				not "1100" when (mode_i = mem_mode_half and addr_i(1) = '1') else
				not "0001" when (mode_i = mem_mode_byte and addr_i(1 downto 0) = "00") else
				not "0010" when (mode_i = mem_mode_byte and addr_i(1 downto 0) = "01") else
				not "0100" when (mode_i = mem_mode_byte and addr_i(1 downto 0) = "10") else
				not "1000";

	ram_ce_o <= '0';
	ram_addr_o <= addr_i(21 downto 2);
	ram_data_io <= we_data when (is_write = '1') else (others => 'Z');
	ram_oe_o <= '0' when (current_state = s0 and is_read = '1') else '1';
	ram_we_o <= '0' when (current_state = s0 and is_write = '1') else '1';
	rd_data <= we_data when (is_write = '1') else ram_data_io;

	ack_o <= '1' when (req_i = '1' and next_state = s0) else '0';

	next_state <= s1 when (current_state = s0 and is_write = '1') else s0;
	process (rd_data, mode_i, addr_i)
	begin
		case (mode_i) is
			when mem_mode_byte =>
				case (addr_i(1 downto 0)) is
					when "00" =>
						rd_data_o <= std_logic_vector(to_unsigned(0, 24)) & rd_data(7 downto 0);
					when "01" =>
						rd_data_o <= std_logic_vector(to_unsigned(0, 24)) & rd_data(15 downto 8);
					when "10" =>
						rd_data_o <= std_logic_vector(to_unsigned(0, 24)) & rd_data(23 downto 16);
					when others =>
						rd_data_o <= std_logic_vector(to_unsigned(0, 24)) & rd_data(31 downto 24);
				end case;
			when mem_mode_half =>
				case (addr_i(1)) is
					when '0' =>
						rd_data_o <= std_logic_vector(to_unsigned(0, 16)) & rd_data(15 downto 0);
					when others =>
						rd_data_o <= std_logic_vector(to_unsigned(0, 16)) & rd_data(31 downto 16);
				end case;
			when others =>
				rd_data_o <= rd_data;
		end case;
	end process;

	process (rst_i, clk_i)
	begin
		if (rst_i = '0') then
			current_state <= s0;
		elsif (clk_i'event and clk_i = '1') then
			current_state <= next_state;
		end if;
	end process;
end architecture behavioral;