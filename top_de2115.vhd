LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

------------------------------------------------------------------------------------------
-- Module: DE2-115 Top-Level for MCS8085FPGA
--
-- KEY(0)           -> Clock (manual step) or use internal PLL
-- KEY(1)           -> Reset (active-low)
-- SW(2 DOWNTO 0)   -> Register select for display (000=ACC, 001=B, 010=C, ...)
-- SW(17)           -> 0 = show register, 1 = show PC
-- LEDR(7 DOWNTO 0) -> Selected register / PC low byte
-- LEDR(17)         -> Halted
-- LEDR(16)         -> State bit 0
-- LEDR(15)         -> State bit 1
-- HEX0-HEX1       -> ACC in hex
-- HEX2-HEX3       -> PC low byte in hex
-- HEX4-HEX5       -> PC high byte in hex
------------------------------------------------------------------------------------------

ENTITY top_de2115 IS
    PORT (
        CLOCK_50 : IN  STD_LOGIC;
        KEY      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        SW       : IN  STD_LOGIC_VECTOR(17 DOWNTO 0);
        LEDR     : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
        HEX0     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX1     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX2     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX3     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX4     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX5     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE structural OF top_de2115 IS

    SIGNAL clk_cpu    : STD_LOGIC;
    SIGNAL rst        : STD_LOGIC;

    SIGNAL mem_addr   : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL mem_din    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mem_dout   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mem_wr     : STD_LOGIC;

    SIGNAL io_addr    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL io_din     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL io_dout    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL io_wr      : STD_LOGIC;
    SIGNAL io_rd      : STD_LOGIC;

    SIGNAL acc_dbg    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL flags_dbg  : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL pc_dbg     : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL halted_dbg : STD_LOGIC;
    SIGNAL state_dbg  : STD_LOGIC_VECTOR(3 DOWNTO 0);

    -- 7-segment decoder function
    FUNCTION to_7seg(nibble : STD_LOGIC_VECTOR(3 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
        VARIABLE seg : STD_LOGIC_VECTOR(6 DOWNTO 0);
    BEGIN
        CASE nibble IS
            WHEN x"0" => seg := "1000000";
            WHEN x"1" => seg := "1111001";
            WHEN x"2" => seg := "0100100";
            WHEN x"3" => seg := "0110000";
            WHEN x"4" => seg := "0011001";
            WHEN x"5" => seg := "0010010";
            WHEN x"6" => seg := "0000010";
            WHEN x"7" => seg := "1111000";
            WHEN x"8" => seg := "0000000";
            WHEN x"9" => seg := "0010000";
            WHEN x"A" => seg := "0001000";
            WHEN x"B" => seg := "0000011";
            WHEN x"C" => seg := "1000110";
            WHEN x"D" => seg := "0100001";
            WHEN x"E" => seg := "0000110";
            WHEN x"F" => seg := "0001110";
            WHEN OTHERS => seg := "1111111";
        END CASE;
        RETURN seg;
    END FUNCTION;

BEGIN

    -- Use manual clock from KEY(0) (active-low button)
    clk_cpu <= NOT KEY(0);
    rst     <= NOT KEY(1);

    CPU : ENTITY work.cpu_8085(rtl)  -- architecture name matches cpu_8085.vhd
        PORT MAP (
            clk          => clk_cpu,
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
            halted       => halted_dbg,
            state_out    => state_dbg
        );

    MEM : ENTITY work.memory_8085(rtl)
        PORT MAP (
            mem_clk      => clk_cpu,
            mem_addr     => mem_addr,
            mem_data_in  => mem_dout,
            mem_data_out => mem_din,
            mem_wr_en    => mem_wr
        );

    -- I/O: SW(7:0) drives port 0 input; no output ports connected to pins
    io_din <= SW(7 DOWNTO 0) WHEN io_addr = x"00" ELSE x"00";

    -- LED display
    LEDR(7 DOWNTO 0)  <= acc_dbg WHEN SW(17) = '0' ELSE pc_dbg(7 DOWNTO 0);
    LEDR(12 DOWNTO 8) <= flags_dbg;
    LEDR(15 DOWNTO 13) <= (OTHERS => '0');
    LEDR(16)           <= state_dbg(0);
    LEDR(17)           <= halted_dbg;

    -- 7-segment: HEX1-HEX0 = ACC, HEX3-HEX2 = PC low, HEX5-HEX4 = PC high
    HEX0 <= to_7seg(acc_dbg(3 DOWNTO 0));
    HEX1 <= to_7seg(acc_dbg(7 DOWNTO 4));
    HEX2 <= to_7seg(pc_dbg(3 DOWNTO 0));
    HEX3 <= to_7seg(pc_dbg(7 DOWNTO 4));
    HEX4 <= to_7seg(pc_dbg(11 DOWNTO 8));
    HEX5 <= to_7seg(pc_dbg(15 DOWNTO 12));

END ARCHITECTURE;
