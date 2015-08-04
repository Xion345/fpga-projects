-- UART Receiver
-- 20/07/2015

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    port(
        clk, reset: in std_logic; -- Clock and reset
        rx: in std_logic; -- UART RX (Receive) pin
        baud16_tick: in std_logic; -- 16x oversampled baud tick
        data_out: out std_logic_vector(7 downto 0); -- Received data byte
        rx_done_tick: out std_logic -- Receive done tick
    );
end uart_rx;

architecture uart_rx_arch of uart_rx is
    type state_type is (idle, start, data, stop);
    signal state_reg, state_next: state_type; -- State register
    signal data_reg, data_next: std_logic_vector(7 downto 0); -- Data register
    signal remaining_reg, remaining_next: unsigned(2 downto 0); -- Remaining bits
    signal ticks_reg, ticks_next: unsigned(3 downto 0); -- Ticks count (oversampling)
begin

    -- State and data registers
    process(clk, reset)
    begin
        if reset='1' then
            state_reg <= idle;
            ticks_reg <= (others => '0');
            remaining_reg <= (others => '0');
            data_reg <= (others => '0');
        elsif rising_edge(clk) then
             state_reg <= state_next;
             ticks_reg <= ticks_next;
             remaining_reg <= remaining_next;
             data_reg <= data_next;
        end if;
    end process;

    -- Next state logic and data path
    process(state_reg, ticks_reg, remaining_reg, data_reg, baud16_tick, rx)
    begin
        state_next <= state_reg;
        ticks_next <= ticks_reg;
        remaining_next <= remaining_reg;
        data_next <= data_reg;
        rx_done_tick <= '0';
        case state_reg is
            --
            when idle =>
                if rx = '0' then
                    state_next <= start;
                    ticks_next <= (others => '0');
                end if;
            --
            when start =>
                if baud16_tick = '1' then
                    if ticks_reg=7 then
                        state_next <= data;
                        ticks_next <= (others => '0');
                        remaining_next <= (others => '0');
                    else
                        ticks_next <= ticks_reg + 1;
                    end if;
                end if;
            --
            when data =>
                if baud16_tick = '1' then
                    if ticks_reg=15 then -- Move to next byte
                        ticks_next <= (others => '0');
                        data_next <= rx & data_reg(7 downto 1);
                        if remaining_reg = 7 then -- Last byte ?
                            state_next <= stop;
                        else
                            remaining_next <= remaining_reg + 1;
                        end if;
                    else
                        ticks_next <= ticks_reg + 1;
                    end if;
                end if;
            --
            when stop =>
                if baud16_tick = '1' then
                    if ticks_reg=15 then
                        state_next <= idle;
                        rx_done_tick <= '1';
                    else
                        ticks_next <= ticks_reg + 1;
                    end if;
                end if;
        end case;
    end process;
    data_out <= data_reg;
end uart_rx_arch;

