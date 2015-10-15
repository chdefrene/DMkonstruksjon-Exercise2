-- Part of TDT4255 Computer Design laboratory exercises
-- Group for Computer Architecture and Design
-- Department of Computer and Information Science
-- Norwegian University of Science and Technology

-- MIPSProcessor.vhd
-- The MIPS processor component to be used in Exercise 1 and 2.

-- TODO replace the architecture DummyArch with a working Behavioral

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.defs.ALL;

entity MIPSProcessor is
	generic (
		ADDR_WIDTH : integer := 8;
		DATA_WIDTH : integer := 32
	);
	port (
		clk, reset				: in std_logic;
		processor_enable		: in std_logic;
		imem_data_in			: in std_logic_vector(DATA_WIDTH-1 downto 0);
		imem_address			: out std_logic_vector(ADDR_WIDTH-1 downto 0);
		dmem_data_in			: in std_logic_vector(DATA_WIDTH-1 downto 0);
		dmem_address			: out std_logic_vector(ADDR_WIDTH-1 downto 0);
		dmem_data_out			: out std_logic_vector(DATA_WIDTH-1 downto 0);
		dmem_write_enable		: out std_logic
	);
end MIPSProcessor;

architecture DummyArch of MIPSProcessor is

	signal immediate : std_logic_vector(15 downto 0);
	signal alu_1, alu_2, alu_result : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal alu_control : alu_operation_t;
	signal alu_zero, mem_to_reg, alu_src, reg_write, jump, branch, pc_write : std_logic;
	signal alu_shamt, read_reg_1, read_reg_2, write_reg : std_logic_vector(4 downto 0);

begin
	
	data_path : entity work.DataPath port map (
			clk => clk,
			reset => reset,
			read_reg_1_in => read_reg_1,
			read_reg_2_in => read_reg_2,
			write_reg_in => write_reg,
			immediate_in => immediate,
			read_data_in => dmem_data_in,
			alu_result_in => alu_result,
			reg_write_in => reg_write,
			alu_src_in => alu_src,
			mem_to_reg_in => mem_to_reg,
			alu_1_out => alu_1,
			alu_2_out => alu_1,
			write_data_out => dmem_data_out
		);
		
	control_flow : entity work.ControlFlow port map (
			clk => clk,
			reset => reset,
			pc_out => imem_address,
			alu_zero_in => alu_zero,
			branch_in => branch,
			jump_in => jump,
			pc_write_in => pc_write,
			instruction_in => imem_data_in
		);
		
	control : entity work.Control port map (
			clk => clk,
			reset => reset,
			instruction_in => imem_data_in,
			alu_control_out => alu_control,
			alu_shamt_out => alu_shamt,
			read_reg_1_out => read_reg_1,
			read_reg_2_out => read_reg_2,	
			write_reg_out => write_reg,
			pc_write_out => pc_write,
			branch_out => branch,
			jump_out => jump,
			reg_write_out => reg_write,
			alu_src_out => alu_src,
			mem_to_reg_out => mem_to_reg,
			mem_write_out => dmem_write_enable
		);

	alu : entity work.ALU port map (
			reset => reset,
			data_1_in => alu_1,
			data_2_in => alu_2,
			control_in => alu_control,
			shamt_in => alu_shamt,
			result_out => alu_result,
			zero_out => alu_zero
		);

end DummyArch;

