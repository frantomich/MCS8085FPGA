LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

------------------------------------------------------------------------------------------

-- Flags: S (Sign), Z (Zero), AC (Auxiliary Carry), P (Parity), CY (Carry)
ENTITY flag_register IS
    PORT (
        clk_fr, reset_fr, load_fr, S_in_f, Z_in_f, AC_in_f, P_in_f, CY_in_f : in  STD_LOGIC;
        S_out_F, Z_out_f, AC_out_f, P_out_f, CY_out_f  : out STD_LOGIC
    );
END flag_register;

------------------------------------------------------------------------------------------

ARCHITECTURE fr_logic OF flag_register IS
    SIGNAL S_reg, Z_reg, AC_reg, P_reg, CY_reg : STD_LOGIC;
BEGIN
    PROCESS(clk_fr, reset_fr)
    BEGIN
        IF reset_fr = '1' THEN
            S_reg  <= '0';
            Z_reg  <= '0';
            AC_reg <= '0';
            P_reg  <= '0';
            CY_reg <= '0';
        ELSIF rising_edge(clk_fr) THEN
            IF load_fr = '1' THEN
                S_reg  <= S_in_f;
                Z_reg  <= Z_in_f;
                AC_reg <= AC_in_f;
                P_reg  <= P_in_f;
                CY_reg <= CY_in_f;
            END IF;
        END IF;
    END PROCESS;

    S_out_F  <= S_reg;
    Z_out_f  <= Z_reg;
    AC_out_f <= AC_reg;
    P_out_f  <= P_reg;
    CY_out_f <= CY_reg;
END fr_logic;
