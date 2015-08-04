-- VGA Tiled Framebuffer
-- 8x16 tiles (8 bits per pixel) - 640x480 screen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_tiling_8x16 is
    port(
        clk, reset: in std_logic;
        -- VGA Sync.
        pixel_tick, video_on: in std_logic;
        pixel_x: in std_logic_vector(9 downto 0);
        pixel_y: in std_logic_vector(9 downto 0);
        -- Indexes memory
        addr_index: in std_logic_vector(13 downto 0);
        data_in_index: in std_logic_vector(7 downto 0);
        data_out_index: out std_logic_vector(7 downto 0);
        wr_index: in std_logic;
        -- Tiles memory
        addr_tiles: in std_logic_vector(14 downto 0);
        data_in_tiles: in std_logic_vector(7 downto 0);
        data_out_tiles: out std_logic_vector(7 downto 0);
        wr_tiles: in std_logic;
        -- Output
        pixel_value: out std_logic_vector(7 downto 0)
    );
end vga_tiling_8x16;

architecture vga_tile_arch of vga_tiling_8x16 is
    -- Indexes memory
    signal addr_rd_index: std_logic_vector(13 downto 0);
    signal data_rd_index: std_logic_vector(7 downto 0);
    -- Tiles memory
    signal addr_rd_tiles: std_logic_vector(14 downto 0);
    signal data_rd_tiles: std_logic_vector(7 downto 0);
    --
    signal tile_x_reg, tile_x_next: unsigned(11 downto 0);
    signal tile_y_reg, tile_y_next: unsigned(11 downto 0);
begin

    -- Indexes memory block (16K x 8 bits)
    index_mem: entity work.block_ram
        generic map(DATA_WIDTH => 8, ADDR_WIDTH => 14)
        port map(
            clk => clk,
            -- Port A (read, internal)
            wr_a => '0',
            addr_a => addr_rd_index,
            data_out_a => data_rd_index,
            data_in_a => (others => '0'),
            -- Port B (write/read, external)
            wr_b => wr_index,
            addr_b => addr_index,
            data_out_b => data_out_index,
            data_in_b => data_in_index
        );

    -- Tiles memory block (32K x 8 bits)
    tiles_mem: entity work.block_ram
        generic map(DATA_WIDTH => 8, ADDR_WIDTH => 15)
        port map(
            clk => clk,
            -- Port A (read, internal)
            wr_a => '0',
            addr_a => addr_rd_tiles,
            data_out_a => data_rd_tiles,
            data_in_a => (others => '0'),
            -- Port B (write/read, external)
            wr_b => wr_tiles,
            addr_b => addr_tiles,
            data_out_b => data_out_tiles,
            data_in_b => data_in_tiles
        );
        
        -- Registers
        process(clk, reset)
        begin
            if reset = '1' then
                tile_x_reg <= (others => '0');
                tile_y_reg <= (others => '0');
            elsif rising_edge(clk) then
                tile_x_reg <= tile_x_next;
                tile_y_reg <= tile_y_next;
            end if;
        end process;

        -- Next state
       process(pixel_tick, video_on, pixel_x, pixel_y, 
            tile_x_reg, tile_y_reg)
        begin
        
            tile_y_next <= tile_y_reg;
            tile_x_next <= tile_x_reg;

            if video_on = '1' and pixel_tick = '1' and pixel_x(2 downto 0) = "111" then -- End of tile x
                    if pixel_x = "1001111111" then -- End of screen x
                        if pixel_y(3 downto 0) = "1111" then -- End of tile y
                            if pixel_y = "0111011111" then -- End of screen y
                                tile_x_next <= (others => '0');
                                tile_y_next <= (others => '0');
                            else
                                tile_y_next <= tile_y_reg + tile_x_reg + 1;
                            end if;
                        end if;
                        tile_x_next <= (others => '0');
                    else
                        tile_x_next <= tile_x_reg + 1;
                    end if;
            end if;
        end process;

        -- Memory wiring
        addr_rd_index(13 downto 12) <= (others => '0');
        addr_rd_index(11 downto 0) <= std_logic_vector(tile_y_reg + tile_x_reg);

        addr_rd_tiles(14 downto 7) <= data_rd_index;
        addr_rd_tiles(6 downto 3) <= pixel_y(3 downto 0);
        addr_rd_tiles(2 downto 0) <= pixel_x(2 downto 0);
        
        -- Output
        pixel_value <= data_rd_tiles when video_on = '1' else "00000000"; -- Black is the new video off !
end vga_tile_arch;

