LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Module: FPGA test wrapper for the 8085 Instruction Register
--
-- Purpose:
-- Provides a simple physical interface to test the Instruction Register
-- directly on the FPGA board.
--
-- SW(7 DOWNTO 0)   -> 8-bit opcode input
-- SW(8)            -> Load enable
-- KEY(0)           -> Manual clock
-- KEY(1)           -> Reset
-- LEDR(7 DOWNTO 0) -> Stored opcode output
--
-- Note:
-- Push buttons are assumed to be active-low.
------------------------------------------------------------------------------------------

ENTITY instruction_register_fpga_test IS
    PORT (
        SW   : IN  STD_LOGIC_VECTOR(17 DOWNTO 0);
        KEY  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        LEDR : OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
    );
END ENTITY instruction_register_fpga_test;

------------------------------------------------------------------------------------------

ARCHITECTURE structural OF instruction_register_fpga_test IS

    SIGNAL ir_data_out_internal : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

    --------------------------------------------------------------------------
    -- 8085 Instruction Register instance
    --------------------------------------------------------------------------

    IR_DUT : ENTITY work.instruction_register_8085(rtl)
        PORT MAP (
            ir_clk      => NOT KEY(0),
            ir_rst      => NOT KEY(1),
            ir_load     => SW(8),
            ir_data_in  => SW(7 DOWNTO 0),
            ir_data_out => ir_data_out_internal
        );

    --------------------------------------------------------------------------
    -- Display the stored opcode on the lower red LEDs.
    --------------------------------------------------------------------------

    LEDR(7 DOWNTO 0) <= ir_data_out_internal;

    --------------------------------------------------------------------------
    -- Unused LEDs are forced to zero.
    --------------------------------------------------------------------------

    LEDR(17 DOWNTO 8) <= (OTHERS => '0');

END ARCHITECTURE structural;