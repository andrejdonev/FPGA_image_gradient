library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity FIFO_PHASE is
    generic (
        G_DATAWIDTH : natural := 8
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        d_in : in std_logic_vector(G_DATAWIDTH -1 downto 0);
        d_out : out std_logic_vector(G_DATAWIDTH -1 downto 0)
    );
end FIFO_PHASE;


architecture Behavioral of FIFO_PHASE is
    signal data_reg : std_logic_vector(G_DATAWIDTH -1 downto 0);
begin
CLOCKED: process(clk) is

begin

    if rising_edge(clk) then
        data_reg <= d_in;
        d_out <= data_reg;
        if reset = '1' then
            data_reg <= (others => '0');
            d_out <= (others => '0');
        end if;
    end if;
end process CLOCKED;


end Behavioral;
