LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Module: 8085 Instruction Decoder
--
-- Purpose:
-- Decodes the 8-bit opcode stored in the Instruction Register and generates
-- the control signals required by the ALU, accumulator, flag register,
-- register array, and execution control logic.
--
-- Current supported instruction families:
--
-- NOP
-- HLT
--
-- ADD r
-- ADC r
-- SUB r
-- SBB r
-- ANA r
-- XRA r
-- ORA r
-- CMP r
--
-- Register encoding:
--
-- 000 = B
-- 001 = C
-- 010 = D
-- 011 = E
-- 100 = H
-- 101 = L
-- 110 = M (memory pointed to by HL, not implemented yet)
-- 111 = A
--
-- ALU operation encoding:
--
-- 000 = ADD
-- 001 = ADC
-- 010 = SUB
-- 011 = SBB
-- 100 = AND
-- 101 = OR
-- 110 = XOR
-- 111 = CMP
------------------------------------------------------------------------------------------

ENTITY instruction_decoder_8085 IS
    PORT (
        dec_opcode_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);

        dec_op_sel_out   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        dec_reg_sel_out  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

        dec_load_acc_out : OUT STD_LOGIC;
        dec_load_fr_out  : OUT STD_LOGIC;

        dec_is_nop_out   : OUT STD_LOGIC;
        dec_is_hlt_out   : OUT STD_LOGIC;

        dec_valid_out    : OUT STD_LOGIC
    );
END ENTITY instruction_decoder_8085;

------------------------------------------------------------------------------------------

ARCHITECTURE id_logic OF instruction_decoder_8085 IS

BEGIN

    PROCESS(dec_opcode_in)
    BEGIN

        ----------------------------------------------------------------------
        -- Default values.
        --
        -- These defaults prevent unintended latch inference and ensure that
        -- no control operation is activated unless explicitly decoded.
        ----------------------------------------------------------------------

        dec_op_sel_out   <= "000";
        dec_reg_sel_out  <= "000";

        dec_load_acc_out <= '0';
        dec_load_fr_out  <= '0';

        dec_is_nop_out   <= '0';
        dec_is_hlt_out   <= '0';

        dec_valid_out    <= '0';


        ----------------------------------------------------------------------
        -- NOP
        --
        -- Opcode: 00H
        --
        -- No register, accumulator, flag, or ALU state is modified.
        ----------------------------------------------------------------------

        IF dec_opcode_in = x"00" THEN

            dec_is_nop_out <= '1';
            dec_valid_out  <= '1';


        ----------------------------------------------------------------------
        -- HLT
        --
        -- Opcode: 76H
        --
        -- The execution control unit will use dec_is_hlt_out to enter
        -- the HALT state.
        ----------------------------------------------------------------------

        ELSIF dec_opcode_in = x"76" THEN

            dec_is_hlt_out <= '1';
            dec_valid_out  <= '1';


        ----------------------------------------------------------------------
        -- ADD r
        --
        -- Opcode format: 10000SSS
        ----------------------------------------------------------------------

        ELSIF dec_opcode_in(7 DOWNTO 3) = "10000" THEN

            dec_op_sel_out   <= "000";
            dec_reg_sel_out  <= dec_opcode_in(2 DOWNTO 0);

            dec_load_acc_out <= '1';
            dec_load_fr_out  <= '1';

            dec_valid_out    <= '1';


        ----------------------------------------------------------------------
        -- ADC r
        --
        -- Opcode format: 10001SSS
        ----------------------------------------------------------------------

        ELSIF dec_opcode_in(7 DOWNTO 3) = "10001" THEN

            dec_op_sel_out   <= "001";
            dec_reg_sel_out  <= dec_opcode_in(2 DOWNTO 0);

            dec_load_acc_out <= '1';
            dec_load_fr_out  <= '1';

            dec_valid_out    <= '1';


        ----------------------------------------------------------------------
        -- SUB r
        --
        -- Opcode format: 10010SSS
        ----------------------------------------------------------------------

        ELSIF dec_opcode_in(7 DOWNTO 3) = "10010" THEN

            dec_op_sel_out   <= "010";
            dec_reg_sel_out  <= dec_opcode_in(2 DOWNTO 0);

            dec_load_acc_out <= '1';
            dec_load_fr_out  <= '1';

            dec_valid_out    <= '1';


        ----------------------------------------------------------------------
        -- SBB r
        --
        -- Opcode format: 10011SSS
        ----------------------------------------------------------------------

        ELSIF dec_opcode_in(7 DOWNTO 3) = "10011" THEN

            dec_op_sel_out   <= "011";
            dec_reg_sel_out  <= dec_opcode_in(2 DOWNTO 0);

            dec_load_acc_out <= '1';
            dec_load_fr_out  <= '1';

            dec_valid_out    <= '1';


        ----------------------------------------------------------------------
        -- ANA r
        --
        -- Opcode format: 10100SSS
        ----------------------------------------------------------------------

        ELSIF dec_opcode_in(7 DOWNTO 3) = "10100" THEN

            dec_op_sel_out   <= "100";
            dec_reg_sel_out  <= dec_opcode_in(2 DOWNTO 0);

            dec_load_acc_out <= '1';
            dec_load_fr_out  <= '1';

            dec_valid_out    <= '1';


        ----------------------------------------------------------------------
        -- XRA r
        --
        -- Opcode format: 10101SSS
        ----------------------------------------------------------------------

        ELSIF dec_opcode_in(7 DOWNTO 3) = "10101" THEN

            dec_op_sel_out   <= "110";
            dec_reg_sel_out  <= dec_opcode_in(2 DOWNTO 0);

            dec_load_acc_out <= '1';
            dec_load_fr_out  <= '1';

            dec_valid_out    <= '1';


        ----------------------------------------------------------------------
        -- ORA r
        --
        -- Opcode format: 10110SSS
        ----------------------------------------------------------------------

        ELSIF dec_opcode_in(7 DOWNTO 3) = "10110" THEN

            dec_op_sel_out   <= "101";
            dec_reg_sel_out  <= dec_opcode_in(2 DOWNTO 0);

            dec_load_acc_out <= '1';
            dec_load_fr_out  <= '1';

            dec_valid_out    <= '1';


        ----------------------------------------------------------------------
        -- CMP r
        --
        -- Opcode format: 10111SSS
        --
        -- CMP updates the flags but does not modify the accumulator.
        ----------------------------------------------------------------------

        ELSIF dec_opcode_in(7 DOWNTO 3) = "10111" THEN

            dec_op_sel_out   <= "111";
            dec_reg_sel_out  <= dec_opcode_in(2 DOWNTO 0);

            dec_load_acc_out <= '0';
            dec_load_fr_out  <= '1';

            dec_valid_out    <= '1';

        END IF;

    END PROCESS;

END ARCHITECTURE id_logic;