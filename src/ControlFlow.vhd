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

	signal pc : unsigned(DATA_WIDTH-1 downto 0);
	
begin

	-- Process for PC register
	PCBehaviour: process(clk, reset, pc_write_in)
	begin
		if reset = '1' then
			pc <= (others => '0');
		elsif rising_edge(clk) and pc_write_in then
			-- Handle Jumps
			if jump_in then
				pc <= (pc and x"FC000000") or (unsigned(instruction_in) and x"03FFFFFF");
			-- Handle branches
			elsif branch_in and alu_zero_in then
				pc <= pc + 1 + unsigned(
					(DATA_WIDTH-1 downto 16 => instruction_in(15)) & instruction_in(15 downto 0)
				);
			-- Handle increment by 1
			else
				pc <= pc + 1;
			end if;
		end if;
	end process;
	pc_out <= std_logic_vector(pc(ADDR_WIDTH-1 downto 0));



end Behavioral;

