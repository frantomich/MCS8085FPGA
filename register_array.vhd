LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY register_array IS

	PORT(
	
		reg_clk: IN STD_LOGIC;                             --Clock.
		reg_rst: IN STD_LOGIC;                             --Reset.
		reg_wr_en: IN STD_LOGIC;                           --Habilitaçao da escrita.
		reg_pair_en: IN STD_LOGIC;                         --Habilitaçao do acesso em pares.
		reg_sel: IN STD_LOGIC_VECTOR(2 DOWNTO 0);          --Seleçao do registrador (3 bits).
		reg_data_in: IN STD_LOGIC_VECTOR(15 DOWNTO 0);     --Barramento de entrada (16 bits).
		reg_data_out: OUT STD_LOGIC_VECTOR(15 DOWNTO 0)    --Barramento de saida (16 bits).
		
	);
	
END ENTITY;

ARCHITECTURE register_array_logic OF register_array IS

	SIGNAL reg_b, reg_c, reg_d, reg_e, reg_h, reg_l: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL reg_sp: STD_LOGIC_VECTOR(15 DOWNTO 0);
	
BEGIN

	PROCESS(reg_sel, reg_pair_en, reg_b, reg_c, reg_d, reg_e, reg_h, reg_l, reg_sp)
	BEGIN
	
		IF reg_pair_en = '0' THEN
			CASE reg_sel IS
				WHEN "000" =>
					reg_data_out(15 DOWNTO 8) <= (OTHERS => '0');
					reg_data_out(7 DOWNTO 0) <= reg_b;
				WHEN "001" =>
					reg_data_out(15 DOWNTO 8) <= (OTHERS => '0');
					reg_data_out(7 DOWNTO 0) <= reg_c;
				WHEN "010" =>
					reg_data_out(15 DOWNTO 8) <= (OTHERS => '0');
					reg_data_out(7 DOWNTO 0) <= reg_d;
				WHEN "011" =>
					reg_data_out(15 DOWNTO 8) <= (OTHERS => '0');
					reg_data_out(7 DOWNTO 0) <= reg_e;
				WHEN "100" =>
					reg_data_out(15 DOWNTO 8) <= (OTHERS => '0');
					reg_data_out(7 DOWNTO 0) <= reg_h;
				WHEN "101" =>
					reg_data_out(15 DOWNTO 8) <= (OTHERS => '0');
					reg_data_out(7 DOWNTO 0) <= reg_l;
				WHEN OTHERS => NULL;
			END CASE;
		ELSE
			CASE reg_sel IS
				WHEN "000" => reg_data_out <= reg_b & reg_c;
				WHEN "001" => reg_data_out <= reg_d & reg_e;
				WHEN "010" => reg_data_out <= reg_h & reg_l;
				WHEN "011" => reg_data_out <= reg_sp;
				WHEN OTHERS => NULL;
			END CASE;
		END IF;
	END PROCESS;
	
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
			ELSE
				IF reg_wr_en = '1' THEN
					IF reg_pair_en = '0' THEN
						CASE reg_sel IS
							WHEN "000" => reg_b <= reg_data_in(7 DOWNTO 0);
							WHEN "001" => reg_c <= reg_data_in(7 DOWNTO 0);
							WHEN "010" => reg_d <= reg_data_in(7 DOWNTO 0);
							WHEN "011" => reg_e <= reg_data_in(7 DOWNTO 0);
							WHEN "100" => reg_h <= reg_data_in(7 DOWNTO 0);
							WHEN "101" => reg_l <= reg_data_in(7 DOWNTO 0);
							WHEN OTHERS => NULL;
						END CASE;
					ELSE
						CASE reg_sel IS
							WHEN "000" =>
								reg_b <= reg_data_in(15 DOWNTO 8);
								reg_c <= reg_data_in(7 DOWNTO 0);
							WHEN "001" =>
								reg_d <= reg_data_in(15 DOWNTO 8);
								reg_e <= reg_data_in(7 DOWNTO 0);
							WHEN "010" =>
								reg_h <= reg_data_in(15 DOWNTO 8);
								reg_l <= reg_data_in(7 DOWNTO 0);
							WHEN "011" =>
								reg_sp <= reg_data_in;
							WHEN OTHERS => NULL;
						END CASE;
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
END ARCHITECTURE;
		