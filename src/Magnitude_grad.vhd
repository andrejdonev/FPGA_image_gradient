library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.sobel_pkg.all;

entity Magnitude_grad is
    generic(
        G_PIXEL_WIDTH : natural := 8
        
    );
    
    port(
        clk : in std_logic;
        start : in std_logic;
        done : out std_logic;
        reset : in std_logic;
        read_out : out std_logic_vector(G_PIXEL_WIDTH - 1 downto 0);
        read_flag : out std_logic;
        tx_valid  : out std_logic;
        tx_busy  : in std_logic

    );
    
end Magnitude_grad;

architecture Behavioral of Magnitude_grad is

    constant C_PIXEL_WIDTH : natural := G_PIXEL_WIDTH;
    constant RAM_SIZE : integer := 256 * 256 - 1;
    
    signal stop: std_logic;
    signal done_flag : std_logic;
    signal tx_valid_delay : std_logic;

    type State_t is (stIdle, stStart, stRead);
    signal state_reg, next_state : State_t;
    
    --REGISTIR MAKSE
    type mask_reg_type is array (0 to 8) of std_logic_vector(G_PIXEL_WIDTH - 1 downto 0);
    signal mask_reg : mask_array_type := (others =>(others => '0'));    
    
    --SOBEL REGISTRI
    signal sobel_reset: std_logic;
    signal valid_data_sobel: std_logic;
    
    --FIFO SIGNALI
    signal fifo_reset : std_logic;
    signal fifo1_wr, fifo2_wr : std_logic_vector(C_PIXEL_WIDTH - 1 downto 0);
    signal fifo1_rd, fifo2_rd : std_logic_vector(C_PIXEL_WIDTH - 1 downto 0);
    
    --SIGNALI BLOCK RAMA
    signal read_addr, read_addr_d : std_logic_vector(15 downto 0) := (others => '0');
    signal write_addr : std_logic_vector(15 downto 0) := (others => '0');
    signal bram_write, bram_read : std_logic_vector(G_PIXEL_WIDTH - 1 downto 0);
    signal bram_wr_en, bram_rd_en : std_logic;    
    
    --OVO SU SIGNALI NA KOJE KACIMO SQRT
    signal sqrt_data_reg, sqrt_res_reg : std_logic_vector(15 downto 0) := (others => '0');
    signal valid_sqrt_data_in, valid_sqrt_res_out : std_logic := '0';
    
    --BROJACI
    signal pixel_cnt, write_cnt, read_cnt : integer range 0 to RAM_SIZE;    
    
begin

    FIFO1: entity work.FIFO
        generic map(
            G_DATAWIDTH => C_PIXEL_WIDTH,
            G_FIFODEPTH => 253
        )
        
        port map(
            clk => clk,
            reset => fifo_reset,
            d_in => fifo1_wr,
            d_out => fifo1_rd            
        );
    
    FIFO2: entity work.FIFO
        generic map(
            G_DATAWIDTH => C_PIXEL_WIDTH,
            G_FIFODEPTH => 253
        )
        
        port map(
            clk => clk,
            reset => fifo_reset,
            d_in => fifo2_wr,
            d_out => fifo2_rd            
        );
        
    IM_RAM: entity work.im_ram
        port map (
            addra => write_addr,       -- Write address bus, width determined from RAM_DEPTH
            addrb => read_addr,      -- Read address bus, width determined from RAM_DEPTH
            dina  => bram_write,	  -- RAM input data
            clka  => clk,             -- Clock
            wea   => bram_wr_en,      -- Write enable
            enb   => '1',             -- RAM Enable, for additional power savings, disable port when not in use
            rstb  => reset,           -- Output reset (does not affect memory contents)
            regceb=> bram_rd_en,      -- Output register enable
            doutb => bram_read 		  -- RAM output data
        );
        
    SQRT: entity work.sqrt(Behavioral_sqrt_pipelined)
    
        Port map (
            clk => clk,
            reset => reset,
            d_in => sqrt_data_reg,
            valid_in => valid_sqrt_data_in,
            d_out => sqrt_res_reg,
            valid_out => valid_sqrt_res_out
        );
        
    SOBEL: entity work.sobel
        port map(
            mask => mask_reg,
            clk => clk,
            reset => sobel_reset,
            sqrt_data => sqrt_data_reg,
            valid_in => valid_data_sobel,
            valid_out => valid_sqrt_data_in
        );
        
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

NEXT_STATE_LOGIC: process(state_reg, stop, start, done_flag) is
begin
    next_state <= state_reg;
    case state_reg is
        when stIdle => 
            if start = '1' then
                next_state <= stStart;
            end if;
        when stStart => 
            if stop = '1' then
                next_state <= stRead;
            end if;
        when stRead => 
            if done_flag = '1' then
                next_state <= stIdle;
            end if;
    end case;
