LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.defs.ALL;


ENTITY tb_Control IS
END tb_Control;

ARCHITECTURE behavior OF tb_Control IS
	constant ADDR_WIDTH : integer := 8;
	constant DATA_WIDTH : integer := 32;
	constant REG_ADDR_WIDTH : integer := 5;
	constant IMMEDIATE_WIDTH : integer := 16;

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT Control
		generic (
			ADDR_WIDTH : integer := 8;	
			DATA_WIDTH : integer := 32;
			REG_ADDR_WIDTH : integer := 5;
			IMMEDIATE_WIDTH : integer := 16
		);
		port (
			clk, reset, enable : in std_logic;
			noop_in, stall_in : in boolean;
			instruction_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
			alu_control_out : out alu_operation_t;
			alu_shamt_out : out std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
			read_reg_1_out, read_reg_2_out, write_reg_out, fwd_write_reg_out : out std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
			pc_write_out, branch_out, jump_out, reg_write_out, fwd_reg_write_out, mem_write_out : out boolean;
			reg_src_out : out reg_src_t;
			alu_src_out : out alu_src_t
		);
  END COMPONENT;

  --Inputs
	signal clk : std_logic := '0';
	signal reset : std_logic := '0';
	signal enable : std_logic := '1';
	signal noop_in : boolean := false;
	signal stall_in : boolean := false;
	signal instruction_in : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
	--Outputs
	signal alu_control_out : alu_operation_t;
	signal alu_shamt_out : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := (others => '0');
	signal read_reg_1_out, read_reg_2_out, write_reg_out : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := (others => '0');
	signal pc_write_out, branch_out, jump_out, reg_write_out, mem_write_out : boolean := false;
	signal reg_src_out : reg_src_t := REG_SRC_ALU;
	signal alu_src_out : alu_src_t := ALU_SRC_REGISTER;
	
	-- Testbench signals
	signal tb_execute_instruction : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal tb_mem_instruction : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal tb_writeback_instruction : std_logic_vector(DATA_WIDTH-1 downto 0);

	

	-- Clock period definitions
	constant clk_period : time := 10 ns;
	


	-- Constants
	constant FUNC_ADD : std_logic_vector(5 downto 0) := "100000";
	constant FUNC_SUB : std_logic_vector(5 downto 0) := "100010";
	constant FUNC_AND : std_logic_vector(5 downto 0) := "100100";
	constant FUNC_OR  : std_logic_vector(5 downto 0) := "100101";
	constant FUNC_SLT : std_logic_vector(5 downto 0) := "101010";
	constant FUNC_SLL : std_logic_vector(5 downto 0) := "000000";
	
	constant OPCODE_ADDI : std_logic_vector(5 downto 0) := "001000";
	constant OPCODE_ANDI : std_logic_vector(5 downto 0) := "001100";
	constant OPCODE_ORI  : std_logic_vector(5 downto 0) := "001101";
	constant OPCODE_SLTI : std_logic_vector(5 downto 0) := "001010";
	constant OPCODE_LUI  : std_logic_vector(5 downto 0) := "001111";
	
	
	-- Test instructions
	constant INSTR_LW : std_logic_vector(DATA_WIDTH-1 downto 0)    := "100011" & "11100" & "00011" & x"0010";
	constant INSTR_SW : std_logic_vector(DATA_WIDTH-1 downto 0)    := "101011" & "11100" & "00011" & x"0010";
	constant INSTR_ADD : std_logic_vector(DATA_WIDTH-1 downto 0)   := "000000" & "10000" & "01000" & "00100" & "00010" & "100000";
	constant INSTR_ADDI : std_logic_vector(DATA_WIDTH-1 downto 0)  := "001000" & "10000" & "01000" & x"0010";
	constant INSTR_SUB : std_logic_vector(DATA_WIDTH-1 downto 0)   := "000000" & "10000" & "01000" & "00100" & "00010" & "100010";
	constant INSTR_AND : std_logic_vector(DATA_WIDTH-1 downto 0)   := "000000" & "10000" & "01000" & "00100" & "00010" & "100100";
	constant INSTR_ANDI : std_logic_vector(DATA_WIDTH-1 downto 0)  := "001100" & "10000" & "01000" & x"0010";
	constant INSTR_OR : std_logic_vector(DATA_WIDTH-1 downto 0)    := "000000" & "10000" & "01000" & "00100" & "00010" & "100101";
	constant INSTR_ORI : std_logic_vector(DATA_WIDTH-1 downto 0)   := "001101" & "10000" & "01000" & x"0010";
	constant INSTR_SLT : std_logic_vector(DATA_WIDTH-1 downto 0)   := "000000" & "10000" & "01000" & "00100" & "00010" & "101010";
	constant INSTR_SLTI : std_logic_vector(DATA_WIDTH-1 downto 0)  := "001010" & "10000" & "01000" & x"0010";
	constant INSTR_SLL : std_logic_vector(DATA_WIDTH-1 downto 0)   := "000000" & "10000" & "01000" & "00100" & "00010" & "000000";
	constant INSTR_LUI : std_logic_vector(DATA_WIDTH-1 downto 0)   := "001111" & "10000" & "01000" & x"0010";
	constant INSTR_BEQ : std_logic_vector(DATA_WIDTH-1 downto 0)   := "000100" & "10000" & "01000" & x"0010";
	constant INSTR_J : std_logic_vector(DATA_WIDTH-1 downto 0)     := "000010" & "00" & x"000000";
	constant INSTR_NONE : std_logic_vector(DATA_WIDTH-1 downto 0)  := x"00000000";


BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: Control PORT MAP (
		clk => clk,
		reset => reset,
		enable => enable,
		noop_in => noop_in,
		stall_in => stall_in,
		instruction_in => instruction_in,
		alu_control_out => alu_control_out,
		alu_shamt_out => alu_shamt_out,
		read_reg_1_out => read_reg_1_out,
		read_reg_2_out => read_reg_2_out,	
		write_reg_out => write_reg_out,
		pc_write_out => pc_write_out,
		branch_out => branch_out,
		jump_out => jump_out,
		reg_write_out => reg_write_out,
		alu_src_out => alu_src_out,
		reg_src_out => reg_src_out,
		mem_write_out => mem_write_out
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



		procedure AssertALUControl 
			(instruction : std_logic_vector(DATA_WIDTH-1 downto 0)) is 
			variable alu_operation : alu_operation_t;
			variable opcode, func : std_logic_vector(5 downto 0);
		begin
			opcode := instruction(DATA_WIDTH-1 downto DATA_WIDTH-6);
			func := instruction(5 downto 0);

			if opcode = "000000" then
				-- R-Type instruction
				case func is
					when FUNC_ADD =>
						alu_operation := ALU_ADD;
					when FUNC_SUB =>
						alu_operation := ALU_SUB;
					when FUNC_AND =>
						alu_operation := ALU_AND;
					when FUNC_OR =>
						alu_operation := ALU_OR;
					when FUNC_SLT =>
						alu_operation := ALU_SLT;
					when FUNC_SLL =>
						alu_operation := ALU_SLL;
				end case;
				
				assert alu_control_out = alu_operation
					report "EX stage, R-Type: ALU Control does not match instruction"
					severity failure;

			else
				-- I-Type instruction
				case opcode is
					when OPCODE_ADDI =>
						alu_operation := ALU_ADD;
					when OPCODE_ANDI =>
						alu_operation := ALU_AND;
					when OPCODE_ORI =>
						alu_operation := ALU_OR;
					when OPCODE_SLTI =>
						alu_operation := ALU_SLT;
					when OPCODE_LUI =>
						alu_operation := ALU_SLL;
				end case;
				
				assert alu_control_out = alu_operation
					report "EX stage, I-Type: ALU Control does not match instruction"
					severity failure;
			end if;

		end AssertALUControl;




		procedure AssertDecodeStage is
		begin
			assert read_reg_1_out = instruction_in(25 downto 21)
				report "read_reg_1_out should be instruction_in[25-21]"
				severity failure;
			if instruction_in(DATA_WIDTH-1 downto DATA_WIDTH-2) = "00" then
				assert read_reg_2_out = instruction_in(20 downto 16)
					report "read_reg_2_out should be instruction[20-16]"
					severity failure;
			end if;
		end AssertDecodeStage;




		procedure AssertExecuteStage
			(instruction : std_logic_vector(DATA_WIDTH-1 downto 0)) is
			variable opcode : std_logic_vector(5 downto 0) := (others => '0');
		begin
						
			opcode := instruction(DATA_WIDTH-1 downto DATA_WIDTH-6);

			-- R-Type
			if opcode = "000000" then
			
				-- Jump 
				assert jump_out = false
					report "EX stage, R-Type: jump out should be '0'"
					severity failure;
			
				-- ALU src
				assert alu_src_out = ALU_SRC_REGISTER
					report "EX stage, R-Type: alu_src_out should be '0' to select register rt instead of immediate value"
					severity failure;
				
				-- SHAMT should always be put through on R type instruction
				assert alu_shamt_out = instruction_in(10 downto 6)
					report "EX stage R-Type: alu_shamt_out should always be put through on R type instructions"
					severity failure;
					
				-- Assert ALU control signal
				AssertALUControl(instruction);

			-- Jump 
			elsif opcode(5 downto 1) = "0001" then
				assert jump_out = true
					report "EX stage, J: jump out should be '1'"
					severity failure;

			-- BEQ
			elsif opcode(5 downto 2) = "001" then
			
				-- Jump 
				assert jump_out = false
					report "EX stage, BEQ: jump out should be '0'"
					severity failure;
			
				-- ALU src
				assert alu_src_out = ALU_SRC_REGISTER
					report "EX stage, BEQ: alu_src_out should be '0' to select register rt instead of immediate value"
					severity failure;
					
				-- ALU operation ALU_SUB
				assert alu_control_out = ALU_SUB
					report "EX stage, BEQ: alu_control_out should be ALU_SUB for BEQ instruction to compare registers rs and rt"
					severity failure;
					
					
			-- I-Type
			elsif opcode(5 downto 3) = "01" then
			
				-- Jump 
				assert jump_out = false
					report "EX stage, I-Type: jump out should be '0'"
					severity failure;
			
				-- LUI shamt
				if opcode = OPCODE_LUI then
					assert unsigned(alu_shamt_out) = 16
						report "EX stage I-Type: alu_shamt_out should be 16 for LUI instruction"
						severity failure;
				end if;
			
				-- ALU src
				assert alu_src_out = ALU_SRC_IMMEDIATE
					report "EX stage, I-Type: alu_src_out should be '1' to select immediate value instead of register rt"
					severity failure;
					
				-- Assert ALU control signal
				AssertALUControl(instruction);
			

			-- LW
			elsif opcode = "100011" then
			
				-- Jump 
				assert jump_out = false
					report "EX stage, LW: jump out should be '0'"
					severity failure;

				-- ALU should be rs + imm
				assert alu_src_out = ALU_SRC_IMMEDIATE
					report "EX stage, LW: alu_src_out should be '1' for LW instruction to select immediate value for the ALU"
					severity failure;

				-- ALU control should be ADD
				assert alu_control_out = ALU_ADD
					report "EX stage, LW: alu_contorl_out should be ALU_ADD for LW instruction"
					severity failure;


			-- SW
			elsif opcode = "101011" then
				
				-- Jump 
				assert jump_out = false
					report "EX stage, SW: jump out should be '0'"
					severity failure;
				
				-- ALU should be rs + imm
				assert alu_src_out = ALU_SRC_IMMEDIATE
					report "EX stage, SW: alu_src_out should be '1' for SW instruction to select immediate value for the ALU"
					severity failure;

				-- ALU control should be ADD
				assert alu_control_out = ALU_ADD
					report "EX stage, LW: alu_contorl_out should be ALU_ADD for LW instruction"
					severity failure;
	
			end if;	
		end AssertExecuteStage;
		



		procedure AssertMemStage
			(instruction : std_logic_vector(DATA_WIDTH-1 downto 0)) is
			variable opcode : std_logic_vector(5 downto 0) := (others => '0');
		begin
						
			opcode := instruction(DATA_WIDTH-1 downto DATA_WIDTH-6);

			-- Pipeline is not yet filled
			if instruction = INSTR_NONE then
				-- Branch 
				assert branch_out = false
					report "MEM stage, No instruction: branch_out should be '0'"
					severity failure;
				
				-- Mem Write
				assert mem_write_out = false
					report "MEM stage, No instruction: mem_write_out should be '0'"
					severity failure;

			-- R-Type
			elsif opcode = "000000" then
			
				-- Branch 
				assert branch_out = false
					report "MEM stage, R-Type: branch_out should be '0'"
					severity failure;
				
				-- Mem Write
				assert mem_write_out = false
					report "MEM stage, R-Type: mem_write_out should be '0'"
					severity failure;

			-- Jump 
			elsif opcode(5 downto 1) = "0001" then
				
			-- BEQ
			elsif opcode(5 downto 2) = "001" then
					
				-- Branch
				assert branch_out = true
					report "MEM stage, BEQ: branch_out should be '1'"
					severity failure; 
				
				-- Mem Write				
				assert mem_write_out = false
					report "MEM stage, BEQ: mem_write_out should be '0'"
					severity failure;
					
					
			-- I-Type
			elsif opcode(5 downto 3) = "01" then

				-- Branch 
				assert branch_out = false
					report "MEM stage, I-Type: branch_out should be '0'"
					severity failure;
				
				-- Mem Write
				assert mem_write_out = false
					report "MEM stage, I-Type: mem_write_out should be '0'"
					severity failure;

			
			-- LW
			elsif opcode = "100011" then
				
				-- Branch 
				assert branch_out = false
					report "MEM stage, LW: branch_out should be '0'"
					severity failure;
				
				-- Mem Write
				assert mem_write_out = false
					report "MEM stage, LW: mem_write_out should be '0'"
					severity failure;

			-- SW
			elsif opcode = "101011" then
				
				-- Branch 
				assert branch_out = false
					report "MEM stage, SW: branch_out should be '0'"
					severity failure;
				
				-- Mem Write
				assert mem_write_out = true
					report "MEM stage, SW: mem_write_out should be '1'"
					severity failure;

			end if;	
		end AssertMemStage;
		
	

		procedure AssertWriteBackStage
			(instruction : std_logic_vector(DATA_WIDTH-1 downto 0)) is
			variable opcode : std_logic_vector(5 downto 0) := (others => '0');
		begin
						
			opcode := instruction(DATA_WIDTH-1 downto DATA_WIDTH-6);
			


			-- Pipeline is not yet filled
			if instruction = INSTR_NONE then
				-- Reg Write
				assert reg_write_out = false
					report "WB stage, No instruction: reg_write_out should be '0'"
					severity failure;

			-- R-Type
			elsif opcode = "000000" then
				
				-- Write Reg
				assert write_reg_out = instruction(15 downto 11)
					report "WB stage, R-Type: write_reg_out should be instruction_in[15-11] for R type instruction"
					severity failure;

				-- Reg Write
				assert reg_write_out = true
					report "WB stage, R-Type: reg_write_out should be '1'"
					severity failure;
				
				-- Mem to Reg
				assert reg_src_out = REG_SRC_ALU
					report "WB stage, R-Type: mem_to_reg_out should be '0'"
					severity failure;
					
			-- Jump TODO 
			elsif opcode(5 downto 1) = "0001" then
				
			-- BEQ
			elsif opcode(5 downto 2) = "001" then
				
				-- Reg Write
				assert reg_write_out = false
					report "WB stage, BEQ: reg_write_out should be '1'"
					severity failure;
					
			-- I-Type
			elsif opcode(5 downto 3) = "01" then
				
				-- Reg dst
				assert write_reg_out = instruction(20 downto 16)
					report "WB stage, I-Type: write_reg_out should be instruction_in[20-16] for I-Type instruction"
					severity failure;

				-- Reg Write
				assert reg_write_out = true
					report "WB stage, I-Type: reg_write_out should be '1'"
					severity failure;
				
				-- Mem to Reg
				assert reg_src_out = REG_SRC_ALU
					report "WB stage, I-Type: mem_to_reg_out should be '0'"
					severity failure;

			-- LW
			elsif opcode = "100011" then
				
				-- Reg dst
				assert write_reg_out = instruction(20 downto 16)
					report "WB stage, LW: write_reg_out should be instruction_in[20-16] for LW instruction"
					severity failure;

				-- Reg Write
				assert reg_write_out = true
					report "WB stage, LW: reg_write_out should be '1'"
					severity failure;
				
				-- Mem to Reg
				assert reg_src_out = REG_SRC_MEMORY
					report "WB stage, LW: mem_to_reg_out should be '1'"
					severity failure;

			-- SW
			elsif opcode = "101011" then
								
				-- Reg Write
				assert reg_write_out = false
					report "WB stage, SW: reg_write_out should be '0'"
					severity failure;

			end if;	
		end AssertWriteBackStage;


		procedure AssertPipelineStages (
				ex  : std_logic_vector(DATA_WIDTH-1 downto 0);
				mem : std_logic_vector(DATA_WIDTH-1 downto 0);
				wb  : std_logic_vector(DATA_WIDTH-1 downto 0)
			) is
		begin
			AssertExecuteStage(ex);
			AssertMemStage(mem);
			AssertWriteBackStage(wb);
		end AssertPipelineStages;



		procedure InsertInstruction
			(instruction : std_logic_vector(DATA_WIDTH-1 downto 0)) is
		begin
			instruction_in <= instruction;
			AssertDecodeStage;
			AssertExecutestage(tb_execute_instruction);
			AssertMemStage(tb_mem_instruction);
			AssertWriteBackStage(tb_writeback_instruction);
			
			tb_writeback_instruction <= tb_mem_instruction;
			tb_mem_instruction <= tb_execute_instruction;
			tb_execute_instruction <= instruction;
	
		end InsertInstruction;



	begin

		-- hold reset state for 100 ns
		reset <= '1';
		wait for 100 ns;
		reset <= '0';
		
		-- Set enable to 0 to disable the processor
		enable <= '0';

		-- Set some instruction as input
		instruction_in <= INSTR_SW;

		-- Wait a couple of clock cycles
		wait for clk_period*10;
		
		-- Enable the processor again
		enable <= '1';
		
		

		-- Insert instructions
		InsertInstruction(INSTR_LW);
		InsertInstruction(INSTR_SW);
		InsertInstruction(INSTR_BEQ);
		InsertInstruction(INSTR_ADD);
		InsertInstruction(INSTR_ADDI);
		InsertInstruction(INSTR_SUB);
		InsertInstruction(INSTR_AND);
		InsertInstruction(INSTR_ANDI);
		InsertInstruction(INSTR_OR);
		InsertInstruction(INSTR_ORI);
		InsertInstruction(INSTR_SLT);
		InsertInstruction(INSTR_SLTI);
		InsertInstruction(INSTR_SLL);
		InsertInstruction(INSTR_LUI);
		InsertInstruction(INSTR_J);

		-- Insert ADD's to propagate the last instructions through the pipeline
		InsertInstruction(INSTR_ADD);
		InsertInstruction(INSTR_ADD);
		InsertInstruction(INSTR_ADD);
		
		report "Test success";
		wait;


	end process;

END;
