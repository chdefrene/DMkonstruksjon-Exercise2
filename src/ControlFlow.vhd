library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;


entity ControlFlow is
	generic (
		ADDR_WIDTH : integer := 8;	
		DATA_WIDTH : integer := 32
	);
	port (
		clk, reset : in std_logic;
		pc_out : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		instruction_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
		alu_zero_in, branch_in, jump_in : in std_logic
	);

end ControlFlow;

architecture Behavioral of ControlFlow is
	
	signal pc, pc_in, pc_add_1, pc_jump, pc_imm_signex, pc_add_imm, pc_branch: std_logic_vector(DATA_WIDTH-1 downto 0);
begin


	PCBehaviour: process is
	begin
		if reset = '0' then
			pc <= (others => '0');
		elsif rising_edge(clk) then
			pc <= pc_in;
		end if;
	end process;
	
	pc_add_1 <= pc + 1;
	pc_jump <= pc(31 downto 26) & instruction_in(25 downto 0);
	pc_imm_signex <= std_logic_vector(resize(signed(instruction(15 downto 0)), DATA_WIDTH));
	pc_add_imm <= pc_imm_signex + pc_add_1;
	pc_branch <= pc_add_1 when (branch_in = '1' and alu_zero_in = '1')
		else pc_add_imm;
	pc_in <= pc_jump when jump_in = '1' else pc_branch;
	pc_out <= pc(ADDR_WIDTH-1 downto 0);

end Behavioral;

