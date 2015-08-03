-- Simple modulo m counter
-- 20/07/2015

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_mod_m is
    generic(
        N: integer := 4; -- Number of bits
        M: integer := 10 -- Maximum value
    );
    port(
        clk: in std_logic; 
        reset: in std_logic; -- Asynchronous reset
        max_tick: out std_logic; -- Maximum value reached tick
        q: out std_logic_vector(N-1 downto 0) -- Current value
    );
end counter_mod_m;

architecture counter_mod_m_arch of counter_mod_m is
    signal r_reg: unsigned(N-1 downto 0);
    signal r_next: unsigned(N-1 downto 0);
begin
    -- State register
    process(clk, reset)
    begin
        if (reset='1') then
            r_reg <= (others => '0');
        elsif (rising_edge(clk)) then
            r_reg <= r_next;
        end if;
    end process;
    -- Next state logic
    r_next <= r_reg + 1 when r_reg /= (M-1) else
                 (others => '0');
    -- Output logic
    q <= std_logic_vector(r_reg);
    max_tick <= '1' when r_reg = (M-1) else '0';
end counter_mod_m_arch;

