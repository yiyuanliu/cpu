library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity pc is
    port (
        clk_i, rst_i : in std_logic;
        if_stall_i, if_finish_i : in std_logic;
        jaddr_i : in std_logic_vector(31 downto 0);
        jump_i : in std_logic;
        addr_o : out std_logic_vector(31 downto 0)
    ) ;
end pc;

architecture behavioral of pc is
    signal addr_r, next_addr : std_logic_vector(31 downto 0);
    signal jump, jump_r : std_logic;
    signal jaddr, jaddr_r : std_logic_vector(31 downto 0);
begin
    jump <= jump_r or jump_i;
    jaddr <= jaddr_r when jump_r = '1' else jaddr_i;
    next_addr <= std_logic_vector(unsigned(addr_r) + 4) when jump = '0' else jaddr;
    addr_o <= next_addr;

    process (clk_i, rst_i)
    begin
        if (rst_i = '0') then
            addr_r <= std_logic_vector('1' & to_unsigned(0, 31) - 4); -- ram1 : 0x80000000 - 0x803FFFFF;
            jump_r <= '0';
            jaddr_r <= (others => '0');
        elsif (clk_i'event and clk_i = '1') then
            if (if_stall_i = '0' and if_finish_i = '1') then
                -- addr has been taken by if, gen new addr
                addr_r <= next_addr;
                jump_r <= '0';
                jaddr_r <= (others => '0');
            elsif (jump = '1') then
                -- record jump infomation
                jump_r <= '1';
                jaddr_r <= jaddr_i;
            end if;
        end if;
    end process;
end behavioral ; -- behavioral
