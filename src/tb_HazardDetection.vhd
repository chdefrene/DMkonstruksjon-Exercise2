--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.defs.ALL;
 
ENTITY tb_HazardDetection IS
END tb_HazardDetection;
 
ARCHITECTURE behavior OF tb_HazardDetection IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT HazardDetection
    PORT(
			if_id_read_reg_1_in, if_id_read_reg_2_in, id_ex_write_reg_in : in std_logic_vector(4 downto 0);
			id_ex_reg_src_in : in reg_src_t;
			id_ex_reg_write_in, id_ex_branch_in : in boolean;
			stall_out : out boolean
        );
    END COMPONENT;
    

   --Inputs
   signal if_id_read_reg_1_in : std_logic_vector(4 downto 0) := (others => '0');
   signal if_id_read_reg_2_in : std_logic_vector(4 downto 0) := (others => '0');
   signal id_ex_write_reg_in : std_logic_vector(4 downto 0) := (others => '0');
   signal id_ex_reg_src_in : reg_src_t := REG_SRC_ALU;
   signal id_ex_reg_write_in : boolean := false;
   signal id_ex_branch_in : boolean := false;
   signal id_ex_jump_in : boolean := false;

 	--Outputs
   signal stall_out : boolean;
 
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: HazardDetection PORT MAP (
          if_id_read_reg_1_in => if_id_read_reg_1_in,
          if_id_read_reg_2_in => if_id_read_reg_2_in,
          id_ex_write_reg_in => id_ex_write_reg_in,
          id_ex_reg_src_in => id_ex_reg_src_in,
          id_ex_reg_write_in => id_ex_reg_write_in,
          id_ex_branch_in => id_ex_branch_in,
          stall_out => stall_out
        );

 

   -- Stimulus process
   stim_proc: process
   begin
      wait for clk_period*10;
		
		-- Should not stall without branch, load or jump
		assert not stall_out
			report "Stalling to much!"
			severity failure;
		
		if_id_read_reg_1_in <= "10101";
		id_ex_write_reg_in <= "10101";
		
		assert not stall_out
			report "Stalling too much!"
			severity failure;
			
		if_id_read_reg_2_in <= "10101";
		id_ex_write_reg_in <= "10101";
		
		assert not stall_out
			report "Stalling to much!"
			severity failure;
			
		if_id_read_reg_2_in <= "00000";
		if_id_read_reg_1_in <= "00000";
		id_ex_write_reg_in <= "00000";
		
		-- Branch should stall pipeline
		id_ex_branch_in <= true;
		wait for clk_period;

		assert stall_out
			report "Should stall on branch"
			severity failure;

		id_ex_branch_in <= false;

		-- Wait for loads when registers match
		id_ex_reg_src_in <= REG_SRC_MEMORY;
		id_ex_reg_write_in <= true;
		id_ex_write_reg_in <= "01010";
		
		if_id_read_reg_1_in <= "01010";
		wait for clk_period;
		assert stall_out
			report "Should stall when reg_1 depends on load"
			severity failure;
			
		if_id_read_reg_2_in <= "01010";
		wait for clk_period;
		assert stall_out
			report "Should stall when reg_2 and reg_1 depends on load"
			severity failure;
		
		if_id_read_reg_1_in <= "00000";
		wait for clk_period;
		assert stall_out
			report "Should stall when reg_2 depends on load"
			severity failure;
			

		report "Test success!"
			severity failure;
			
	end process;

END;
