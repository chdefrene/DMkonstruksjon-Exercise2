library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_MISC.ALL;
use work.defs.ALL;

entity Control is
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
			read_reg_1_out, read_reg_2_out, write_reg_out, fwd_write_reg_out, hd_write_reg_out : out std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
			pc_write_out, branch_out, jump_out, reg_write_out, fwd_reg_write_out,
				hd_reg_write_out, mem_write_out, hd_jump_out : out boolean;
			reg_src_out, hd_reg_src_out : out reg_src_t;
			alu_src_out : out alu_src_t
	);

end Control;


architecture Behavioral of Control is
	-- Opcodes for later
	constant OP_LUI : std_logic_vector := "001111";
	constant OP_ANDI : std_logic_vector := "001100";
	constant OP_ORI : std_logic_vector := "001101";
	constant OP_SLTI : std_logic_vector := "001010";
	constant OP_JUMP : std_logic_vector := "000010";


	-- Signals to make code simpler
	signal opcode, func : std_logic_vector (5 downto 0);
	signal rs, rt, rd, shamt, write_reg, alu_shamt : std_logic_vector (4 downto 0);
	signal func_op, alu_control : alu_operation_t;
	signal reg_src : reg_src_t;
	signal alu_src : alu_src_t;

	signal is_i_type, is_j_type, is_r_type, is_load_store, is_load,
		is_store,is_jump,is_branch, is_enabled, is_noop, is_stall : boolean;
	
	-- ID/EX registers
	signal ex_branch, ex_jump, ex_reg_write, ex_mem_write : boolean;
	signal ex_write_reg, ex_alu_shamt : std_logic_vector(4 downto 0);
	signal ex_reg_src : reg_src_t;
	signal ex_alu_control : alu_operation_t;
	signal ex_alu_src : alu_src_t;
	
	-- EX/MEM
	signal mem_reg_write, mem_mem_write : boolean;
	signal mem_write_reg : std_logic_vector(4 downto 0);
	signal mem_reg_src : reg_src_t;
	
	-- MEM/WB
	signal wb_reg_write : boolean;
	signal wb_write_reg : std_logic_vector(4 downto 0);
	signal wb_reg_src : reg_src_t;

begin

	-- Extract information from instruction
	opcode <= instruction_in(31 downto 26);
	rs <= instruction_in(25 downto 21);
	rt <= instruction_in(20 downto 16);
	rd <= instruction_in(15 downto 11);
	func <= instruction_in(5 downto 0);
	shamt <= instruction_in(10 downto 6);

	-- Decode instruction
	is_i_type <= or_reduce(opcode(5 downto 2)) = '1';
	is_j_type <= not is_i_type and (opcode(1) = '1' or opcode(0) = '1');
	is_r_type <= not is_i_type and not is_j_type;
	is_load_store <= opcode(5) = '1';
	is_load <= is_load_store and opcode(3) = '0';
	is_store <= is_load_store and opcode(3) = '1';
	is_jump <= opcode = OP_JUMP;
	is_branch <= opcode(4 downto 1) = "0010";
	is_enabled <= enable = '1';
	is_noop <= noop_in or not is_enabled;
	is_stall <= stall_in or not is_enabled;
	
	-- Handle pipeline registers
	process (clk, reset) is begin
		if reset = '1' then
			-- ID/EX registers
			ex_branch <= false;
			ex_jump <= false;
			ex_reg_write <= false;
			ex_mem_write <= false;
			
			-- EX/MEM
			mem_reg_write <= false;
			mem_mem_write <= false;
			
			-- MEM/WB
			wb_reg_write <= false;

		elsif rising_edge(clk) then
			-- ID/EX
			ex_branch <= is_branch and not is_noop;
			ex_jump <= is_j_type and not is_noop;
			ex_reg_write <= (not is_noop and
				not is_jump and
				not is_branch and
				not is_store);
			ex_mem_write <= is_store and not is_noop;
			ex_write_reg <= write_reg;
			ex_reg_src <= reg_src;
			ex_alu_control <= alu_control;
			ex_alu_src <= alu_src;
			ex_alu_shamt <= alu_shamt;

			-- EX/MEM
			mem_reg_write <= ex_reg_write;
			mem_mem_write <= ex_mem_write;
			mem_write_reg <= ex_write_reg;
			mem_reg_src <= ex_reg_src;
		
			-- MEM/WB
			wb_reg_write <= mem_reg_write;
			wb_write_reg <= mem_write_reg;
			wb_reg_src <= mem_reg_src;

		end if;
	end process;


	-- Set control signals
	pc_write_out <= not is_stall;
	reg_src <= REG_SRC_MEMORY when is_load else REG_SRC_ALU;
	alu_src <= ALU_SRC_IMMEDIATE when is_i_type and not is_branch else ALU_SRC_REGISTER;

	-- Set register addresses
	read_reg_1_out <= rs;
	read_reg_2_out <= "00000" when is_i_type else rt; -- Prevent forwarding
	write_reg <= rt when is_i_type else rd;

	-- ALU function selection
	alu_control <=
			ALU_ADD when is_load_store or opcode(5 downto 1) = "00100" else -- ADDI and ADDIU
			ALU_SUB when opcode(5 downto 1) = "00010" else -- BEQ and BNE
			ALU_OR when opcode = OP_ORI else
			ALU_AND when opcode = OP_ANDI else
			ALU_SLT when opcode = OP_SLTI else
			func_op when is_r_type else
			ALU_SLL;

	func_op <=
		ALU_ADD when func(5 downto 1) = "10000" else
		ALU_SUB when func(5 downto 1) = "10001" else
		ALU_AND when func = "100100" else
		ALU_OR when func = "100101" else
		ALU_SLT when func = "101010" else
		ALU_SLL;

	alu_shamt <= "10000" when opcode = OP_LUI else shamt;

	-- Output correct signals
	alu_src_out <= ex_alu_src;
	alu_control_out <= ex_alu_control;
	alu_shamt_out <= ex_alu_shamt;
	write_reg_out <= wb_write_reg;
	branch_out <= ex_branch;
	jump_out <= is_j_type and not is_noop;
	reg_write_out <= wb_reg_write;
	mem_write_out <= mem_mem_write;
	reg_src_out <= wb_reg_src;
	fwd_write_reg_out <= mem_write_reg;
	fwd_reg_write_out <= mem_reg_write;
	hd_reg_write_out <= ex_reg_write;
	hd_write_reg_out <= ex_write_reg;
	hd_reg_src_out <= ex_reg_src;
	hd_jump_out <= ex_jump;
	
	

end Behavioral;
