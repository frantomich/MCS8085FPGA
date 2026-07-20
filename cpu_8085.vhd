LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

------------------------------------------------------------------------------------------
-- Module: 8085 CPU Core
--
-- Architecture: single clocked process per resource, combinational control signals.
-- All control decisions are made combinationally from (state, opcode, decoder outputs).
-- The clocked processes only capture results.
--
-- Internal register file (flat, not using register_array component for clarity):
--   A (accumulator), B, C, D, E, H, L, SP(15:0), PC(15:0)
--   TMP (8-bit operand buffer), IMM_L, IMM_H (immediate bytes)
--   W, Z (16-bit temp for CALL/RET/LHLD/SHLD)
--
-- FSM states (tc_state):
--   0000 FETCH       : mem[PC] -> IR, PC++
--   0001 DECODE      : combinational decode
--   0010 IMM1        : mem[PC] -> IMM_L, PC++
--   0011 IMM2        : mem[PC] -> IMM_H, PC++
--   0100 MEM_RD      : mem[addr] -> TMP
--   0101 MEM_RD2     : mem[addr+1] -> W  (for LHLD second byte)
--   0110 MEM_WR      : data -> mem[addr]
--   0111 MEM_WR2     : data -> mem[addr+1]
--   1000 EXECUTE     : apply results
--   1001 PUSH_H      : mem[SP-1] <- data_h, SP--
--   1010 PUSH_L      : mem[SP-1] <- data_l, SP--
--   1011 POP_L       : TMP <- mem[SP], SP++
--   1100 POP_H       : W   <- mem[SP], SP++
--   1101 INT_ACK
--   1111 HALT
------------------------------------------------------------------------------------------

