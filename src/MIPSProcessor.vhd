-- Part of TDT4255 Computer Design laboratory exercises
-- Group for Computer Architecture and Design
-- Department of Computer and Information Science
-- Norwegian University of Science and Technology

-- MIPSProcessor.vhd
-- The MIPS processor component to be used in Exercise 1 and 2.


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

architecture Behavioral of MIPSProcessor is

	signal alu_1, alu_2, fwd_alu_1, fwd_alu_2, alu_result, reg_2, mem_addr, instruction : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal alu_control : alu_operation_t;
	signal alu_zero, reg_write, fwd_reg_write, jump, branch,
		pc_write, mem_write, hd_jump, hd_reg_write, noop, stall : boolean;
	signal reg_src, hd_reg_src : reg_src_t;
	signal alu_shamt, read_reg_1, read_reg_2, write_reg, fwd_write_reg, hd_write_reg : std_logic_vector(4 downto 0);
	signal alu_src : alu_src_t;

begin

	delayer: entity work.DataDelayer port map (
			clk => clk,
			data_in => imem_data_in,
			data_out => instruction,
			delay => stall
		);
	
	data_path : entity work.DataPath port map (
			clk => clk,
			reset => reset,
			read_reg_1_in => read_reg_1,
			read_reg_2_in => read_reg_2,
			write_reg_in => write_reg,
			immediate_in => instruction(15 downto 0),
			read_data_in => dmem_data_in,
			alu_result_in => alu_result,
			reg_write_in => reg_write,
			alu_src_in => alu_src,
			reg_src_in => reg_src,
			alu_1_out => fwd_alu_1,
			alu_2_out => alu_2,
			write_data_out => dmem_data_out,
			mem_addr_out => mem_addr,
			fwd_reg_2_data => reg_2,
			fwd_write_data => fwd_alu_2
		);
		
	control_flow : entity work.ControlFlow port map (
			clk => clk,
			reset => reset,
			pc_out => imem_address,
			alu_zero_in => alu_zero,
			branch_in => branch,
			jump_in => jump,
			pc_write_in => pc_write,
			instruction_in => instruction
		);
		
	control : entity work.Control port map (
			clk => clk,
			noop_in => noop,
			stall_in => stall,
			reset => reset,
			enable => processor_enable,
			instruction_in => instruction,
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
			reg_src_out => reg_src,
			mem_write_out => mem_write,
			hd_jump_out => hd_jump,
			hd_write_reg_out => hd_write_reg,
			hd_reg_write_out => hd_reg_write,
			hd_reg_src_out => hd_reg_src,
			fwd_write_reg_out => fwd_write_reg,
			fwd_reg_write_out => fwd_reg_write
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

	-- Forwarding units - one for each alu input
	forward_1: entity work.Forward port map (
			clk => clk,
			reg_write_in => fwd_reg_write,
			read_reg_in => read_reg_1,
			write_reg_in => fwd_write_reg,
			alu_in => fwd_alu_1,
			alu_result_in => mem_addr,
			read_data_in => dmem_data_in,
			alu_out => alu_1
		);

	forward_2: entity work.Forward port map (
			clk => clk,
			reg_write_in => fwd_reg_write,
			read_reg_in => read_reg_2,
			write_reg_in => fwd_write_reg,
			alu_in => reg_2,
			alu_result_in => mem_addr,
			read_data_in => dmem_data_in,
			alu_out => fwd_alu_2
		);
		
	hazard_detection: entity work.HazardDetection port map (
		if_id_read_reg_1_in => read_reg_1,
		if_id_read_reg_2_in => read_reg_2,
		id_ex_write_reg_in => hd_write_reg,
		id_ex_reg_src_in => hd_reg_src,
		id_ex_reg_write_in => hd_reg_write,
		id_ex_branch_in => branch,
		id_ex_jump_in => hd_jump,
		stall_out => stall,
		noop_out => noop
	);

	dmem_address <= mem_addr(ADDR_WIDTH-1 downto 0);
	dmem_write_enable <= '1' when mem_write else '0';

end Behavioral;

