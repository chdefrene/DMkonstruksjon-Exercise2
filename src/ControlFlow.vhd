library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;


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

begin


end Behavioral;

