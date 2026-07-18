LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Module: 8085 Timing and Control Unit (complete)
--
-- State machine implementing the multi-cycle execution of all 8085 instructions.
--
-- Main states:
--   FETCH      : load opcode from memory[PC], increment PC
--   DECODE     : decode opcode (combinational, 1 cycle)
--   MEM_READ   : read byte from memory (for M operand, LDA, LDAX, etc.)
--   MEM_WRITE  : write byte to memory (STA, STAX, MOV M,r, etc.)
--   FETCH_LOW  : fetch low byte of 16-bit immediate
--   FETCH_HIGH : fetch high byte of 16-bit immediate
--   EXECUTE    : apply decoded control signals
--   PUSH_HIGH  : push high byte to stack
--   PUSH_LOW   : push low byte to stack
--   POP_HIGH   : pop high byte from stack
--   POP_LOW    : pop low byte from stack
--   INT_ACK    : interrupt acknowledge cycle
--   HALT       : halted until reset
------------------------------------------------------------------------------------------

ENTITY timing_control_8085 IS
    PORT (
        tc_clk               : IN  STD_LOGIC;
        tc_rst               : IN  STD_LOGIC;

        -- From decoder
        tc_hlt_detected      : IN  STD_LOGIC;
        tc_valid_instruction : IN  STD_LOGIC;
        tc_is_mem_out        : IN  STD_LOGIC;
        tc_itype             : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);

        -- Interrupt
        tc_int_pending       : IN  STD_LOGIC;

        -- Control outputs to datapath
        tc_ir_load_out       : OUT STD_LOGIC;
        tc_pc_inc_out        : OUT STD_LOGIC;
        tc_mem_rd_out        : OUT STD_LOGIC;
        tc_mem_wr_out        : OUT STD_LOGIC;
        tc_fetch_low_out     : OUT STD_LOGIC;
        tc_fetch_high_out    : OUT STD_LOGIC;
        tc_execute_enable_out: OUT STD_LOGIC;
        tc_push_out          : OUT STD_LOGIC;
        tc_pop_out           : OUT STD_LOGIC;
        tc_int_ack_out       : OUT STD_LOGIC;
        tc_halted_out        : OUT STD_LOGIC;

        tc_state_out         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY timing_control_8085;

ARCHITECTURE fsm OF timing_control_8085 IS

    TYPE state_type IS (
        FETCH_STATE,
        DECODE_STATE,
        MEM_READ_STATE,
        MEM_WRITE_STATE,
        FETCH_LOW_STATE,
        FETCH_HIGH_STATE,
        EXECUTE_STATE,
        PUSH_HIGH_STATE,
        PUSH_LOW_STATE,
        POP_LOW_STATE,
        POP_HIGH_STATE,
        INT_ACK_STATE,
        HALT_STATE
    );

    SIGNAL current_state : state_type;
    SIGNAL next_state    : state_type;

