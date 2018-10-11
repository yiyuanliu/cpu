library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_ctrl is
	port (
		clk_i, rst_i : in std_logic;
		we_i, rd_i : in std_logic;
		full_o, empty_o : out std_logic;
		we_addr_o, rd_addr_o : out std_logic_vector(1 downto 0);
		we_ptr, rd_ptr : out unsigned(2 downto 0)
	);
end entity fifo_ctrl;

architecture behavioral of fifo_ctrl is
	signal we_ptr_reg, we_ptr_next : unsigned(2 downto 0);
	signal rd_prt_reg, rd_ptr_next : unsigned(2 downto 0);
	signal full_flag, empty_flag : std_logic;
begin

we_ptr <= we_ptr_reg;
rd_ptr <= rd_prt_reg;
	process(clk_i, rst_i)
	begin
		if (rst_i = '0') then
			we_ptr_reg <= (others => '0');
			rd_prt_reg <= (others => '0');
		elsif (clk_i'event and clk_i = '1') then
			we_ptr_reg <= we_ptr_next;
			rd_prt_reg <= rd_ptr_next;
		end if;
	end process;

	we_ptr_next <= (we_ptr_reg + 1) when (we_i = '1' and full_flag = '0') else we_ptr_reg;
	full_flag <= '1' when (rd_prt_reg(2) /= we_ptr_reg(2) and rd_prt_reg(1 downto 0) = we_ptr_reg(1 downto 0)) else
				 '0';
	we_addr_o <= std_logic_vector(we_ptr_reg(1 downto 0));
	full_o <= full_flag;

	rd_ptr_next <= (rd_prt_reg + 1) when (rd_i = '1' and empty_flag = '0') else rd_prt_reg;
	empty_flag <= '1' when rd_prt_reg = we_ptr_reg else
				  '0';
	rd_addr_o <= std_logic_vector(rd_prt_reg(1 downto 0));
	empty_o <= empty_flag;
end architecture behavioral;