LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

------------------------------------------------------------------------------------------
-- Testbench: MCS8085FPGA
--
-- Loads a small program into memory and runs the CPU.
-- Modify the `mem` initialization in memory_8085.vhd to change the program.
--
-- Default program (NOP, NOP, HLT) just verifies fetch/decode/halt cycle.
-- Replace with a real program to test the full instruction set.
------------------------------------------------------------------------------------------

ENTITY tb_cpu_8085 IS
END ENTITY;

ARCHITECTURE sim OF tb_cpu_8085 IS

    SIGNAL clk         : STD_LOGIC := '0';
    SIGNAL rst         : STD_LOGIC := '1';

    SIGNAL mem_addr    : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL mem_din     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mem_dout    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mem_wr      : STD_LOGIC;

    SIGNAL io_addr     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL io_din      : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"42";  -- Port 0 input = 0x42
    SIGNAL io_dout     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL io_wr       : STD_LOGIC;
    SIGNAL io_rd       : STD_LOGIC;

    SIGNAL acc_dbg     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL flags_dbg   : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL pc_dbg      : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL halted      : STD_LOGIC;
    SIGNAL state_out   : STD_LOGIC_VECTOR(3 DOWNTO 0);

    CONSTANT CLK_PERIOD : TIME := 20 ns;

BEGIN

    clk <= NOT clk AFTER CLK_PERIOD / 2;

    -- Release reset after 3 clock cycles
    PROCESS
    BEGIN
        rst <= '1';
        WAIT FOR CLK_PERIOD * 3;
        rst <= '0';
        WAIT;
    END PROCESS;

    CPU : ENTITY work.cpu_8085(rtl)
        PORT MAP (
            clk          => clk,
            rst          => rst,
            mem_addr     => mem_addr,
            mem_data_in  => mem_din,
            mem_data_out => mem_dout,
            mem_wr_en    => mem_wr,
            io_addr      => io_addr,
            io_data_in   => io_din,
            io_data_out  => io_dout,
            io_wr_en     => io_wr,
            io_rd_en     => io_rd,
            trap         => '0',
            rst75        => '0',
            rst65        => '0',
            rst55        => '0',
            intr         => '0',
            acc_out      => acc_dbg,
            flags_out    => flags_dbg,
            pc_out       => pc_dbg,
            halted       => halted,
            state_out    => state_out
        );

    MEM : ENTITY work.memory_8085(rtl)
        PORT MAP (
            mem_clk      => clk,
            mem_addr     => mem_addr,
            mem_data_in  => mem_dout,
            mem_data_out => mem_din,
            mem_wr_en    => mem_wr
        );

    -- Stop simulation when CPU halts or after timeout
    PROCESS
    BEGIN
        WAIT UNTIL halted = '1' OR NOW > 10 us;

        ASSERT halted = '1'
            REPORT "TIMEOUT: CPU did not halt within 10us" SEVERITY WARNING;

        -- Expected results for program: NOP, NOP, HLT
        ASSERT acc_dbg = x"00"
            REPORT "FAIL: ACC expected 00h, got " & INTEGER'IMAGE(TO_INTEGER(UNSIGNED(acc_dbg)))
            SEVERITY ERROR;

        ASSERT flags_dbg = "00000"
            REPORT "FAIL: FLAGS expected 00000, got " & INTEGER'IMAGE(TO_INTEGER(UNSIGNED(flags_dbg)))
            SEVERITY ERROR;

        ASSERT pc_dbg = x"0003"
            REPORT "FAIL: PC expected 0003h, got " & INTEGER'IMAGE(TO_INTEGER(UNSIGNED(pc_dbg)))
            SEVERITY ERROR;

        REPORT "Simulation ended. ACC=" & INTEGER'IMAGE(TO_INTEGER(UNSIGNED(acc_dbg))) &
               " PC=" & INTEGER'IMAGE(TO_INTEGER(UNSIGNED(pc_dbg)))
            SEVERITY NOTE;
        WAIT;
    END PROCESS;

END ARCHITECTURE;
