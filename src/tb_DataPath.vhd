LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
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
         reg_write_in : IN  std_logic;
         alu_src_in : IN  std_logic;
         mem_to_reg_in : IN  std_logic;
         alu_1_out : OUT  std_logic_vector(31 downto 0);
         alu_2_out : OUT  std_logic_vector(31 downto 0);
         write_data_out : OUT  std_logic_vector(31 downto 0)
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
   signal reg_write_in : std_logic := '0';
   signal alu_src_in : std_logic := '0';
   signal mem_to_reg_in : std_logic := '0';

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
          mem_to_reg_in => mem_to_reg_in,
          alu_1_out => alu_1_out,
          alu_2_out => alu_2_out,
          write_data_out => write_data_out
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
		
		-- Set ALU src to output read data 2
		alu_src_in <= '0';
		
		-- Registers should now be zero
		for i in 0 to 32 loop
			read_reg_1_in <= std_logic_vector(to_unsigned(i,5));
			for j in 0 to 32 loop
				read_reg_2_in <= std_logic_vector(to_unsigned(j,5));
				wait for clk_period;
				assert alu_1_out = x"00000000" and alu_2_out = x"00000000";
					report "all registers should be 0 after reset"
					severity failure;
			end loop;
		end loop;
		
		-- Try to fill registers with values when RegWrite is 0
		for i in 1 to 32 loop
			write_reg_in <= std_logic_vector(to_unsigned(i,5));
			alu_result_in <= std_logic_vector(to_unsigned(i,32));
			mem_to_reg_in <= '0';
			reg_write_in <= '0';
			wait for clk_period;
		end loop;
		
		-- Registers should still be zero
		for i in 0 to 32 loop
			read_reg_1_in <= std_logic_vector(to_unsigned(i,5));
			for j in 0 to 32 loop
				read_reg_2_in <= std_logic_vector(to_unsigned(j,5));
				wait for clk_period;
				assert alu_1_out = x"00000000" and alu_2_out = x"00000000";
					report "Registers should not update value while reg_write_in is '0'"
					severity failure;
			end loop;
		end loop;
		
			
		-- Fill registers with values when RegWrite is 1
		for i in 1 to 32 loop
			write_reg_in <= std_logic_vector(to_unsigned(i,5));
			alu_result_in <= std_logic_vector(to_unsigned(i,32));
			mem_to_reg_in <= '0';
			reg_write_in <= '1';
			wait for clk_period;
		end loop;
		
		
		-- Do not write any more values
		reg_write_in <= '0';
		
		
		-- Check if we get the correct values out
		for i in 1 to 32 loop
			read_reg_1_in <= std_logic_vector(to_unsigned(i,5));
			for j in 0 to 32 loop
				read_reg_2_in <= std_logic_vector(to_unsigned(i,5));
				wait for clk_period;
				assert alu_1_out = std_logic_vector(to_unsigned(i,5)) and alu_2_out = std_logic_vector(to_unsigned(j,5))
					report "ALU out 1 and 2 has wrong values"
					severity failure;
			end loop;
		end loop;
		
		
		-- Try to write a value in register 0
		write_reg_in <= "00000";
		alu_result_in <= x"11111111";
		read_reg_1_in <= "00000";
		read_reg_2_in <= "00000";
		wait for clk_period;
		
		-- Should always output 0
		assert alu_1_out = x"00000000" and alu_2_out = x"00000000"
			report "Register 0 should always output 0"
			severity failure;
		
		
		-- Test alu_src_in for immediate value
		alu_src_in <= '1';
		read_reg_2_in <= "00100"; -- Register 4, should have value 4
		immediate_in <= x"1001"; -- Immediate value 
		wait for clk_period;
		
		-- alu_2_out should be sign extended immediate_in
		assert alu_2_out = std_logic_vector(resize(signed(immediate_in),32))
			report "alu_2_out should be sign extended immediate in"
			severity failure;
			
		-- write_data_out should be register 4 value
		assert write_data_out = x"00000100"
			report "write_data_out out should be the same as read data 2"
			severity failure;
			
		
		-- Test MemToReg
		alu_result_in <= x"00011000";
		read_data_in <= x"11001100";
		mem_to_reg_in <= '1';
		read_reg_1_in <= "10000"; -- Read reg 16
		write_reg_in <= "10000"; -- Write reg 16
		reg_write_in <= '1';
		wait for clk_period;
		reg_write_in <= '0';
		
		
		-- alu_1_out should now be read_data_in
		assert alu_1_out = read_data_in
			report "alu_1_out should be read_data_in when mem_to_reg is '1'"
			severity failure;
			

		report "Test success";
      wait;
   end process;

END;
