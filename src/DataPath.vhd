library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;


entity DataPath is
	generic (
		ADDR_WIDTH : integer := 8;	
		DATA_WIDTH : integer := 32;
		REG_ADDR_WIDTH : integer := 5;
		IMMEDIATE_WIDTH : integer := 16
	);
	port (
		clk, reset : in std_logic;
		read_reg_1_in, read_reg_2_in, write_reg : in std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
		immediate_in : in std_logic_vector(IMMEDIATE_WIDTH-1 downto 0);
		-- Control signals
		reg_write_in, alu_src_in, mem_to_reg_in : in std_logic;
		alu_result_out : out std_logic_vector(DATA_WIDTH-1 downto 0);  
		write_data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end DataPath;

architecture Behavioral of DataPath is

begin


end Behavioral;

