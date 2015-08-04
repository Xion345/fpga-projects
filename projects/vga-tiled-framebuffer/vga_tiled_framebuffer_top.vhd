-- VGA controller with tiled frambuffer
-- Video mode: 640x480 60Hz 8 bit pixel depth
-- Tiles: 8x16 - 256 Tiles
-- UART: 115200 bauds - 8 bits - No parity

library ieee;
use ieee.std_logic_1164.all;

entity vga_tiled_framebuffer_top is
    port(clk, reset: in std_logic;
		-- UART
		rx: in std_logic;
		tx: out std_logic;
		-- VGA
		red: out std_logic_vector(2 downto 0);
		green: out std_logic_vector(2 downto 0);
		blue: out std_logic_vector(2 downto 1);
		hsync: out std_logic;
		vsync: out std_logic
	);
end vga_tiled_framebuffer_top;

architecture vga_tiled_framebuffer_top_arch of vga_tiled_framebuffer_top is
	constant ADDR_BYTES: integer := 2;
	-- VGA Sync.
	signal pixel_tick: std_logic;
	signal pixel_x, pixel_y: std_logic_vector(9 downto 0);
	signal video_on: std_logic;
	-- VGA Tiling system
	signal addr_index: std_logic_vector(13 downto 0);
	signal data_in_index: std_logic_vector(7 downto 0);
	signal data_out_index: std_logic_vector(7 downto 0);
	signal wr_index: std_logic;
	-- 
	signal addr_tiles: std_logic_vector(14 downto 0);
	signal data_in_tiles: std_logic_vector(7 downto 0);
	signal data_out_tiles: std_logic_vector(7 downto 0);
	signal wr_tiles: std_logic;
	-- DMA
	signal dma_addr: std_logic_vector(15 downto 0);
	signal dma_data_in: std_logic_vector(7 downto 0);
	signal dma_data_out: std_logic_vector(7 downto 0);
	signal dma_wr: std_logic;
	-- UART
	signal rx_done_tick: std_logic;
	signal tx_done_tick: std_logic;
	signal data_rx: std_logic_vector(7 downto 0);
	signal data_tx: std_logic_vector(7 downto 0);
	signal tx_start_tick: std_logic;
begin
    
    -- VGA Synchronization
    vga_sync: entity work.vga_sync
		port map(clk => clk, reset => reset, 
            pixel_tick => pixel_tick,
			x => pixel_x, y => pixel_y, 
            hsync => hsync, vsync => vsync, video_on => video_on);
	
    -- VGA Tiled Framebuffer
	vga_tiling: entity work.vga_tiling_8x16
		port map(
			clk => clk, reset => reset,
			pixel_tick => pixel_tick, video_on => video_on,
			pixel_x => pixel_x, pixel_y => pixel_y,
			--
			addr_index => addr_index,
			data_in_index => data_in_index,
			data_out_index => data_out_index,
			wr_index => wr_index,
			--
			addr_tiles => addr_tiles,
			data_in_tiles => data_in_tiles,
			data_out_tiles => data_out_tiles,
			wr_tiles => wr_tiles,
			-- Output
			pixel_value(7 downto 5) => red,
			pixel_value(4 downto 2) => green,
			pixel_value(1 downto 0) => blue 
		);
       
    -- DMA
	dma: entity work.uart_dma
		generic map(
			RAM_READ_TICKS => 1, ADDR_BYTES => 2)
		port map(
			clk => clk, reset => reset,
			rx_done_tick => rx_done_tick,
			tx_done_tick => tx_done_tick,
			data_rx => data_rx,
			data_tx => data_tx,
			tx_start_tick => tx_start_tick,
			--
			data_ram_rd => dma_data_in,
			data_ram_wr => dma_data_out,
			addr(22 downto 16) => open,
			addr(15 downto 0) => dma_addr,
			wr => dma_wr
		);

	-- Memory multiplexing (on shared bus)
	-- Multiplex on 16th byte address (dma_addr(15))
	
	addr_index <= dma_addr(13 downto 0);
	addr_tiles <= dma_addr(14 downto 0);
	
	data_in_tiles <= dma_data_out;
	data_in_index <= dma_data_out;
	
	dma_data_in <= data_out_tiles when dma_addr(15) = '0' else data_out_index;
	wr_tiles <= dma_wr when dma_addr(15) = '0' else '0';
	wr_index <= dma_wr when dma_addr(15) = '1' else '0';
	
	-- UART
	uart_rxtx: entity work.uart_rxtx_clock
		port map(
			clk => clk, reset => reset,
			rx => rx, tx => tx,
			data_rx => data_rx, data_tx => data_tx,
			rx_done_tick => rx_done_tick, tx_done_tick => tx_done_tick,
			tx_start => tx_start_tick
    );
 
end vga_tiled_framebuffer_top_arch;

