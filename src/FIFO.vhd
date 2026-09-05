library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FIFO is
    generic (
        G_DATAWIDTH : natural := 8;
        G_FIFODEPTH : natural := 253
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        d_in : in std_logic_vector(G_DATAWIDTH -1 downto 0);
        d_out : out std_logic_vector(G_DATAWIDTH -1 downto 0)
    );
end FIFO;

architecture Behavioral of FIFO is
    type dat_array_t is array (0 to G_FIFODEPTH) of std_logic_vector(G_DATAWIDTH-1 downto 0);
    signal dat_array : dat_array_t;
begin

dat_array(0) <= d_in;
d_out <= dat_array(G_FIFODEPTH);

    GEN_PIPE: for i in 0 to G_FIFODEPTH-1 generate
        PHASE_INST: entity work.FIFO_PHASE
            port map (
                clk   => clk,
                reset => reset,
                d_in  => dat_array(i),
                d_out => dat_array(i+1)
            );
    end generate;



end Behavioral;
