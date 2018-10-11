library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common.all;

entity tb_ram is
	
end entity tb_ram;

architecture behaviorl of tb_ram is
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

	signal clk, rst : std_logic;
	signal rd_data, data_io : std_logic_vector(31 downto 0);
	signal addr : std_logic_vector(21 downto 0);
	signal ram_addr_o : std_logic_vector(19 downto 0);
	signal mode : mem_mode_type;
	signal be : std_logic_vector(3 downto 0);
	signal oe, ce, we : std_logic;
	signal op_we : std_logic;

	signal r : integer;
	signal rn : std_logic_vector(3 downto 0);
begin
	addr <= std_logic_vector(to_unsigned(r, 22));
	op_we <= '1';
	data_io <= "10001000100110011010101010111011" when op_we = '0' 
			   else (others => 'Z');
	mode <= mem_mode_word when (r < 3) else
			mem_mode_byte when (r < 8) else
			mem_mode_half;
	uut : ram_ctrl port map (
		clk_i => clk,
		rst_i => rst,
		we_data_i => "10001000100110011010101010111011", 
		addr_i => addr,
		we_i => op_we,
		req_i => '1',
		mode_i => mode,

		rd_data_o => rd_data,

		ram_addr_o => ram_addr_o,
		ram_data_io => data_io,
		ram_be_o => be,
		ram_oe_o => oe,
		ram_we_o => we,
		ram_ce_o => ce
	);

	process(clk, rst)
	begin
		if rst = '0' then
			r <= 0;
			rn <= "0001";
		elsif clk'event and clk = '1' then
			if rn(3) = '1' then
				rn <= "0001";
				r <= r + 1;
			else
				rn <= rn(2 downto 0) & '0';
			end if;
		end if;
	end process;
	process
	begin
		rst <= '0';
		wait for 30ns;
		rst <= '1';
		wait;
	end process;

	process
	begin
		clk <= '1';
		wait for 10ns;
		clk <= '0';
		wait for 10ns;
	end process;
end architecture behaviorl;