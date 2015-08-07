-- VGA Synchronisation Circuit
-- 640x480 60Hz - Adjust clock divisor to generate a 25 Mhz pixel tick 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync is
    generic(
        CLOCK_DIVISOR: integer := 4;
        --
        SCREEN_WIDTH: integer := 640;
        SCREEN_HEIGHT: integer := 480;
        --
        TOTAL_WIDTH: integer := 800;
        TOTAL_HEIGHT: integer := 525;
        --
        HSYNC_START: integer := 656;
        HSYNC_STOP: integer := 752;
        HSYNC_POLARITY: std_logic := '0'; -- 0 negative polarity, 1 positive polarity
        --
        VSYNC_START: integer := 490;
        VSYNC_STOP: integer := 492;
        VSYNC_POLARITY: std_logic := '0' -- 0 negative polarity, 1 positive polarity
    );
    port(
        clk, reset: in std_logic;
        hsync, vsync: out std_logic;
        pixel_tick: out std_logic;
        x, y: out std_logic_vector(9 downto 0);
        video_on: out std_logic
    );
end vga_sync;

architecture arch of vga_sync is
    constant CLOCK_DIVISOR_WIDTH: integer := 2;
    signal pixel_tick_internal: std_logic;
    -- Sync. counters
    signal vcount_reg, vcount_next: unsigned(9 downto 0);
    signal hcount_reg, hcount_next: unsigned(9 downto 0);
    -- Output buffer
    signal vsync_reg, vsync_next: std_logic;
    signal hsync_reg, hsync_next: std_logic;
begin
    -- Generate Pixel Tick
    vga_clock: entity work.counter_mod_m
        generic map(N => CLOCK_DIVISOR_WIDTH, M => CLOCK_DIVISOR)
        port map(clk => clk, reset => reset, max_tick => pixel_tick_internal);

    -- State registers
    process(clk, reset)
    begin
        if reset='1' then
            vcount_reg <= (others => '0');
            hcount_reg <= (others => '0');
            vsync_reg <= '0';
            hsync_reg <= '0';
        elsif rising_edge(clk) then
            vcount_reg <= vcount_next;
            hcount_reg <= hcount_next;
            vsync_reg <= vsync_next;
            hsync_reg <= hsync_next;
        end if;
    end process;

    -- Increment hcount/vcount
    process(hcount_reg, vcount_reg, pixel_tick_internal)
	 begin
        hcount_next <= hcount_reg;
        vcount_next <= vcount_reg;

        if pixel_tick_internal = '1' then
            if hcount_reg = TOTAL_WIDTH-1 then
                hcount_next <= (others => '0');
                if vcount_reg = TOTAL_HEIGHT-1 then
                    vcount_next <= (others => '0');
                else
                    vcount_next <= vcount_reg + 1;
                end if;
            else
                hcount_next <= hcount_reg + 1;
            end if;
        end if;
    end process;

    -- Hsync/Vsync
    hsync_next <= HSYNC_POLARITY when hcount_reg >= HSYNC_START and hcount_reg < HSYNC_STOP-1 else
                  not HSYNC_POLARITY;
    vsync_next <= VSYNC_POLARITY when vcount_reg >= VSYNC_START and vcount_reg < VSYNC_STOP-1 else
                  not VSYNC_POLARITY;

    -- Output
    pixel_tick <= pixel_tick_internal;
    hsync <= hsync_reg;
    vsync <= vsync_reg;
    x <= std_logic_vector(hcount_reg);
    y <= std_logic_vector(vcount_reg);
    video_on <= '1' when hcount_reg < SCREEN_WIDTH and vcount_reg < SCREEN_HEIGHT else '0';

end arch;