LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Module: FPGA integration test for Instruction Register, Decoder and Timing Control
--
-- Purpose:
-- Connects the Instruction Register, Instruction Decoder and simplified
-- Timing and Control FSM in order to test the control path of the 8085 project.
--
-- Physical interface:
--
-- SW(7 DOWNTO 0)     -> 8-bit opcode input
-- KEY(0)             -> Manual clock
-- KEY(1)             -> Reset
--
-- LEDR(7 DOWNTO 0)   -> Stored opcode
-- LEDR(9 DOWNTO 8)   -> Current FSM state
-- LEDR(10)            -> Instruction Register load signal
-- LEDR(11)            -> Execute enable signal
-- LEDR(12)            -> Final accumulator load signal
-- LEDR(13)            -> Final flag register load signal
-- LEDR(14)            -> Valid instruction detected
-- LEDR(15)            -> HLT instruction detected
-- LEDR(17 DOWNTO 16)  -> Reserved
--
-- State encoding:
--
-- 00 = FETCH
-- 01 = DECODE
-- 10 = EXECUTE
-- 11 = HALT
--
-- Note:
-- Push buttons are assumed to be active-low.
------------------------------------------------------------------------------------------

ENTITY instruction_control_fpga_test IS
    PORT (
        SW   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        KEY  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        LEDR : OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
    );
END ENTITY instruction_control_fpga_test;

------------------------------------------------------------------------------------------

ARCHITECTURE structural OF instruction_control_fpga_test IS

    SIGNAL internal_clk : STD_LOGIC;
    SIGNAL internal_rst : STD_LOGIC;

    SIGNAL stored_opcode : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL dec_op_sel_internal   : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL dec_reg_sel_internal  : STD_LOGIC_VECTOR(2 DOWNTO 0);

    SIGNAL dec_load_acc_internal : STD_LOGIC;
    SIGNAL dec_load_fr_internal  : STD_LOGIC;

    SIGNAL dec_is_nop_internal   : STD_LOGIC;
    SIGNAL dec_is_hlt_internal   : STD_LOGIC;
    SIGNAL dec_valid_internal    : STD_LOGIC;

    SIGNAL tc_ir_load_internal        : STD_LOGIC;
    SIGNAL tc_execute_enable_internal : STD_LOGIC;
    SIGNAL tc_halted_internal         : STD_LOGIC;
    SIGNAL tc_state_internal          : STD_LOGIC_VECTOR(1 DOWNTO 0);

    SIGNAL final_load_acc_internal : STD_LOGIC;
    SIGNAL final_load_fr_internal  : STD_LOGIC;

BEGIN

    --------------------------------------------------------------------------
    -- Internal clock and reset.
    --------------------------------------------------------------------------

    internal_clk <= NOT KEY(0);
    internal_rst <= NOT KEY(1);

    --------------------------------------------------------------------------
    -- Instruction Register instance.
    --------------------------------------------------------------------------

    IR_INSTANCE : ENTITY work.instruction_register_8085(rtl)
        PORT MAP (
            ir_clk      => internal_clk,
            ir_rst      => internal_rst,
            ir_load     => tc_ir_load_internal,
            ir_data_in  => SW(7 DOWNTO 0),
            ir_data_out => stored_opcode
        );

    --------------------------------------------------------------------------
    -- Instruction Decoder instance.
    --------------------------------------------------------------------------

    DECODER_INSTANCE : ENTITY work.instruction_decoder_8085(combinational)
        PORT MAP (
            dec_opcode_in    => stored_opcode,

            dec_op_sel_out   => dec_op_sel_internal,
            dec_reg_sel_out  => dec_reg_sel_internal,

            dec_load_acc_out => dec_load_acc_internal,
            dec_load_fr_out  => dec_load_fr_internal,

            dec_is_nop_out   => dec_is_nop_internal,
            dec_is_hlt_out   => dec_is_hlt_internal,

            dec_valid_out    => dec_valid_internal
        );

    --------------------------------------------------------------------------
    -- Timing and Control instance.
    --------------------------------------------------------------------------

    TC_INSTANCE : ENTITY work.timing_control_8085(fsm)
        PORT MAP (
            tc_clk                => internal_clk,
            tc_rst                => internal_rst,

            tc_hlt_detected       => dec_is_hlt_internal,
            tc_valid_instruction  => dec_valid_internal,

            tc_ir_load_out        => tc_ir_load_internal,
            tc_execute_enable_out => tc_execute_enable_internal,
            tc_halted_out         => tc_halted_internal,

            tc_state_out          => tc_state_internal
        );

    --------------------------------------------------------------------------
    -- Final gated control signals.
    --
    -- The decoder identifies what should happen, but the Timing and Control
    -- unit decides when the execution is allowed.
    --------------------------------------------------------------------------

    final_load_acc_internal <= dec_load_acc_internal AND tc_execute_enable_internal;
    final_load_fr_internal  <= dec_load_fr_internal  AND tc_execute_enable_internal;

    --------------------------------------------------------------------------
    -- FPGA output mapping.
    --------------------------------------------------------------------------

    LEDR(7 DOWNTO 0) <= stored_opcode;

    LEDR(9 DOWNTO 8) <= tc_state_internal;

    LEDR(10) <= tc_ir_load_internal;
    LEDR(11) <= tc_execute_enable_internal;

    LEDR(12) <= final_load_acc_internal;
    LEDR(13) <= final_load_fr_internal;

    LEDR(14) <= dec_valid_internal;
    LEDR(15) <= dec_is_hlt_internal;

    LEDR(17 DOWNTO 16) <= (OTHERS => '0');

END ARCHITECTURE structural;