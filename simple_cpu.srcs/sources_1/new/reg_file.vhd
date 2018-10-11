library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity reg_file is
	port (
		clk_i, rst_i : in std_logic;
		rd_1_addr_i, rd_2_addr_i, we_addr_i : in std_logic_vector(4 downto 0);
		rd_1_data_o, rd_2_data_o : out std_logic_vector(31 downto 0);
		we_data_i : in std_logic_vector(31 downto 0);
		we_i : in std_logic
	);
end entity reg_file;

architecture behavioral of reg_file is
	type reg_file_type is array(31 downto 0) of std_logic_vector(31 downto 0);
	signal array_reg : reg_file_type;
	signal array_next : reg_file_type;
begin
	rd_1_data_o <= (others => '0') when (rd_1_addr_i = "00000") else
				   we_data_i when (rd_1_addr_i = we_addr_i and we_i = '1') else 
				   array_reg(to_integer(unsigned(rd_1_addr_i)));

	rd_2_data_o <= (others => '0') when (rd_2_addr_i = "00000") else
				   we_data_i when (rd_2_addr_i = we_addr_i and we_i = '1') else 
				   array_reg(to_integer(unsigned(rd_2_addr_i)));

	process (we_addr_i, we_data_i, array_reg)
	begin
		for i in 0 to 31 loop
			if i = to_integer(unsigned(we_addr_i)) then
				array_next(i) <= we_data_i;
			else
				array_next(i) <= array_reg(i);
			end if;
		end loop;
	end process;

	process (clk_i, rst_i)
	begin
		if (rst_i = '0') then
		 	for i in 0 to 31 loop
				array_reg(i) <= (others => '0');
			end loop;
		elsif (clk_i'event and clk_i = '1') then
			for i in 0 to 31 loop
				array_reg(i) <= array_next(i);
			end loop;
		end if ; 
	end process;
end architecture behavioral;

