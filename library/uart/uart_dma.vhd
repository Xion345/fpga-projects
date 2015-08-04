-- Direct Memory Access for UART
-- 8 bit words - Configurable number of address bytes

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_dma is

    generic(
        RAM_READ_TICKS: integer := 1; -- Number of clocks ticks to wait to get data from memory
        ADDR_BYTES: integer := 1 -- Total adress bytes: 7 + ADDR_BYTES, so 15 bits by default
    );

    port(
        clk, reset: in std_logic;
        -- UART
        rx_done_tick: in std_logic;
        tx_done_tick: in std_logic;
        data_rx: in std_logic_vector(7 downto 0); -- UART Received byte
        data_tx: out std_logic_vector(7 downto 0); -- UART byte to transmit
        tx_start_tick: out std_logic; -- Tick to start UART transmission
        -- Synchronous RAM
        data_ram_rd: in std_logic_vector(7 downto 0); -- RAM read byte
        data_ram_wr: out std_logic_vector(7 downto 0); -- RAM byte to write
        addr: out std_logic_vector(ADDR_BYTES*8 + 6 downto 0); -- RAM address (15 bits)
        wr: out std_logic -- RAM read/write switch
    );

    -- Number of bits necessary to represent integer value
    function int_width(value: integer) return integer is
    begin
        return integer(floor(log2(real(value))));
    end function;

end uart_dma;

architecture uart_dma_arch of uart_dma is
    type state_type is (idle, addr_recv, send_start, send, recv, write_mem, read_mem);
    signal state_reg, state_next: state_type; -- State register
    signal cmd_reg, cmd_next: std_logic; -- Command register (0 - read, 1 - write)

    constant ADDR_OTHER_MSB: integer := (ADDR_BYTES * 8) - 1; -- MSB for "other" address bits
    constant ADDR_MSB: integer := (ADDR_OTHER_MSB + 7); -- MSB for total address bits
    signal addr_reg, addr_next: std_logic_vector(ADDR_MSB downto 0); -- Memory address register
    signal addr_msb_reg, addr_msb_next:
        unsigned(int_width(ADDR_OTHER_MSB) downto 0); -- Most significant bit position in addr_reg for next received byte

    signal data_reg, data_next: std_logic_vector(7 downto 0); -- Received data
    signal ticks_reg, ticks_next:
        unsigned(int_width(RAM_READ_TICKS) downto 0); -- Clock cycles counter for memory accesses
begin

    -- State and data regisuter
    process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= idle;
            cmd_reg <= '0';
            addr_msb_reg <= (others => '0');
            addr_reg <= (others => '0');
            data_reg <= (others => '0');
            ticks_reg <= (others => '0');
        elsif rising_edge(clk) then
            state_reg <= state_next;
            cmd_reg <= cmd_next;
            addr_msb_reg <= addr_msb_next;
            addr_reg <= addr_next;
            data_reg <= data_next;
            ticks_reg <= ticks_next;
        end if;
    end process;

    -- Next state logic and data path
    process(clk, state_reg, rx_done_tick, tx_done_tick,
        state_reg, cmd_reg, addr_msb_reg, addr_reg, data_reg, ticks_reg,
        data_rx, data_ram_rd)
    begin
        -- Default values
        state_next <= state_reg;
        cmd_next <= cmd_reg;
        addr_msb_next <= addr_msb_reg;
        addr_next <= addr_reg;
        data_next <= data_reg;
        ticks_next <= ticks_reg;
        tx_start_tick <= '0';
        wr <= '0';

        case state_reg is
        -- Idle, waiting for a command
        -- When byte received:
        -- data_rx[7] (MSB): 1 -> write to memory, 0 -> read from memory (Command)
        -- data_rx[6..0]: 7 address most significant bits
        when idle =>
            if rx_done_tick = '1' then -- We got a byte from UART
                state_next <= addr_recv;
                cmd_next <= data_rx(7);
                addr_msb_next <= to_unsigned(ADDR_OTHER_MSB, addr_msb_reg'length);
                addr_next(ADDR_MSB downto ADDR_MSB-6) <= data_rx(6 downto 0);
            end if;
        -- Receive others address byte
        when addr_recv =>
            if rx_done_tick = '1' then
                addr_next(to_integer(addr_msb_reg) downto to_integer(addr_msb_reg - 7)) <= data_rx;
                if addr_msb_reg = to_unsigned(7, addr_msb_reg'length) then -- Last address byte ?
                    if cmd_reg = '0' then -- Move to send_start state
                        state_next <= read_mem;
                        ticks_next <= (others => '0');
                    else
                        state_next <= recv;
                    end if;
                else
                    addr_msb_next <= addr_msb_reg - 8;
                end if;
            end if;
        -- Read byte (to register)
        when read_mem =>
            if ticks_reg = RAM_READ_TICKS then
                data_next <= data_ram_rd;
                state_next <= send_start;
            else
                ticks_next <= ticks_reg + 1;
            end if;
        -- Send read byte
        when send_start =>
            tx_start_tick <= '1';
            state_next <= send;
        when send =>
            if tx_done_tick = '1' then
                state_next <= idle;
            end if;
        --  Receive byte (to register)
        when recv =>
            if rx_done_tick = '1' then
                data_next <= data_rx;
                state_next <= write_mem;
            end if;
        -- Write received byte (register to memory)
        when write_mem =>
            wr <= '1';
            state_next <= idle;
        end case;
    end process;

    -- Output logic
    -- UART
    data_tx <= data_reg;

    -- Memory
    addr <= addr_reg;
    data_ram_wr <= data_reg;

end uart_dma_arch;

