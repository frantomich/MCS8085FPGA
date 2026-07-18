LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY tmp_reg IS

	PORT(
		
		tmp_reg_clk: IN STD_LOGIC;
		tmp_reg_rst: IN STD_LOGIC;
		tmp_reg_load: IN STD_LOGIC;
		tmp_reg_data_in: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		tmp_reg_data_out: OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		
	);
	
END ENTITY;

ARCHITECTURE tmp_reg_logic OF tmp_reg IS

	SIGNAL reg: STD_LOGIC_VECTOR(7 DOWNTO 0);
	
BEGIN

	PROCESS(tmp_reg_clk, tmp_reg_rst)
	BEGIN
		
		IF tmp_reg_rst = '1' THEN
			reg <= (OTHERS => '0');
		ELSIF rising_edge(tmp_reg_clk) THEN
			IF tmp_reg_load = '1' THEN
				reg <= tmp_reg_data_in;
			END IF;
		END IF;
		
	END PROCESS;
	
	tmp_reg_data_out <= reg;

END ARCHITECTURE;