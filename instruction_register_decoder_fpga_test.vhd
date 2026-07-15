LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Module: FPGA integration test for the 8085 Instruction Register and Decoder
--
-- Purpose:
-- Connects the Instruction Register to the Instruction Decoder in order to
-- test both modules together directly on the FPGA board.
--
-- Physical interface:
--
-- SW(7 DOWNTO 0)     -> 8-bit opcode input
-- SW(8)              -> Instruction Register load enable
-- KEY(0)             -> Manual clock
-- KEY(1)             -> Reset
--
-- LEDR(7 DOWNTO 0)   -> Stored opcode
-- LEDR(10 DOWNTO 8)  -> ALU operation selection
-- LEDR(13 DOWNTO 11) -> Register selection
-- LEDR(14)            -> Accumulator load enable
-- LEDR(15)            -> Flag register load enable
-- LEDR(16)            -> Valid instruction detected
-- LEDR(17)            -> HLT instruction detected
--
-- Note:
-- Push buttons are assumed to be active-low.
------------------------------------------------------------------------------------------

ENTITY instruction_register_decoder_fpga_test IS
    PORT (
        SW   : IN  STD_LOGIC_VECTOR(17 DOWNTO 0);
        KEY  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        LEDR : OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
    );
END ENTITY instruction_register_decoder_fpga_test;

------------------------------------------------------------------------------------------

ARCHITECTURE structural OF instruction_register_decoder_fpga_test IS

    SIGNAL stored_opcode : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL dec_op_sel_internal   : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL dec_reg_sel_internal  : STD_LOGIC_VECTOR(2 DOWNTO 0);

    SIGNAL dec_load_acc_internal : STD_LOGIC;
    SIGNAL dec_load_fr_internal  : STD_LOGIC;

    SIGNAL dec_is_hlt_internal   : STD_LOGIC;
    SIGNAL dec_valid_internal    : STD_LOGIC;

BEGIN

    --------------------------------------------------------------------------
    -- Instruction Register instance
    --------------------------------------------------------------------------

    IR_INSTANCE : ENTITY work.instruction_register_8085(rtl)
        PORT MAP (
            ir_clk      => NOT KEY(0),
            ir_rst      => NOT KEY(1),
            ir_load     => SW(8),
            ir_data_in  => SW(7 DOWNTO 0),
            ir_data_out => stored_opcode
        );

    --------------------------------------------------------------------------
    -- Instruction Decoder instance
    --------------------------------------------------------------------------

    DECODER_INSTANCE : ENTITY work.instruction_decoder_8085(combinational)
        PORT MAP (
            dec_opcode_in     => stored_opcode,

            dec_op_sel_out    => dec_op_sel_internal,
            dec_reg_sel_out   => dec_reg_sel_internal,

            dec_load_acc_out  => dec_load_acc_internal,
            dec_load_fr_out   => dec_load_fr_internal,

            dec_is_nop_out    => OPEN,
            dec_is_hlt_out    => dec_is_hlt_internal,

            dec_valid_out     => dec_valid_internal
        );

    --------------------------------------------------------------------------
    -- FPGA output mapping
    --------------------------------------------------------------------------

    LEDR(7 DOWNTO 0)   <= stored_opcode;

    LEDR(10 DOWNTO 8)  <= dec_op_sel_internal;
    LEDR(13 DOWNTO 11) <= dec_reg_sel_internal;

    LEDR(14) <= dec_load_acc_internal;
    LEDR(15) <= dec_load_fr_internal;

    LEDR(16) <= dec_valid_internal;
    LEDR(17) <= dec_is_hlt_internal;

END ARCHITECTURE structural;