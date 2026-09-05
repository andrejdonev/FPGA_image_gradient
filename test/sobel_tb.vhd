library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.sobel_pkg.all;

entity sobel_tb is
--  Port ( );
end sobel_tb;

architecture Test of sobel_tb is
    signal mask : mask_array_type := (others =>(others => '0'));
    signal reset, clk, valid_in, valid_out : std_logic := '0';
    signal sqrt_data : std_logic_vector(15 downto 0);
begin
    DUT: entity work.sobel
        port map(
            clk => clk,
            reset => reset,
            valid_in => valid_in,
            valid_out => valid_out,
            mask => mask,
            sqrt_data => sqrt_data
        );

clk <= not clk after 4ns;

STIMULUS: process is
begin
    mask(0) <= "11000000";
    mask(1) <= "11000000";
    mask(2) <= "11000000";
    mask(3) <= "11000000";
    mask(4) <= "11000000";
    mask(5) <= "00000000";
    mask(6) <= "00000000";
    mask(7) <= "00000000";
    mask(8) <= "00000000";
    wait for 8ns;
    valid_in <= '0';
    wait for 8ns;
    valid_in <= '1';
    wait for 8ns;
    valid_in <= '0';
    wait;
end process STIMULUS;

end Test;
