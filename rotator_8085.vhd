LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

------------------------------------------------------------------------------------------
-- Module: 8085 Rotate / Complement / DAA unit
--
-- op_sel encoding (from opcode bits 5-3):
--   000 = RLC  (07) : rotate A left,  CY = A(7)
--   001 = RRC  (0F) : rotate A right, CY = A(0)
--   010 = RAL  (17) : rotate A left through carry
--   011 = RAR  (1F) : rotate A right through carry
--   101 = CMA  (2F) : complement A
--   111 = CMC  (3F) : complement CY
--   110 = STC  (37) : set CY
--   100 = DAA  (27) : decimal adjust A
------------------------------------------------------------------------------------------

ENTITY rotator_8085 IS
    PORT (
        acc_in    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        cy_in     : IN  STD_LOGIC;
        ac_in     : IN  STD_LOGIC;
        op_sel    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);

        acc_out   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        cy_out    : OUT STD_LOGIC;
        ac_out    : OUT STD_LOGIC
    );
END ENTITY;

ARCHITECTURE combinational OF rotator_8085 IS
BEGIN

    PROCESS(acc_in, cy_in, ac_in, op_sel)
        VARIABLE v_acc : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE v_cy  : STD_LOGIC;
        VARIABLE v_ac  : STD_LOGIC;
        VARIABLE v_daa : UNSIGNED(8 DOWNTO 0);
    BEGIN
        v_acc := acc_in;
        v_cy  := cy_in;
        v_ac  := ac_in;

        CASE op_sel IS
            WHEN "000" =>  -- RLC
                v_cy  := acc_in(7);
                v_acc := acc_in(6 DOWNTO 0) & acc_in(7);

            WHEN "001" =>  -- RRC
                v_cy  := acc_in(0);
                v_acc := acc_in(0) & acc_in(7 DOWNTO 1);

            WHEN "010" =>  -- RAL
                v_cy  := acc_in(7);
                v_acc := acc_in(6 DOWNTO 0) & cy_in;

            WHEN "011" =>  -- RAR
                v_cy  := acc_in(0);
                v_acc := cy_in & acc_in(7 DOWNTO 1);

            WHEN "100" =>  -- DAA
                v_daa := '0' & UNSIGNED(acc_in);
                v_ac  := ac_in;
                IF acc_in(3 DOWNTO 0) > "1001" OR ac_in = '1' THEN
                    v_daa := v_daa + 6;
                    v_ac  := '1';
                ELSE
                    v_ac  := '0';
                END IF;
                IF v_daa(7 DOWNTO 4) > "1001" OR cy_in = '1' THEN
                    v_daa := v_daa + 96;
                    v_cy  := '1';
                END IF;
                v_acc := STD_LOGIC_VECTOR(v_daa(7 DOWNTO 0));

            WHEN "101" =>  -- CMA
                v_acc := NOT acc_in;

            WHEN "110" =>  -- STC
                v_cy := '1';

            WHEN "111" =>  -- CMC
                v_cy := NOT cy_in;

            WHEN OTHERS =>
                NULL;
        END CASE;

        acc_out <= v_acc;
        cy_out  <= v_cy;
        ac_out  <= v_ac;
    END PROCESS;

END ARCHITECTURE;
