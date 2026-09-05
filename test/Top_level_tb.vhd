----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/15/2026 07:12:11 PM
-- Design Name: 
-- Module Name: Top_level_tb - Test
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Top_level_tb is
--  Port ( );
end Top_level_tb;

architecture Test of Top_level_tb is
    signal button_in : std_logic;
    signal tx        : std_logic;
    signal reset     : std_logic;
    signal clk       : std_logic := '0';
begin

    DUT: entity work.Top_level
        port map (
            button_in => button_in,
            tx => tx,
            reset => reset,
            clk => clk
        );

clk <= not clk after 4 ns;

STIMULUS: process is
begin
    reset <= '1';
    button_in <= '0';
    wait for 16ns;
    reset <= '0';
    button_in <= '1';
    wait for 1100us;
    button_in <= '0';    
    wait;
    
end process STIMULUS;


end Test;
