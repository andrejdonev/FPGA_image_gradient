library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package sobel_pkg is
    type mask_array_type is array (0 to 8) of std_logic_vector(7 downto 0);
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.sobel_pkg.all;

entity sobel is
    port(
        reset     : in std_logic;
        clk       : in std_logic;
        mask      : in mask_array_type;
        sqrt_data : out std_logic_vector(15 downto 0);
        valid_in  : in std_logic;
        valid_out : out std_logic
    );
end sobel;

architecture Behavioral of sobel is

    type phase1_array_type is array (0 to 5) of integer range -512 to 512;
    
    signal h_mask : phase1_array_type := (others => 0);
    signal v_mask : phase1_array_type := (others => 0);
    signal h_result : integer range -1024 to 1024 := 0;
    signal v_result : integer range -1024 to 1024 := 0;
    signal h_squared : integer range 0 to 1024 * 1024 := 0;
    signal v_squared : integer range 0 to 1024 * 1024 := 0;
    signal h_scaled : integer range 0 to 1024 * 1024 / 64 := 0;
    signal v_scaled : integer range 0 to 1024 * 1024 / 64 := 0;
    signal mag_res  : integer range 0 to 1024 * 1024 / 64 * 2 := 0;
    signal valid_1, valid_2, valid_3, valid_4, valid_5 : std_logic;
begin

PHASE_1: process(clk) is
begin
    if rising_edge(clk) then
        if reset = '1' then
            h_mask <= (others => 0);
            v_mask <= (others => 0);
            valid_1 <= '0';
        else

            h_mask(0) <= to_integer(unsigned(mask(0)));
            h_mask(1) <= 2 * to_integer(unsigned(mask(3)));
            h_mask(2) <= to_integer(unsigned(mask(6)));
            h_mask(3) <= (-1) * to_integer(unsigned(mask(2)));
            h_mask(4) <= (-2) * to_integer(unsigned(mask(5)));
            h_mask(5) <= (-1) * to_integer(unsigned(mask(8)));
            
            v_mask(0) <= to_integer(unsigned(mask(0)));
            v_mask(1) <= 2 * to_integer(unsigned(mask(1)));
            v_mask(2) <= to_integer(unsigned(mask(2)));
            v_mask(3) <= (-1) * to_integer(unsigned(mask(6)));
            v_mask(4) <= (-2) * to_integer(unsigned(mask(7)));
            v_mask(5) <= (-1) * to_integer(unsigned(mask(8)));
            
            valid_1 <= valid_in;
        end if;
    end if;
end process PHASE_1;

PHASE_2: process(clk) is
begin
    if rising_edge(clk) then
        if reset = '1' then 
            h_result <= 0;
            v_result <= 0;
            valid_2 <= '0';
        else
            h_result <= h_mask(0) + h_mask(1) + h_mask(2) + h_mask(3) + h_mask(4) + h_mask(5);
            v_result <= v_mask(0) + v_mask(1) + v_mask(2) + v_mask(3) + v_mask(4) + v_mask(5);
            valid_2 <= valid_1;
        end if;
    end if;
end process PHASE_2;

PHASE_3: process(clk) is
begin
    if rising_edge(clk) then
        if reset = '1' then 
            h_squared <= 0;
            v_squared <= 0;
            valid_3 <= '0';
        else
            h_squared <= h_result * h_result;
            v_squared <= v_result * v_result;
            valid_3 <= valid_2;
        end if;
    end if;
end process PHASE_3;

PHASE_4: process(clk) is
begin
    if rising_edge(clk) then
        if reset = '1' then 
            h_scaled <= 0;
            v_scaled <= 0;
            valid_4 <= '0';
        else
            h_scaled <= h_squared / 64;
            v_scaled <= v_squared / 64;
            valid_4 <= valid_3;
        end if;
    end if;
end process PHASE_4;

PHASE_5: process(clk) is
begin
    if rising_edge(clk) then
        if reset = '1' then 
            mag_res <= 0;
            valid_5 <= '0';
        else
            mag_res <= h_scaled + v_scaled;
            valid_5 <= valid_4;
        end if;
    end if;
end process PHASE_5;

sqrt_data <= std_logic_vector(to_unsigned(mag_res, 16));
valid_out <= valid_5;

end Behavioral;