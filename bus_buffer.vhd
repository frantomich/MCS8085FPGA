LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY bus_buffer IS

	PORT(
		
		addr_to_bus: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_to_bus: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		data_from_bus: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		
		ale: IN STD_LOGIC;
		write_en: IN STD_LOGIC;
	
		a: OUT STD_LOGIC_VECTOR(15 DOWNTO 8);
		ad: INOUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		
	);
	
END ENTITY;

ARCHITECTURE bus_buffer_logic OF bus_buffer IS

	SIGNAL wr: STD_LOGIC;

BEGIN

	a <= addr_to_bus(15 DOWNTO 8);
	
	wr <= write_en;
	
	PROCESS(ale, wr, addr_to_bus, data_to_bus, ad)
	BEGIN
		IF ale = '1' THEN
			ad <= addr_to_bus(7 DOWNTO 0);
		ELSIF wr = '1' THEN
			ad <= data_to_bus;
		ELSE
			ad <= (OTHERS => 'Z');
		END IF;
	END PROCESS;
	
	data_from_bus <= ad;
	
END ARCHITECTURE;