LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------
-- Module: 8085 I/O Ports
--
-- 256 output ports and 256 input ports, all 8-bit wide.
-- OUT instruction writes to out_ports; IN instruction reads from in_ports.
-- in_ports can be driven externally (testbench or FPGA pins).
------------------------------------------------------------------------------------------

ENTITY io_ports_8085 IS
    PORT (
        io_clk      : IN  STD_LOGIC;
        io_rst      : IN  STD_LOGIC;

        io_addr     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        io_data_in  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        io_data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        io_wr_en    : IN  STD_LOGIC;
        io_rd_en    : IN  STD_LOGIC;

        -- External connections (testbench / FPGA pins)
        in_ports    : IN  STD_LOGIC_VECTOR(2047 DOWNTO 0);  -- 256 x 8-bit input ports
        out_ports   : OUT STD_LOGIC_VECTOR(2047 DOWNTO 0)   -- 256 x 8-bit output ports
    );
END ENTITY;

ARCHITECTURE rtl OF io_ports_8085 IS

    TYPE port_array IS ARRAY(0 TO 255) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL out_regs : port_array;

BEGIN

    -- Write to output port
    PROCESS(io_clk, io_rst)
    BEGIN
        IF io_rst = '1' THEN
            out_regs <= (OTHERS => (OTHERS => '0'));
        ELSIF rising_edge(io_clk) THEN
            IF io_wr_en = '1' THEN
                out_regs(TO_INTEGER(UNSIGNED(io_addr))) <= io_data_in;
            END IF;
        END IF;
    END PROCESS;

    -- Read from input port (combinational)
    PROCESS(io_rd_en, io_addr, in_ports)
        VARIABLE idx : INTEGER;
    BEGIN
        IF io_rd_en = '1' THEN
            idx := TO_INTEGER(UNSIGNED(io_addr));
            io_data_out <= in_ports(idx * 8 + 7 DOWNTO idx * 8);
        ELSE
            io_data_out <= (OTHERS => '0');
        END IF;
    END PROCESS;

    -- Flatten out_regs to output vector
    GEN_OUT : FOR i IN 0 TO 255 GENERATE
        out_ports(i * 8 + 7 DOWNTO i * 8) <= out_regs(i);
    END GENERATE;

END ARCHITECTURE;
