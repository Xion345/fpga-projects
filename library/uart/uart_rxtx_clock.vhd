-- UART RX/TX with clock
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rxtx_clock is
    port(
        clk, reset: in std_logic; -- Clock and reset
        --
        rx: in std_logic; -- UART RX (Receive) pin
        tx: out std_logic; -- UART TX (Send) pin
        data_rx: out std_logic_vector(7 downto 0); -- Data byte to send
        data_tx: in std_logic_vector(7 downto 0); -- Received data byte
        rx_done_tick: out std_logic; -- Sent done tick
        tx_done_tick: out std_logic; -- Receive done tick
        tx_start: in std_logic -- Start transmission tick
    );
end uart_rxtx_clock;

architecture uart_rxtx_clock_arch of uart_rxtx_clock is
    signal baud16_tick: std_logic;
begin

    uart_clock: entity work.counter_mod_m
        generic map(N => 10, M => 54) -- 115200 bauds from 100Mhz clock (16x oversampling)
        port map(clk => clk, reset => reset, max_tick => baud16_tick);

    receiver: entity work.uart_rx
        port map(clk => clk, reset => reset,
            rx => rx, baud16_tick => baud16_tick,
            data_out => data_rx, rx_done_tick => rx_done_tick);

    transmitter: entity work.uart_tx
        port map(clk => clk, reset => reset,
            tx => tx, baud16_tick => baud16_tick,
            data_in => data_tx, tx_done_tick => tx_done_tick,
            tx_start => tx_start);

end uart_rxtx_clock_arch;