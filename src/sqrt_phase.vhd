library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sqrt_phase is
    Generic (
        G_BLOCK_WIDTH : natural := 32;
        G_WIDTH : natural := 16
    );
    
    Port (
        clk : in std_logic;
        reset : in std_logic;
        
        shift : in integer range 0 to G_BLOCK_WIDTH/2 - 1;
        

        block_in : in std_logic_vector(G_BLOCK_WIDTH - 1 downto 0);
        block_out : out std_logic_vector(G_BLOCK_WIDTH - 1 downto 0);
                        
        P_in : in std_logic_vector(G_WIDTH - 1 downto 0);
        P_out : out std_logic_vector(G_WIDTH - 1 downto 0);

        R_in : in std_logic_vector(G_WIDTH - 1 downto 0);
        R_out : out std_logic_vector(G_WIDTH - 1 downto 0);
        
        valid_in : in std_logic;
        valid_out : out std_logic
    );
end sqrt_phase;

architecture Behavioral of sqrt_phase is
    constant C_BLOCK_WIDTH : natural := G_BLOCK_WIDTH;
begin
CLOCKED: process(clk) is
    variable Rnew       : integer;
    variable test_value : integer;
    variable block_sel  : integer;
begin
    if rising_edge(clk) then
        if reset = '1' then
            P_out <= (others => '0');
            R_out <= (others => '0');
            block_out <= (others => '0');
            valid_out <= '0';
        else
            block_sel := C_BLOCK_WIDTH - shift*2 - 1;
            Rnew := to_integer(unsigned(R_in)) * 4 + to_integer(unsigned(block_in(block_sel downto block_sel - 1)));
            test_value := 4 * to_integer(unsigned(P_in)) + 1;


            if Rnew >= test_value then 
                P_out <= std_logic_vector(to_unsigned(2 * to_integer(unsigned(P_in)) + 1, P_out'length));
                R_out <= std_logic_vector(to_unsigned(Rnew - test_value, R_out'length));
            else
                P_out <= std_logic_vector(to_unsigned(2 * to_integer(unsigned(P_in)), P_out'length));
                R_out <= std_logic_vector(to_unsigned(Rnew, R_out'length));    
            end if;
            valid_out <= valid_in;
            block_out <= block_in;
        end if;
    end if;
end process CLOCKED;
end Behavioral;