library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity if_stage is
    port (
        clk_i : in std_logic;
        rst_i : in std_logic;
        pc_addr_i : in std_logic_vector(31 downto 0);
        stall_i : in std_logic;
        finished_o : out std_logic;
        ins_data_o : out std_logic_vector(31 downto 0);
        ins_addr_o : out std_logic_vector(31 downto 0);

        data_i : in std_logic_vector(31 downto 0);
        ack_i : in std_logic;
        addr_o : out std_logic_vector(31 downto 0);
        req_o : out std_logic
    ) ;
end if_stage;

architecture behavioral of if_stage is
    -- finished_r and data_r are used to remember state when if stage is finished but stalled by other stages
    signal finished : std_logic;
    signal finished_r : std_logic;
    signal data, data_r : std_logic_vector(31 downto 0);
begin
    finished_o <= finished;
    finished <= ack_i or finished_r;
    data <= data_r when finished_r = '1' else
            data_i;
    ins_data_o <= data;

    process (clk_i, rst_i)
    begin
        if (rst_i = '0') then
            finished_r <= '1';
            req_o <= '0';
            data_r <= (others => '0');
            ins_addr_o <= (others => '0');
        elsif (clk_i'event and clk_i = '1') then
            if (finished = '1') then
                if (stall_i = '1') then
                    -- finished but stalled by other stages, set finished_r and save data, unset req
                    finished_r <= '1';
                    data_r <= data;
                    req_o <= '0';
                else
                    -- not stalled and finished, update addr_o and clear finished_r, set req
                    finished_r <= '0';
                    addr_o <= pc_addr_i;
                    ins_addr_o <= pc_addr_i;
                    req_o <= '1';
                end if;
            else
                -- not finished, just keep signals and set req
                req_o <= '1';
            end if;
        end if;
    end process;
end behavioral ; -- behavioral
