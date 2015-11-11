LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.defs.ALL;


ENTITY tb_Forward IS
END tb_Forward;

ARCHITECTURE behavior OF tb_Forward IS

	constant REG_ADDR_WIDTH : integer := 5;
	constant DATA_WIDTH : integer := 32;


	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT Forward
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
  END COMPONENT;

	-- Inputs
	signal clk : std_logic;
	signal reg_write_in : boolean := false;
	signal read_reg_in : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := "00000";
	signal write_reg_in : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := "00000";
	signal alu_in : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000000";
	signal alu_result_in : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000000";
	signal read_data_in : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000000";
	
	-- Outputs
	signal alu_out : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000000";
	
	constant clk_period : time := 10 ns;


BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: Forward PORT MAP (
		clk => clk,
		reg_write_in => reg_write_in,
		read_reg_in => read_reg_in,
		write_reg_in => write_reg_in,
		alu_in => alu_in,
		alu_result_in => alu_result_in,
		read_data_in => read_data_in,
		alu_out => alu_out
	);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
	
	-- Stimulus process
	stim_proc: process

	begin

		-- Initialize data inputs
		alu_in <= x"00000011";
		alu_result_in <= x"00110000";
		read_data_in <= x"11000000";
		
		-- Set read_reg to 00001 in ID
		read_reg_in <= "00001";
		
		-- Next pipeline stage
		wait for clk_period;
		
		read_reg_in <= "00010";
		write_reg_in <= "00001";
		reg_write_in <= true;
		
		
		
		-- ID/EX read_reg is 00001 EX/MEM write_reg is 00001
		wait for 2*clk_period/5;
		assert alu_out = alu_result_in
			report "Should forward alu_result_in when ID/EX read_reg = EX/MEM write_reg"
			severity failure;
		wait for 3*clk_period/5;
		
		read_reg_in <= "00011";
		write_reg_in <= "00011";
		reg_write_in <= true;
		
		
		-- ID/EX read_reg is 00010, EX/MEM write_reg is 00011, MEM/WB write_reg is 00001
		wait for 2*clk_period/5;
		assert alu_out = alu_in
			report "Should not forward when ID/EX read_reg is different from EX/MEM write_reg and MEM/WB write_reg"
			severity failure;
		wait for 3*clk_period/5;
		
		read_reg_in <= "00000";
		write_reg_in <= "00001";
		reg_write_in <= true;
		

		-- ID/EX read_reg is 00011, EX/MEM write_reg is 00001, MEM/WB write_reg is 00011
		wait for 2*clk_period/5;
		assert alu_out = read_data_in
			report "Should forward read_data_in when ID/EX read_reg is equal to MEM/WB write_reg but not EX/MEM write_reg"
			severity failure;
		wait for 3*clk_period/5;
			
		read_reg_in <= "00000";
		write_reg_in <= "00000";
		reg_write_in <= true;
		

		-- ID/EX read_reg is 00000, EX/MEM write_reg is 00000, MEM/WB write_reg is 00001
		wait for 2*clk_period/5;
		assert alu_out = alu_in
			report "Should not forward if ID/EX read_reg = EX/MEM write_reg = 00000"
			severity failure;
		wait for 3*clk_period/5;
		
		read_reg_in <= "00001";
		write_reg_in <= "00001";
		reg_write_in <= true;
		
		
		-- ID/EX read_reg is 00000, EX/MEM write_reg is 00001, MEM/WB write_reg is 00000
		wait for 2*clk_period/5;
		assert alu_out = alu_in
			report "Should not forward if ID/EX read_reg = MEM/WB write_reg = 00000"
			severity failure;
		wait for 3*clk_period/5;

		read_reg_in <= "00001";
		write_reg_in <= "00001";
		
		-- ID/EX read_reg is 00001, EX/MEM write_reg is 00001, MEM/WB write_reg is 00001
		wait for 2*clk_period/5;
		assert alu_out = alu_result_in
			report "Should forward alu_result_in if ID/EX read_reg = EX/MEM write_reg = MEM/WB write_reg"
			severity failure;
		wait for 3*clk_period/5;
		
		
		read_reg_in <= "00001";
		write_reg_in <= "00001";
		reg_write_in <= false;
		
		-- ID/EX read_reg is 00001, EX/MEM is 00001, MEM/WB is 00001, EX/MEM reg_write is false, MEM/WB reg_write is true
		wait for 2*clk_period/5;
		assert alu_out = read_data_in
			report "Should forward read_data if ID/EX read_reg is 00001, EX/MEM is 00001, MEM/WB is 00001, EX/MEM reg_write is false, MEM/WB reg_write is true"
			severity failure;
		wait for 3*clk_period/5;
		
		
		read_reg_in <= "00001";
		write_reg_in <= "00001";
		reg_write_in <= false;
		
		-- ID/EX read_reg is 00001, EX/MEM is 00001, MEM/WB is 00001, EX/MEM reg_write is false, MEM/WB reg_write is false
		wait for 2*clk_period/5;
		assert alu_out = alu_in
			report "Should not forward when ID/EX read_reg is 00001, EX/MEM is 00001, MEM/WB is 00001, EX/MEM reg_write is false, MEM/WB reg_write is true"
			severity failure;
		wait for 3*clk_period/5;
		
		
		read_reg_in <= "00001";
		write_reg_in <= "00001";
		reg_write_in <= true;
		
		-- ID/EX read_reg is 00001, EX/MEM is 00001, MEM/WB is 00001, EX/MEM reg_write is true, MEM/WB reg_write is false
		wait for 2*clk_period/5;
		assert alu_out = alu_result_in
			report "Should not forward when ID/EX read_reg is 00001, EX/MEM is 00001, MEM/WB is 00001, EX/MEM reg_write is true, MEM/WB reg_write is false"
			severity failure;
		wait for 3*clk_period/5;
		
		
		report "Test success";
		wait;


	end process;

END;
