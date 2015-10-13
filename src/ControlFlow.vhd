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
		alu_zero_in, branch_in, jump_in, pc_write_in : in std_logic
	);

end ControlFlow;

architecture Behavioral of ControlFlow is

	signal pc, pc_in, pc_add_1, pc_jump, pc_immediate_signextend, pc_add_immediate, pc_branch : signed(DATA_WIDTH-1 downto 0);
	
begin

	-- Process for PC register
	PCBehaviour: process(clk, reset)
	begin
		if reset = '1' then
			pc <= (others => '0');
		elsif rising_edge(clk) and pc_write_in = '1' then
			pc <= pc_in;
		end if;
	end process;
	
	-- Increment PC with 1
	pc_add_1 <= pc + 1;
	
	-- Concat pc[31-26] and instruction[25-0] to get jump address
	pc_jump <= signed(std_logic_vector(pc(31 downto 26)) & instruction_in(25 downto 0));
	
	-- Use resize on signed to sign extend immediate value
	pc_immediate_signextend <= (resize(signed(instruction_in(15 downto 0)), DATA_WIDTH));
	
	-- Immediate + PC + 1
	pc_add_immediate <= pc_immediate_signextend + pc_add_1;
	
	-- if zero signal on ALU and branch signal are set, add immediate as offset, else increment with 1 
	pc_branch <= pc_add_immediate when (branch_in = '1' and alu_zero_in = '1')
		else pc_add_1;
	
	-- Choose jump address if jump signal is set
	pc_in <= pc_jump when jump_in = '1' else pc_branch;
	
	-- Cut the address for instruction memory to the correct address width
	pc_out <= std_logic_vector(pc(ADDR_WIDTH-1 downto 0));

end Behavioral;

