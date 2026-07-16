LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY register_array IS

	PORT(
	
		reg_clk: IN STD_LOGIC;                               --Clock.
		reg_rst: IN STD_LOGIC;                               --Reset.
		
		reg_sel: IN STD_LOGIC_VECTOR(2 DOWNTO 0);            --Seleçao do registrador (3 bits).
		reg_wr_en: IN STD_LOGIC;                             --Habilitaçao da escrita.
		
		reg8_data_in: IN STD_LOGIC_VECTOR(7 DOWNTO 0);       --Barramento de entrada simples(8 bits).
		reg8_data_out: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);     --Barramento de saida simples(8 bits).
		
		reg16_en: IN STD_LOGIC;                              --Habilitaçao do acesso duplo.
		reg16_op: IN STD_LOGIC_VECTOR(1 DOWNTO 0);           --Operaçao a ser executada no registrador duplo (2 bits).
		reg16_data_in: IN STD_LOGIC_VECTOR(15 DOWNTO 0);     --Barramento de entrada dupla (16 bits).
		reg16_data_out: OUT STD_LOGIC_VECTOR(15 DOWNTO 0)    --Barramento de saida dupla (16 bits).
		
	);
	
END ENTITY;

ARCHITECTURE register_array_logic OF register_array IS

	SIGNAL reg_b, reg_c, reg_d, reg_e, reg_h, reg_l: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL reg_sp, reg_pc: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL reg16_sel_value, reg16_new_value: UNSIGNED(15 DOWNTO 0);
	
BEGIN

	PROCESS(reg_sel, reg16_en, reg_b, reg_c, reg_d, reg_e, reg_h, reg_l, reg_sp, reg_pc)
	BEGIN
	
		IF reg16_en = '0' THEN
			CASE reg_sel IS
				WHEN "000" => reg8_data_out <= reg_b;
				WHEN "001" => reg8_data_out <= reg_c;
				WHEN "010" => reg8_data_out <= reg_d;
				WHEN "011" => reg8_data_out <= reg_e;
				WHEN "100" => reg8_data_out <= reg_h;
				WHEN "101" => reg8_data_out <= reg_l;
				WHEN OTHERS => reg8_data_out <= (OTHERS => '0');
			END CASE;
		ELSE
			CASE reg_sel IS
				WHEN "000" => reg16_sel_value <= UNSIGNED(reg_b & reg_c);
				WHEN "001" => reg16_sel_value <= UNSIGNED(reg_d & reg_e);
				WHEN "010" => reg16_sel_value <= UNSIGNED(reg_h & reg_l);
				WHEN "011" => reg16_sel_value <= UNSIGNED(reg_sp);
				WHEN "100" => reg16_sel_value <= UNSIGNED(reg_pc);
				WHEN OTHERS => reg16_sel_value <= (OTHERS => '0');
			END CASE;
		END IF;
		
	END PROCESS;
	
	reg16_data_out <= STD_LOGIC_VECTOR(reg16_sel_value);
	
	PROCESS(reg_clk)
	BEGIN
	
		IF reg_clk'EVENT AND reg_clk = '1' THEN
			IF reg_rst = '1' THEN
				reg_b <= (OTHERS => '0');
				reg_c <= (OTHERS => '0');
				reg_d <= (OTHERS => '0');
				reg_e <= (OTHERS => '0');
				reg_h <= (OTHERS => '0');
				reg_l <= (OTHERS => '0');
				reg_sp <= (OTHERS => '0');
				reg_pc <= (OTHERS => '0');
			ELSIF reg_wr_en = '1' THEN
				IF reg16_en = '0' THEN
					CASE reg_sel IS
						WHEN "000" => reg_b <= reg8_data_in;
						WHEN "001" => reg_c <= reg8_data_in;
						WHEN "010" => reg_d <= reg8_data_in;
						WHEN "011" => reg_e <= reg8_data_in;
						WHEN "100" => reg_h <= reg8_data_in;
						WHEN "101" => reg_l <= reg8_data_in;
						WHEN OTHERS => NULL;
					END CASE;
				ELSE
					CASE reg16_op IS
						WHEN "01" => reg16_new_value <= reg16_sel_value + 1;
						WHEN "10" => reg16_new_value <= reg16_sel_value - 1;
						WHEN "11" => reg16_new_value <= UNSIGNED(reg16_data_in);
						WHEN OTHERS => reg16_new_value <= reg16_sel_value;
					END CASE;
				
					CASE reg_sel IS
						WHEN "000" =>
							reg_b <= STD_LOGIC_VECTOR(reg16_new_value(15 DOWNTO 8));
							reg_c <= STD_LOGIC_VECTOR(reg16_new_value(7 DOWNTO 0));
						WHEN "001" => 
							reg_d <= STD_LOGIC_VECTOR(reg16_new_value(15 DOWNTO 8));
							reg_e <= STD_LOGIC_VECTOR(reg16_new_value(7 DOWNTO 0));
						WHEN "010" =>
							reg_h <= STD_LOGIC_VECTOR(reg16_new_value(15 DOWNTO 8));
							reg_l <= STD_LOGIC_VECTOR(reg16_new_value(7 DOWNTO 0));
						WHEN "011" =>
							reg_sp <= STD_LOGIC_VECTOR(reg16_new_value);
						WHEN "100" =>
							reg_pc <= STD_LOGIC_VECTOR(reg16_new_value);
						WHEN OTHERS => NULL;
					END CASE;
				END IF;
			END IF;
		END IF;
		
	END PROCESS;
	
END ARCHITECTURE;