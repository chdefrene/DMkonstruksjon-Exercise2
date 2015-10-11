library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

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
		alu_control_out : out alu_operation_t;
		read_reg_1_out, read_reg_2_out, write_reg_out : out std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
		pc_write, branch_out, jump_out, reg_write_out, alu_src_out, mem_to_reg_out, mem_write_out : out std_logic
	);

end Control;

architecture Behavioral of Control is

begin


end Behavioral;

