library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DataDelayer is
	generic (
		DATA_WIDTH : integer := 32
	);
	port (
		clk : in std_logic;
		delay : in boolean;
		data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
		data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end DataDelayer;

architecture Behavioral of DataDelayer is
	signal delayed_data : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal delay_next : boolean;
begin

	process(clk)
	begin
		if rising_edge(clk) then
			delayed_data <= data_in;
			delay_next <= delay;
		end if;
	end process;
	
	data_out <= delayed_data when delay_next else data_in;

end Behavioral;

