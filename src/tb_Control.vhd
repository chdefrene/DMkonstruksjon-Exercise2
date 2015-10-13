LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.defs.ALL;


ENTITY tb_ALU IS
END tb_ALU;

ARCHITECTURE behavior OF tb_ALU IS
	constant ADDR_WIDTH : integer := 8;
	constant DATA_WIDTH : integer := 32;
	constant REG_ADDR_WIDTH : integer := 5;
	constant IMMEDIATE_WIDTH : integer := 16

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT Control
		generic (
			ADDR_WIDTH : integer := 8;	
			DATA_WIDTH : integer := 32;
			REG_ADDR_WIDTH : integer := 5;
			IMMEDIATE_WIDTH : integer := 16
		);
		port (
			clk, reset : in std_logic;
			instruction_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
			alu_control_out : out alu_operation_t;
			read_reg_1_out, read_reg_2_out, write_reg_out : out std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
			reg_dst_out, pc_write_out, branch_out, jump_out, reg_write_out, alu_src_out, mem_to_reg_out, mem_write_out : out std_logic
		);
  END COMPONENT;

  --Inputs
	signal clk : std_logic := '0';
	signal reset : std_logic := '0';
	signal instruction_in : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
	--Outputs
	signal alu_control_out : alu_operation_t;
	signal read_reg_1_out, read_reg_2_out, write_reg_out : std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
	signal reg_dst_out, pc_write_out, branch_out, jump_out, reg_write_out, alu_src_out, mem_to_reg_out, mem_write_out : std_logic;

	-- Clock period definitions
	constant clk_period : time := 10 ns;
BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: Control PORT MAP (
		clk => clk,
		reset => reset,
		instruction_in => instruction_in,
		alu_control_out => alu_control_out,
		read_reg_1_out => read_reg_1_out,
		read_reg_2_out => read_reg_2_out,	
		write_reg_out => write_reg_out,
		reg_dst_out => reg_dst_out,
		pc_write_out => pc_write_out,
		branch_out => branch_out,
		jump_out => jump_out,
		reg_write_out => reg_write_out,
		alu_src_out => alu_src_out,
		mem_to_reg_out => mem_to_reg_out,
		mem_write_out = mem_write_out
	);

	-- Clock process definitions
	clk_process: process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;




	-- Stimulus process
	stim_proc: process

		process AssertFetchState is
		begin
			assert pc_write_out = '0'
				report "pc_write_out should be '0' when in fetch state"
				severity failure;
			assert reg_write_out = '0'
				report "reg_write_out should be '0' when in fetch state"
				severity failure;
			assert mem_write_out = '0'
				report "mem_write_out should be '0' when in fetch state"
				severity failure;
		end AssertFetchState;


		process AssertExecuteState is
		begin
			assert pc_wite_out = '1'
				report "pc_write_out should be '1' in execute state"
				severity failure;
		end AssertExecuteState;
			

		process AssertStallState is
		begin
			assert pc_write_out = '0'
				report "pc_write_out should be '0' in stall state"
				severity failure;
		end AssertStallState; 


		process AssertALUInstruction(
			alu_operation : alu_operation_t) is
		begin
			-- Reg write enable
			assert reg_write_out = '1'
				report "reg_write_out should be '1' to write back data from ALU result"
				severity failure;

			-- ALU operation
			assert alu_control_out = alu_operation
				report "alu_control_out is not set according to instruction"
				severity failure;

			-- MemToReg
			assert mem_to_reg_out = '0'
				report "mem_to_reg_out should be '0' to write back data from ALU result"
				severity failure;
		 
			-- Branch signal should not be set
			assert branch_out = '0'
				report "branch_out should be '0' for writeback instructions"
				severity failure;
			
			-- Jump signal should not be set
			assert jump_out = '0'
				report "jump_out should be '0' for writeback instructions"
				severity failure;

		end AssertALUInstruction;


		process AssertRTypeInstruction is
		begin
			-- Reg dst
			assert reg_dst_out = '1'
				report "reg_dst should be '1' to set register rd as write register"
				severity failure;
	
			-- ALU src
			assert alu_src_out = '0'
				report "alu_src_out should be '0' to select register rt instead of immediate value"
				severity failure;
		end AssertRTypeInstruction;


		process AssertITypeInstruction is
		begin
			-- Reg dst
			assert reg_dst_out = '0'
				report "reg_dst should be '0' to set register rt as write register"
				severity failure;
	
			-- ALU src
			assert alu_src_out = '1'
				report "alu_src_out should be '1' to select immediate value instead of register rt"
				severity failure;
		end AssertITypeInstruction;


	begin

		-- hold reset state for 100 ns
		reset <= '1';
		wait for 100 ns;
		reset <= '0';

		-- Control should be in fetch state
		AssertFetchState;

		--- LOAD instruction ---
		report "Testing LOAD instruction";
		intruction_in <= INSTR_LOAD;
		wait for clk_period;
		
		-- Control should now be in execute state
		AssertExecuteState;

		-- Branch signal should not be set
		assert branch_out = '0'
			report "branch_out should be '0' for LOAD instructions"
			severity failure;
		
		-- Jump signal should not be set
		assert jump_out = '0'
			report "jump_out should be '0' for LOAD instructions"
			severity failure;

		-- Check signals for load instruction
		assert reg_write_out = '0'
			report "reg_write_out should be '0' for LOAD instruction"
			severity failure;

		-- ALU should be rs + imm
		assert alu_src_out = '1'
			report "alu_src_out should be '1' for LOAD instruction to select immediate value for the ALU"
			severity failure;

		-- ALU control should be ADD
		assert alu_control_out = ALU_ADD
			report "alu_contorl_out should be ALU_ADD for LOAD instruction"
			severity failure;

		-- Mem Write should be off, since we are not writing any new values 
		assert mem_write_out = '0'
			report "mem_write_out should be '0' for LOAD instruction to prevent writing to data memory"
			severity failure;


		-- Wait a clock cycle						
		wait for clk_period;

		-- Instruction from memory changes to a STORE instruction
		instruction_in <= INSTR_STORE;

		-- Should now be in stall state
		AssertStallState;

		-- Mem to reg enable
		assert mem_to_reg_out = '1'
			report "mem_to_reg_out should be '1' for LOAD instruction in stall state to write the correct value in the register"
			severity failure;

		-- Reg write enable
		assert reg_write_out = '1'
			report "reg_write_out should be '1' for LOAD instruction in stall state to write the value in the register"
		severity failure;

		assert reg_dst_out = '0'
			report "reg_dst_out should be '0' for LOAD instruciton in stall state to select rt from instruction"

		-- Mem write disable
		assert mem_write_out = '0'
			report "mem_write_out should be '0' for LOAD instruction in stall state to prevent writing to data memory"
		severity failure;
		
		--- Done with LOAD instruction
		report "LOAD instruction passed";


		wait for clk_period;
		

		--- Test STORE instruction
		report "Testing STORE instruction"

		-- Should now be in fetch state
		AssertFetchState;

		wait for clk_period;
		
		-- Should now be in execute state
		AssertExecuteState;
	
		-- Branch signal should not be set
		assert branch_out = '0'
			report "branch_out should be '0' for STORE instructions"
			severity failure;
		
		-- Jump signal should not be set
		assert jump_out = '0'
			report "jump_out should be '0' for STORE instructions"
			severity failure;

		-- Check signals for STORE instruction
		assert reg_write_out = '0'
			report "reg_write_out should be '0' for STORE instruction"
			severity failure;

		-- ALU should be rs + imm
		assert alu_src_out = '1'
			report "alu_src_out should be '1' for STORE instruction to select immediate value for the ALU"
			severity failure;

		-- ALU control should be ADD
		assert alu_control_out = ALU_ADD
			report "alu_control_out should be ALU_ADD for STORE instruction"
			severity failure;

		-- Should write to memory
		assert mem_write_out = '1'
			report "mem_write_out should be '1' for STORE instruction"
			severity failure;

		-- instruction_in should now change
		instruction_in <= INSTR_ADD

		wait for clk_period;

		-- Should now be in stall state
		AssertStallState;

		-- Reg write should still be 0
		assert reg_write_out = '0'
			report "reg_write_out should be '0' for STORE instruction in stall state"
			severity failure;

		-- Mem write should still be 1
		assert mem_write_out = '1'
			report "mem_write_out should be '1' for STORE instruction in statll state"
			severity failure;
		
		-- Done with STORE instruction
		report "STORE instruction passed";
	

		wait for clk_period;



		--- Testing R type and I type instructions ---

		--- ADD (R type) ---		
		-- set instruction and wait for clk_period already done
		AssertFetchState;
		wait for clk_period;
		AssertExecuteState;
		AssertRTypeInstruction;
		AssertALUInstruction(ALU_ADD);
		report "ADD instruction passed";

		--- ADDI (I type) ---
		instruction_in <= INSTR_ADDI;
		wait for clk_period;
		AssertFetchState;
		wait for clk_period;
		AssertExecuteState;
		AssertITypeInstruction;
		AssertALUInstruction(ALU_ADD);
		report "ADDI instruction passed";

		--- SUB (R type) ---
		instruction_in <= INSTR_SUB;
		wait for clk_period;
		AssertFetchState;
		wait for clk_period;
		AssertExecuteState;
		AssertRTypeInstruction;
		AssertALUInstruction(ALU_SUB);
		report "SUB instruction passed";

		--- SUBI (I type) ---
		instruction_in <= INSTR_SUBI;
		wait for clk_period;
		AssertFetchState;
		wait for clk_period;
		AssertExecuteState;
		AssertITypeInstruction;
		AssertALUInstruction(ALU_SUB);
		report "SUBI instruction passed";
		
		--- AND (R type) ---
		instruction_in <= INSTR_AND;
		wait for clk_period;
		AssertFetchState;
		wait for clk_period;
		AssertExecuteState;
		AssertRTypeInstruction;
		AssertALUInstruction(ALU_AND);
		report "AND instruction passed";
		
		--- ANDI (I type) ---
		instruction_in <= INSTR_ANDI;
		wait for clk_period;
		AssertFetchState;
		wait for clk_period;
		AssertExecuteState;
		AssertITypeInstruction;
		AssertALUInstruction(ALU_AND);
		report "ANDI instruction passed";
		
		--- OR (R type) ---
		instruction_in <= INSTR_OR;
		wait for clk_period;
		AssertFetchState;
		wait for clk_period;
		AssertExecuteState;
		AssertRTypeInstruction;
		AssertALUInstruction(ALU_OR);
		report "OR instruction passed";
		
		--- ORI (I type) ---
		instruction_in <= INSTR_ORI;
		wait for clk_period;
		AssertFetchState;
		wait for clk_period;
		AssertExecuteState;
		AssertITypeInstruction;
		AssertALUInstruction(ALU_OR);
		report "ORI instruction passed";
		

		--- SLT (R type) ---
		instruction_in <= INSTR_SLT;
		wait for clk_period;
		AssertFetchState;
		wait for clk_period;
		AssertExecuteState;
		AssertRTypeInstruction;
		AssertALUInstruction(ALU_SLT);
		report "SLT instruction passed";
		
		--- SLTI (I type) ---
		instruction_in <= INSTR_SLTI;
		wait for clk_period;
		AssertFetchState;
		wait for clk_period;
		AssertExecuteState;
		AssertITypeInstruction;
		AssertALUInstruction(ALU_SLT);
		report "SLTI instruction passed";


		--- LUI (I type) ---
