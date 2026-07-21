LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY MCS8085FPGA IS

	PORT(
	
		clk        : IN  STD_LOGIC;
		ready      : IN  STD_LOGIC;
		rst_in     : IN  STD_LOGIC;
		
		status_s0  : OUT STD_LOGIC;
		status_s1  : OUT STD_LOGIC;
		status_iom : OUT STD_LOGIC;
		
		ale        : OUT STD_LOGIC;
		ctr_rd     : OUT STD_LOGIC;
		ctr_wr     : OUT STD_LOGIC;
		
		dma_hold   : IN  STD_LOGIC;
		dma_hlda   : OUT STD_LOGIC;
		
		ic_intr    : IN  STD_LOGIC;
		ic_inta    : OUT STD_LOGIC;
		ic_rst55   : OUT STD_LOGIC;
		ic_rst65   : OUT STD_LOGIC;
		ic_rst75   : OUT STD_LOGIC;
		ic_trap    : OUT STD_LOGIC;
		
		sio_sid    : IN  STD_LOGIC;
		sio_sod    : OUT STD_LOGIC;
		
		a          : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		din        : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
		dout       : OUT STD_LOGIC_VECTOR( 7 DOWNTO 0)
	
	);
	
END ENTITY;

ARCHITECTURE MCS8085FPGA_LOGIC OF MCS8085FPGA IS

	SIGNAL reg_to_buffer: STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN

	REG_ARRAY: ENTITY WORK.register_array PORT MAP(reg_clk => clk, reg_rst, reg_sel, reg_wr_en, reg8_data_in, reg8_data_out, reg16_en, reg16_op, reg16_data_in, reg16_data_out => reg_to_buffer);
	
END ARCHITECTURE;
		