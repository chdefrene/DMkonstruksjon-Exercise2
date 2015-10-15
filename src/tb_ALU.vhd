LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.defs.ALL;


ENTITY tb_ALU IS
END tb_ALU;

ARCHITECTURE behavior OF tb_ALU IS
	constant ADDR_WIDTH : integer := 8;
	constant DATA_WIDTH : integer := 32;
	constant SHAMT_WIDTH : integer := 5;

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT ALU
	generic (
		ADDR_WIDTH : integer := 8;	
		DATA_WIDTH : integer := 32;
		SHAMT_WIDTH : integer := 5
	);
	port (
		clk, reset : in std_logic;
		data_1_in, data_2_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
		control_in : in alu_operation_t;
		shamt_in : in std_logic_vector(SHAMT_WIDTH-1 downto 0);
		result_out : out std_logic_vector(DATA_WIDTH-1 downto 0);
		zero_out : out std_logic
	);
  END COMPONENT;


   --Inputs
	signal clk : std_logic := '0';
	signal reset : std_logic := '0';
	signal data_1_in : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000000";
	signal data_2_in : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000000";
	signal control_in : alu_operation_t := ALU_ADD;
	signal shamt_in : std_logic_vector(SHAMT_WIDTH-1 downto 0) := "00000";

	--Outputs
	signal result_out : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000000";
	signal zero_out: std_logic;

	-- Clock period definitions
	constant clk_period : time := 10 ns;

	-- Testbench correct result
	signal tb_correct_result : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000000";
	


BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: ALU PORT MAP (
		clk => clk,
		reset => reset,
		data_1_in => data_1_in,
		data_2_in => data_2_in,
		control_in => control_in,
		shamt_in => shamt_in,
		result_out => result_out,
		zero_out => zero_out
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


		-- Procedure for asserting zero_out
		procedure AssertZero is
		begin
			if unsigned(tb_correct_result) = 0 then
				assert zero_out = '1'
					report "zero_out should be 1 when result_out is 0"
					severity failure;
			else
				assert zero_out = '0'
					report "zero_out should be 0 when result_out is not 0"
					severity failure;
			end if;	
		end AssertZero;


		-- Procedure for asserting values
		procedure AssertNumber(
			data_1 : integer;
			data_2 : integer;
			result : integer;
			correct_result : integer;
			alu_operation : alu_operation_t) is
			variable alu_operation_string : string(1 to 3);
			variable string_length : integer;
		begin
			-- ALU operation string for building a report string
			case alu_operation is
				when ALU_ADD =>
					alu_operation_string := " + ";
				when ALU_SUB =>
					alu_operation_string := " - ";
				when ALU_AND =>
					alu_operation_string := "AND";
				when ALU_OR =>
					alu_operation_string := "OR ";
				when ALU_SLT =>
					alu_operation_string := "SLT";
				when ALU_SLL =>
					alu_operation_string := "SLL";
			end case;
			
			-- Assert and report error
			assert result_out = tb_correct_result
				report
					integer'image(data_1) &
					" " & alu_operation_string(1 to 3) & " " &
					integer'image(data_2) &
					" should be: " & integer'image(correct_result) &
					", was: " & integer'image(result)
				severity failure;
			AssertZero;
		end AssertNumber;


		-- Procedure for checking result
		procedure CheckResult(
			data_1 : integer;
			data_2 : integer;
			shamt  : integer;
			alu_operation: alu_operation_t) is
			variable assert_arg1 : integer;
			variable assert_arg2 : integer;
		begin
			-- arguments to AssertNumber
			assert_arg1 := data_1;
			assert_arg2 := data_2;
			
			-- Set the in signals
			data_1_in <= std_logic_vector(to_signed(data_1, DATA_WIDTH));
			data_2_in <= std_logic_vector(to_signed(data_2, DATA_WIDTH));
			shamt_in <= std_logic_vector(to_unsigned(shamt, SHAMT_WIDTH));
			control_in <= alu_operation;
			
			-- Set the correct result to check against
			case alu_operation is
				when ALU_ADD =>
					tb_correct_result <= std_logic_vector(to_signed(data_1 + data_2, DATA_WIDTH));		
				when ALU_SUB =>
					tb_correct_result <= std_logic_vector(to_signed(data_1 - data_2, DATA_WIDTH));
				when ALU_AND =>
					tb_correct_result <= std_logic_vector(to_signed(data_1, DATA_WIDTH) and to_signed(data_2,DATA_WIDTH));
				when ALU_OR =>
					tb_correct_result <= std_logic_vector(to_signed(data_1, DATA_WIDTH) or to_signed(data_2,DATA_WIDTH));
				when ALU_SLT =>
					if data_1 < data_2 then
						tb_correct_result <= (0=>'1', others => '0');
					else
						tb_correct_result <= (others => '0');
					end if;
				when ALU_SLL =>
					tb_correct_result <= std_logic_vector(to_signed(data_2,DATA_WIDTH) sll shamt);
					assert_arg1 := data_2;
					assert_arg2 := shamt;
			end case;
			
			-- Wait for signals to propagate
			wait for clk_period;
			
			-- Assert result = correct result
			AssertNumber(
				assert_arg1,
				assert_arg2,
				to_integer(signed(result_out)),
				to_integer(signed(tb_correct_result)),
				alu_operation);
				
		end CheckResult;


		-- Procedure for checking a single ALU operation with multiple numbers
		procedure CheckALUOperation(
			alu_operation : alu_operation_t) is
		begin
			-- Zero test
			CheckResult(0, 0, 0, alu_operation);
			
			-- Positive and zero
			CheckResult(123,0, 0, alu_operation);
			CheckResult(0, 123, 0, alu_operation);
			
			-- -1 and 1
			CheckResult(-1, 1, 0, alu_operation);
			
			-- Try to get overflow / underflow
			CheckResult(294967293,30, 0, alu_operation);
			CheckResult(-294967294,-30, 0, alu_operation);
			
			-- Positive and negative
			CheckResult(321, -123, 0, alu_operation);
			CheckResult(-123, 321, 0, alu_operation);
			
			-- Test with shamt values
			CheckResult(0, 0, 16, alu_operation);
			CheckResult(123,0, 1, alu_operation);
			CheckResult(0, 123, 3, alu_operation);
			CheckResult(-1, 1, 31, alu_operation);
			CheckResult(294967293,30, 5, alu_operation);
			CheckResult(-294967294,-30, 4, alu_operation);
			CheckResult(321, -123, 16, alu_operation);
			CheckResult(-123, 321, 16, alu_operation);

		end CheckALUOperation;


	begin

		-- hold reset state for 100 ns.
		reset <= '1';
		wait for 100 ns;
		reset <= '0';
		
		--- Test the different ALU operations ---
		CheckALUOperation(ALU_ADD);
		report "ADD passed";
		CheckALUOperation(ALU_SUB);
		report "SUB passed";
		CheckALUOperation(ALU_AND);	
		report "AND passed";
		CheckALUOperation(ALU_OR);
		report "OR passed";
		CheckALUOperation(ALU_SLT);
		report "SLT passed";
		CheckALUOperation(ALU_SLL);
		report "SLL passed";


		report "Test success";
		wait;

	end process;

END;
