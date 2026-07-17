LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Module: 8085 Simplified Timing and Control Unit
--
-- Purpose:
-- Controls the simplified instruction execution sequence used by this project.
--
-- The implemented state sequence is:
--
--     FETCH -> DECODE -> EXECUTE -> FETCH
--
-- If an HLT instruction is detected during the DECODE state:
--
--     FETCH -> DECODE -> HALT
--
-- The HALT state is maintained until reset is asserted.
--
-- This first version does not implement the complete T-state timing of the
-- original Intel 8085. It implements the simplified machine cycle previously
-- defined by the project team.
------------------------------------------------------------------------------------------

ENTITY timing_control_8085 IS
    PORT (
        tc_clk               : IN  STD_LOGIC;
        tc_rst               : IN  STD_LOGIC;

        tc_hlt_detected      : IN  STD_LOGIC;
        tc_valid_instruction : IN  STD_LOGIC;

        tc_ir_load_out       : OUT STD_LOGIC;
        tc_execute_enable_out: OUT STD_LOGIC;
        tc_halted_out        : OUT STD_LOGIC;

        tc_state_out         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
    );
END ENTITY timing_control_8085;

------------------------------------------------------------------------------------------

ARCHITECTURE fsm OF timing_control_8085 IS

    --------------------------------------------------------------------------
    -- Internal state definition.
    --------------------------------------------------------------------------

    TYPE state_type IS (
        FETCH_STATE,
        DECODE_STATE,
        EXECUTE_STATE,
        HALT_STATE
    );

    SIGNAL current_state : state_type;
    SIGNAL next_state    : state_type;

BEGIN

    --------------------------------------------------------------------------
    -- State register process.
    --
    -- The current state changes on every rising clock edge.
    -- Reset immediately returns the control unit to FETCH_STATE.
    --------------------------------------------------------------------------

    state_register : PROCESS(tc_clk, tc_rst)
    BEGIN

        IF tc_rst = '1' THEN
            current_state <= FETCH_STATE;

        ELSIF rising_edge(tc_clk) THEN
            current_state <= next_state;

        END IF;

    END PROCESS state_register;


    --------------------------------------------------------------------------
    -- Next-state logic.
    --------------------------------------------------------------------------

    next_state_logic : PROCESS(
        current_state,
        tc_hlt_detected,
        tc_valid_instruction
    )
    BEGIN

        -- Default behavior: remain in the current state.
        next_state <= current_state;

        CASE current_state IS

            ------------------------------------------------------------------
            -- FETCH:
            -- The Instruction Register loads the opcode.
            ------------------------------------------------------------------

            WHEN FETCH_STATE =>

                next_state <= DECODE_STATE;


            ------------------------------------------------------------------
            -- DECODE:
            -- The opcode has already been stored and decoded.
            --
            -- If HLT is detected, enter HALT_STATE.
            -- If the instruction is valid, continue to EXECUTE_STATE.
            -- If the opcode is unsupported, return to FETCH_STATE.
            ------------------------------------------------------------------

            WHEN DECODE_STATE =>

                IF tc_hlt_detected = '1' THEN
                    next_state <= HALT_STATE;

                ELSIF tc_valid_instruction = '1' THEN
                    next_state <= EXECUTE_STATE;

                ELSE
                    next_state <= FETCH_STATE;

                END IF;


            ------------------------------------------------------------------
            -- EXECUTE:
            -- Enable the execution of the decoded control signals.
            -- After one execution cycle, return to FETCH_STATE.
            ------------------------------------------------------------------

            WHEN EXECUTE_STATE =>

                next_state <= FETCH_STATE;


            ------------------------------------------------------------------
            -- HALT:
            -- Remain halted until reset is asserted.
            ------------------------------------------------------------------

            WHEN HALT_STATE =>

                next_state <= HALT_STATE;


            ------------------------------------------------------------------
            -- Safety fallback.
            ------------------------------------------------------------------

            WHEN OTHERS =>

                next_state <= FETCH_STATE;

        END CASE;

    END PROCESS next_state_logic;


    --------------------------------------------------------------------------
    -- Output logic.
    --
    -- State encoding:
    --
    -- 00 = FETCH
    -- 01 = DECODE
    -- 10 = EXECUTE
    -- 11 = HALT
    --------------------------------------------------------------------------

    output_logic : PROCESS(current_state)
    BEGIN

        -- Default output values.
        tc_ir_load_out        <= '0';
        tc_execute_enable_out <= '0';
        tc_halted_out         <= '0';
        tc_state_out          <= "00";

        CASE current_state IS

            WHEN FETCH_STATE =>

                tc_ir_load_out <= '1';
                tc_state_out   <= "00";


            WHEN DECODE_STATE =>

                tc_state_out <= "01";


            WHEN EXECUTE_STATE =>

                tc_execute_enable_out <= '1';
                tc_state_out          <= "10";


            WHEN HALT_STATE =>

                tc_halted_out <= '1';
                tc_state_out  <= "11";


            WHEN OTHERS =>

                tc_state_out <= "00";

        END CASE;

    END PROCESS output_logic;

END ARCHITECTURE fsm;