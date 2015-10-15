library ieee;
use ieee.std_logic_1164.all;

package defs is

	-- ALU type definitions
	type alu_operation_t is (ALU_ADD, ALU_SUB, ALU_SLT, ALU_AND, ALU_OR, ALU_SLL);

end package defs;
