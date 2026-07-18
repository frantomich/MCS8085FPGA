LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Testbench: 8085 Timing and Control Unit
--
-- Purpose:
-- Verifies the simplified Timing and Control FSM.
--
-- Tested cases:
-- 1. Reset returns the FSM to FETCH.
-- 2. A valid normal instruction follows FETCH -> DECODE -> EXECUTE -> FETCH.
-- 3. An invalid instruction returns from DECODE to FETCH.
-- 4. An HLT instruction follows FETCH -> DECODE -> HALT.
-- 5. The HALT state is maintained until reset.
------------------------------------------------------------------------------------------

ENTITY tb_timing_control_8085 IS
END ENTITY tb_timing_control_8085;

------------------------------------------------------------------------------------------

ARCHITECTURE simulation OF tb_timing_control_8085 IS

    SIGNAL tb_clk               : STD_LOGIC := '0';
    SIGNAL tb_rst               : STD_LOGIC := '0';

    SIGNAL tb_hlt_detected      : STD_LOGIC := '0';
    SIGNAL tb_valid_instruction : STD_LOGIC := '0';

    SIGNAL tb_ir_load           : STD_LOGIC;
    SIGNAL tb_execute_enable    : STD_LOGIC;
    SIGNAL tb_halted            : STD_LOGIC;

    SIGNAL tb_state             : STD_LOGIC_VECTOR(1 DOWNTO 0);

    CONSTANT clk_period : TIME := 20 ns;

