----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2018/10/05 19:14:07
-- Design Name: 
-- Module Name: tb_pc_mem - behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.common.all;
entity tb_pc_mem is
--  Port ( );
end tb_pc_mem;

architecture behavioral of tb_pc_mem is
	component pc_mem is
		port (
			
			clk_50M : in std_logic;
			reset_btn : in std_logic;
	
			txd : out std_logic;
			rxd : in std_logic;
			leds : out std_logic_vector(15 downto 0);
	
			base_ram_addr : out std_logic_vector(19 downto 0);
			base_ram_data : inout std_logic_vector(31 downto 0);
			base_ram_be_n : out std_logic_vector(3 downto 0);
			base_ram_ce_n : out std_logic;
			base_ram_oe_n : out std_logic;
			base_ram_we_n : out std_logic;
	
			ext_ram_addr : out std_logic_vector(19 downto 0);
			ext_ram_data : inout std_logic_vector(31 downto 0);
			ext_ram_be_n : out std_logic_vector(3 downto 0);
			ext_ram_ce_n : out std_logic;
			ext_ram_oe_n : out std_logic;
			ext_ram_we_n : out std_logic
		);
	end component;
	
	signal clk_50M : std_logic;
	signal reset_btn : std_logic;
	signal txd : std_logic;
	signal rxd : std_logic;
	signal leds : std_logic_vector(15 downto 0);
	signal base_ram_addr : std_logic_vector(19 downto 0);
	signal base_ram_data : std_logic_vector(31 downto 0);
	signal base_ram_be_n : std_logic_vector(3 downto 0);
	signal base_ram_ce_n : std_logic;
	signal base_ram_oe_n : std_logic;
	signal base_ram_we_n : std_logic;
	signal ext_ram_addr : std_logic_vector(19 downto 0);
	signal ext_ram_data : std_logic_vector(31 downto 0);
	signal ext_ram_be_n : std_logic_vector(3 downto 0);
	signal ext_ram_ce_n : std_logic;
	signal ext_ram_oe_n : std_logic;
	signal ext_ram_we_n : std_logic;
	signal tb_stall, tb_mem_finish : std_logic;
begin
	uut : pc_mem
		port map (
			clk_50M => clk_50M,
			reset_btn => reset_btn,
			txd => txd,
			rxd => rxd,
			leds => leds,
			base_ram_addr => base_ram_addr,
			base_ram_data => base_ram_data,
			base_ram_be_n => base_ram_be_n,
			base_ram_ce_n => base_ram_ce_n,
			base_ram_oe_n => base_ram_oe_n,
			base_ram_we_n => base_ram_we_n,
			ext_ram_addr => ext_ram_addr,
			ext_ram_data => ext_ram_data,
			ext_ram_be_n => ext_ram_be_n,
			ext_ram_ce_n => ext_ram_ce_n,
			ext_ram_oe_n => ext_ram_oe_n,
			ext_ram_we_n => ext_ram_we_n
		);
	base_ram_data <= std_logic_vector(to_unsigned(0, 12)) & base_ram_addr when base_ram_oe_n = '0' else (others => 'Z');
	ext_ram_data <= (others => '0') when ext_ram_oe_n = '0' else (others => 'Z');

	process
	
	begin
		clk_50m <= '1';
		wait for 10ns;
		clk_50m <= '0';
		wait for 10ns;
	end process;
	
	process
	begin
		reset_btn <= '1';
		wait for 10000ns;
		reset_btn <= '0';
		wait;
	end process;

end behavioral;
