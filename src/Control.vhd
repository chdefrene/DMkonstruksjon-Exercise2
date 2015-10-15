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
		clk, reset : in std_logic;
		instruction_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
		alu_shamt_out : out std_logic_vector(4 downto 0);
		alu_control_out : out alu_operation_t;
		read_reg_1_out, read_reg_2_out, write_reg_out : out std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
		pc_write_out, branch_out, jump_out, reg_write_out, alu_src_out, mem_to_reg_out, mem_write_out : out std_logic
	);

end Control;

architecture Behavioral of Control is
	type control_state is (FETCH, EXECUTE, STALL);
	
	signal state : control_state;
	signal i_type, j_type : std_logic;
	signal opcode : std_logic_vector (5 downto 0);
	signal rs, rt, rd, sh : std_logic_vector (4 downto 0);
	signal func : std_logic_vector (5 downto 0);
	signal func_op : alu_operation_t;

begin

	-- State machine updates
	state_proc: process(clk, reset)
	begin
		if reset = '1' then
			state <= FETCH;
		elsif rising_edge(clk) then
			if state = FETCH then
				state <= EXECUTE;
			elsif state = EXECUTE and instruction_in(31) = '1' then
				state <= STALL;
			else
				state <= FETCH;
			end if;
		end if;
	end process;


	-- Define useful signals
	opcode <= instruction_in(31 downto 26);
	i_type <= or_reduce(opcode(5 downto 2));
	j_type <= not i_type and or_reduce(opcode(1 downto 0));
	rs <= instruction_in(25 downto 21);
	rt <= instruction_in(20 downto 16);
	rd <= instruction_in(15 downto 11);
	sh <= instruction_in(10 downto 6);
	func <= instruction_in(5 downto 0);


	-- Set control signals
	alu_src_out <= '1' when i_type = '1' and opcode(5 downto 1) /= "00010" else '0';
	jump_out <= j_type;
	branch_out <= '1' when opcode(5 downto 1) = "00010" else '0';
	mem_write_out <= '1' when opcode(5 downto 2) = "1010" and state /= FETCH else '0';
	mem_to_reg_out <= '1' when opcode(5 downto 3) = "100" else '0';
	pc_write_out <= '1' when (state = EXECUTE and instruction_in(31) /= '1') or state = STALL else '0';
	reg_write_out <= '1' when
			(
				state /= FETCH and
				opcode /= "000010" and
				opcode(4 downto 1) /= "0010" and
				opcode(5) = '0'
			) or (
				state = STALL and opcode(3) = '0'
			)
		else '0';

	-- Set register addresses
	read_reg_1_out <= rs;
	read_reg_2_out <= rt;
	write_reg_out <= rt when i_type = '1' else rd;

	-- ALU function selection
	func_op <=
		ALU_ADD when func(5 downto 1) = "10000" else
		ALU_SUB when func(5 downto 1) = "10001" else
		ALU_AND when func = "100100" else
		ALU_OR when func = "100101" else
		ALU_SLT when func = "101010" else
		ALU_SLL;
	
	alu_control_out <=
		ALU_ADD when opcode(5) = '1' or opcode(5 downto 1) = "00100" else
		ALU_SUB when opcode(5 downto 1) = "00010" else
		ALU_OR when opcode = "001101" else
		ALU_AND when opcode = "001100" else
		ALU_SLT when opcode = "001010" else
		func_op when or_reduce(opcode(5 downto 0)) = '0' else
		ALU_SLL;
	
	alu_shamt_out <= "10000" when opcode = "001111" else instruction_in(10 downto 6);


end Behavioral;
