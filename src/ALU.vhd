library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.defs.all;

entity ALU is
	generic (
		ADDR_WIDTH : integer := 8;
		DATA_WIDTH : integer := 32;
		SHAMT_WIDTH : integer := 5
	);
	port (
		clk, reset : in std_logic;
		data_1_in : in std_logic_vector(DATA_WIDTH-1 downto 0); 		-- read data 1
		data_2_in : in std_logic_vector(DATA_WIDTH-1 downto 0);		-- read data 2
		control_in : in alu_operation_t;
		shamt_in : std_logic_vector(SHAMT_WIDTH-1 downto 0);
		result_out : out std_logic_vector(DATA_WIDTH-1 downto 0);
		zero_out : out std_logic
	);
		
end entity ALU;

architecture behavioural of ALU is
	
	signal result : std_logic_vector(DATA_WIDTH-1 downto 0);
	
begin 


	alu_behaviour: process(data_1_in, data_2_in, shamt_in, control_in, reset)
	begin
		if reset = '1' then
			result <= (others => '0');
		else
			case (control_in) is
				when ALU_ADD =>
					result <= std_logic_vector(signed(data_1_in) + signed(data_2_in));
		
				when ALU_SUB =>
					result <= std_logic_vector(signed(data_1_in) - signed(data_2_in));
					
				when ALU_AND =>
					result <= data_1_in and data_2_in;
					
				when ALU_OR =>
					result <= data_1_in or data_2_in;
					
				when ALU_SLT =>
					if signed(data_1_in) < signed(data_2_in) then
						result <= (0 => '1', others => '0');
					else
						result <= (others => '0');
					end if;
					
				when ALU_SLL =>
					result <= std_logic_vector(shift_left(unsigned(data_2_in), to_integer(unsigned(shamt_in))));
					
				when others =>
					result <= (others => '0');
					
			end case;
		end if;
	end process;

	-- Output zero if result is 0
	zero_out <= '1' when unsigned(result) = 0 else '0';
	
	-- Output result
	result_out <= result;


end architecture behavioural;
