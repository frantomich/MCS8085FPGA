LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

------------------------------------------------------------------------------------------
-- Module: 8085 CPU Core
--
-- Architecture: single clocked process per resource, combinational control signals.
-- All control decisions are made combinationally from (state, opcode, decoder outputs).
-- The clocked processes only capture results.
--
-- Mem
--   A (accumulator), B, C, D, E, H, L, SP(15:0), PC(15:0)
--   TMP (8-bit operand buffer), IMM_L, IMM_H (immediate bytes)
--   W, Z (16-bit temp for CALL/RET/LHLD/SHLD)
--

------------------------------------------------------------------------------------------

ENTITY cpu_80852 IS
    PORT (

        -- Clock e Reset

        clk_main          : IN  STD_LOGIC;
        rst_main          : IN  STD_LOGIC;

        -- Barramento externos
        addr_bus     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        data_bus_in  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        data_bus_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        ale          : OUT STD_LOGIC;
        io_addr      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        io_data_in   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        io_data_out  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        io_wr_en     : OUT STD_LOGIC;
        io_rd_en     : OUT STD_LOGIC;

        -- Flags de Interrupção

        trap         : IN  STD_LOGIC;
        rst75        : IN  STD_LOGIC;
        rst65        : IN  STD_LOGIC;
        rst55        : IN  STD_LOGIC;
        intr         : IN  STD_LOGIC;
        inta         : IN  STD_LOGIC;

        -- Saidas de Debug

        acc_deb_out      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        B_deb_out      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        C_deb_out      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        D_deb_out      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        E_deb_out      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        H_deb_out      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        L_deb_out      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        flags_deb_out    : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        pc_deb_out       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        halted_deb       : OUT STD_LOGIC;
        state_deb_out    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY cpu_80852;

ARCHITECTURE rtl OF cpu_80852 IS

BEGIN

BB_INST : ENTITY work.bus_buffer(bus_buffer_logic)

	PORT MAP (
		
		addr_to_bus -- 16 bits
		data_to_bus -- 8 bits
		data_from_bus -- 8 bits
		
		ale
		write_en
	
		a -- 8 bits
		ad -- 8 bits
		
	);
-- accumulator instance
    ACC_INST : ENTITY work.accumulator(acc_logic)
        PORT MAP(
             clk_acc => clk_main,  
             reset_acc => rst_main, 
             load_acc    
             data_in_acc  -- 8bits
             data_out_acc
        );
-- ALU instance
    ALU_INST : ENTITY work.alu(logic_alu)
        PORT MAP (
             A --8bits
             B --8bits, 
             CY_in
             op_sel     -- 3 bits
             alu_result -- 8 bits
             alu_s,
             alu_z,
             alu_ac, 
             alu_p, 
             alu_cy
        );

-- Rotator instance
    ROT_INST : ENTITY work.rotator_8085(combinational)
        PORT MAP (
            acc_in, -- 8 bits
            cy_in, 
            ac_in, 
            op_sel, -- 3 bits
            rot_result, -- 8 bits
            cy_out, 
            ac_out
        );

-- Flag Register instance
 FR_INST : ENTITY work.flag_register(fr_logic)
    PORT MAP(
        clk_fr => clk_main, 
        reset_fr, 
        load_fr, 
        S_in_f, 
        Z_in_f, 
        AC_in_f, 
        P_in_f, 
        CY_in_f,
        S_out_F, 
        Z_out_f, 
        AC_out_f, 
        P_out_f, 
        CY_out_f
    );

ID_INST : ENTITY work.instruction_decoder_8085(id_logic)
    PORT MAP (
        dec_opcode_in -- 8 bits

        dec_op_sel_out   -- 3 bits
        dec_reg_sel_out  -- 3 bits

        dec_load_acc_out 
        dec_load_fr_out  

        dec_is_nop_out   
        dec_is_hlt_out   

        dec_valid_out    
    );

IR_INST : ENTITY work.instruction_register_8085(ir_logic)
    PORT MAP (
        ir_clk  => clk_main,      
        ir_rst  => rst_main,
        ir_load     
        ir_data_in  -- 8 bits
        ir_data_out -- 8 bits
    );

IC_INST : ENTITY work.interrupt_control_8085(ic_logic)
    PORT MAP (

        ic_clk  => clk_main,
        ic_rst  => rst_main,

        -- Interrupt inputs
        trap        -- Non-maskable, edge+level
        rst75       -- Maskable, edge-triggered
        rst65       -- Maskable, level-triggered
        rst55       -- Maskable, level-triggered
        intr        -- Maskable, level-triggered

        -- Interrupt enable control (from EI/DI instructions)
        ei           -- Enable interrupts
        di           -- Disable interrupts

        -- SIM instruction mask bits
        sim_load
        sim_m75     -- Mask RST7.5
        sim_m65     -- Mask RST6.5
        sim_m55     -- Mask RST5.5
        sim_r75     -- Reset RST7.5 flip-flop

        -- RIM outputs (read interrupt masks)
        rim_ie
        rim_m75
        rim_m65
        rim_m55
        rim_p75

        -- To CPU
        int_pending 
        int_vector  -- 8 bits
        int_ack    
    );

RA_INST : ENTITY work.register_array(register_array_logic)
	PORT MAP (
	
		reg_clk  => clk_main, --Clock.
		reg_rst  => rst_main,--Reset.
		
		reg_sel --Seleçao do registrador (3 bits).
		reg_wr_en --Habilitaçao da escrita.
		
		reg8_data_in --Barramento de entrada simples(8 bits).
		reg8_data_out --Barramento de saida simples(8 bits).
		
		reg16_en --Habilitaçao do acesso duplo.
		reg16_op --Operaçao a ser executada no registrador duplo (2 bits).
		reg16_data_in --Barramento de entrada dupla (16 bits).
		reg16_data_out --Barramento de saida dupla (16 bits).
		
	);


TC_INST : ENTITY timing_control_8085(fsm)
    PORT MAP (
        tc_clk => clk_main,  
        tc_rst => rst_main,

        tc_hlt_detected
        tc_valid_instruction

        tc_ir_load_out       
        tc_execute_enable_out
        tc_halted_out        

        tc_state_out         -- 2 bits
    );

TR_INST : ENTITY work.tmp_reg(tmp_reg_logic)

	PORT MAP (
		
		tmp_reg_clk  => clk_main,
		tmp_reg_rst  => rst_main,
		tmp_reg_load
		tmp_reg_data_in -- 8bits
		tmp_reg_data_out -- 8bits
		
	);
END ARCHITECTURE;