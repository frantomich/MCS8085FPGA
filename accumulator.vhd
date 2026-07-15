LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------

ENTITY accumulator IS
    port (
        clk_acc     : in  STD_LOGIC;
        reset_acc   : in  STD_LOGIC;
        load_acc    : in  STD_LOGIC;
        data_in_acc : in  STD_LOGIC_VECTOR(7 downto 0);
        data_out_acc: out STD_LOGIC_VECTOR(7 downto 0)
    );
END accumulator;

------------------------------------------------------------------------------------------

ARCHITECTURE acc_logic OF accumulator IS
    SIGNAL reg : STD_LOGIC_VECTOR(7 downto 0);
BEGIN
    PROCESS(clk_acc, reset_acc)
    BEGIN
        IF reset_acc = '1' THEN
            reg <= (others => '0');
        ELSIF rising_edge(clk_acc) THEN
            IF load_acc = '1' THEN
                reg <= data_in_acc;
            END IF;
        END IF;
    END PROCESS;

    data_out_acc <= reg;
end acc_logic;
