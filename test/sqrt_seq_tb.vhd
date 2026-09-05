library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sqrt_seq_tb is
--  Port ( );
end sqrt_seq_tb;

architecture Test of sqrt_seq_tb is

    constant CLK_PERIOD : time := 10ns;

    constant C_IN_BW    : natural := 16;
    constant C_OUT_BW   : natural := 16;
    constant C_OUT_FRAC : natural := 8;
    
    constant C_BLOCKS : natural := (C_IN_BW + 1) / 2 + C_OUT_FRAC;
    constant C_MAX    : integer := 2**C_BLOCKS;

    signal d_in      : std_logic_vector(C_IN_BW - 1 downto 0) := (others => '0');
    signal d_out     : std_logic_vector(C_OUT_BW - 1 downto 0);
    signal clk       : std_logic := '0';
    signal reset     : std_logic := '0';
    signal valid_in  : std_logic := '0';
    signal valid_out : std_logic;
    
begin

    DUT: entity work.sqrt(Behavioral_sqrt_seq)
        port map (
            clk => clk,
            reset => reset,
            d_in => d_in,
            d_out => d_out,
            valid_in => valid_in,
            valid_out => valid_out 
        );
      
clk <= not clk after CLK_PERIOD/2;


STIMULUS: process is
begin

    --POCINJEMO SA RESETOM
    d_in <= "0000000000000000";
    reset <= '1';
    wait for 10ns;

    --RESET STAVLJAMO NA NULU I PROSLEDJUJEMO BRO
    reset <= '0';
    d_in <= "0001000100010001";
    valid_in <= '1';
    wait for 10 ns;
    
    --SPUSTAMO BROJ
    d_in <= "0000000000000000";
    valid_in <= '0';
    wait for 50 ns;
    
    --PREKIDAMO ITERACIJE SA RESETOM, DA VIDIMO JE L TO OKEJ
    reset <= '1';
    wait for 10ns;
    reset <= '0';
    wait for 10 ns;
    
    --PROSLEDJUJEMO BROJ
    d_in <= "0001000100010001";
    valid_in <= '1';
    wait for 10 ns;
    
    --SPUSTAMO BROJ
    d_in <= "0000000000000000";
    valid_in <= '0';
    wait for 100 ns;
    
    --PROSLEDJUJEMO BROJ U SRED TERACIJE
    d_in <= "0010011100010000";
    valid_in <= '1';
    wait for 400 ns;
    
    --SPUSTAMO BROJ
    d_in <= "0000000000000000";
    valid_in <= '0';
    wait for 10 ns;
    wait;
end process;

end Test;
