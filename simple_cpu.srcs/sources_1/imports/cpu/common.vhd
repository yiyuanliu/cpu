library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common is
	type mem_op_type is (mem_op_no, mem_op_write, mem_op_read);
	type mem_mode_type is (mem_mode_byte, mem_mode_half, mem_mode_word);

	type ex_op_type is (ex_op_add, ex_op_and, ex_op_or, ex_op_sll, ex_op_srl, ex_op_xor);
end package common;

package body common is

end package body common;