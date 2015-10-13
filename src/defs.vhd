library ieee;
use ieee.std_logic_1164.all;

package defs is

	-- ALU type definitions
  type alu_operation_t is (ALU_ADD, ALU_SUB, ALU_SLT, ALU_AND, ALU_OR, ALU_LUI);


	-- Control module type definitions
	type control_state is (CONTROL_FETCH, CONTROL_EXECUTE, CONTROL_STALL);

end package defs;
