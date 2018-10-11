library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wb_stage is
	port (
		clk_i : in std_logic;
		rst_i : in std_logic;
		stall_i : in std_logic;
		finish_o : out std_logic;

		wb_dst_i : in std_logic_vector(4 downto 0);
		mem_data_i : in std_logic_vector(31 downto 0);

		-- to reg_file
		reg_we_o : out std_logic;
		reg_we_data_o : out std_logic_vector(31 downto 0);
		reg_we_addr_o : out std_logic_vector(4 downto 0)
	);
end wb_stage;

architecture behavioral of wb_stage is
	
begin
	finish_o <= '1';
	
	process(clk_i, rst_i)
	begin
		if (rst_i = '0') then
			reg_we_o <= '0';
			reg_we_addr_o <= (others => '0');
			reg_we_data_o <= (others => '0');
		elsif (clk_i'event and clk_i = '1') then
			if (stall_i = '0') then
				if (wb_dst_i /= "00000") then
					reg_we_o <= '1';
				else
					reg_we_o <= '0';
				end if;
				reg_we_data_o <= mem_data_i;
				reg_we_addr_o <= wb_dst_i;
			end if;
		end if;
	end process;

end behavioral;
