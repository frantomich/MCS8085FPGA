LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Module: 8085 Instruction Decoder (complete instruction set)
--
-- Instruction type encoding (dec_itype_out):
--   0000 = ALU reg        (ADD/ADC/SUB/SBB/ANA/XRA/ORA/CMP r)
--   0001 = ALU imm        (ADI/ACI/SUI/SBI/ANI/XRI/ORI/CPI)
--   0010 = MOV reg        (MOV r1,r2)
--   0011 = MOV mem load   (MOV r,M)
--   0100 = MOV mem store  (MOV M,r)
--   0101 = MVI reg        (MVI r,d8)
--   0110 = MVI mem        (MVI M,d8)
--   0111 = LXI            (LXI rp,d16)
--   1000 = LDA/STA/LHLD/SHLD
--   1001 = LDAX/STAX
--   1010 = INR/DCR reg
--   1011 = INR/DCR mem
--   1100 = INX/DCX
--   1101 = DAD
--   1110 = ROTATE/CMA/CMC/STC/DAA
--   1111 = JUMP/CALL/RET/RST/PUSH/POP/PCHL/SPHL/XTHL/XCHG/EI/DI/RIM/SIM/IN/OUT/NOP/HLT
--
-- dec_rp_out: register pair encoding
--   00 = BC   01 = DE   10 = HL   11 = SP
------------------------------------------------------------------------------------------

ENTITY instruction_decoder_8085 IS
    PORT (
        dec_opcode_in    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);

        -- ALU / datapath
        dec_op_sel_out   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        dec_reg_sel_out  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        dec_dst_sel_out  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        dec_rp_out       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

        -- Load enables
        dec_load_acc_out : OUT STD_LOGIC;
        dec_load_fr_out  : OUT STD_LOGIC;

        -- Instruction type
        dec_itype_out    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

        -- Condition code for conditional jumps/calls/rets
        dec_cond_out     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        dec_cond_en_out  : OUT STD_LOGIC;  -- '1' = conditional, '0' = unconditional

        -- Special flags
        dec_is_nop_out   : OUT STD_LOGIC;
        dec_is_hlt_out   : OUT STD_LOGIC;
        dec_is_mem_out   : OUT STD_LOGIC;

        dec_valid_out    : OUT STD_LOGIC
    );
END ENTITY instruction_decoder_8085;

