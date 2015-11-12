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
		alu_zero_in, branch_in, jump_in, pc_write_in : in boolean
	);

end ControlFlow;

architecture Behavioral of ControlFlow is

	signal pc, extended_imm, next_pc, jump_target, branch_target, branch_base : unsigned(DATA_WIDTH-1 downto 0);
	
begin

	-- Process for PC register
	PCBehaviour: process(clk, reset, pc_write_in)
	begin
		if reset = '1' then
			pc <= (others => '0');
		elsif rising_edge(clk) then

			-- Fetch => decode
			branch_base <= next_pc;

			-- Decode => Execute
			branch_target <= branch_base + unsigned(
					(DATA_WIDTH-1 downto 16 => instruction_in(15)) & instruction_in(15 downto 0)
				);

			-- * => Fetch
			if jump_in then
				pc <= branch_base(DATA_WIDTH - 1 downto DATA_WIDTH - 6) &
					unsigned(instruction_in(DATA_WIDTH - 7 downto 0));
			elsif branch_in and alu_zero_in then
				pc <= branch_target;
			elsif pc_write_in then
				pc <= next_pc;
			end if;

		end if;
	end process;

	next_pc <= pc + 1;
	pc_out <= std_logic_vector(pc(ADDR_WIDTH-1 downto 0));

end Behavioral;
