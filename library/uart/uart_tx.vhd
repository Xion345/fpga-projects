-- UART Transmitter
-- 20/07/2015

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    port(
        clk, reset: in std_logic; -- Clock and reset
        baud16_tick: in std_logic; -- 16x oversampled baud tick
        data_in: in std_logic_vector(7 downto 0); -- Data byte to send
        tx_start: in std_logic; -- Start transmission tick
        tx: out std_logic; -- UART TX (Send) pin
        tx_done_tick: out std_logic
    );
end uart_tx;

architecture uart_tx_arch of uart_tx is
    type state_type is (idle, start, data, stop);
    signal state_reg, state_next: state_type; -- State register
    signal data_reg, data_next: std_logic_vector(7 downto 0); -- Data (shift) register
    signal sent_reg, sent_next: unsigned(2 downto 0); -- Count sent bits
    signal ticks_reg, ticks_next: unsigned(3 downto 0); -- Ticks count (oversampling)
    signal tx_reg, tx_next: std_logic; -- TX pin register
begin

    -- State and data registers
    process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= idle;
            ticks_reg <= (others => '0');
            sent_reg <= (others => '0');
            data_reg <= (others => '0');
            tx_reg <= '1'; -- Keep TX high for idle state (it is held low to start transmission)
        elsif rising_edge(clk) then
            state_reg <= state_next;
            data_reg <= data_next;
            sent_reg <= sent_next;
            ticks_reg <= ticks_next;
            tx_reg <= tx_next;
        end if;
    end process;

    -- Next state logic and data path
    process(state_reg, data_reg, sent_reg, ticks_reg, tx_reg, baud16_tick, tx_start, data_in)
    begin
        state_next <= state_reg;
        data_next <= data_reg;
        sent_next <= sent_reg;
        ticks_next <= ticks_reg;
        tx_next <= tx_reg;
        tx_done_tick <= '0';
        case state_reg is
            --
            when idle =>
                if tx_start = '1' then
                    state_next <= start;
                    ticks_next <= (others => '0');
                    data_next <= data_in;
                end if;
            --
            when start =>
                if baud16_tick = '1' then
                    if ticks_reg = 15 then -- Move to data state
                        state_next <= data;
                        ticks_next <= (others => '0');
                        sent_next <= (others => '0');
                    else
                        tx_next <= '0';
                        ticks_next <= ticks_reg + 1;
                    end if;
                end if;
            --
            when data =>
                if baud16_tick = '1' then
                    if ticks_reg = 15 then -- Move to next bit
                        ticks_next <= (others => '0');
                        data_next <= '0' & data_reg(7 downto 1);
                        if sent_reg = 7 then -- Last byte ?
                            state_next <= stop;
                        else
                            sent_next <= sent_reg + 1;
                        end if;
                    else
                        tx_next <= data_reg(0);
                        ticks_next <= ticks_reg + 1;
                    end if;
                end if;
            --
            when stop =>
                if baud16_tick = '1' then
                    if ticks_reg = 15 then
                        state_next <= idle;
                        tx_done_tick <= '1';
                    else
                        tx_next <= '1'; -- I FOUND YOU BASTARD BUG !
                        ticks_next <= ticks_reg + 1;
                    end if;
                end if;
        end case;
    end process;

    -- Output logic
    tx <= tx_reg;

end uart_tx_arch;

