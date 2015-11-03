LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.defs.ALL;
 
ENTITY tb_DataPath IS
END tb_DataPath;
 
ARCHITECTURE behavior OF tb_DataPath IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT DataPath
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         read_reg_1_in : IN  std_logic_vector(4 downto 0);
         read_reg_2_in : IN  std_logic_vector(4 downto 0);
         write_reg_in : IN  std_logic_vector(4 downto 0);
         immediate_in : IN  std_logic_vector(15 downto 0);
         read_data_in : IN  std_logic_vector(31 downto 0);
         alu_result_in : IN  std_logic_vector(31 downto 0);
         reg_write_in : IN  boolean;
         alu_src_in : IN  alu_src_t;
         reg_src_in : IN  reg_src_t;
         alu_1_out : OUT  std_logic_vector(31 downto 0);
         alu_2_out : OUT  std_logic_vector(31 downto 0);
         write_data_out : OUT  std_logic_vector(31 downto 0);
			mem_addr_out : OUT std_logic_vector(31 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal read_reg_1_in : std_logic_vector(4 downto 0) := (others => '0');
   signal read_reg_2_in : std_logic_vector(4 downto 0) := (others => '0');
   signal write_reg_in : std_logic_vector(4 downto 0) := (others => '0');
   signal immediate_in : std_logic_vector(15 downto 0) := (others => '0');
   signal read_data_in : std_logic_vector(31 downto 0) := (others => '0');
   signal alu_result_in : std_logic_vector(31 downto 0) := (others => '0');
	signal mem_addr_out : std_logic_vector(31 downto 0) := (others => '0');
   signal reg_write_in : boolean := false;
   signal alu_src_in : alu_src_t := ALU_SRC_REGISTER;
   signal reg_src_in : reg_src_t := REG_SRC_ALU;

 	--Outputs
   signal alu_1_out : std_logic_vector(31 downto 0);
   signal alu_2_out : std_logic_vector(31 downto 0);
   signal write_data_out : std_logic_vector(31 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: DataPath PORT MAP (
          clk => clk,
          reset => reset,
          read_reg_1_in => read_reg_1_in,
          read_reg_2_in => read_reg_2_in,
          write_reg_in => write_reg_in,
          immediate_in => immediate_in,
          read_data_in => read_data_in,
          alu_result_in => alu_result_in,
          reg_write_in => reg_write_in,
          alu_src_in => alu_src_in,
          reg_src_in => reg_src_in,
          alu_1_out => alu_1_out,
          alu_2_out => alu_2_out,
          write_data_out => write_data_out,
          mem_addr_out => mem_addr_out
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
		-- Checks all regs are zero
		procedure AssertRegsZero is
		begin
			for i in 0 to 31 loop
				read_reg_1_in <= std_logic_vector(to_unsigned(i,5));
				for j in 0 to 31 loop
					read_reg_2_in <= std_logic_vector(to_unsigned(j,5));
					wait for clk_period;
					assert alu_1_out = x"00000000" and alu_2_out = x"00000000"
						report "all registers should be 0 after reset"
						severity failure;
				end loop;
			end loop;
		end procedure;
   begin
	
      -- hold reset state for 100 ns.
		reset <= '1';
      wait for 100 ns;	
		reset <= '0';
		
		-- Set ALU src to output read data 2
		alu_src_in <= ALU_SRC_REGISTER;
		
		AssertRegsZero;
		
		-- Try to fill registers with values when RegWrite is 0
		for i in 1 to 31 loop
			write_reg_in <= std_logic_vector(to_unsigned(i,5));
			alu_result_in <= std_logic_vector(to_unsigned(i,32));
			reg_src_in <= REG_SRC_ALU;
			reg_write_in <= false;
			wait for clk_period;
		end loop;
		
		-- Registers should still be zero
		AssertRegsZero;
			
		-- Fill registers with values when RegWrite is 1
		for i in 1 to 31 loop
			write_reg_in <= std_logic_vector(to_unsigned(i,5));
			alu_result_in <= std_logic_vector(to_unsigned(i,32));
			reg_src_in <= REG_SRC_ALU;
			reg_write_in <= true;
			wait for clk_period;
		end loop;
		
		
		-- Do not write any more values
		reg_write_in <= false;
		
		
		-- Check if we get the correct values out
		for i in 1 to 31 loop
			read_reg_1_in <= std_logic_vector(to_unsigned(i,5));
			for j in 0 to 31 loop
				read_reg_2_in <= std_logic_vector(to_unsigned(j,5));
				wait for clk_period;
				assert alu_1_out = std_logic_vector(to_unsigned(i,32)) and alu_2_out = std_logic_vector(to_unsigned(j,32))
					report "ALU out 1 and 2 has wrong values"
					severity failure;
			end loop;
		end loop;

		-- Check that value is held for a clock cycle
		for i in 1 to 31 loop
			read_reg_1_in <= std_logic_vector(to_unsigned(i,5));
			for j in 0 to 31 loop
				read_reg_2_in <= std_logic_vector(to_unsigned(j,5));

				-- Simulate rising edge
				wait for 3*clk_period/5;

				-- Change addresses, wait and check again
				read_reg_1_in <= std_logic_vector(to_unsigned(i + 1, 5));
				read_reg_2_in <= std_logic_vector(to_unsigned(j + 1, 5));

				wait for 2*clk_period/5;

				assert alu_1_out = std_logic_vector(to_unsigned(i,32)) and alu_2_out = std_logic_vector(to_unsigned(j,32))
					report "alu out should be held for a clock cycle"
					severity failure;

			end loop;
		end loop;
		
		
		-- Try to write a value in register 0
		write_reg_in <= "00000";
		alu_result_in <= x"11111111";
		read_reg_1_in <= "00000";
		read_reg_2_in <= "00000";
		
		wait for 2*clk_period;
		reg_write_in <= true;
		wait for clk_period;
		reg_write_in <= false;
		wait for clk_period;
		
		-- Should always output 0
		assert alu_1_out = x"00000000" and alu_2_out = x"00000000"
			report "Register 0 should always output 0"
			severity failure;
		
		
		-- Test alu_src_in for immediate value
		alu_src_in <= ALU_SRC_IMMEDIATE;
		read_reg_2_in <= "00100"; -- Register 4, should have value 4
		immediate_in <= x"1001"; -- Immediate value 
		wait for clk_period;

		-- alu_2_out should be sign extended immediate_in
		assert alu_2_out = std_logic_vector(resize(signed(immediate_in),32))
			report "alu_2_out should be sign extended immediate in"
			severity failure;

		-- Check immediate delay
		immediate_in <= x"1000";
		wait for 2*clk_period/5; -- No rising edge
		assert alu_2_out = x"00001001"
			report "alu_2_out should be delayed by one cycle"
			severity failure;

		wait for 3*clk_period/5; -- Rising edge
		assert alu_2_out = std_logic_vector(resize(signed(immediate_in),32))
			report "alu_2_out should be delayed by one cycle only"
			severity failure;



		-- write_data_out should be register 2 output
		alu_src_in <= ALU_SRC_REGISTER;
		for i in 0 to 31 loop
			read_reg_2_in <= std_logic_vector(to_unsigned(i, 5));
			wait for 2*clk_period;
			assert write_data_out = alu_2_out
				report "write_data_out out should be the same as read data 2 when alu_src_in = ALU_SRC_REGISTER with a cycle extra delay."
				severity failure;
		end loop;
			
		
		-- Test reg_src
		reg_src_in <= REG_SRC_ALU;
		read_reg_1_in <= "10000"; -- Read reg 16
		write_reg_in <= "10000"; -- Write reg 16

		for i in 0 to 200 loop
			alu_result_in <= std_logic_vector(to_unsigned(i, 32));
			wait for 3*clk_period/5; -- Rising edge crossed
			assert mem_addr_out = alu_result_in
				report "mem_addr should be alu_result delayed by one cycle"
				severity failure;

			alu_result_in <= std_logic_vector(to_unsigned(i + 20, 32));
			wait for 2*clk_period/5; -- No edge crossing
			assert mem_addr_out = std_logic_vector(to_unsigned(i, 32))
				report "mem_addr should be held for one clock cycle"
				severity failure;

			wait for clk_period;
			reg_write_in <= true;
			wait for clk_period;
			reg_write_in <= false;
			wait for clk_period;
			
			-- check reg output
			assert to_integer(unsigned(alu_2_out)) = i
				report "Correct alu result not written back"
				severity failure;

		end loop;

		reg_src_in <= REG_SRC_MEMORY;

		for i in 0 to 200 loop
			read_data_in <= std_logic_vector(to_unsigned(i, 32));
			
			reg_write_in <= true;
			wait for clk_period;
			reg_write_in <= false;
			wait for clk_period;

			-- check reg output
			assert to_integer(unsigned(alu_2_out)) = i
				report "Correct memory data not written back"
				severity failure;

		end loop;

		report "Test success";
   end process;

END;
