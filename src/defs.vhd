library ieee;
use ieee.std_logic_1164.all;

package defs is

	-- ALU type definitions
	type alu_operation_t is (ALU_ADD, ALU_SUB, ALU_SLT, ALU_AND, ALU_OR, ALU_SLL);
	type alu_src_t is (ALU_SRC_REGISTER, ALU_SRC_IMMEDIATE);
	type reg_src_t is (REG_SRC_ALU, REG_SRC_MEMORY);

end package defs;
