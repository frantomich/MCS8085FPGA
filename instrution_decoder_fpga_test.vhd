LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Module: FPGA test wrapper for the 8085 Instruction Decoder
--
-- Purpose:
-- Provides a simple physical interface to test the Instruction Decoder
-- directly on the FPGA board.
--
-- SW(7 DOWNTO 0)    -> 8-bit opcode input
--
-- LEDR(2 DOWNTO 0)  -> ALU operation selection
-- LEDR(5 DOWNTO 3)  -> Register selection
-- LEDR(6)            -> Accumulator load enable
-- LEDR(7)            -> Flag register load enable
-- LEDR(8)            -> NOP detected
-- LEDR(9)            -> HLT detected
-- LEDR(10)           -> Valid instruction detected
------------------------------------------------------------------------------------------

ENTITY instruction_decoder_fpga_test IS
    PORT (
        SW   : IN  STD_LOGIC_VECTOR(17 DOWNTO 0);
        LEDR : OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
    );
END ENTITY instruction_decoder_fpga_test;

------------------------------------------------------------------------------------------

ARCHITECTURE structural OF instruction_decoder_fpga_test IS

    SIGNAL dec_op_sel_internal   : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL dec_reg_sel_internal  : STD_LOGIC_VECTOR(2 DOWNTO 0);

    SIGNAL dec_load_acc_internal : STD_LOGIC;
    SIGNAL dec_load_fr_internal  : STD_LOGIC;

    SIGNAL dec_is_nop_internal   : STD_LOGIC;
    SIGNAL dec_is_hlt_internal   : STD_LOGIC;

    SIGNAL dec_valid_internal    : STD_LOGIC;

BEGIN

    --------------------------------------------------------------------------
    -- 8085 Instruction Decoder instance
    --------------------------------------------------------------------------

    DECODER_DUT : ENTITY work.instruction_decoder_8085(combinational)
        PORT MAP (
            dec_opcode_in   => SW(7 DOWNTO 0),

            dec_op_sel_out  => dec_op_sel_internal,
            dec_reg_sel_out => dec_reg_sel_internal,

            dec_load_acc_out => dec_load_acc_internal,
            dec_load_fr_out  => dec_load_fr_internal,

            dec_is_nop_out   => dec_is_nop_internal,
            dec_is_hlt_out   => dec_is_hlt_internal,

            dec_valid_out    => dec_valid_internal
        );


    --------------------------------------------------------------------------
    -- Display decoded control signals on red LEDs.
    --------------------------------------------------------------------------

    LEDR(2 DOWNTO 0) <= dec_op_sel_internal;
    LEDR(5 DOWNTO 3) <= dec_reg_sel_internal;

    LEDR(6)  <= dec_load_acc_internal;
    LEDR(7)  <= dec_load_fr_internal;

    LEDR(8)  <= dec_is_nop_internal;
    LEDR(9)  <= dec_is_hlt_internal;

    LEDR(10) <= dec_valid_internal;


    --------------------------------------------------------------------------
    -- Unused LEDs are forced to zero.
    --------------------------------------------------------------------------

    LEDR(17 DOWNTO 11) <= (OTHERS => '0');

END ARCHITECTURE structural;