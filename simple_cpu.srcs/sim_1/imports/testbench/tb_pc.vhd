library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;	
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_pc is
	
end entity tb_pc;

architecture behavioral of tb_pc is
	component pc is
		port (
			clk_i, rst_i : in std_logic;
	        if_stall_i, if_finish_i : in std_logic;
	        jaddr_i : in std_logic_vector(31 downto 0);
	        jump_i : in std_logic;
	        addr_o : out std_logic_vector(31 downto 0)
		);
	end component pc;

	signal clk, rst : std_logic;
	signal if_stall, if_finish : std_logic;
	signal jaddr : std_logic_vector(31 downto 0);
	signal jump : std_logic;
	signal pc_addr : std_logic_vector(31 downto 0);

	signal r : natural;
begin
	uut : pc port map (
		clk_i => clk,
		rst_i => rst,
        if_stall_i => if_stall,
        if_finish_i => if_finish,
        jaddr_i => jaddr,
        jump_i => jump,
        addr_o => pc_addr
	);

	-- r 		0	1	2	3	4	5	6	7	8	9	10	11
	-- jaddr 	0	0	0	0	0	0	0	0	0	0	0	0
	-- j 		0	0	0	0	1	0	0	1	0	0	0	0
	-- finish 	1	1	1	1	1	0	1	1	1	1	1	1
	-- stall 	0	0	0	0	1	0	0	0	0	0	1	0
	-- pc 		0	4	8	12	16	16	16	0	0	4	8	8
	-- addr     4	8	12	16	0	0	0	0	4	8	12	12

	if_finish <= '0' when r = 5 else '1';
	if_stall <= '1' when r = 4 or r = 10 else '0';
	jaddr <= (others => '0');
	jump <= '1' when (r = 4 or r = 7) else '0';

	process(rst, clk)
	begin
		if rst = '0' then
			jaddr <= (others => '0');
			r <= 0;
		elsif clk'event and clk = '1' then
			r <= r + 1;
		end if;
	end process;

	clock : process
	begin
		clk <= '1';
		wait for 10ns;
		clk <= '0';
		wait for 10ns;
	end process;

	process
	begin
		rst <= '0';
		wait for 21ns;
		rst <= '1';
		wait;
	end process;
end architecture behavioral;