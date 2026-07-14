LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

------------------------------------------------------------------------------------------
-- op_sel:
--   000 = ADD
--   001 = ADC (ADD with carry)
--   010 = SUB
--   011 = SBB (SUB with borrow)
--   100 = AND
--   101 = OR
--   110 = XOR
--   111 = CMP (compara, não armazena resultado)
ENTITY alu IS
    PORT (
        A, B   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        CY_in  : IN  STD_LOGIC;
        op_sel : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        result : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        S_out_alu, Z_out_alu, AC_out_alu, P_out_alu, CY_out_alu: OUT STD_LOGIC
        --  Signal, Zero, Carry Axuliar(bit 3 para 4), Paridade de 1, Carry
		  
		  attribute chip_pin of A : signal is ",,,,Y23, Y24, AA22, AA23"; ------------------- SW 17 - SW 14        A
		  attribute chip_pin: string;
		  attribute chip_pin of A : signal is "AC25, AB26, AD26, AC26,Y23, Y24, AA22, AA23"; ------------------- SW 17 - SW 14        A
		  attribute chip_pin of B : signal is "AB22, AB21, AC21, AD21,AA24, AB23, AB24, AC24"; ----------------- SW 13 - SW 10        B
        attribute chip_pin of CY_in : signal is "AB25";   --------------------------------- SW 9                 C in
		  attribute chip_pin of op_sel : signal is "AC27, AC28, AB28";   -------------------- SW2 - SW 0           OP
        attribute chip_pin of result : signal is "E21, E22, E25, E24, H15, G16, G15, F15";   -------------- LEDR 17 - 14         Result
		  attribute chip_pin of AC_out_alu : signal is "F18";   ----------------------------- LEDR 4               Auxiliar Carry
        attribute chip_pin of S_out_alu : signal is "F21";   ------------------------------ LEDR 3               Bit de sinal
		  attribute chip_pin of Z_out_alu : signal is "E19";   ------------------------------ LEDR 2               Bit de Zero
		  attribute chip_pin of P_out_alu : signal is "F19";   ------------------------------ LEDR 1               Bit de Paridade
		  attribute chip_pin of CY_out_alu : signal is "G19";   ----------------------------- LEDR 0               Carry over
    );
END alu;

------------------------------------------------------------------------------------------

ARCHITECTURE logic_alu OF alu IS
      SIGNAL res : STD_LOGIC_VECTOR(7 DOWNTO 0);
		SIGNAL res9 : STD_LOGIC_VECTOR(8 DOWNTO 0);
		SIGNAL ac_bit : STD_LOGIC;
BEGIN

    parity : ENTITY work.parity_checker(parity_logic)
        port map (
            data_parity   => res,
            parity => P_out_alu
        );

    PROCESS(A, B, CY_in, op_sel)
        VARIABLE v_res9  : STD_LOGIC_VECTOR(8 DOWNTO 0);
        VARIABLE v_ac    : STD_LOGIC;
    BEGIN
        v_res9 := (others => '0');
        v_ac   := '0';

        CASE op_sel IS
            WHEN "000" => -- ADD
                v_res9 := STD_LOGIC_VECTOR(('0' & SIGNED(A)) + ('0' & SIGNED(B)));   -- O carry in ta vindo como SIgned, ai entende como negativo e tem que inverter
                v_ac   := STD_LOGIC_VECTOR(UNSIGNED('0' & A(3 DOWNTO 0)) + UNSIGNED('0' & B(3 DOWNTO 0)))(4);

            WHEN "001" => -- ADC
                v_res9 := STD_LOGIC_VECTOR(('0' & SIGNED(A)) + ('0' & SIGNED(B)) - SIGNED'("" & CY_in));
                v_ac   := STD_LOGIC_VECTOR(UNSIGNED('0' & A(3 DOWNTO 0)) + UNSIGNED('0' & B(3 DOWNTO 0)) + UNSIGNED'("" & CY_IN))(4);

            WHEN "010" => -- SUB
                v_res9 := STD_LOGIC_VECTOR(('0' & SIGNED(A)) - ('0' & SIGNED(B)));
                v_ac   := NOT STD_LOGIC_VECTOR(UNSIGNED('0' & A(3 DOWNTO 0)) - UNSIGNED('0' & B(3 DOWNTO 0)))(4);

            WHEN "011" => -- SBB
                v_res9 := STD_LOGIC_VECTOR(('0' & SIGNED(A)) - ('0' & SIGNED(B)) + SIGNED'("" & CY_in)); -- O carry in ta vindo como SIgned, ai entende como negativo e tem que inverter
                v_ac   := NOT STD_LOGIC_VECTOR(UNSIGNED('0' & A(3 DOWNTO 0)) - UNSIGNED('0' & B(3 DOWNTO 0)) - UNSIGNED'("" & CY_in))(4);

            WHEN "100" => -- AND 
                v_res9(7 DOWNTO 0) := A AND B;
                v_ac               := A(3) OR B(3);

            WHEN "101" => -- OR
                v_res9(7 DOWNTO 0) := A OR B;
                v_ac               := '0';

            WHEN "110" => -- XOR
                v_res9(7 DOWNTO 0) := A XOR B;
                v_ac               := '0';

            WHEN "111" => -- CMP
                v_res9 := STD_LOGIC_VECTOR(('0' & UNSIGNED(A)) - ('0' & UNSIGNED(B)));
                v_ac   := NOT STD_LOGIC_VECTOR(UNSIGNED("0" & A(3 DOWNTO 0)) - UNSIGNED("0" & B(3 DOWNTO 0)))(4);

            WHEN others =>
                v_res9 := (others => '0');
        END CASE;

        res9   <= v_res9;
        ac_bit <= v_ac;
    END PROCESS;

    res    <= res9(7 DOWNTO 0);
    result <= A WHEN op_sel = "111" ELSE res;
    S_out_alu  <= res(7);
    Z_out_alu  <= '1' WHEN res = x"00" ELSE '0';
    AC_out_alu <= ac_bit;
    CY_out_alu <= res9(8);

END logic_alu;