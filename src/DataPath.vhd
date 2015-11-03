library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.defs.ALL;

entity DataPath is
	generic (
		ADDR_WIDTH : integer := 8;	
		DATA_WIDTH : integer := 32;
		REG_ADDR_WIDTH : integer := 5;
		IMMEDIATE_WIDTH : integer := 16
	);
	port (
		clk, reset : in std_logic;
		read_reg_1_in, read_reg_2_in, write_reg_in : in std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
		immediate_in : in std_logic_vector(IMMEDIATE_WIDTH-1 downto 0);
		read_data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
		alu_result_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
		-- Control signals
		reg_write_in : in boolean;
		alu_src_in : in alu_src_t;
		reg_src_in : in reg_src_t;
		alu_1_out, alu_2_out : out std_logic_vector(DATA_WIDTH-1 downto 0);  
		mem_addr_out : out std_logic_vector(DATA_WIDTH-1 downto 0);
		write_data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end DataPath;

architecture Behavioral of DataPath is

	type register_file_t is array(31 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);

	signal register_file : register_file_t;
	signal reg_write_data : std_logic_vector(DATA_WIDTH-1 downto 0);
	
	signal alu_1, alu_2 : std_logic_vector(DATA_WIDTH-1 downto 0);
	
	-- ID/EX registers
	signal id_ex_alu_1, id_ex_alu_2, id_ex_immediate : std_logic_vector(DATA_WIDTH-1 downto 0);
	
	-- EX/MEM registers
	signal ex_mem_write_data, ex_mem_alu_result : std_logic_vector(DATA_WIDTH-1 downto 0);

	-- MEM/WB
	signal mem_wb_alu_result : std_logic_vector(DATA_WIDTH-1 downto 0);
	
	
	
	
begin

	-- Handle register updates
	process (clk, reset) is begin
			if reset = '1' then
				register_file <= (others => (others => '0'));

			elsif rising_edge(clk) and reg_write_in = true then
				if unsigned(write_reg_in) /= 0 then
					register_file(to_integer(unsigned(write_reg_in))) <= reg_write_data;
				end if;
			end if;
	end process;
	

	-- Handle pipeline registers
	process (clk, reset) is begin
		if reset = '1' then
			id_ex_alu_1 <= (others => '0');
			id_ex_alu_2 <= (others => '0');
			id_ex_immediate <= (others => '0');
			ex_mem_write_data <= (others => '0');
			ex_mem_alu_result <= (others => '0');
			mem_wb_alu_result <= (others => '0');
		elsif rising_edge(clk) then
			id_ex_alu_1 <= register_file(to_integer(unsigned(read_reg_1_in)));
			id_ex_alu_2 <= register_file(to_integer(unsigned(read_reg_2_in)));
			id_ex_immediate <= std_logic_vector(resize(signed(immediate_in), DATA_WIDTH));
			ex_mem_write_data <= id_ex_alu_2;
			ex_mem_alu_result <= alu_result_in;
			mem_wb_alu_result <= ex_mem_alu_result;
		end if;
	end process;
	
	
	-- Data writeback
	with reg_src_in select reg_write_data <=
		read_data_in when REG_SRC_MEMORY,
		mem_wb_alu_result when REG_SRC_ALU;

	-- Outputs for memory
	write_data_out <= ex_mem_write_data;
	mem_addr_out <= ex_mem_alu_result;
	
	-- Outputs for ALU
	alu_1_out <= id_ex_alu_1;
	with alu_src_in select alu_2_out <=
		id_ex_alu_2 when ALU_SRC_REGISTER,
		id_ex_immediate when ALU_SRC_IMMEDIATE;
	

end Behavioral;

