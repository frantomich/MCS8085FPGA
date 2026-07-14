LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------

ENTITY parity_checker IS
    PORT (
        data_parity   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        parity : OUT STD_LOGIC
    );
END parity_checker;

------------------------------------------------------------------------------------------

ARCHITECTURE parity_logic OF parity_checker IS
BEGIN
    PROCESS(data_parity)
        VARIABLE p : STD_LOGIC;
    BEGIN
        p := '0';

        FOR i IN data_parity'RANGE LOOP
            p := p XOR data_parity(i);
        END LOOP;

        parity <= NOT p;
    END PROCESS;
END parity_logic;