library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sqrt is
    Generic (
        G_IN_BW : natural := 16;
        G_OUT_BW : natural := 16;
        G_OUT_FRAC : natural := 8
    );
    
    Port (
        clk : in std_logic;
        reset : in std_logic;
        d_in : in std_logic_vector(G_IN_BW - 1 downto 0);
        valid_in : in std_logic;
        d_out : out std_logic_vector(G_OUT_BW - 1 downto 0);
        valid_out : out std_logic

    );
end sqrt;

architecture Behavioral_sqrt_seq of sqrt is

    constant C_BLOCKS : natural := (G_IN_BW + 1) / 2 + G_OUT_FRAC;
    constant C_MAX    : integer := 2**C_BLOCKS;
    constant C_IN     : natural := G_IN_BW;
    
    type State_t is (stIdle, stSetup,  stShift, stCheck, stOutput);
    signal state_reg, next_state : State_t;    

    signal d_in_reg, block_reg : std_logic_vector(2* C_BLOCKS - 1 downto 0) := (others => '0');
    signal shift_cnt : integer range 0 to C_BLOCKS;
    
    signal Rnew, P, Ri : integer range 0 to 2**C_BLOCKS;
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

NEXT_STATE_LOGIC: process(state_reg, valid_in, shift_cnt) is
begin
    next_state <= state_reg;
    case state_reg is
        when stIdle =>
            if valid_in = '1' then
                next_state <= stSetup;
            end if;
        when stSetup =>
            next_state <= stShift;
        when stShift =>
            next_state <= stCheck;
        when stCheck =>
            next_state <= stShift;
            if shift_cnt = C_BLOCKS then
                next_state <= stOutput;
            end if;
        when stOutput =>
            next_state <= stIdle;
    end case;
end process NEXT_STATE_LOGIC;

REG_LOGIC: process(clk) is
begin
    if rising_edge(clk) then
        d_in_reg(2*C_BLOCKS - 1 downto 2*C_BLOCKS - C_IN) <= d_in;
        case state_reg is
            when stIdle =>
                block_reg <= (others => '0');
                shift_cnt <= 0; Rnew <= 0; Ri <= 0; P <= 0;                
            when stSetup =>
                block_reg <= d_in_reg;
                shift_cnt <= 0; Rnew <= 0; Ri <= 0; P <= 0;                
            when stShift =>
                shift_cnt <= shift_cnt + 1;
                Rnew <= Ri * 4 + to_integer(unsigned(
                    block_reg(2*C_BLOCKS - 2*(shift_cnt) - 1
                    downto 2*C_BLOCKS - 2*(shift_cnt) - 2))
                    );  
            when stCheck =>
                if Rnew >= 4*P + 1 then
                    P <= P*2 + 1;
                    Ri <= Rnew - 4*P - 1;
                else
                    P <= P*2;
                    Ri <= Rnew;
                end if;            
            when stOutput =>           
        end case;
    end if;
end process REG_LOGIC;

OUTPUT_LOGIC: process(clk) is
begin
    if rising_edge(clk) then
        if state_reg = stOutput then
            d_out <= std_logic_vector(to_unsigned(P, d_out'length));
            valid_out <= '1';
        else
            d_out <= (others => '0');
            valid_out <= '0'; 
        end if;
    end if;
end process OUTPUT_LOGIC;

end Behavioral_sqrt_seq;

architecture Behavioral_sqrt_pipelined of sqrt is

    constant C_BLOCKS : natural := (G_IN_BW + 1) / 2 + G_OUT_FRAC;
    
    type t_P_array is array (0 to C_BLOCKS) of std_logic_vector(C_BLOCKS - 1 downto 0);
    type t_R_array is array (0 to C_BLOCKS) of std_logic_vector(C_BLOCKS - 1 downto 0);
    
    type t_Data_array is array (0 to C_BLOCKS) of std_logic_vector(2*C_BLOCKS - 1 downto 0);

    signal sig_P : t_P_array;
    signal sig_R : t_R_array;
    signal sig_Data : t_Data_array;
    signal valid_pipe : std_logic_vector(C_BLOCKS downto 0);
    
    
begin

    sig_P(0) <= (others => '0');
    sig_R(0) <= (others => '0');
    valid_pipe(0) <= valid_in;

    process(clk)
    begin
        if rising_edge(clk) then
            sig_Data(0) <= (others => '0');
            sig_Data(0)(2*C_BLOCKS - 1 downto 2*C_BLOCKS - G_IN_BW) <= d_in;
        end if;
    end process;

    GEN_SQRT: for i in 0 to C_BLOCKS - 1 generate

        PHASE_INST: entity work.sqrt_phase
            generic map (
                G_WIDTH      => C_BLOCKS,
                G_BLOCK_WIDTH => 2*C_BLOCKS
            )
            port map (
                clk      => clk,
                reset    => reset,
                shift    => i,            
                block_in => sig_Data(i),
                block_out=> sig_Data(i+1),  
                P_in     => sig_P(i),       
                P_out    => sig_P(i+1),     
                R_in     => sig_R(i),        
                R_out    => sig_R(i+1) ,   
                valid_in => valid_pipe(i),
                valid_out=> valid_pipe(i+1)
            );
    end generate GEN_SQRT;

    d_out <= sig_P(C_BLOCKS);
    valid_out <= valid_pipe(C_BLOCKS);

end Behavioral_sqrt_pipelined;
