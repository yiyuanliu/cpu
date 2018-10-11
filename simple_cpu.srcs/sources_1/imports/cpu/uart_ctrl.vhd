library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common.all;

entity uart_ctrl is
	port (
		clk_i, rst_i : in std_logic;
		req_i : in std_logic;
		we_i : in std_logic;
		mode_data_i : in std_logic;
		data_i : in std_logic_vector(7 downto 0);

		data_o : out std_logic_vector(7 downto 0);
		ack_o : out std_logic;

		rxd_i : in std_logic;
		txd_o : out std_logic
	);
end entity uart_ctrl;

architecture behavioral of uart_ctrl is
	component async_transmitter is
		port (
			clk : in std_logic;
			txd_start : in std_logic;
			txd_data : in std_logic_vector(7 downto 0);
			txd : out std_logic;
			txd_busy : out std_logic
		);
	end component async_transmitter;

	component async_receiver is
		port (
			clk : in std_logic;
			rxd : in std_logic;
			rxd_data_ready : out std_logic;
			rxd_clear : in std_logic;
			rxd_data : out std_logic_vector(7 downto 0);
			rxd_idle : out std_logic;
			rxd_endofpacket : out std_logic
		);
	end component async_receiver;

	component fifo is
		port (
			rst_i, clk_i : in std_logic;
			we_i, rd_i : in std_logic;
			we_data_i : in std_logic_vector(7 downto 0);
			rd_data_o : out std_logic_vector(7 downto 0);
			full_o, empty_o : out std_logic
		);
	end component fifo;

	signal uart_op_send, uart_op_read, uart_op_state : std_logic;

	signal txd_busy, txd_start : std_logic;
	signal txd_data : std_logic_vector(7 downto 0);
	signal fifo_send_full, fifo_send_empty : std_logic;
	signal we_send_fifo : std_logic;

	signal rxd_ready : std_logic;
	signal rxd_data, fifo_read_data : std_logic_vector(7 downto 0);
	signal fifo_read_full, fifo_read_empty : std_logic;
begin
	uart_op_send <= req_i and (mode_data_i) and we_i;
	uart_op_read <= req_i and mode_data_i and not we_i;
	uart_op_state <= req_i and not mode_data_i;

	ack_o <= '0' when ((fifo_send_full = '1' and uart_op_send = '1') or req_i = '0') else '1';
	data_o <= "000000" & not fifo_read_empty & not fifo_send_full when uart_op_state = '1' else
			  fifo_read_data;

	async_transmitter_ins : async_transmitter
		port map (
			clk => clk_i,
			txd_start => txd_start,
			txd_data => txd_data,
			txd => txd_o,
			txd_busy => txd_busy
		);
	fifo_send : fifo
		port map (
			rst_i => rst_i,
			clk_i => clk_i,
			we_i => we_send_fifo,
			rd_i => txd_start,
			we_data_i => data_i,
			rd_data_o => txd_data,
			full_o => fifo_send_full,
			empty_o => fifo_send_empty
		);
	txd_start <= (not txd_busy) and (not fifo_send_empty);
	we_send_fifo <= uart_op_send and not fifo_send_full;
	
	async_receiver_ins : async_receiver
		port map (
			clk => clk_i,
			rxd => rxd_i,
			rxd_data_ready => rxd_ready,
			rxd_data => rxd_data,
			rxd_clear => rxd_ready
		);
	fifo_read : fifo
		port map (
			rst_i => rst_i,
			clk_i => clk_i,
			we_i => rxd_ready,
			rd_i => uart_op_read,
			we_data_i => rxd_data,
			rd_data_o => fifo_read_data,
			full_o => fifo_read_full,
			empty_o => fifo_read_empty
		);
end architecture behavioral;