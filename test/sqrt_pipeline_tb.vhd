library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sqrt_pipeline_tb is
--  Port ( );
end sqrt_pipeline_tb;

architecture Test of sqrt_pipeline_tb is

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

    DUT: entity work.sqrt(Behavioral_sqrt_pipelined)
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
    reset <= '0';

    --POSTAVLJAMO CIFRE SUKCESIVNO SVAKI TAKT
    d_in <= "0000000001100000";  
    valid_in <= '0';
    wait for 10ns;        
    d_in <= "0110000000000011";  
    wait for 10ns; 
    d_in <= "0110100001101011";  
    wait for 10ns; 
    d_in <= "1110100001101011";  
    wait for 10ns;
    d_in <= "0110000000000011";  
    wait for 10ns; 
    d_in <= "0110100001101011";  
    wait for 10ns; 
    d_in <= "1110100001101011";  
    wait for 10ns; 
    d_in <= "0110000000000011";  
    wait for 10ns; 
    d_in <= "0110100001101011";  
    wait for 10ns; 
    d_in <= "1110100001101011";  
    wait for 10ns; 
    d_in <= "0110000000000011";  
    wait for 10ns; 
    d_in <= "0110100001101011";  
    wait for 10ns; 
    d_in <= "1110100001101011";  
    wait for 10ns;      
    valid_in <= '0';
    wait for 500ns;
 
    --POSTAVLJAMO CIFRE ALI GA PREKIDAMO SA RESETOM
    d_in <= "0000000001100000";  
    valid_in <= '0';
    wait for 10ns;        
    d_in <= "0110000000000011";  
    wait for 10ns; 
    d_in <= "0110100001101011";
    reset <= '1';  
    wait for 10ns; 
    d_in <= "1110100001101011";  
    wait for 10ns;     
    valid_in <= '0';
    wait for 200ns;   
    wait;
    
end process STIMULUS;
end Test;