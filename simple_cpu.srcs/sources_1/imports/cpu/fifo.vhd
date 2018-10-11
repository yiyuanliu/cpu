library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity fifo is
	port (
		rst_i, clk_i : in std_logic;
		we_i, rd_i : in std_logic;
		we_data_i : in std_logic_vector(7 downto 0);
		rd_data_o : out std_logic_vector(7 downto 0);
		full_o, empty_o : out std_logic
	);
end entity fifo;

architecture behavioral of fifo is
	component fifo_ctrl is
		port (
			clk_i, rst_i : in std_logic;
			we_i, rd_i : in std_logic;
			full_o, empty_o : out std_logic;
			we_addr_o, rd_addr_o : out std_logic_vector(1 downto 0)
		);
	end component fifo_ctrl;

	component fifo_reg is
		port (
			clk_i, rst_i : in std_logic;
			rd_addr_i, we_addr_i : in std_logic_vector(1 downto 0);
			rd_data_o : out std_logic_vector(7 downto 0);
			we_data_i : in std_logic_vector(7 downto 0);
			we_i : in std_logic
		);
	end component fifo_reg;

	signal we_addr, rd_addr : std_logic_vector(1 downto 0);
begin
	fifo_ctrl_ins : fifo_ctrl
		port map (
			clk_i => clk_i,
			rst_i => rst_i,
			we_i => we_i,
			rd_i => rd_i,
			full_o => full_o,
			empty_o => empty_o,
			we_addr_o => we_addr,
			rd_addr_o => rd_addr
		);
	fifo_reg_ins : fifo_reg
		port map (
			clk_i => clk_i,
			rst_i => rst_i,
			rd_addr_i => rd_addr,
			we_addr_i => we_addr,
			rd_data_o => rd_data_o,
			we_data_i => we_data_i,
			we_i => we_i
		);
end architecture behavioral;