end process NEXT_STATE_LOGIC;

MASK_REG_LOGIC: process(clk) is
begin
    if rising_edge(clk) then
        case state_reg is
            when stIdle =>
                mask_reg <= (others =>(others => '0'));
                fifo_reset <= '1';
            when stStart =>
                fifo_reset <= '0';
                mask_reg(0) <= bram_read;
                mask_reg(1) <= mask_reg(0);
                mask_reg(2) <= mask_reg(1);
                fifo1_wr <= mask_reg(2);
                mask_reg(3) <= fifo1_rd;
                mask_reg(4) <= mask_reg(3);
                mask_reg(5) <= mask_reg(4);
                fifo2_wr <= mask_reg(5);
                mask_reg(6) <= fifo2_rd;
                mask_reg(7) <= mask_reg(6);
                mask_reg(8) <= mask_reg(7);                     
            when stRead => 
                mask_reg <= (others =>(others => '0'));
                fifo_reset <= '1';   
         end case;
     end if;
end process MASK_REG_LOGIC;

SOBEL_LOGIC: process(clk) is
begin
    if rising_edge(clk) then
        case state_reg is
            when stIdle =>
                sobel_reset <= '1';
            when stStart =>
                sobel_reset <= '0';
            when stRead =>
                sobel_reset <= '1';
        end case;          
    end if;
end process SOBEL_LOGIC;

PIXEL_READ_LOGIC: process(clk) is
begin

    if rising_edge(clk) then
        case state_reg is
            when stIdle =>
                tx_valid_delay <= '0';
                tx_valid <= '0';
                pixel_cnt <= 0;
                read_cnt <= 0;
                read_addr <= (others => '0');
                bram_rd_en <= '0'; done_flag <= '0'; read_flag <= '0'; read_out <= (others => '0');

            when stStart =>
                tx_valid_delay <= '0';
                tx_valid <= '0';
                read_cnt <= 0; done_flag <= '0'; read_flag <= '0'; read_out <= (others => '0');
                read_addr <= std_logic_vector(to_unsigned(pixel_cnt, read_addr'length));
                if pixel_cnt < RAM_SIZE then
                    valid_data_sobel <= '1'; 
                    pixel_cnt  <= pixel_cnt + 1;
                    bram_rd_en <= '1';                
                else
                    valid_data_sobel <= '0';                
                    pixel_cnt <= pixel_cnt;
                    bram_rd_en <= '0';
                end if;
            when stRead =>
                valid_data_sobel <= '0'; read_flag <= '1';
                pixel_cnt <= 0;
                read_out <= bram_read;
                read_addr <= std_logic_vector(to_unsigned(read_cnt, read_addr'length));
                bram_rd_en <= '1';    
                if read_cnt <= RAM_SIZE then
                    done_flag <= '0';
                    if tx_busy = '0' then
                        if tx_valid_delay = '0' then
                            read_cnt <= read_cnt + 1;
                        else
                            read_cnt <= read_cnt;
                        end if;
                        tx_valid_delay <= '1';
                        tx_valid <= tx_valid_delay;
                    else
                        read_cnt <= read_cnt;
                        tx_valid_delay <= '0';
                        tx_valid <= '0';
                    end if;
                else
                    read_cnt <= read_cnt;
                    done_flag <= '1';
                end if;            
        end case;
    end if;
end process PIXEL_READ_LOGIC;

WRITE_LOGIC: process(clk) is
begin
    if rising_edge(clk) then
        case state_reg is
            when stIdle =>
                bram_wr_en <= '0';
                write_addr <= (others => '0');
                bram_write <= (others => '0');
                write_cnt <= 0;
                stop <= '0';
            when stStart =>
                write_addr <= std_logic_vector(to_signed(write_cnt - 257, write_addr'length));
                if write_cnt <= RAM_SIZE - 1  and valid_sqrt_res_out = '1' then
                    write_cnt <= write_cnt + 1;
                    bram_wr_en <= '1';
                    bram_write <= sqrt_res_reg(15 downto 8);
                else
                    write_cnt <= write_cnt;
                    bram_wr_en <= '0';
                    bram_write <= (others => '0');
                end if;
                if write_cnt <= RAM_SIZE - 1 then
                    stop <= '0';
                else
                    stop <= '1';
                end if;
            when stRead =>
                bram_wr_en <= '0';
                write_addr <= (others => '0');
                bram_write <= (others => '0');
                write_cnt <= 0;            
                stop <= '0';                        
        end case;
    end if;
end process WRITE_LOGIC;

done <= done_flag; 

end Behavioral;
    