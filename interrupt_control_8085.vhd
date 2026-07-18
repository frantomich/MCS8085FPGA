LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Module: 8085 Interrupt Controller
--
-- Handles: TRAP (NMI), RST 5.5, RST 6.5, RST 7.5, INTR
-- Priority (highest to lowest): TRAP > RST7.5 > RST6.5 > RST5.5 > INTR
--
-- Outputs:
--   int_pending    : an interrupt is pending and CPU is not halted/disabled
--   int_vector     : RST vector address (low byte) to push onto the bus
--   int_ack        : CPU pulses this to acknowledge and clear the interrupt
------------------------------------------------------------------------------------------

ENTITY interrupt_control_8085 IS
    PORT (
        ic_clk      : IN  STD_LOGIC;
        ic_rst      : IN  STD_LOGIC;

        -- Interrupt inputs
        trap        : IN  STD_LOGIC;  -- Non-maskable, edge+level
        rst75       : IN  STD_LOGIC;  -- Maskable, edge-triggered
        rst65       : IN  STD_LOGIC;  -- Maskable, level-triggered
        rst55       : IN  STD_LOGIC;  -- Maskable, level-triggered
        intr        : IN  STD_LOGIC;  -- Maskable, level-triggered

        -- Interrupt enable control (from EI/DI instructions)
        ei          : IN  STD_LOGIC;  -- Enable interrupts
        di          : IN  STD_LOGIC;  -- Disable interrupts

        -- SIM instruction mask bits
        sim_load    : IN  STD_LOGIC;
        sim_m75     : IN  STD_LOGIC;  -- Mask RST7.5
        sim_m65     : IN  STD_LOGIC;  -- Mask RST6.5
        sim_m55     : IN  STD_LOGIC;  -- Mask RST5.5
        sim_r75     : IN  STD_LOGIC;  -- Reset RST7.5 flip-flop

        -- RIM outputs (read interrupt masks)
        rim_ie      : OUT STD_LOGIC;
        rim_m75     : OUT STD_LOGIC;
        rim_m65     : OUT STD_LOGIC;
        rim_m55     : OUT STD_LOGIC;
        rim_p75     : OUT STD_LOGIC;  -- RST7.5 pending flip-flop

        -- To CPU
        int_pending : OUT STD_LOGIC;
        int_vector  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        int_ack     : IN  STD_LOGIC
    );
END ENTITY;

ARCHITECTURE rtl OF interrupt_control_8085 IS

    SIGNAL ie_flag  : STD_LOGIC;                    -- Interrupt Enable flip-flop
    SIGNAL mask75, mask65, mask55 : STD_LOGIC;      -- Interrupt masks
    SIGNAL ff75     : STD_LOGIC;                    -- RST7.5 edge flip-flop
    SIGNAL trap_ff  : STD_LOGIC;                    -- TRAP latch

BEGIN

    PROCESS(ic_clk, ic_rst)
    BEGIN
        IF ic_rst = '1' THEN
            ie_flag  <= '0';
            mask75   <= '1';
            mask65   <= '1';
            mask55   <= '1';
            ff75     <= '0';
            trap_ff  <= '0';

        ELSIF rising_edge(ic_clk) THEN

            -- EI / DI
            IF ei = '1' THEN ie_flag <= '1'; END IF;
            IF di = '1' THEN ie_flag <= '0'; END IF;

            -- SIM
            IF sim_load = '1' THEN
                mask75 <= sim_m75;
                mask65 <= sim_m65;
                mask55 <= sim_m55;
                IF sim_r75 = '1' THEN ff75 <= '0'; END IF;
            END IF;

            -- RST7.5 edge latch
            IF rst75 = '1' THEN ff75 <= '1'; END IF;
            IF int_ack = '1' THEN ff75 <= '0'; END IF;

            -- TRAP latch (set on rising edge, cleared on ack)
            IF trap = '1' THEN trap_ff <= '1'; END IF;
            IF int_ack = '1' THEN trap_ff <= '0'; END IF;

        END IF;
    END PROCESS;

    -- Priority encoder + vector generation (combinational)
    PROCESS(trap_ff, ff75, mask75, rst65, mask65, rst55, mask55, intr, ie_flag)
    BEGIN
        int_pending <= '0';
        int_vector  <= x"00";

        IF trap_ff = '1' THEN
            int_pending <= '1';
            int_vector  <= x"24";  -- RST 4.5 -> 0x0024

        ELSIF ie_flag = '1' THEN

            IF ff75 = '1' AND mask75 = '0' THEN
                int_pending <= '1';
                int_vector  <= x"3C";  -- RST 7.5 -> 0x003C

            ELSIF rst65 = '1' AND mask65 = '0' THEN
                int_pending <= '1';
                int_vector  <= x"34";  -- RST 6.5 -> 0x0034

            ELSIF rst55 = '1' AND mask55 = '0' THEN
                int_pending <= '1';
                int_vector  <= x"2C";  -- RST 5.5 -> 0x002C

            ELSIF intr = '1' THEN
                int_pending <= '1';
                int_vector  <= x"00";  -- Vector supplied externally via data bus

            END IF;
        END IF;
    END PROCESS;

    rim_ie  <= ie_flag;
    rim_m75 <= mask75;
    rim_m65 <= mask65;
    rim_m55 <= mask55;
    rim_p75 <= ff75;

END ARCHITECTURE;
