library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.defs.all;

entity ALU is
	port (
		rd1 : in std_logic; 		-- read data 1
		rd2 : in std_logic;		-- read data 2
		imm : in std_logic; 		-- immediate value
		ALU_ctrl : in std_logic;
		
		ALU_result : out std_logic;
		ALU_zero : out std_logic;
		
end entity ALU;

architecture behavioural of ALU is
	
	signal res : std_logic;
	
begin 

	ALU_zero = '0';

	add : process ( rd1, rd2, imm )
	begin
		if (ALU_ctrl = XXXX) then		-- Check for I-type or R-type
			res <= rd1 + rd2;
		else 
			res <= rd1 + imm;
	end process;
	
	sub : process ( rd1, rd2, imm )
	begin
		if (ALU_ctrl = XXXX) then		-- Check for I-type or R-type
			res <= rd1 - rd2;
			if (res = '0') then
				ALU_zero = '1';
		else 
			res <= rd1 - imm;
	end process;
	
	slt : process ( rd1, rd2, imm )
	begin
		if (ALU_ctrl = XXXX) then		-- Check for I-type or R-type
			res <= '1' when rd1<rd2 else '0';
		else 
			res <= '1' when rd1<imm else '0';
	end process;
	
	ALU_and : process ( rd1, rd2, imm )
	begin
		if (ALU_ctrl = XXXX) then		-- Check for I-type or R-type 
			res <= rd1 and rd2;
		else 
			res <= rd1 and imm;
	end process;
	
	ALU_or : process ( rd1, rd2, imm )
	begin
		if (ALU_ctrl = XXXX) then		-- Check for I-type or R-type
			res <= rd1 or rd2;
		else 
			res <= rd1 or imm;
	end process;
	
	-- This does not compile on current system. Use shift_left instead 
	ALU_sll : process ( rd1, rd2, imm )
	begin
		if (ALU_ctrl = XXXX) then		-- Check for I-type or R-type
			res <= rd1 sll rd2;
		else 
			res <= rd1 sll imm;
	end process;
	
	ALU_result <= res;

end architecture behavioural;
