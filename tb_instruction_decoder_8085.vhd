LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Testbench: 8085 Instruction Decoder
--
-- Purpose:
-- Verifies that the Instruction Decoder correctly identifies supported
-- 8085 instruction opcodes and generates the expected control signals.
--
-- Tested instructions:
-- 1. NOP
-- 2. HLT
-- 3. ADD B
-- 4. ADD C
-- 5. SUB B
-- 6. ANA H
-- 7. XRA L
-- 8. ORA B
-- 9. CMP B
-- 10. Unsupported opcode
------------------------------------------------------------------------------------------

ENTITY tb_instruction_decoder_8085 IS
END ENTITY tb_instruction_decoder_8085;

------------------------------------------------------------------------------------------

ARCHITECTURE simulation OF tb_instruction_decoder_8085 IS

    SIGNAL tb_opcode   : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    SIGNAL tb_op_sel   : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL tb_reg_sel  : STD_LOGIC_VECTOR(2 DOWNTO 0);

    SIGNAL tb_load_acc : STD_LOGIC;
    SIGNAL tb_load_fr  : STD_LOGIC;

    SIGNAL tb_is_nop   : STD_LOGIC;
    SIGNAL tb_is_hlt   : STD_LOGIC;

    SIGNAL tb_valid    : STD_LOGIC;

