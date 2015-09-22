library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;


entity ALU is
	generic (
		ADDR_WIDTH : integer := 8;	
		DATA_WIDTH : integer := 32
	);
	port (
		clk, reset : in std_logic;
		data_1_in, data_2_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
		control_in : in std_logic_vector(TEMP downto 0); -- TODO fix!!!!!!!!111!
		result_out : out std_logic_vector(DATA_WIDTH-1 downto 0);
		zero_out : out std_logic
	);
		

end ALU;

architecture Behavioral of ALU is

begin


end Behavioral;

