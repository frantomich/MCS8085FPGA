LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Module: FPGA test wrapper for the 8085 Timing and Control Unit
--
-- Purpose:
-- Provides a simple physical interface to test the simplified Timing and
-- Control FSM directly on the FPGA board.
--
-- Physical interface:
--
-- KEY(0)              -> Manual clock
-- KEY(1)              -> Reset
--
-- SW(0)               -> Valid instruction input
-- SW(1)               -> HLT detected input
--
-- LEDR(0)             -> Instruction Register load signal
-- LEDR(1)             -> Execute enable signal
-- LEDR(2)             -> Halted signal
-- LEDR(4 DOWNTO 3)    -> Current FSM state
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

ENTITY timing_control_fpga_test IS
    PORT (
        SW   : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        KEY  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        LEDR : OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
    );
END ENTITY timing_control_fpga_test;

------------------------------------------------------------------------------------------

ARCHITECTURE structural OF timing_control_fpga_test IS

    SIGNAL tc_ir_load_internal        : STD_LOGIC;
    SIGNAL tc_execute_enable_internal : STD_LOGIC;
    SIGNAL tc_halted_internal         : STD_LOGIC;
    SIGNAL tc_state_internal          : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN

    TC_DUT : ENTITY work.timing_control_8085(fsm)
        PORT MAP (
            tc_clk                => NOT KEY(0),
            tc_rst                => NOT KEY(1),

            tc_valid_instruction  => SW(0),
            tc_hlt_detected       => SW(1),

            tc_ir_load_out        => tc_ir_load_internal,
            tc_execute_enable_out => tc_execute_enable_internal,
            tc_halted_out         => tc_halted_internal,

            tc_state_out          => tc_state_internal
        );

    LEDR(0) <= tc_ir_load_internal;
    LEDR(1) <= tc_execute_enable_internal;
    LEDR(2) <= tc_halted_internal;

    LEDR(4 DOWNTO 3) <= tc_state_internal;

END ARCHITECTURE structural;