BEGIN

    --------------------------------------------------------------------------
    -- Device Under Test.
    --------------------------------------------------------------------------

    DUT : ENTITY work.instruction_decoder_8085(combinational)
        PORT MAP (
            dec_opcode_in    => tb_opcode,

            dec_op_sel_out   => tb_op_sel,
            dec_reg_sel_out  => tb_reg_sel,

            dec_load_acc_out => tb_load_acc,
            dec_load_fr_out  => tb_load_fr,

            dec_is_nop_out   => tb_is_nop,
            dec_is_hlt_out   => tb_is_hlt,

            dec_valid_out    => tb_valid
        );

    --------------------------------------------------------------------------
    -- Test sequence.
    --------------------------------------------------------------------------

    stimulus_process : PROCESS
    BEGIN

        ----------------------------------------------------------------------
        -- Test 1: NOP
        -- Opcode: 00H = 00000000
        ----------------------------------------------------------------------

        tb_opcode <= x"00";
        WAIT FOR 10 ns;

        ASSERT tb_is_nop = '1'
            REPORT "Test 1 failed: NOP was not detected."
            SEVERITY ERROR;

        ASSERT tb_is_hlt = '0'
            REPORT "Test 1 failed: HLT should not be active for NOP."
            SEVERITY ERROR;

        ASSERT tb_valid = '1'
            REPORT "Test 1 failed: NOP should be a valid instruction."
            SEVERITY ERROR;

        ASSERT tb_load_acc = '0'
            REPORT "Test 1 failed: NOP should not load accumulator."
            SEVERITY ERROR;

        ASSERT tb_load_fr = '0'
            REPORT "Test 1 failed: NOP should not load flag register."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- Test 2: HLT
        -- Opcode: 76H = 01110110
        ----------------------------------------------------------------------

        tb_opcode <= x"76";
        WAIT FOR 10 ns;

        ASSERT tb_is_hlt = '1'
            REPORT "Test 2 failed: HLT was not detected."
            SEVERITY ERROR;

        ASSERT tb_is_nop = '0'
            REPORT "Test 2 failed: NOP should not be active for HLT."
            SEVERITY ERROR;

        ASSERT tb_valid = '1'
            REPORT "Test 2 failed: HLT should be a valid instruction."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- Test 3: ADD B
        -- Opcode: 80H = 10000000
        -- Expected:
        -- op_sel  = 000
        -- reg_sel = 000
        -- load accumulator = 1
        -- load flags = 1
        ----------------------------------------------------------------------

        tb_opcode <= x"80";
        WAIT FOR 10 ns;

        ASSERT tb_op_sel = "000"
            REPORT "Test 3 failed: ADD B should generate op_sel 000."
            SEVERITY ERROR;

        ASSERT tb_reg_sel = "000"
            REPORT "Test 3 failed: ADD B should select register B."
            SEVERITY ERROR;

        ASSERT tb_load_acc = '1'
            REPORT "Test 3 failed: ADD B should load accumulator."
            SEVERITY ERROR;

        ASSERT tb_load_fr = '1'
            REPORT "Test 3 failed: ADD B should load flag register."
            SEVERITY ERROR;

        ASSERT tb_valid = '1'
            REPORT "Test 3 failed: ADD B should be valid."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- Test 4: ADD C
        -- Opcode: 81H = 10000001
        ----------------------------------------------------------------------

        tb_opcode <= x"81";
        WAIT FOR 10 ns;

        ASSERT tb_op_sel = "000"
            REPORT "Test 4 failed: ADD C should generate op_sel 000."
            SEVERITY ERROR;

        ASSERT tb_reg_sel = "001"
            REPORT "Test 4 failed: ADD C should select register C."
            SEVERITY ERROR;

        ASSERT tb_load_acc = '1'
            REPORT "Test 4 failed: ADD C should load accumulator."
            SEVERITY ERROR;

        ASSERT tb_load_fr = '1'
            REPORT "Test 4 failed: ADD C should load flag register."
            SEVERITY ERROR;

        ASSERT tb_valid = '1'
            REPORT "Test 4 failed: ADD C should be valid."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- Test 5: SUB B
        -- Opcode: 90H = 10010000
        -- Expected op_sel = 010
        ----------------------------------------------------------------------

        tb_opcode <= x"90";
        WAIT FOR 10 ns;

        ASSERT tb_op_sel = "010"
            REPORT "Test 5 failed: SUB B should generate op_sel 010."
            SEVERITY ERROR;

        ASSERT tb_reg_sel = "000"
            REPORT "Test 5 failed: SUB B should select register B."
            SEVERITY ERROR;

        ASSERT tb_load_acc = '1'
            REPORT "Test 5 failed: SUB B should load accumulator."
            SEVERITY ERROR;

        ASSERT tb_load_fr = '1'
            REPORT "Test 5 failed: SUB B should load flag register."
            SEVERITY ERROR;

        ASSERT tb_valid = '1'
            REPORT "Test 5 failed: SUB B should be valid."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- Test 6: ANA H
        -- Opcode: A4H = 10100100
        -- Expected op_sel = 100, reg_sel = 100
        ----------------------------------------------------------------------

        tb_opcode <= x"A4";
        WAIT FOR 10 ns;

        ASSERT tb_op_sel = "100"
            REPORT "Test 6 failed: ANA H should generate op_sel 100."
            SEVERITY ERROR;

        ASSERT tb_reg_sel = "100"
            REPORT "Test 6 failed: ANA H should select register H."
            SEVERITY ERROR;

        ASSERT tb_load_acc = '1'
            REPORT "Test 6 failed: ANA H should load accumulator."
            SEVERITY ERROR;

        ASSERT tb_load_fr = '1'
            REPORT "Test 6 failed: ANA H should load flag register."
            SEVERITY ERROR;

        ASSERT tb_valid = '1'
            REPORT "Test 6 failed: ANA H should be valid."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- Test 7: XRA L
        -- Opcode: ADH = 10101101
        -- Expected op_sel = 110, reg_sel = 101
        ----------------------------------------------------------------------

        tb_opcode <= x"AD";
        WAIT FOR 10 ns;

        ASSERT tb_op_sel = "110"
            REPORT "Test 7 failed: XRA L should generate op_sel 110."
            SEVERITY ERROR;

        ASSERT tb_reg_sel = "101"
            REPORT "Test 7 failed: XRA L should select register L."
            SEVERITY ERROR;

        ASSERT tb_load_acc = '1'
            REPORT "Test 7 failed: XRA L should load accumulator."
            SEVERITY ERROR;

        ASSERT tb_load_fr = '1'
            REPORT "Test 7 failed: XRA L should load flag register."
            SEVERITY ERROR;

        ASSERT tb_valid = '1'
            REPORT "Test 7 failed: XRA L should be valid."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- Test 8: ORA B
        -- Opcode: B0H = 10110000
        -- Expected op_sel = 101
        ----------------------------------------------------------------------

        tb_opcode <= x"B0";
        WAIT FOR 10 ns;

        ASSERT tb_op_sel = "101"
            REPORT "Test 8 failed: ORA B should generate op_sel 101."
            SEVERITY ERROR;

        ASSERT tb_reg_sel = "000"
            REPORT "Test 8 failed: ORA B should select register B."
            SEVERITY ERROR;

        ASSERT tb_load_acc = '1'
            REPORT "Test 8 failed: ORA B should load accumulator."
            SEVERITY ERROR;

        ASSERT tb_load_fr = '1'
            REPORT "Test 8 failed: ORA B should load flag register."
            SEVERITY ERROR;

        ASSERT tb_valid = '1'
            REPORT "Test 8 failed: ORA B should be valid."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- Test 9: CMP B
        -- Opcode: B8H = 10111000
        -- Expected:
        -- op_sel = 111
        -- load accumulator = 0
        -- load flags = 1
        ----------------------------------------------------------------------

        tb_opcode <= x"B8";
        WAIT FOR 10 ns;

        ASSERT tb_op_sel = "111"
            REPORT "Test 9 failed: CMP B should generate op_sel 111."
            SEVERITY ERROR;

        ASSERT tb_reg_sel = "000"
            REPORT "Test 9 failed: CMP B should select register B."
            SEVERITY ERROR;

        ASSERT tb_load_acc = '0'
            REPORT "Test 9 failed: CMP B should not load accumulator."
            SEVERITY ERROR;

        ASSERT tb_load_fr = '1'
            REPORT "Test 9 failed: CMP B should load flag register."
            SEVERITY ERROR;

        ASSERT tb_valid = '1'
            REPORT "Test 9 failed: CMP B should be valid."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- Test 10: Unsupported opcode
        -- Opcode: C3H is JMP in the real 8085, but it is not supported yet
        -- by this first version of the decoder.
        ----------------------------------------------------------------------

        tb_opcode <= x"C3";
        WAIT FOR 10 ns;

        ASSERT tb_valid = '0'
            REPORT "Test 10 failed: unsupported opcode should not be valid yet."
            SEVERITY ERROR;

        ASSERT tb_load_acc = '0'
            REPORT "Test 10 failed: unsupported opcode should not load accumulator."
            SEVERITY ERROR;

        ASSERT tb_load_fr = '0'
            REPORT "Test 10 failed: unsupported opcode should not load flag register."
            SEVERITY ERROR;


        ----------------------------------------------------------------------
        -- End of simulation.
        ----------------------------------------------------------------------

        REPORT "All Instruction Decoder tests passed successfully."
            SEVERITY NOTE;

        WAIT;

    END PROCESS stimulus_process;

END ARCHITECTURE simulation;