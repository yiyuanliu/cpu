library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity prob_top is
	port (
		-- tb_stall, tb_mem_finish : out std_logic;
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
		ext_ram_we_n : out std_logic;
		
		uart_wrn : out std_logic;
		uart_rdn : out std_logic
	);
end prob_top;

architecture behavioral of prob_top is

	component pc_mem is
		port (
			-- tb_stall, tb_mem_finish : out std_logic;
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
			ext_ram_we_n : out std_logic;
			
			uart_wrn : out std_logic;
			uart_rdn : out std_logic;
			
			prob_clk, prob_clk_ram, prob_rst : out std_logic;
			prob_base_ram_addr : out std_logic_vector(19 downto 0);
			prob_base_ram_data : out std_logic_vector(31 downto 0);
			prob_base_smmu_data : out std_logic_vector(31 downto 0);
			prob_base_ram_ce, prob_base_ram_we, prob_base_ram_oe : out std_logic;
			prob_base_ram_be : out std_logic_vector(3 downto 0)
		);
	end component;
	
	component prob is
		port (
			clk : in std_logic;
			probe0 : in std_logic_vector(0 downto 0);
			probe1 : in std_logic_vector(0 downto 0);
			probe2 : in std_logic_vector(19 downto 0);
			probe3 : in std_logic_vector(31 downto 0);
			probe4 : in std_logic_vector(31 downto 0);
			probe5 : in std_logic_vector(0 downto 0);
			probe6 : in std_logic_vector(0 downto 0);
			probe7 : in std_logic_vector(0 downto 0);
			probe8 : in std_logic_vector(3 downto 0)
		);
	end component;
	signal clk : std_logic;
	signal prob_clk : std_logic_vector(0 downto 0);
	signal prob_rst : std_logic_vector(0 downto 0);
	signal prob_base_ram_addr : std_logic_vector(19 downto 0);
	signal prob_base_ram_data : std_logic_vector(31 downto 0);
	signal prob_base_smmu_data : std_logic_vector(31 downto 0);
	signal prob_base_ram_ce, prob_base_ram_we, prob_base_ram_oe : std_logic_vector(0 downto 0);
	signal prob_base_ram_be : std_logic_vector(3 downto 0);

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
		ext_ram_we_n => ext_ram_we_n, 
		uart_wrn => uart_wrn, 
		uart_rdn => uart_rdn,
		
		prob_clk_ram => clk,
		
		prob_clk => prob_clk(0),
		prob_rst => prob_rst(0),
		prob_base_ram_addr => prob_base_ram_addr,
		prob_base_ram_data => prob_base_ram_data,
		prob_base_smmu_data => prob_base_smmu_data,
		prob_base_ram_ce => prob_base_ram_ce(0),
		prob_base_ram_we => prob_base_ram_we(0),
		prob_base_ram_oe => prob_base_ram_oe(0),
		prob_base_ram_be => prob_base_ram_be
	);
	
	prober : prob
	port map(
		clk => clk,
		probe0 => prob_clk,
		probe1 => prob_rst,
		probe2 => prob_base_ram_addr,
		probe3 => prob_base_ram_data,
		probe4 => prob_base_smmu_data,
		probe5 => prob_base_ram_ce,
		probe6 => prob_base_ram_we,
		probe7 => prob_base_ram_oe,
		probe8 => prob_base_ram_be
	);

end behavioral;
