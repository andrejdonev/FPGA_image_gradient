
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debouncer is
    generic(
        G_CLK_PERIOD : natural := 8 --period u ns
    );
    port(
        reset     : in std_logic;
        clk       : in std_logic;
        button_in : in std_logic;
        button_out: out std_logic
    );
end debouncer;

architecture Behavioral of debouncer is
    constant C_WAIT_CNT : integer := 100000000 * 10 / 1000 / G_CLK_PERIOD;
    type State_t is (stIdle, stWait, stCheck, stGenerate);
    signal state_reg, next_state : State_t;
    signal wait_cnt : integer range 0 to  C_WAIT_CNT;
begin

STATE_TRANSITION: process(clk) is
begin
    if rising_edge(clk) then
        if reset = '1' then
            state_reg <= stIdle;
        else    
            state_reg <= next_state;
        end if;
    end if;
end process STATE_TRANSITION;

NEXT_STATE_LOGIC: process(state_reg, wait_cnt, button_in) is
begin
    next_state <= state_reg;
    case state_reg is
        when stIdle =>
            if button_in = '1' then
                next_state <= stWait;
            end if;
        when stWait =>
            if wait_cnt = C_WAIT_CNT then
                next_state <= stCheck;
            end if;
        when stCheck =>
            if button_in = '1' then
                next_state <= stGenerate;
            else
                next_state <= stIdle;
            end if;
        when stGenerate =>
            next_state <= stIdle;
    end case;
end process NEXT_STATE_LOGIC;

REG_LOGIC: process(clk) is
begin
    if rising_edge(clk) then
        case state_reg is
            when stIdle =>
                wait_cnt <= 0;
                button_out <= '0';
            when stWait =>
                if wait_cnt < C_WAIT_CNT then
                    wait_cnt <= wait_cnt + 1;
                else
                    wait_cnt <= wait_cnt;
                end if;
                button_out <= '0';
            when stCheck =>
                wait_cnt <= 0;
                button_out <= '0';
            when stGenerate =>
                wait_cnt <= 0;
                button_out <= '1';
        end case;
    end if;
end process REG_LOGIC;

end Behavioral;
