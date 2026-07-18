LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Testbench: 8085 Instruction Register
--
-- Purpose:
-- Verifies the behavior of the 8-bit Instruction Register.
--
-- This testbench simulates the same actions that were tested physically
-- on the FPGA board using switches, buttons and LEDs.
--
-- Tested cases:
-- 1. Reset clears the register.
-- 2. The register loads data when ir_load = '1'.
-- 3. The register keeps the previous value when ir_load = '0'.
-- 4. The register loads a new value when ir_load returns to '1'.
-- 5. Reset clears the register again.
------------------------------------------------------------------------------------------

ENTITY tb_instruction_register_8085 IS
END ENTITY tb_instruction_register_8085;

------------------------------------------------------------------------------------------

ARCHITECTURE simulation OF tb_instruction_register_8085 IS

    SIGNAL tb_clk      : STD_LOGIC := '0';
    SIGNAL tb_rst      : STD_LOGIC := '0';
    SIGNAL tb_load     : STD_LOGIC := '0';
    SIGNAL tb_data_in  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_data_out : STD_LOGIC_VECTOR(7 DOWNTO 0);

    CONSTANT clk_period : TIME := 20 ns;

BEGIN

    --------------------------------------------------------------------------
    -- Device Under Test.
    --------------------------------------------------------------------------

    DUT : ENTITY work.instruction_register_8085(rtl)
        PORT MAP (
            ir_clk      => tb_clk,
            ir_rst      => tb_rst,
            ir_load     => tb_load,
            ir_data_in  => tb_data_in,
            ir_data_out => tb_data_out
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
        -- Test 1: Reset clears the register.
        ----------------------------------------------------------------------

        tb_rst     <= '1';
        tb_load    <= '0';
        tb_data_in <= x"FF";

        WAIT FOR 10 ns;

        ASSERT tb_data_out = x"00"
            REPORT "Test 1 failed: reset did not clear the register."
            SEVERITY ERROR;

        ----------------------------------------------------------------------
        -- Test 2: Load 80H.
        --
        -- This is equivalent to:
        -- SW(7 DOWNTO 0) = 10000000
        -- SW(8) = 1
        -- Press KEY(0)
        ----------------------------------------------------------------------

        tb_rst     <= '0';
        tb_load    <= '1';
        tb_data_in <= x"80";

        WAIT UNTIL rising_edge(tb_clk);
        WAIT FOR 2 ns;

        ASSERT tb_data_out = x"80"
            REPORT "Test 2 failed: register did not load 80H."
            SEVERITY ERROR;

        ----------------------------------------------------------------------
        -- Test 3: Change input to 90H, but keep load disabled.
        --
        -- The output must remain 80H.
        ----------------------------------------------------------------------

        tb_load    <= '0';
        tb_data_in <= x"90";

        WAIT UNTIL rising_edge(tb_clk);
        WAIT FOR 2 ns;

        ASSERT tb_data_out = x"80"
            REPORT "Test 3 failed: register changed even though load was disabled."
            SEVERITY ERROR;

        ----------------------------------------------------------------------
        -- Test 4: Enable load and store 90H.
        ----------------------------------------------------------------------

        tb_load    <= '1';
        tb_data_in <= x"90";

        WAIT UNTIL rising_edge(tb_clk);
        WAIT FOR 2 ns;

        ASSERT tb_data_out = x"90"
            REPORT "Test 4 failed: register did not load 90H."
            SEVERITY ERROR;

        ----------------------------------------------------------------------
        -- Test 5: Reset again.
        ----------------------------------------------------------------------

        tb_rst     <= '1';
        tb_load    <= '1';
        tb_data_in <= x"B8";

        WAIT FOR 10 ns;

        ASSERT tb_data_out = x"00"
            REPORT "Test 5 failed: reset did not clear the register again."
            SEVERITY ERROR;

        ----------------------------------------------------------------------
        -- End of simulation.
        ----------------------------------------------------------------------

        REPORT "All Instruction Register tests passed successfully."
            SEVERITY NOTE;

        WAIT;

    END PROCESS stimulus_process;

END ARCHITECTURE simulation;