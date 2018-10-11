library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity fifo_reg is
	port (
		clk_i, rst_i : in std_logic;
		rd_addr_i, we_addr_i : in std_logic_vector(1 downto 0);
		rd_data_o : out std_logic_vector(7 downto 0);
		we_data_i : in std_logic_vector(7 downto 0);
		we_i : in std_logic
	);
end entity fifo_reg;

architecture behavioral of fifo_reg is
	type reg_file_type is array(3 downto 0) of std_logic_vector(7 downto 0);
	signal array_reg : reg_file_type;
	signal array_next : reg_file_type;
begin
	process (clk_i, rst_i)
	begin
		if (rst_i = '0') then
			array_reg(3) <= (others => '0');
			array_reg(2) <= (others => '0');
			array_reg(1) <= (others => '0');
			array_reg(0) <= (others => '0');
		elsif (clk_i'event and clk_i = '1') then
			array_reg(3) <= array_next(3);
			array_reg(2) <= array_next(2);
			array_reg(1) <= array_next(1);
			array_reg(0) <= array_next(0);
		end if ; 
	end process;

	array_next(0) <= we_data_i when (we_i = '1' and we_addr_i = "00") else array_reg(0);
	array_next(1) <= we_data_i when (we_i = '1' and we_addr_i = "01") else array_reg(1);
	array_next(2) <= we_data_i when (we_i = '1' and we_addr_i = "10") else array_reg(2);
	array_next(3) <= we_data_i when (we_i = '1' and we_addr_i = "11") else array_reg(3);

	with rd_addr_i select
		rd_data_o <= array_reg(0) when "00",
					 array_reg(1) when "01",
					 array_reg(2) when "10",
					 array_reg(3) when others;
end architecture behavioral;

