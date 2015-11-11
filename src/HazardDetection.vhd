library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_MISC.ALL;
use work.defs.ALL;

entity HazardDetection is

	port (
		if_id_read_reg_1_in, if_id_read_reg_2_in, id_ex_write_reg_in : in std_logic_vector(4 downto 0);
		id_ex_reg_src_in : in reg_src_t;
		id_ex_reg_write_in, id_ex_branch_in, id_ex_jump_in : in boolean;
		stall_out, noop_out : out boolean
	);

end HazardDetection;

architecture Behavioral of HazardDetection is
	signal ld_hazard : boolean;
begin

	ld_hazard <= ((if_id_read_reg_1_in = id_ex_write_reg_in) or (if_id_read_reg_2_in = id_ex_write_reg_in)) and 
		id_ex_reg_src_in = REG_SRC_MEMORY and id_ex_reg_write_in;

	stall_out <= ld_hazard or id_ex_branch_in or id_ex_jump_in;
	noop_out <= ld_hazard or id_ex_branch_in;

end Behavioral;
