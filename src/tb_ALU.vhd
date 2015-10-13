LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.defs.ALL;


ENTITY tb_ALU IS
END tb_ALU;

ARCHITECTURE behavior OF tb_ALU IS
	constant ADDR_WIDTH : integer := 8;
	constant DATA_WIDTH : integer := 32;

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT ALU
	generic (
		ADDR_WIDTH : integer := 8;	
		DATA_WIDTH : integer := 32
	);
	port (
		clk, reset : in std_logic;
		data_1_in, data_2_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
		control_in : in alu_operation_t;
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
				if tb_correct_result = std_logic_vector(to_unsigned(0,DATA_WIDTH)) then
				assert zero_out = '0'
					report "zero_out should be 1 when result_out is 0"
					severity failure;
			else
				assert zero_out = '1'
					report "zero_out should be 0 when result_out is not 0"
					severity failure;
			end if;	
		end AssertZero;


		-- Procedure for asserting signed values
		procedure AssertNumber(
			data_1 : integer;
			data_2 : integer;
			result : integer;
			correct_result : integer;
			alu_operation : alu_operation_t) is
			variable alu_operation_string : string(0 to 2);
			variable string_length : integer;
		begin
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
			end case;
			assert result_out = tb_correct_result
				report
					integer'image(data_1) &
					" " & alu_operation_string(0 to 2) & " " &
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
			alu_operation: alu_operation_t) is
		begin
			report "CheckResult";
			-- Check signed values
			data_1_in <= std_logic_vector(to_signed(data_1, DATA_WIDTH));
			data_2_in <= std_logic_vector(to_signed(data_2, DATA_WIDTH));
			control_in <= alu_operation;
			case alu_operation is
				when ALU_ADD =>
					tb_correct_result <= std_logic_vector(signed(data_1_in) + signed(data_2_in));		
				when ALU_SUB =>
					tb_correct_result <= std_logic_vector(signed(data_1_in) - signed(data_2_in));
				when ALU_AND =>
					tb_correct_result <= data_1_in and data_2_in;
				when ALU_OR =>
					tb_correct_result <= data_1_in or data_2_in;
				when ALU_SLT =>
					if signed(data_1_in) < signed(data_2_in) then
						tb_correct_result <= (0=>'1', others => '0');
					else
						tb_correct_result <= (others => '0');
					end if;
			end case;
			wait for clk_period;
			AssertNumber(
				data_1,
				data_2,
				to_integer(signed(result_out)),
				to_integer(signed(tb_correct_result)),
				alu_operation);

			-- Check unsigned values
			data_1_in <= std_logic_vector(to_unsigned(data_1, DATA_WIDTH));
			data_2_in <= std_logic_vector(to_unsigned(data_2, DATA_WIDTH));
			control_in <= alu_operation;
			case alu_operation is
				when ALU_ADD =>
					tb_correct_result <= std_logic_vector(unsigned(data_1_in) + unsigned(data_2_in));		
				when ALU_SUB =>
					tb_correct_result <= std_logic_vector(unsigned(data_1_in) - unsigned(data_2_in));
				when ALU_AND =>
					tb_correct_result <= data_1_in and data_2_in;
				when ALU_OR =>
					tb_correct_result <= data_1_in or data_2_in;
				when ALU_SLT =>
					if unsigned(data_1_in) < unsigned(data_2_in) then
						tb_correct_result <= (0=>'1', others => '0');
					else
						tb_correct_result <= (others => '0');
					end if;
			end case;
			wait for clk_period;
			AssertNumber(
				data_1,
				data_2,
				to_integer(unsigned(result_out)),
				to_integer(unsigned(tb_correct_result)),
				alu_operation);
		end CheckResult;


		-- Procedure for checking a single ALU operation with multiple numbers
		procedure CheckALUOperation(
			alu_operation : alu_operation_t) is
		begin
			CheckResult(0, 0, alu_operation);
			CheckResult(200,0, alu_operation);
			CheckResult(0, 200, alu_operation);
			CheckResult(-1, 1, alu_operation);
			CheckResult(294967293,30, alu_operation);
			CheckResult(-294967294,-30, alu_operation);
			CheckResult(321, -123, alu_operation);
			CheckResult(-123, 321, alu_operation);
			-- TODO add more test cases

		end CheckALUOperation;


	begin

		-- hold reset state for 100 ns.
		reset <= '1';
		wait for 100 ns;
		reset <= '0';

		--- Test the different ALU operations ---
		report "Testing ADD";
		CheckALUOperation(ALU_ADD);
		report "Testing SUB";
		CheckALUOperation(ALU_SUB);
		report "Testing AND";
		CheckALUOperation(ALU_AND);	
		report "Testing OR";
		CheckALUOperation(ALU_OR);
		report "Testing SLT";
		CheckALUOperation(ALU_SLT);


		report "Test success";
		wait;

		--- TODO Consider implementing these ---

		-- NOR
		-- XOR
		-- MULT
		-- DIV
		-- SLL
		-- SRL
		-- SRA

	end process;

END;