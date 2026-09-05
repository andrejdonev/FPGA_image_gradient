library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Top_level is
    Port ( 
        button_in : in std_logic;
        tx        : out std_logic;
        reset     : in std_logic;
        clk       : in std_logic
    );
end Top_level;

architecture Structural of Top_level is
    signal tx_valid : std_logic;
    signal tx_busy  : std_logic;
    signal tx_read  : std_logic_vector(7 downto 0);
    signal start    : std_logic;
begin
    
    MAGNITUDE_GRAD: entity work.Magnitude_grad
        port map (
            start => start,
            clk => clk,
            tx_valid => tx_valid,
            read_out => tx_read,
            tx_busy => tx_busy,
            done => open,
            read_flag => open,
            reset => reset
        );
        
    DEBOUNCER: entity work.debouncer 
        port map (
            clk => clk,
            reset => reset,
            button_in => button_in,
            button_out => start
        );
    UART: entity work.uart_tx
        port map (
            clk => clk,
            rst => reset,
            tx => tx,
            tx_busy => tx_busy,
            tx_dvalid => tx_valid,
            tx_data => tx_read,
            par_en => '0'
        );
        
end Structural;