BEGIN

    --------------------------------------------------------------------------
    -- Device Under Test.
    --------------------------------------------------------------------------

    DUT : ENTITY work.timing_control_8085(fsm)
        PORT MAP (
            tc_clk                => tb_clk,
            tc_rst                => tb_rst,

            tc_hlt_detected       => tb_hlt_detected,
            tc_valid_instruction  => tb_valid_instruction,

            tc_ir_load_out        => tb_ir_load,
            tc_execute_enable_out => tb_execute_enable,
            tc_halted_out         => tb_halted,

            tc_state_out          => tb_state
        );

    --------------------------------------------------------------------------
    -- Clock generation.
    --------------------------------------------------------------------------

    clock_process : PROCESS
    BEGIN

        WHILE TRUE LOOP

            tb_clk <= '0';
            WAIT FOR clk_period / 2;

            tb_clk <= '1';
            WAIT FOR clk_period / 2;

        END LOOP;

    END PROCESS clock_process;

    --------------------------------------------------------------------------
    -- Test sequence.
    --------------------------------------------------------------------------

    stimulus_process : PROCESS
    BEGIN

        ----------------------------------------------------------------------
        -- Test 1: Reset returns the FSM to FETCH.
        ----------------------------------------------------------------------

        tb_rst               <= '1';
        tb_valid_instruction <= '0';
        tb_hlt_detected      <= '0';

        WAIT FOR 5 ns;

        ASSERT tb_state = "00"
            REPORT "Test 1 failed: reset did not return FSM to FETCH."
            SEVERITY ERROR;

        ASSERT tb_ir_load = '1'
            REPORT "Test 1 failed: ir_load should be active in FETCH."
            SEVERITY ERROR;

        ASSERT tb_execute_enable = '0'
            REPORT "Test 1 failed: execute_enable should be inactive in FETCH."
            SEVERITY ERROR;

        ASSERT tb_halted = '0'
            REPORT "Test 1 failed: halted should be inactive in FETCH."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- Test 2: Valid normal instruction.
        -- Expected sequence:
        -- FETCH -> DECODE -> EXECUTE -> FETCH
        ----------------------------------------------------------------------

        tb_rst               <= '0';
        tb_valid_instruction <= '1';
        tb_hlt_detected      <= '0';

        WAIT UNTIL rising_edge(tb_clk);
        WAIT FOR 2 ns;

        ASSERT tb_state = "01"
            REPORT "Test 2 failed: FSM did not move from FETCH to DECODE."
            SEVERITY ERROR;

        ASSERT tb_ir_load = '0'
            REPORT "Test 2 failed: ir_load should be inactive in DECODE."
            SEVERITY ERROR;

        ASSERT tb_execute_enable = '0'
            REPORT "Test 2 failed: execute_enable should be inactive in DECODE."
            SEVERITY ERROR;


        WAIT UNTIL rising_edge(tb_clk);
        WAIT FOR 2 ns;

        ASSERT tb_state = "10"
            REPORT "Test 2 failed: FSM did not move from DECODE to EXECUTE."
            SEVERITY ERROR;

        ASSERT tb_execute_enable = '1'
            REPORT "Test 2 failed: execute_enable should be active in EXECUTE."
            SEVERITY ERROR;


        WAIT UNTIL rising_edge(tb_clk);
        WAIT FOR 2 ns;

        ASSERT tb_state = "00"
            REPORT "Test 2 failed: FSM did not return from EXECUTE to FETCH."
            SEVERITY ERROR;

        ASSERT tb_ir_load = '1'
            REPORT "Test 2 failed: ir_load should be active again in FETCH."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- Test 3: Invalid instruction.
        -- Expected sequence:
        -- FETCH -> DECODE -> FETCH
        ----------------------------------------------------------------------

        tb_valid_instruction <= '0';
        tb_hlt_detected      <= '0';

        WAIT UNTIL rising_edge(tb_clk);
        WAIT FOR 2 ns;

        ASSERT tb_state = "01"
            REPORT "Test 3 failed: FSM did not move from FETCH to DECODE."
            SEVERITY ERROR;


        WAIT UNTIL rising_edge(tb_clk);
        WAIT FOR 2 ns;

        ASSERT tb_state = "00"
            REPORT "Test 3 failed: invalid instruction should return to FETCH."
            SEVERITY ERROR;

        ASSERT tb_execute_enable = '0'
            REPORT "Test 3 failed: invalid instruction should not enable execution."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- Test 4: HLT instruction.
        -- Expected sequence:
        -- FETCH -> DECODE -> HALT
        ----------------------------------------------------------------------

        tb_valid_instruction <= '1';
        tb_hlt_detected      <= '1';

        WAIT UNTIL rising_edge(tb_clk);
        WAIT FOR 2 ns;

        ASSERT tb_state = "01"
            REPORT "Test 4 failed: FSM did not move from FETCH to DECODE for HLT."
            SEVERITY ERROR;


        WAIT UNTIL rising_edge(tb_clk);
        WAIT FOR 2 ns;

        ASSERT tb_state = "11"
            REPORT "Test 4 failed: HLT instruction did not move FSM to HALT."
            SEVERITY ERROR;

        ASSERT tb_halted = '1'
            REPORT "Test 4 failed: halted output should be active in HALT."
            SEVERITY ERROR;

        ASSERT tb_execute_enable = '0'
            REPORT "Test 4 failed: execute_enable should be inactive in HALT."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- Test 5: HALT state is maintained.
        ----------------------------------------------------------------------

        WAIT UNTIL rising_edge(tb_clk);
        WAIT FOR 2 ns;

        ASSERT tb_state = "11"
            REPORT "Test 5 failed: FSM should remain in HALT."
            SEVERITY ERROR;

        ASSERT tb_halted = '1'
            REPORT "Test 5 failed: halted should remain active."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- Test 6: Reset leaves HALT and returns to FETCH.
        ----------------------------------------------------------------------

        tb_rst <= '1';

        WAIT FOR 5 ns;

        ASSERT tb_state = "00"
            REPORT "Test 6 failed: reset did not return FSM from HALT to FETCH."
            SEVERITY ERROR;

        ASSERT tb_ir_load = '1'
            REPORT "Test 6 failed: ir_load should be active after reset."
            SEVERITY ERROR;

        ASSERT tb_halted = '0'
            REPORT "Test 6 failed: halted should be inactive after reset."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- End of simulation.
        ----------------------------------------------------------------------

        REPORT "All Timing and Control tests passed successfully."
            SEVERITY NOTE;

        WAIT;

    END PROCESS stimulus_process;

END ARCHITECTURE simulation;