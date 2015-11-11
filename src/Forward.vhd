library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

entity Forward is
	generic (
		DATA_WIDTH : integer := 32
	);
	port (
		clk : in std_logic;
		reg_write_in : in boolean;
		read_reg_in, write_reg_in : in std_logic_vector(4 downto 0);
		alu_in, alu_result_in, read_data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
		alu_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end Forward;

architecture Behavioral of Forward is
	signal forward_alu_result, forward_read_data : boolean;
	
	-- ID/EX
	signal ex_is_zero : boolean;
	signal ex_read_reg : std_logic_vector(4 downto 0);
	
	-- MEM/WB
	signal wb_reg_write : boolean;
	signal wb_write_reg : std_logic_vector(4 downto 0);

begin
	
	-- Propagate data through pipeline stages
	process(clk) is begin
		if rising_edge(clk) then
			ex_is_zero <= read_reg_in = "00000";
			ex_read_reg <= read_reg_in;
			wb_reg_write <= reg_write_in;
			wb_write_reg <= write_reg_in;
		end if;
	end process;

	-- Determine whether to forward
	forward_alu_result <= reg_write_in and
			not ex_is_zero and
			ex_read_reg = write_reg_in;
	
	forward_read_data <= wb_reg_write and
			not ex_is_zero and
			ex_read_reg = wb_write_reg;
	
	-- Do forwarding
	alu_out <=
		alu_result_in when forward_alu_result else
		read_data_in when forward_read_data else
		alu_in;

end Behavioral;

