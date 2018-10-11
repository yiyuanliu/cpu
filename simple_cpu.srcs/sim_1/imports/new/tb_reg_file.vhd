library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;	

entity tb_reg_file is
	
end entity tb_reg_file;

architecture behavioral of tb_reg_file is
	component reg_file is
		port (
			clk_i, rst_i : in std_logic;
			rd_1_addr_i, rd_2_addr_i, we_addr_i : in std_logic_vector(4 downto 0);
			rd_1_data_o, rd_2_data_o : out std_logic_vector(31 downto 0);
			we_data_i : in std_logic_vector(31 downto 0);
			we_i : in std_logic
		);
	end component reg_file;

	signal rst, clk : std_logic;
	signal rs, rt, rd : std_logic_vector(4 downto 0);
	signal we_data, rs_data, rt_data : std_logic_vector(31 downto 0);
begin

	reg : reg_file
	port map (
		clk_i => clk,
		rst_i => rst,
		rd_1_addr_i => rs,
		rd_2_addr_i => rt,
		we_addr_i => rd,
		we_data_i => we_data,
		rd_1_data_o => rs_data,
		rd_2_data_o => rt_data,
		we_i => '1'
	);
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

	process (rst, clk)
	begin
		if rst = '0' then
			we_data <= (others => '0');
		elsif clk'event and clk = '1' then
			we_data <= std_logic_vector(unsigned(we_data) + 1);
		end if;
	end process;

	rs <= we_data(4 downto 0);
	rt <= std_logic_vector(unsigned(rs) - 1);
	rd <= we_data(4 downto 0);
end architecture behavioral;