--		instruction_in <= INSTR_LUI;
--		wait for clk_period;
--		AssertFetchState;
--		wait for clk_period;
--		AssertExecuteState;
--		AssertITypeInstruction(ALU_SLL16);
--		report "LUI instruction passed";



		--- Test BEQ instruction ---
		instruction_in <= INSTR_BEQ
		wait for clk_period;
		AssertFetchState;
		wait for clk_period;
		AssertExecuteState;

		-- reg write 0
		assert reg_write_out = '0'
			report "reg_write_out should be '0' for BEQ instruction to prevent data from ALU or memory to be written to register"
			severity failure;

		-- ALU src 0
		assert alu_src_out = '0'
			report "alu_src_out should be '0' for BEQ instruction to select rt instead of immediate"
			severity failure;
		
		-- ALU operation ALU_SUB
		assert alu_control_out = ALU_SUB
			report "alu_control_out should be ALU_SUB for BEQ instruction to compare registers rs and rt"
			severity failure;

		-- mem write 0
		assert mem_write_out = '0'
			report "mem_write_out should be '0' for BEQ instruction to prevent data being written to memory"		
			severity failure;

		-- branch enable
		assert branch_out = '1'
			report "branch_out should be '1' on BEQ instruction"
			severity failure;
	
		-- jump disable
		assert jump_out = '0'
			report "jump_out should be '0' on BEQ instruction"
			severity failure;

		-- Done with BEQ instruction
		report "BEQ instruction passed";




		--- Test J instruction (JUMP) ---
		instruction <= INSTR_J;
		wait for clk_period;
		AssertFetchState;
		wait for clk_period;
		AssertExecuteState;
		
		-- reg write 0
		assert reg_write_out = '0'
			report "reg_write_out should be '0' for J instruction to prevent data from ALU or memory to be written to register"
			severity failure;

		-- mem write 0
		assert mem_write_out = '0'
			report "mem_write_out should be '0' for J instruction to prevent data being written to memory"
			severity failure;

		-- branch enable
		assert branch_out = '0'
			report "branch_out should be '0' on J instruction"
			severity failure;
	
		-- jump disable
		assert jump_out = '1'
			report "jump_out should be '1' on J instruction"
			severity failure;

		report "J instruction passed";


		report "Test success";
		wait;


	end process;

END;