ARCHITECTURE combinational OF instruction_decoder_8085 IS
BEGIN

    PROCESS(dec_opcode_in)
    BEGIN
        -- Defaults
        dec_op_sel_out   <= "000";
        dec_reg_sel_out  <= dec_opcode_in(2 DOWNTO 0);
        dec_dst_sel_out  <= dec_opcode_in(5 DOWNTO 3);
        dec_rp_out       <= dec_opcode_in(5 DOWNTO 4);
        dec_load_acc_out <= '0';
        dec_load_fr_out  <= '0';
        dec_itype_out    <= "1111";
        dec_cond_out     <= "000";
        dec_cond_en_out  <= '0';
        dec_is_nop_out   <= '0';
        dec_is_hlt_out   <= '0';
        dec_is_mem_out   <= '0';
        dec_valid_out    <= '0';

        -- NOP
        IF dec_opcode_in = x"00" THEN
            dec_is_nop_out <= '1';
            dec_valid_out  <= '1';

        -- HLT
        ELSIF dec_opcode_in = x"76" THEN
            dec_is_hlt_out <= '1';
            dec_valid_out  <= '1';

        -- MOV r1, r2  (01DDDSSS, excludes 76)
        ELSIF dec_opcode_in(7 DOWNTO 6) = "01" THEN
            dec_itype_out   <= "0010";
            dec_dst_sel_out <= dec_opcode_in(5 DOWNTO 3);
            dec_reg_sel_out <= dec_opcode_in(2 DOWNTO 0);
            dec_valid_out   <= '1';
            IF dec_opcode_in(2 DOWNTO 0) = "110" THEN
                dec_itype_out  <= "0011";  -- MOV r,M
                dec_is_mem_out <= '1';
            ELSIF dec_opcode_in(5 DOWNTO 3) = "110" THEN
                dec_itype_out  <= "0100";  -- MOV M,r
                dec_is_mem_out <= '1';
            END IF;

        -- ALU reg  (10OOOSSS)
        ELSIF dec_opcode_in(7 DOWNTO 6) = "10" THEN
            dec_itype_out    <= "0000";
            dec_op_sel_out   <= dec_opcode_in(5 DOWNTO 3);
            dec_reg_sel_out  <= dec_opcode_in(2 DOWNTO 0);
            dec_load_fr_out  <= '1';
            dec_valid_out    <= '1';
            IF dec_opcode_in(5 DOWNTO 3) /= "111" THEN  -- CMP does not write ACC
                dec_load_acc_out <= '1';
            END IF;
            IF dec_opcode_in(2 DOWNTO 0) = "110" THEN
                dec_is_mem_out   <= '1';  -- Bug fix: ALU M precisa ler memória
                dec_load_acc_out <= '0';
                dec_load_fr_out  <= '0';
            END IF;

        -- MVI r, d8  (00RRR110)
        ELSIF dec_opcode_in(2 DOWNTO 0) = "110" AND dec_opcode_in(7 DOWNTO 6) = "00" THEN
            dec_dst_sel_out <= dec_opcode_in(5 DOWNTO 3);
            dec_valid_out   <= '1';
            IF dec_opcode_in(5 DOWNTO 3) = "110" THEN
                dec_itype_out  <= "0110";  -- MVI M, d8
                dec_is_mem_out <= '1';
            ELSE
                dec_itype_out  <= "0101";  -- MVI r, d8
            END IF;

        -- LXI rp, d16  (00RP0001)
        ELSIF dec_opcode_in(3 DOWNTO 0) = "0001" AND dec_opcode_in(7 DOWNTO 6) = "00" THEN
            dec_itype_out <= "0111";
            dec_rp_out    <= dec_opcode_in(5 DOWNTO 4);
            dec_valid_out <= '1';

        -- INX rp  (00RP0011)
        ELSIF dec_opcode_in(3 DOWNTO 0) = "0011" AND dec_opcode_in(7 DOWNTO 6) = "00" THEN
            dec_itype_out <= "1100";
            dec_rp_out    <= dec_opcode_in(5 DOWNTO 4);
            dec_op_sel_out <= "001";  -- increment
            dec_valid_out <= '1';

        -- DCX rp  (00RP1011)
        ELSIF dec_opcode_in(3 DOWNTO 0) = "1011" AND dec_opcode_in(7 DOWNTO 6) = "00" THEN
            dec_itype_out  <= "1100";
            dec_rp_out     <= dec_opcode_in(5 DOWNTO 4);
            dec_op_sel_out <= "010";  -- decrement
            dec_valid_out  <= '1';

        -- DAD rp  (00RP1001)
        ELSIF dec_opcode_in(3 DOWNTO 0) = "1001" AND dec_opcode_in(7 DOWNTO 6) = "00" THEN
            dec_itype_out <= "1101";
            dec_rp_out    <= dec_opcode_in(5 DOWNTO 4);
            dec_valid_out <= '1';

        -- INR r  (00RRR100)
        ELSIF dec_opcode_in(2 DOWNTO 0) = "100" AND dec_opcode_in(7 DOWNTO 6) = "00" THEN
            dec_itype_out    <= "1010";
            dec_dst_sel_out  <= dec_opcode_in(5 DOWNTO 3);
            dec_op_sel_out   <= "001";  -- increment
            dec_load_fr_out  <= '1';
            dec_valid_out    <= '1';
            IF dec_opcode_in(5 DOWNTO 3) = "110" THEN
                dec_is_mem_out <= '1';
                dec_itype_out  <= "1011";
            END IF;

        -- DCR r  (00RRR101)
        ELSIF dec_opcode_in(2 DOWNTO 0) = "101" AND dec_opcode_in(7 DOWNTO 6) = "00" THEN
            dec_itype_out    <= "1010";
            dec_dst_sel_out  <= dec_opcode_in(5 DOWNTO 3);
            dec_op_sel_out   <= "010";  -- decrement
            dec_load_fr_out  <= '1';
            dec_valid_out    <= '1';
            IF dec_opcode_in(5 DOWNTO 3) = "110" THEN
                dec_is_mem_out <= '1';
                dec_itype_out  <= "1011";
            END IF;

        -- ALU immediate (11OOO110)
        ELSIF dec_opcode_in(7 DOWNTO 6) = "11" AND dec_opcode_in(2 DOWNTO 0) = "110" THEN
            dec_itype_out    <= "0001";
            dec_op_sel_out   <= dec_opcode_in(5 DOWNTO 3);
            dec_load_fr_out  <= '1';
            dec_valid_out    <= '1';
            IF dec_opcode_in(5 DOWNTO 3) /= "111" THEN
                dec_load_acc_out <= '1';
            END IF;

        -- LDA  (3A)
        ELSIF dec_opcode_in = x"3A" THEN
            dec_itype_out <= "1000";
            dec_op_sel_out <= "000";  -- load
            dec_valid_out <= '1';

        -- STA  (32)
        ELSIF dec_opcode_in = x"32" THEN
            dec_itype_out <= "1000";
            dec_op_sel_out <= "001";  -- store
            dec_valid_out <= '1';

        -- LHLD (2A)
        ELSIF dec_opcode_in = x"2A" THEN
            dec_itype_out <= "1000";
            dec_op_sel_out <= "010";
            dec_valid_out <= '1';

        -- SHLD (22)
        ELSIF dec_opcode_in = x"22" THEN
            dec_itype_out <= "1000";
            dec_op_sel_out <= "011";
            dec_valid_out <= '1';

        -- LDAX BC (0A)
        ELSIF dec_opcode_in = x"0A" THEN
            dec_itype_out <= "1001";
            dec_rp_out    <= "00";
            dec_op_sel_out <= "000";  -- load
            dec_valid_out <= '1';

        -- LDAX DE (1A)
        ELSIF dec_opcode_in = x"1A" THEN
            dec_itype_out <= "1001";
            dec_rp_out    <= "01";
            dec_op_sel_out <= "000";
            dec_valid_out <= '1';

        -- STAX BC (02)
        ELSIF dec_opcode_in = x"02" THEN
            dec_itype_out <= "1001";
            dec_rp_out    <= "00";
            dec_op_sel_out <= "001";  -- store
            dec_valid_out <= '1';

        -- STAX DE (12)
        ELSIF dec_opcode_in = x"12" THEN
            dec_itype_out <= "1001";
            dec_rp_out    <= "01";
            dec_op_sel_out <= "001";
            dec_valid_out <= '1';

        -- Rotate / CMA / CMC / STC / DAA (1110xxxx group)
        ELSIF dec_opcode_in = x"07" OR dec_opcode_in = x"0F" OR
              dec_opcode_in = x"17" OR dec_opcode_in = x"1F" OR
              dec_opcode_in = x"2F" OR dec_opcode_in = x"3F" OR
              dec_opcode_in = x"37" OR dec_opcode_in = x"27" THEN
            dec_itype_out  <= "1110";
            dec_op_sel_out <= dec_opcode_in(5 DOWNTO 3);
            dec_valid_out  <= '1';

        -- PUSH rp  (11RP0101)
        ELSIF dec_opcode_in(3 DOWNTO 0) = "0101" AND dec_opcode_in(7 DOWNTO 6) = "11" THEN
            dec_itype_out <= "1111";
            dec_op_sel_out <= "000";  -- push
            dec_rp_out    <= dec_opcode_in(5 DOWNTO 4);
            dec_valid_out <= '1';

        -- POP rp  (11RP0001)
        ELSIF dec_opcode_in(3 DOWNTO 0) = "0001" AND dec_opcode_in(7 DOWNTO 6) = "11" THEN
            dec_itype_out <= "1111";
            dec_op_sel_out <= "001";  -- pop
            dec_rp_out    <= dec_opcode_in(5 DOWNTO 4);
            dec_valid_out <= '1';

        -- JMP (C3) / conditional jumps (11CCC010)
        ELSIF dec_opcode_in = x"C3" THEN
            dec_itype_out   <= "1111";
            dec_op_sel_out  <= "010";  -- jump
            dec_cond_en_out <= '0';
            dec_valid_out   <= '1';
        ELSIF dec_opcode_in(2 DOWNTO 0) = "010" AND dec_opcode_in(7 DOWNTO 6) = "11" THEN
            dec_itype_out   <= "1111";
            dec_op_sel_out  <= "010";
            dec_cond_out    <= dec_opcode_in(5 DOWNTO 3);
            dec_cond_en_out <= '1';
            dec_valid_out   <= '1';

        -- CALL (CD) / conditional calls (11CCC100)
        ELSIF dec_opcode_in = x"CD" THEN
            dec_itype_out   <= "1111";
            dec_op_sel_out  <= "011";  -- call
            dec_cond_en_out <= '0';
            dec_valid_out   <= '1';
        ELSIF dec_opcode_in(2 DOWNTO 0) = "100" AND dec_opcode_in(7 DOWNTO 6) = "11" THEN
            dec_itype_out   <= "1111";
            dec_op_sel_out  <= "011";
            dec_cond_out    <= dec_opcode_in(5 DOWNTO 3);
            dec_cond_en_out <= '1';
            dec_valid_out   <= '1';

        -- RET (C9) / conditional rets (11CCC000)
        ELSIF dec_opcode_in = x"C9" THEN
            dec_itype_out   <= "1111";
            dec_op_sel_out  <= "100";  -- ret
            dec_cond_en_out <= '0';
            dec_valid_out   <= '1';
        ELSIF dec_opcode_in(2 DOWNTO 0) = "000" AND dec_opcode_in(7 DOWNTO 6) = "11" THEN
            dec_itype_out   <= "1111";
            dec_op_sel_out  <= "100";
            dec_cond_out    <= dec_opcode_in(5 DOWNTO 3);
            dec_cond_en_out <= '1';
            dec_valid_out   <= '1';

        -- RST n  (11NNN111)
        ELSIF dec_opcode_in(2 DOWNTO 0) = "111" AND dec_opcode_in(7 DOWNTO 6) = "11" THEN
            dec_itype_out  <= "1111";
            dec_op_sel_out <= "101";  -- rst
            dec_dst_sel_out <= dec_opcode_in(5 DOWNTO 3);  -- RST vector n
            dec_valid_out  <= '1';

        -- IN port  (DB)
        ELSIF dec_opcode_in = x"DB" THEN
            dec_itype_out <= "1111";
            dec_op_sel_out <= "110";  -- in
            dec_valid_out <= '1';

        -- OUT port  (D3)
        ELSIF dec_opcode_in = x"D3" THEN
            dec_itype_out <= "1111";
            dec_op_sel_out <= "111";  -- out
            dec_valid_out <= '1';

        -- PCHL (E9)
        ELSIF dec_opcode_in = x"E9" THEN
            dec_itype_out <= "1111";
            dec_op_sel_out <= "010";
            dec_rp_out    <= "10";  -- HL
            dec_valid_out <= '1';

        -- SPHL (F9)
        ELSIF dec_opcode_in = x"F9" THEN
            dec_itype_out <= "1111";
            dec_valid_out <= '1';

        -- XTHL (E3)
        ELSIF dec_opcode_in = x"E3" THEN
            dec_itype_out  <= "1111";
            dec_is_mem_out <= '1';
            dec_valid_out  <= '1';

        -- XCHG (EB)
        ELSIF dec_opcode_in = x"EB" THEN
            dec_itype_out <= "1111";
            dec_valid_out <= '1';

        -- EI (FB)
        ELSIF dec_opcode_in = x"FB" THEN
            dec_itype_out <= "1111";
            dec_valid_out <= '1';

        -- DI (F3)
        ELSIF dec_opcode_in = x"F3" THEN
            dec_itype_out <= "1111";
            dec_valid_out <= '1';

        -- RIM (20)
        ELSIF dec_opcode_in = x"20" THEN
            dec_itype_out <= "1111";
            dec_valid_out <= '1';

        -- SIM (30)
        ELSIF dec_opcode_in = x"30" THEN
            dec_itype_out <= "1111";
            dec_valid_out <= '1';

        END IF;

    END PROCESS;

END ARCHITECTURE combinational;
