-- VGA Palette testing circuit
--

library ieee;
use ieee.std_logic_1164.ALL;

entity vga_palette_top is
    port(
        clk, reset: in std_logic;
        red: out  std_logic_vector(2 downto 0);
        green: out  std_logic_vector(2 downto 0);
        blue: out  std_logic_vector(2 downto 1);
        hsync: out  std_logic;
        vsync: out  std_logic;
        blue_on: in std_logic;
        green_on: in std_logic;
        red_on: in std_logic
    );
end vga_palette_top;

architecture vga_palette_top_arch of vga_palette_top is
	-- VGA Sync.
    signal pixel_tick: std_logic;
    signal pixel_x, pixel_y: std_logic_vector(9 downto 0);
    signal video_on: std_logic;
begin

    vga_sync: entity work.vga_sync
		port map(clk => clk, reset => reset, 
            pixel_tick => pixel_tick,
			x => pixel_x, y => pixel_y, 
            hsync => hsync, vsync => vsync, video_on => video_on);

    vga_palette: entity work.vga_palette
        port map(pixel_x => pixel_x(6 downto 0), pixel_y => pixel_y(6 downto 0),
            video_on => video_on,
            red => red, green => green, blue => blue,
            red_on => red_on, green_on => green_on, blue_on => blue_on);

end vga_palette_top_arch;

