-- Single clock - Dual port block RAM
-- Heavily inspired from
--    http://danstrother.com/2010/09/11/inferring-rams-in-fpgas/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity block_ram is
    generic(
        DATA_WIDTH: integer := 8;
        ADDR_WIDTH: integer := 10
    );
    port(
        clk: in std_logic;
        -- Port A
        wr_a: in std_logic;
        addr_a: in std_logic_vector(ADDR_WIDTH-1 downto 0);
        data_in_a: in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_a: out std_logic_vector(DATA_WIDTH-1 downto 0);
        -- Port B
        wr_b: in std_logic;
        addr_b: in std_logic_vector(ADDR_WIDTH-1 downto 0);
        data_in_b: in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_b: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end block_ram;

architecture block_ram_arch of block_ram is
    -- Shared memory
    type mem_type is array ((2**ADDR_WIDTH)-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    shared variable mem : mem_type;
begin

    -- Port A
    process(clk)
    begin
         if(rising_edge(clk)) then
              if(wr_a = '1') then
                    mem(conv_integer(addr_a)) := data_in_a;
              end if;
              data_out_a <= mem(conv_integer(addr_a));
         end if;
    end process;

    -- Port B
    process(clk)
    begin
         if(rising_edge(clk)) then
              if(wr_b = '1') then
                    mem(conv_integer(addr_b)) := data_in_b;
              end if;
              data_out_b <= mem(conv_integer(addr_b));
         end if;
    end process;
end block_ram_arch;

