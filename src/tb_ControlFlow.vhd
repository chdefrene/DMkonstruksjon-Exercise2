LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_ControlFlow IS
END tb_ControlFlow;

ARCHITECTURE behavior OF tb_ControlFlow IS

	 -- Component Declaration for the Unit Under Test (UUT)

	COMPONENT ControlFlow
	GENERIC(
			  ADDR_WIDTH : integer := 32
		 );
	 PORT(
			clk : IN  std_logic;
			reset : IN	std_logic;
			pc_out : OUT  std_logic_vector(31 downto 0);
			alu_zero_in : IN	boolean;
			branch_in : IN  boolean;
			jump_in : IN  boolean;
			pc_write_in : IN	boolean;
			instruction_in : IN	std_logic_vector(31 downto 0)
		  );

	 END COMPONENT;


	--Inputs
	signal clk : std_logic := '0';
	signal reset : std_logic := '0';
	signal alu_zero_in : boolean := false;
	signal branch_in : boolean := false;
	signal jump_in : boolean := false;
	signal pc_write_in : boolean := false;
	signal instruction_in : std_logic_vector(31 downto 0) := x"00000000";

	--Outputs
	signal pc_out : std_logic_vector(31 downto 0);

	-- Clock period definitions
	constant clk_period : time := 10 ns;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: ControlFlow PORT MAP (
			 clk => clk,
			 reset => reset,
			 pc_out => pc_out,
			 alu_zero_in => alu_zero_in,
			 branch_in => branch_in,
			 jump_in => jump_in,
			 pc_write_in => pc_write_in,
			 instruction_in => instruction_in
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
		-- hold reset state for 100 ns.
		reset <= '1';
		wait for 100 ns;
		reset <= '0';

		-- Default pc value
		assert pc_out = x"00000000"
			report "pc_out should be 0 after first clock cycle"
			severity failure;


		-- No change on pc_write = 0
		for i in 0 to 8 loop
			if (i mod 2) = 0 then
				branch_in <= false;
			else
				branch_in <= true;
			end if;

			if ((i/2) mod 2) = 0 then
				alu_zero_in <= false;
			else
				alu_zero_in <= true;
			end if;

			if ((i/4) mod 2) = 0 then
				jump_in <= false;
			else
				jump_in <= true;
			end if;

			wait for clk_period;
			assert pc_out = x"00000000"
				report "pc_out should not change without pc_write = 1"
				severity failure;
		end loop;

		---- Start doing something interesting ----
		pc_write_in <= true;


		-- Automatic pc increase on pc_write
		for i in 1 to 10 loop
			wait for clk_period;

			assert to_integer(unsigned(pc_out)) = i
				report "pc_out should increment by 1 each clock cycle when pc_write = true"
				severity failure;
		end loop;

		-- Can do branching forward
		branch_in <= true;
		alu_zero_in <= true;
		instruction_in <= x"0000000F"; -- Immediate: 15
		wait for clk_period;
		assert to_integer(unsigned(pc_out)) = 26
			report "Does not branch on branch = true and zero = true"
			severity failure;

		-- Can do branching backwards
		instruction_in <= x"0000FFF1"; -- Immediate: -15
		wait for clk_period;
		assert to_integer(unsigned(pc_out)) = 12
			report "Does not branch backwards properly"
			severity failure;

		-- Branching with immediate = 0
		instruction_in <= x"00000000";
		wait for clk_period;
		assert to_integer(unsigned(pc_out)) = 13
			report "Not handeling branch with immediate = 0"
			severity failure;

		-- Branch should only use the last 16 bits
		instruction_in <= x"FFFF0000";
		wait for clk_period;
		assert to_integer(unsigned(pc_out)) = 14
			report "Too much of the instruction used as immediate"
			severity failure;

		-- Not branching when zero = 1
		alu_zero_in <= false;
		wait for clk_period;
		assert to_integer(unsigned(pc_out)) = 15
			report "Branching even when zero = false"
			severity failure;

		-- Not branching when branch = 0
		alu_zero_in <= true;
		branch_in <= false;
		wait for clk_period;
		assert to_integer(unsigned(pc_out)) = 16
			report "Branching even when branch = false"
			severity failure;

		-- Simple jump works
		alu_zero_in <= false;
		branch_in <= false;
		jump_in <= true;
		instruction_in <= x"000000FF";
		wait for clk_period;
		assert pc_out = x"000000FF"
			report "Jump does not jump to correct location"
			severity failure;

		-- Jump uses the 26 last bits of instruction
		instruction_in <= x"FFFFFFFF";
		wait for clk_period;
		assert pc_out = x"03FFFFFF"
			report "Jump uses too many bits of the instruction"
			severity failure;

		-- Try ticking over limits
		for i in 1 to 10 loop
			jump_in <= false;
			wait for clk_period;
			assert to_integer(unsigned(pc_out(31 downto 26))) = i and
					to_integer(unsigned(pc_out(25 downto 0))) = 0
				report "Not incrementing properly after jump"
				severity failure;

			jump_in <= true;
			wait for clk_period;
		end loop;


		report "Test success!";
		wait;

	end process;

END;