ENTITY cpu_8085 IS
    PORT (
        clk          : IN  STD_LOGIC;
        rst          : IN  STD_LOGIC;
        mem_addr     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        mem_data_in  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        mem_data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        mem_wr_en    : OUT STD_LOGIC;
        io_addr      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        io_data_in   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        io_data_out  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        io_wr_en     : OUT STD_LOGIC;
        io_rd_en     : OUT STD_LOGIC;
        trap         : IN  STD_LOGIC;
        rst75        : IN  STD_LOGIC;
        rst65        : IN  STD_LOGIC;
        rst55        : IN  STD_LOGIC;
        intr         : IN  STD_LOGIC;
        acc_out      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        flags_out    : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        pc_out       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        halted       : OUT STD_LOGIC;
        state_out    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY cpu_8085;

ARCHITECTURE rtl OF cpu_8085 IS

    -- FSM state
    TYPE state_t IS (
        S_FETCH, S_DECODE,
        S_IMM1, S_IMM2,
        S_MEM_RD, S_MEM_RD2,
        S_MEM_WR, S_MEM_WR2,
        S_EXECUTE,
        S_PUSH_H, S_PUSH_L,
        S_POP_L,  S_POP_H,
        S_INT_ACK,
        S_HALT
    );
    SIGNAL state : state_t := S_FETCH;

    -- Register file
    SIGNAL A   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
    SIGNAL B   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
    SIGNAL C   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
    SIGNAL D   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
    SIGNAL E   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
    SIGNAL H   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
    SIGNAL L   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
    SIGNAL SP  : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0000";
    SIGNAL PC  : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0000";

    -- Flags: S, Z, AC, P, CY
    SIGNAL fS, fZ, fAC, fP, fCY : STD_LOGIC := '0';

    -- Temp buffers
    SIGNAL IR    : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
    SIGNAL TMP   : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
    SIGNAL W     : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";  -- high byte temp
    SIGNAL IMM_L : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
    SIGNAL IMM_H : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";

    -- Interrupt controller state
    SIGNAL ie_flag : STD_LOGIC := '0';
    SIGNAL mask75, mask65, mask55 : STD_LOGIC := '1';
    SIGNAL ff75    : STD_LOGIC := '0';
    SIGNAL trap_ff : STD_LOGIC := '0';

    -- Push/pop data staging
    SIGNAL push_h  : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
    SIGNAL push_l  : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";

    -- ALU wires (combinational)
    SIGNAL alu_a, alu_b : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL alu_op       : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL alu_result   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL alu_s, alu_z, alu_ac, alu_p, alu_cy : STD_LOGIC;

    -- Rotator wires
    SIGNAL rot_op     : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL rot_result : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL rot_cy     : STD_LOGIC;
    SIGNAL rot_ac     : STD_LOGIC;

    -- Decoder wires (combinational from IR)
    SIGNAL dec_op_sel  : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL dec_src     : STD_LOGIC_VECTOR(2 DOWNTO 0);  -- IR(2:0)
    SIGNAL dec_dst     : STD_LOGIC_VECTOR(2 DOWNTO 0);  -- IR(5:3)
    SIGNAL dec_rp      : STD_LOGIC_VECTOR(1 DOWNTO 0);  -- IR(5:4)
    SIGNAL dec_itype   : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL dec_cond    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL dec_cond_en : STD_LOGIC;
    SIGNAL dec_is_hlt  : STD_LOGIC;
    SIGNAL dec_is_mem  : STD_LOGIC;
    SIGNAL dec_valid   : STD_LOGIC;
    SIGNAL cond_met    : STD_LOGIC;

    -- Interrupt pending
    SIGNAL int_pending  : STD_LOGIC;
    SIGNAL int_vector   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL rim_p75_sig  : STD_LOGIC;

    -- Helper: read register by 3-bit code (combinational)
    FUNCTION read_reg(sel : STD_LOGIC_VECTOR(2 DOWNTO 0);
                      rA, rB, rC, rD, rE, rH, rL : STD_LOGIC_VECTOR(7 DOWNTO 0))
        RETURN STD_LOGIC_VECTOR IS
    BEGIN
        CASE sel IS
            WHEN "000" => RETURN rB;
            WHEN "001" => RETURN rC;
            WHEN "010" => RETURN rD;
            WHEN "011" => RETURN rE;
            WHEN "100" => RETURN rH;
            WHEN "101" => RETURN rL;
            WHEN "111" => RETURN rA;
            WHEN OTHERS => RETURN x"00";
        END CASE;
    END FUNCTION;

    -- Helper: read register pair by 2-bit code
    FUNCTION read_rp(sel : STD_LOGIC_VECTOR(1 DOWNTO 0);
                     rB, rC, rD, rE, rH, rL : STD_LOGIC_VECTOR(7 DOWNTO 0);
                     rSP : STD_LOGIC_VECTOR(15 DOWNTO 0))
        RETURN STD_LOGIC_VECTOR IS
    BEGIN
        CASE sel IS
            WHEN "00" => RETURN rB & rC;
            WHEN "01" => RETURN rD & rE;
            WHEN "10" => RETURN rH & rL;
            WHEN "11" => RETURN rSP;
            WHEN OTHERS => RETURN x"0000";
        END CASE;
    END FUNCTION;

BEGIN

    -- ALU instance
    ALU_INST : ENTITY work.alu(logic_alu)
        PORT MAP (
            A => alu_a, B => alu_b, CY_in => fCY, op_sel => alu_op,
            result => alu_result,
            S_out_alu => alu_s, Z_out_alu => alu_z,
            AC_out_alu => alu_ac, P_out_alu => alu_p, CY_out_alu => alu_cy
        );

    -- Rotator instance
    ROT_INST : ENTITY work.rotator_8085(combinational)
        PORT MAP (
            acc_in => A, cy_in => fCY, ac_in => fAC, op_sel => rot_op,
            acc_out => rot_result, cy_out => rot_cy, ac_out => rot_ac
        );

    -- Decoder instance
    DEC_INST : ENTITY work.instruction_decoder_8085(combinational)
        PORT MAP (
            dec_opcode_in    => IR,
            dec_op_sel_out   => dec_op_sel,
            dec_reg_sel_out  => dec_src,
            dec_dst_sel_out  => dec_dst,
            dec_rp_out       => dec_rp,
            dec_load_acc_out => OPEN,
            dec_load_fr_out  => OPEN,
            dec_itype_out    => dec_itype,
            dec_cond_out     => dec_cond,
            dec_cond_en_out  => dec_cond_en,
            dec_is_nop_out   => OPEN,
            dec_is_hlt_out   => dec_is_hlt,
            dec_is_mem_out   => dec_is_mem,
            dec_valid_out    => dec_valid
        );

    -- Condition evaluation
    PROCESS(dec_cond, fS, fZ, fP, fCY)
    BEGIN
        CASE dec_cond IS
            WHEN "000" => cond_met <= NOT fZ;
            WHEN "001" => cond_met <= fZ;
            WHEN "010" => cond_met <= NOT fCY;
            WHEN "011" => cond_met <= fCY;
            WHEN "100" => cond_met <= NOT fP;
            WHEN "101" => cond_met <= fP;
            WHEN "110" => cond_met <= NOT fS;
            WHEN "111" => cond_met <= fS;
            WHEN OTHERS => cond_met <= '1';
        END CASE;
    END PROCESS;

    -- Interrupt priority encoder
    PROCESS(trap_ff, ff75, mask75, rst65, mask65, rst55, mask55, intr, ie_flag)
    BEGIN
        int_pending <= '0';
        int_vector  <= x"00";
        IF trap_ff = '1' THEN
            int_pending <= '1'; int_vector <= x"24";
        ELSIF ie_flag = '1' THEN
            IF ff75 = '1' AND mask75 = '0' THEN
                int_pending <= '1'; int_vector <= x"3C";
            ELSIF rst65 = '1' AND mask65 = '0' THEN
                int_pending <= '1'; int_vector <= x"34";
            ELSIF rst55 = '1' AND mask55 = '0' THEN
                int_pending <= '1'; int_vector <= x"2C";
            ELSIF intr = '1' THEN
                int_pending <= '1'; int_vector <= x"00";
            END IF;
        END IF;
    END PROCESS;

    -- ALU input mux (combinational, used in EXECUTE)
    -- Bug fix: INR/DCR M (itype=1011) deve operar sobre TMP (valor lido da memória), não sobre A
    alu_a  <= TMP WHEN dec_itype = "1011" ELSE A;
    alu_b  <= read_reg(dec_src, A, B, C, D, E, H, L) WHEN dec_itype = "0000" AND dec_src /= "110" ELSE
              TMP                                      WHEN dec_itype = "0000" AND dec_src = "110" ELSE
              IMM_L                                    WHEN dec_itype = "0001" ELSE
              x"01";  -- for INR/DCR
    alu_op <= dec_op_sel WHEN dec_itype = "0000" OR dec_itype = "0001" ELSE
              "000" WHEN dec_op_sel(0) = '1' ELSE  -- INR -> ADD
              "010";                                -- DCR -> SUB

    rot_op <= dec_op_sel;


    -- Memory address mux
    PROCESS(state, PC, SP, H, L, IMM_L, IMM_H, dec_itype, dec_rp, B, C, D, E)
        VARIABLE hl : STD_LOGIC_VECTOR(15 DOWNTO 0);
    BEGIN
        hl := H & L;
        CASE state IS
            WHEN S_FETCH | S_IMM1 | S_IMM2 =>
                mem_addr <= PC;
            WHEN S_MEM_RD | S_MEM_WR =>
                CASE dec_itype IS
                    WHEN "0011"|"0100"|"1011" => mem_addr <= hl;
                    WHEN "0000" => mem_addr <= hl;  -- Bug fix: ALU M usa endereço HL
                    WHEN "1001" =>
                        IF dec_rp = "00" THEN mem_addr <= B & C;
                        ELSE                  mem_addr <= D & E; END IF;
                    WHEN "1111" => mem_addr <= SP;  -- XTHL: read (SP)
                    WHEN OTHERS => mem_addr <= IMM_H & IMM_L;
                END CASE;
            WHEN S_MEM_RD2 | S_MEM_WR2 =>
                IF IR = x"E3" THEN
                    mem_addr <= STD_LOGIC_VECTOR(UNSIGNED(SP) + 1);  -- XTHL: (SP+1)
                ELSE
                    mem_addr <= STD_LOGIC_VECTOR(UNSIGNED(IMM_H & IMM_L) + 1);
                END IF;
            WHEN S_PUSH_H =>
                mem_addr <= STD_LOGIC_VECTOR(UNSIGNED(SP) - 1);
            WHEN S_PUSH_L =>
                mem_addr <= STD_LOGIC_VECTOR(UNSIGNED(SP) - 1);
            WHEN S_POP_L =>
                mem_addr <= SP;
            WHEN S_POP_H =>
                mem_addr <= SP;
            WHEN OTHERS =>
                mem_addr <= PC;
        END CASE;
    END PROCESS;

    -- Memory write data mux
    PROCESS(state, A, B, C, D, E, H, L, SP, PC, IMM_L, dec_itype, dec_src,
            dec_op_sel, dec_rp, push_h, push_l, fS, fZ, fAC, fP, fCY, TMP)
    BEGIN
        mem_data_out <= x"00";
        mem_wr_en    <= '0';
        CASE state IS
            WHEN S_MEM_WR =>
                mem_wr_en <= '1';
                CASE dec_itype IS
                    WHEN "0100" =>  -- MOV M, r
                        mem_data_out <= read_reg(dec_src, A, B, C, D, E, H, L);
                    WHEN "0110" =>  -- MVI M, d8
                        mem_data_out <= IMM_L;
                    WHEN "1000" =>  -- STA / SHLD (L)
                        IF dec_op_sel = "001" THEN mem_data_out <= A;
                        ELSE                       mem_data_out <= L; END IF;
                    WHEN "1001" =>  -- STAX
                        mem_data_out <= A;
                    WHEN "1011" =>  -- DCR/INR M result stored in TMP after execute
                        mem_data_out <= TMP;
                    WHEN "1111" =>  -- XTHL: write old L to (SP)
                        mem_data_out <= push_l;
                    WHEN OTHERS => NULL;
                END CASE;
            WHEN S_MEM_WR2 =>  -- SHLD high byte (H) or XTHL old H to (SP+1)
                mem_wr_en    <= '1';
                IF (IR = x"E3") THEN
                    mem_data_out <= push_h;
                ELSE
                    mem_data_out <= H;
                    END IF;
            WHEN S_PUSH_H =>
                mem_wr_en    <= '1';
                mem_data_out <= push_h;
            WHEN S_PUSH_L =>
                mem_wr_en    <= '1';
                mem_data_out <= push_l;
            WHEN OTHERS => NULL;
        END CASE;
    END PROCESS;

    -- I/O
    io_addr     <= IMM_L;
    io_data_out <= A;
    io_wr_en    <= '1' WHEN state = S_EXECUTE AND IR = x"D3" ELSE '0';
    io_rd_en    <= '1' WHEN state = S_EXECUTE AND IR = x"DB" ELSE '0';


    -- Main clocked process: FSM + all register updates
    PROCESS(clk, rst)
        VARIABLE v17  : UNSIGNED(16 DOWNTO 0);
        VARIABLE v_rp : STD_LOGIC_VECTOR(15 DOWNTO 0);

        PROCEDURE write_reg8(sel : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
                             val : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) IS
        BEGIN
            CASE sel IS
                WHEN "000" => B <= val;
                WHEN "001" => C <= val;
                WHEN "010" => D <= val;
                WHEN "011" => E <= val;
                WHEN "100" => H <= val;
                WHEN "101" => L <= val;
                WHEN "111" => A <= val;
                WHEN OTHERS => NULL;
            END CASE;
        END PROCEDURE;

        PROCEDURE write_rp(sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
                           val : IN STD_LOGIC_VECTOR(15 DOWNTO 0)) IS
        BEGIN
            CASE sel IS
                WHEN "00" => B <= val(15 DOWNTO 8); C <= val(7 DOWNTO 0);
                WHEN "01" => D <= val(15 DOWNTO 8); E <= val(7 DOWNTO 0);
                WHEN "10" => H <= val(15 DOWNTO 8); L <= val(7 DOWNTO 0);
                WHEN "11" => SP <= val;
                WHEN OTHERS => NULL;
            END CASE;
        END PROCEDURE;

        PROCEDURE set_flags_alu IS
        BEGIN
            fS <= alu_s; fZ <= alu_z; fAC <= alu_ac; fP <= alu_p; fCY <= alu_cy;
        END PROCEDURE;

        PROCEDURE set_flags_no_cy IS  -- INR/DCR: CY unaffected
        BEGIN
            fS <= alu_s; fZ <= alu_z; fAC <= alu_ac; fP <= alu_p;
        END PROCEDURE;

    BEGIN
        IF rst = '1' THEN
            state  <= S_FETCH;
            A <= x"00"; B <= x"00"; C <= x"00"; D <= x"00";
            E <= x"00"; H <= x"00"; L <= x"00";
            SP <= x"0000"; PC <= x"0000";
            fS <= '0'; fZ <= '0'; fAC <= '0'; fP <= '0'; fCY <= '0';
            IR <= x"00"; TMP <= x"00"; W <= x"00";
            IMM_L <= x"00"; IMM_H <= x"00";
            ie_flag <= '0'; mask75 <= '1'; mask65 <= '1'; mask55 <= '1';
            ff75 <= '0'; trap_ff <= '0';
            push_h <= x"00"; push_l <= x"00";

        ELSIF rising_edge(clk) THEN

            -- Interrupt latch updates (every cycle)
            IF trap = '1'  THEN trap_ff <= '1'; END IF;
            IF rst75 = '1' THEN ff75    <= '1'; END IF;

            CASE state IS

                WHEN S_FETCH =>
                    IR  <= mem_data_in;
                    PC  <= STD_LOGIC_VECTOR(UNSIGNED(PC) + 1);
                    state <= S_DECODE;

                WHEN S_DECODE =>
                    IF dec_is_hlt = '1' THEN
                        state <= S_HALT;
                    ELSIF dec_valid = '0' THEN
                        state <= S_FETCH;
                    -- Need 16-bit immediate: LXI, LDA, STA, LHLD, SHLD, JMP, CALL, cond J/C
                    ELSIF (dec_itype = "0111") OR (dec_itype = "1000") OR
                          (dec_itype = "1111" AND (dec_op_sel = "010" OR dec_op_sel = "011") AND IR /= x"E9") THEN
                        state <= S_IMM1;
                    -- Need 8-bit immediate: MVI r, ALU imm, MVI M, IN, OUT
                    ELSIF (dec_itype = "0001") OR (dec_itype = "0101") OR
                          (dec_itype = "0110") OR IR = x"DB" OR IR = x"D3" THEN
                        state <= S_IMM1;
                    -- M operand read: MOV r,M / ALU M / INR M / DCR M
                    ELSIF dec_is_mem = '1' AND dec_itype /= "0100" AND dec_itype /= "1001" THEN
                        state <= S_MEM_RD;
                    -- LDAX: lê memória apontada por BC ou DE
                    ELSIF dec_itype = "1001" AND dec_op_sel(0) = '0' THEN
                        state <= S_MEM_RD;
                    -- XTHL needs two memory reads (SP) and (SP+1)
                    ELSIF IR = x"E3" THEN
                        state <= S_MEM_RD;
                    -- RET condicional: só faz POP se condição satisfeita
                    ELSIF dec_itype = "1111" AND dec_op_sel = "100" THEN
                        IF dec_cond_en = '0' OR cond_met = '1' THEN
                            state <= S_POP_L;
                        ELSE
                            state <= S_FETCH;
                        END IF;
                    -- POP: vai direto para POP_L
                    ELSIF dec_itype = "1111" AND dec_op_sel = "001" THEN
                        state <= S_POP_L;
                    -- LHLD needs two reads
                    ELSIF dec_itype = "1000" AND dec_op_sel = "010" THEN
                        state <= S_IMM1;
                    ELSE
                        state <= S_EXECUTE;
                    END IF;

                WHEN S_IMM1 =>
                    IMM_L <= mem_data_in;
                    PC    <= STD_LOGIC_VECTOR(UNSIGNED(PC) + 1);
                    -- Need second byte?
                    IF (dec_itype = "0111") OR (dec_itype = "1000") OR
                       (dec_itype = "1111" AND (dec_op_sel = "010" OR dec_op_sel = "011") AND IR /= x"E9") THEN
                        state <= S_IMM2;
                    ELSIF dec_itype = "1000" AND dec_op_sel = "010" THEN
                        state <= S_IMM2;  -- LHLD: need addr high
                    ELSE
                        -- MVI M needs a write after
                        IF dec_itype = "0110" THEN state <= S_MEM_WR;
                        ELSE                       state <= S_EXECUTE; END IF;
                    END IF;

                WHEN S_IMM2 =>
                    IMM_H <= mem_data_in;
                    PC    <= STD_LOGIC_VECTOR(UNSIGNED(PC) + 1);
                    -- LDA/LDAX/LHLD need a memory read; STA/STAX/SHLD need a write
                    IF dec_itype = "1000" THEN
                        CASE dec_op_sel IS
                            WHEN "000" => state <= S_MEM_RD;   -- LDA
                            WHEN "001" => state <= S_MEM_WR;   -- STA
                            WHEN "010" => state <= S_MEM_RD;   -- LHLD (L)
                            WHEN "011" => state <= S_MEM_WR;   -- SHLD (L)
                            WHEN OTHERS => state <= S_EXECUTE;
                        END CASE;
                    ELSE
                        state <= S_EXECUTE;
                    END IF;

                WHEN S_MEM_RD =>
                    TMP <= mem_data_in;
                    -- LHLD and XTHL need second read
                    IF (dec_itype = "1000" AND dec_op_sel = "010") OR IR = x"E3" THEN
                        state <= S_MEM_RD2;
                    ELSE
                        -- INR/DCR M: execute then write back
                        IF dec_itype = "1011" THEN state <= S_EXECUTE;
                        ELSE                       state <= S_EXECUTE; END IF;
                    END IF;

                WHEN S_MEM_RD2 =>
                    W     <= mem_data_in;  -- LHLD: H byte
                    state <= S_EXECUTE;

                WHEN S_MEM_WR =>
                    -- SHLD and XTHL need second write
                    IF (dec_itype = "1000" AND dec_op_sel = "011") OR IR = x"E3" THEN
                        state <= S_MEM_WR2;
                    ELSE
                        state <= S_FETCH;
                    END IF;

                WHEN S_MEM_WR2 =>
                    state <= S_FETCH;

                WHEN S_PUSH_H =>
                    SP    <= STD_LOGIC_VECTOR(UNSIGNED(SP) - 1);
                    state <= S_PUSH_L;

                WHEN S_PUSH_L =>
                    SP    <= STD_LOGIC_VECTOR(UNSIGNED(SP) - 1);
                    state <= S_FETCH;

                WHEN S_POP_L =>
                    TMP   <= mem_data_in;
                    SP    <= STD_LOGIC_VECTOR(UNSIGNED(SP) + 1);
                    state <= S_POP_H;

                WHEN S_POP_H =>
                    W     <= mem_data_in;
                    SP    <= STD_LOGIC_VECTOR(UNSIGNED(SP) + 1);
                    -- RET: write to PC; POP: write to rp
                    IF dec_op_sel = "100" THEN  -- RET
                        PC    <= mem_data_in & TMP;
                        state <= S_FETCH;
                    ELSE
                        state <= S_EXECUTE;
                    END IF;

                WHEN S_INT_ACK =>
                    trap_ff <= '0'; ff75 <= '0'; ie_flag <= '0';
                    -- Push PC, jump to vector
                    push_h <= PC(15 DOWNTO 8);
                    push_l <= PC(7 DOWNTO 0);
                    PC     <= x"00" & int_vector;
                    state  <= S_PUSH_H;

                WHEN S_HALT =>
                    IF int_pending = '1' THEN
                        state <= S_INT_ACK;
                    END IF;

                WHEN S_EXECUTE =>

                    CASE dec_itype IS

                        -- ALU reg (src = register or A)
                        WHEN "0000" =>
                            IF dec_op_sel /= "111" THEN A <= alu_result; END IF;  -- CMP: no write
                            set_flags_alu;

                        -- ALU immediate
                        WHEN "0001" =>
                            IF dec_op_sel /= "111" THEN A <= alu_result; END IF;
                            set_flags_alu;

                        -- MOV r1, r2
                        WHEN "0010" =>
                            write_reg8(dec_dst, read_reg(dec_src, A, B, C, D, E, H, L));

                        -- MOV r, M
                        WHEN "0011" =>
                            write_reg8(dec_dst, TMP);

                        -- MVI r, d8
                        WHEN "0101" =>
                            write_reg8(dec_dst, IMM_L);

                        -- LXI rp, d16
                        WHEN "0111" =>
                            write_rp(dec_rp, IMM_H & IMM_L);

                        -- LDA
                        WHEN "1000" =>
                            CASE dec_op_sel IS
                                WHEN "000" => A <= TMP;           -- LDA
                                WHEN "010" => L <= TMP; H <= W;   -- LHLD
                                WHEN OTHERS => NULL;
                            END CASE;

                        -- LDAX
                        WHEN "1001" =>
                            IF dec_op_sel(0) = '0' THEN A <= TMP; END IF;

                        -- INR / DCR reg
                        WHEN "1010" =>
                            write_reg8(dec_dst, alu_result);
                            set_flags_no_cy;

                        -- INR / DCR M (result goes back to memory via S_MEM_WR)
                        WHEN "1011" =>
                            TMP   <= alu_result;
                            set_flags_no_cy;
                            state <= S_MEM_WR;  -- override next state

                        -- INX / DCX
                        WHEN "1100" =>
                            v_rp := read_rp(dec_rp, B, C, D, E, H, L, SP);
                            IF dec_op_sel(0) = '1' THEN
                                write_rp(dec_rp, STD_LOGIC_VECTOR(UNSIGNED(v_rp) + 1));
                            ELSE
                                write_rp(dec_rp, STD_LOGIC_VECTOR(UNSIGNED(v_rp) - 1));
                            END IF;

                        -- DAD rp: HL = HL + rp
                        WHEN "1101" =>
                            v_rp := read_rp(dec_rp, B, C, D, E, H, L, SP);
                            v17  := ('0' & UNSIGNED(H & L)) + ('0' & UNSIGNED(v_rp));
                            H    <= STD_LOGIC_VECTOR(v17(15 DOWNTO 8));
                            L    <= STD_LOGIC_VECTOR(v17(7 DOWNTO 0));
                            fCY  <= v17(16);

                        -- Rotate / CMA / CMC / STC / DAA
                        WHEN "1110" =>
                            A    <= rot_result;
                            fCY  <= rot_cy;
                            fAC  <= rot_ac;

                        -- Misc / jump / call / ret / push / pop / IO
                        WHEN "1111" =>

                            -- JMP / conditional JMP
                            IF dec_op_sel = "010" THEN
                                IF IR = x"E9" THEN  -- PCHL
                                    PC <= H & L;
                                ELSIF dec_cond_en = '0' OR cond_met = '1' THEN
                                    PC <= IMM_H & IMM_L;
                                END IF;

                            -- CALL / conditional CALL
                            ELSIF dec_op_sel = "011" THEN
                                IF dec_cond_en = '0' OR cond_met = '1' THEN
                                    push_h <= PC(15 DOWNTO 8);
                                    push_l <= PC(7 DOWNTO 0);
                                    PC     <= IMM_H & IMM_L;
                                    state  <= S_PUSH_H;
                                END IF;

                            -- RST n
                            ELSIF dec_op_sel = "101" THEN
                                push_h <= PC(15 DOWNTO 8);
                                push_l <= PC(7 DOWNTO 0);
                                PC     <= x"00" & "00" & dec_dst & "000";
                                state  <= S_PUSH_H;

                            -- PUSH rp (data staged in S_PUSH_H/L)
                            ELSIF dec_op_sel = "000" THEN
                                IF dec_rp = "11" THEN  -- PUSH PSW
                                    push_h <= A;
                                    -- Bug fix: formato real do PSW: S Z 0 AC 0 P 1 CY
                                    push_l <= fS & fZ & '0' & fAC & '0' & fP & '1' & fCY;
                                ELSE
                                    v_rp   := read_rp(dec_rp, B, C, D, E, H, L, SP);
                                    push_h <= v_rp(15 DOWNTO 8);
                                    push_l <= v_rp(7 DOWNTO 0);
                                END IF;
                                state <= S_PUSH_H;

                            -- POP rp (W=high, TMP=low already loaded)
                            ELSIF dec_op_sel = "001" THEN
                                IF dec_rp = "11" THEN  -- POP PSW
                                    A   <= W;
                                    -- Bug fix: formato real do PSW: S Z 0 AC 0 P 1 CY
                                    fS  <= TMP(7); fZ  <= TMP(6);
                                    fAC <= TMP(4); fP  <= TMP(2); fCY <= TMP(0);
                                ELSE
                                    write_rp(dec_rp, W & TMP);
                                END IF;

                            -- XCHG: swap DE <-> HL
                            ELSIF IR = x"EB" THEN
                                D <= H; E <= L; H <= D; L <= E;

                            -- SPHL: SP = HL
                            ELSIF IR = x"F9" THEN
                                SP <= H & L;

                            -- XTHL: swap HL with (SP) — TMP=(SP), W=(SP+1) already loaded
                            ELSIF IR = x"E3" THEN
                                push_h <= H;  -- old H goes to (SP+1)
                                push_l <= L;  -- old L goes to (SP)
                                H <= W; L <= TMP;
                                state <= S_MEM_WR;

                            -- EI / DI
                            ELSIF IR = x"FB" THEN ie_flag <= '1';
                            ELSIF IR = x"F3" THEN ie_flag <= '0';

                            -- RIM: Bug fix: formato correto SID(0) | IE | M7.5 | M6.5 | M5.5 | R7.5 | 0 | INTR
                            ELSIF IR = x"20" THEN
                                A <= '0' & ie_flag & mask75 & mask65 & mask55 & rim_p75_sig & '0' & intr;

                            -- SIM
                            ELSIF IR = x"30" THEN
                                IF A(3) = '1' THEN
                                    mask75 <= A(2);
                                    mask65 <= A(1);
                                    mask55 <= A(0);
                                END IF;
                                IF A(4) = '1' THEN ff75 <= '0'; END IF;

                            -- IN port
                            ELSIF IR = x"DB" THEN
                                A <= io_data_in;

                            -- OUT port: handled combinationally (io_wr_en)
                            ELSE NULL;
                            END IF;

                        WHEN OTHERS => NULL;
                    END CASE;

                    -- Default next state after execute (may be overridden above)
                    IF state = S_EXECUTE AND
                       NOT (dec_itype = "1111" AND (dec_op_sel = "101" OR IR = x"E3")) AND
                       NOT (dec_itype = "1111" AND dec_op_sel = "011" AND (dec_cond_en = '0' OR cond_met = '1')) AND
                       NOT (dec_itype = "1111" AND dec_op_sel = "000") AND
                       NOT (dec_itype = "1011") THEN
                        IF int_pending = '1' AND ie_flag = '1' THEN
                            state <= S_INT_ACK;
                        ELSE
                            state <= S_FETCH;
                        END IF;
                    END IF;

            END CASE;
        END IF;
    END PROCESS;

    -- RIM helper signal
    rim_p75_sig <= ff75;

    -- Debug outputs
    acc_out   <= A;
    flags_out <= fS & fZ & fAC & fP & fCY;
    pc_out    <= PC;
    halted    <= '1' WHEN state = S_HALT ELSE '0';

    PROCESS(state)
    BEGIN
        CASE state IS
            WHEN S_FETCH    => state_out <= "0000";
            WHEN S_DECODE   => state_out <= "0001";
            WHEN S_IMM1     => state_out <= "0010";
            WHEN S_IMM2     => state_out <= "0011";
            WHEN S_MEM_RD   => state_out <= "0100";
            WHEN S_MEM_RD2  => state_out <= "0101";
            WHEN S_MEM_WR   => state_out <= "0110";
            WHEN S_MEM_WR2  => state_out <= "0111";
            WHEN S_EXECUTE  => state_out <= "1000";
            WHEN S_PUSH_H   => state_out <= "1001";
            WHEN S_PUSH_L   => state_out <= "1010";
            WHEN S_POP_L    => state_out <= "1011";
            WHEN S_POP_H    => state_out <= "1100";
            WHEN S_INT_ACK  => state_out <= "1101";
            WHEN S_HALT     => state_out <= "1111";
            WHEN OTHERS     => state_out <= "0000";
        END CASE;
    END PROCESS;

END ARCHITECTURE rtl;
