-- VGA Palette Pixel Generation Circuit
-- 

library ieee;
use ieee.std_logic_1164.ALL;

entity vga_palette is
    generic(
        SQUARE_SIDE_BITS: integer := 2
    );
    port(
        red: out  std_logic_vector(2 downto 0);
        green: out  std_logic_vector(2 downto 0);
        blue: out  std_logic_vector(2 downto 1);
        pixel_x: in  std_logic_vector(SQUARE_SIDE_BITS + 4 downto 0);
        pixel_y: in  std_logic_vector(SQUARE_SIDE_BITS + 4 downto 0);
        video_on: in std_logic;
        red_on: in std_logic; -- Activate red component
        green_on: in std_logic; -- Activate green component
        blue_on: in std_logic -- Activate blue component
    );
end vga_palette;

architecture vga_palette_arch of vga_palette is
begin
    blue <= pixel_x(SQUARE_SIDE_BITS+2 downto SQUARE_SIDE_BITS+1) when video_on = '1' and blue_on = '1'
        else "00";
    green(1 downto 0) <= pixel_x(SQUARE_SIDE_BITS+4 downto SQUARE_SIDE_BITS+3) when video_on = '1' and green_on = '1'
        else "00";
    green(2) <= pixel_y(SQUARE_SIDE_BITS+1) when video_on = '1' and green_on = '1'
        else '0';
    red <= pixel_y(SQUARE_SIDE_BITS+4 downto SQUARE_SIDE_BITS+2) when video_on = '1' and red_on = '1'
        else "000";
end vga_palette_arch;

