LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Module: 8085 Instruction Register
--
-- Function:
-- Stores the 8-bit opcode of the instruction currently being executed.
--
-- When ir_load = '1', the value present at ir_data_in is stored
-- on the next rising edge of the clock.
--
-- When ir_rst = '1', the register is cleared to 00000000.
------------------------------------------------------------------------------------------

ENTITY instruction_register_8085 IS
    PORT (
        ir_clk      : IN  STD_LOGIC;
        ir_rst      : IN  STD_LOGIC;
        ir_load     : IN  STD_LOGIC;
        ir_data_in  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        ir_data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END ENTITY instruction_register_8085;

------------------------------------------------------------------------------------------

ARCHITECTURE rtl OF instruction_register_8085 IS

    SIGNAL ir_reg : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

    PROCESS(ir_clk, ir_rst)
    BEGIN

        IF ir_rst = '1' THEN
            ir_reg <= (OTHERS => '0');

        ELSIF rising_edge(ir_clk) THEN

            IF ir_load = '1' THEN
                ir_reg <= ir_data_in;
            END IF;

        END IF;

    END PROCESS;

    ir_data_out <= ir_reg;

END ARCHITECTURE rtl;