LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

------------------------------------------------------------------------------------------
-- Module: 8085 Memory
--
-- Simple single-port synchronous RAM.
-- To preload a program, modify the `mem` signal initialization below.
-- The entire 64KB space is writable (no ROM protection) to keep it simple
-- for testbench use; restrict writes in the top-level if needed.
------------------------------------------------------------------------------------------

ENTITY memory_8085 IS
    PORT (
        mem_clk      : IN  STD_LOGIC;
        mem_addr     : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
        mem_data_in  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        mem_data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        mem_wr_en    : IN  STD_LOGIC
    );
END ENTITY;

ARCHITECTURE rtl OF memory_8085 IS

    TYPE mem_array IS ARRAY(0 TO 65535) OF STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Modify this initialization to load your program.
    -- Example: NOP, NOP, HLT
    SIGNAL mem : mem_array := (
        0 => x"00",  -- NOP
        1 => x"00",  -- NOP
        2 => x"76",  -- HLT
        OTHERS => x"00"
    );

BEGIN

    PROCESS(mem_clk)
    BEGIN
        IF rising_edge(mem_clk) THEN
            IF mem_wr_en = '1' THEN
                mem(TO_INTEGER(UNSIGNED(mem_addr))) <= mem_data_in;
            END IF;
        END IF;
    END PROCESS;

    mem_data_out <= mem(TO_INTEGER(UNSIGNED(mem_addr)));

END ARCHITECTURE;
