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
		instruction_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
		alu_shamt_out : out std_logic_vector(4 downto 0);
		alu_control_out : out alu_operation_t;
		read_reg_1_out, read_reg_2_out, write_reg_out : out std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
		pc_write_out, branch_out, jump_out, reg_write_out, mem_write_out : out boolean;
		reg_src_out : out reg_src_t;
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

	-- State register for state machine
	type control_state is (START, FETCH, EXECUTE, STALL);
	signal state : control_state;

	-- Signals to make code simpler
	signal opcode, func : std_logic_vector (5 downto 0);
	signal rs, rt, rd, shamt : std_logic_vector (4 downto 0);
	signal func_op : alu_operation_t;

	signal is_i_type, is_j_type, is_r_type : boolean;
	signal is_load_store : boolean;
	signal is_load : boolean;
	signal is_store : boolean;
	signal is_jump : boolean;
	signal is_branch : boolean;
	signal is_enabled : boolean;

begin

	-- State machine updates
	state_proc: process(clk, reset)
	begin
		if reset = '1' then
			state <= START;
		elsif rising_edge(clk) and is_enabled then
			if state = FETCH then
				state <= EXECUTE;
			elsif state = EXECUTE and is_load_store then
				state <= STALL;
			else
				state <= FETCH;
			end if;
		end if;
	end process;


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


	-- Set control signals
	alu_src_out <= ALU_SRC_IMMEDIATE when is_i_type and not is_branch else ALU_SRC_REGISTER;
	jump_out <= is_j_type;
	branch_out <= is_branch;
	mem_write_out <= is_store and state = STALL;
	reg_src_out <= REG_SRC_MEMORY when is_load else REG_SRC_ALU;

	pc_write_out <= (
				(state = EXECUTE and not is_load_store) or state = STALL
			) and is_enabled;

	reg_write_out <= (
			state = EXECUTE and
			not is_jump and
			not is_branch and
			not is_load_store
		) or (
			state = STALL and is_load
		);

	-- Set register addresses
	read_reg_1_out <= rs;
	read_reg_2_out <= rt;
	write_reg_out <= rt when is_i_type else rd;

	-- ALU function selection
	func_op <=
		ALU_ADD when func(5 downto 1) = "10000" else
		ALU_SUB when func(5 downto 1) = "10001" else
		ALU_AND when func = "100100" else
		ALU_OR when func = "100101" else
		ALU_SLT when func = "101010" else
		ALU_SLL;
	
	alu_control_out <=
		ALU_ADD when is_load_store or opcode(5 downto 1) = "00100" else -- ADDI and ADDIU
		ALU_SUB when opcode(5 downto 1) = "00010" else -- SUBI and SUBIU
		ALU_OR when opcode = OP_ORI else
		ALU_AND when opcode = OP_ANDI else
		ALU_SLT when opcode = OP_SLTI else
		func_op when is_r_type else
		ALU_SLL;
	
	alu_shamt_out <= "10000" when opcode = OP_LUI else shamt;


end Behavioral;