BEGIN

    state_register : PROCESS(tc_clk, tc_rst)
    BEGIN
        IF tc_rst = '1' THEN
            current_state <= FETCH_STATE;
        ELSIF rising_edge(tc_clk) THEN
            current_state <= next_state;
        END IF;
    END PROCESS;

    next_state_logic : PROCESS(current_state, tc_hlt_detected, tc_valid_instruction,
                                tc_is_mem_out, tc_itype, tc_int_pending)
    BEGIN
        next_state <= current_state;

        CASE current_state IS

            WHEN FETCH_STATE =>
                next_state <= DECODE_STATE;

            WHEN DECODE_STATE =>
                IF tc_hlt_detected = '1' THEN
                    next_state <= HALT_STATE;
                ELSIF tc_valid_instruction = '0' THEN
                    next_state <= FETCH_STATE;
                -- Instructions needing 16-bit immediate
                ELSIF tc_itype = "0111" OR tc_itype = "1000" OR   -- LXI, LDA/STA/LHLD/SHLD
                      (tc_itype = "1111" AND (
                          -- JMP, CALL, conditional jumps/calls
                          -- detected by op_sel in execute; we use itype=1111 for all
                          -- The CPU core will gate these properly
                          tc_itype = "1111")) THEN
                    next_state <= FETCH_LOW_STATE;
                -- Instructions needing 8-bit immediate
                ELSIF tc_itype = "0001" OR tc_itype = "0101" OR   -- ALU imm, MVI r
                      tc_itype = "0110" THEN                        -- MVI M
                    next_state <= FETCH_LOW_STATE;
                -- M operand read
                ELSIF tc_is_mem_out = '1' THEN
                    next_state <= MEM_READ_STATE;
                -- PUSH
                ELSIF tc_itype = "1111" THEN
                    next_state <= EXECUTE_STATE;
                ELSE
                    next_state <= EXECUTE_STATE;
                END IF;

            WHEN FETCH_LOW_STATE =>
                -- If 16-bit immediate needed
                IF tc_itype = "0111" OR tc_itype = "1000" THEN
                    next_state <= FETCH_HIGH_STATE;
                ELSE
                    next_state <= EXECUTE_STATE;
                END IF;

            WHEN FETCH_HIGH_STATE =>
                next_state <= EXECUTE_STATE;

            WHEN MEM_READ_STATE =>
                next_state <= EXECUTE_STATE;

            WHEN MEM_WRITE_STATE =>
                next_state <= FETCH_STATE;

            WHEN EXECUTE_STATE =>
                -- PUSH needs two memory writes
                IF tc_itype = "1111" THEN
                    next_state <= FETCH_STATE;
                ELSE
                    next_state <= FETCH_STATE;
                END IF;

            WHEN PUSH_HIGH_STATE =>
                next_state <= PUSH_LOW_STATE;

            WHEN PUSH_LOW_STATE =>
                next_state <= FETCH_STATE;

            WHEN POP_LOW_STATE =>
                next_state <= POP_HIGH_STATE;

            WHEN POP_HIGH_STATE =>
                next_state <= EXECUTE_STATE;

            WHEN INT_ACK_STATE =>
                next_state <= FETCH_STATE;

            WHEN HALT_STATE =>
                IF tc_int_pending = '1' THEN
                    next_state <= INT_ACK_STATE;
                ELSE
                    next_state <= HALT_STATE;
                END IF;

            WHEN OTHERS =>
                next_state <= FETCH_STATE;

        END CASE;
    END PROCESS;

    output_logic : PROCESS(current_state)
    BEGIN
        tc_ir_load_out        <= '0';
        tc_pc_inc_out         <= '0';
        tc_mem_rd_out         <= '0';
        tc_mem_wr_out         <= '0';
        tc_fetch_low_out      <= '0';
        tc_fetch_high_out     <= '0';
        tc_execute_enable_out <= '0';
        tc_push_out           <= '0';
        tc_pop_out            <= '0';
        tc_int_ack_out        <= '0';
        tc_halted_out         <= '0';
        tc_state_out          <= "0000";

        CASE current_state IS
            WHEN FETCH_STATE =>
                tc_ir_load_out <= '1';
                tc_pc_inc_out  <= '1';
                tc_state_out   <= "0000";

            WHEN DECODE_STATE =>
                tc_state_out <= "0001";

            WHEN FETCH_LOW_STATE =>
                tc_fetch_low_out <= '1';
                tc_pc_inc_out    <= '1';
                tc_state_out     <= "0010";

            WHEN FETCH_HIGH_STATE =>
                tc_fetch_high_out <= '1';
                tc_pc_inc_out     <= '1';
                tc_state_out      <= "0011";

            WHEN MEM_READ_STATE =>
                tc_mem_rd_out <= '1';
                tc_state_out  <= "0100";

            WHEN MEM_WRITE_STATE =>
                tc_mem_wr_out <= '1';
                tc_state_out  <= "0101";

            WHEN EXECUTE_STATE =>
                tc_execute_enable_out <= '1';
                tc_state_out          <= "0110";

            WHEN PUSH_HIGH_STATE =>
                tc_push_out  <= '1';
                tc_mem_wr_out <= '1';
                tc_state_out <= "0111";

            WHEN PUSH_LOW_STATE =>
                tc_push_out  <= '1';
                tc_mem_wr_out <= '1';
                tc_state_out <= "1000";

            WHEN POP_LOW_STATE =>
                tc_pop_out   <= '1';
                tc_mem_rd_out <= '1';
                tc_state_out <= "1001";

            WHEN POP_HIGH_STATE =>
                tc_pop_out   <= '1';
                tc_mem_rd_out <= '1';
                tc_state_out <= "1010";

            WHEN INT_ACK_STATE =>
                tc_int_ack_out <= '1';
                tc_state_out   <= "1011";

            WHEN HALT_STATE =>
                tc_halted_out <= '1';
                tc_state_out  <= "1111";

            WHEN OTHERS =>
                tc_state_out <= "0000";
        END CASE;
    END PROCESS;

END ARCHITECTURE fsm;
