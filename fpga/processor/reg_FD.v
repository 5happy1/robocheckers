module reg_FD(pc_in, instr_in, clock, reset, enable, pc_out, instr_out);

	input [31:0] pc_in, instr_in;
	input clock, enable, reset;
	output [31:0] pc_out, instr_out;

	register reg_pc(pc_in, enable, clock, reset, pc_out);
	register reg_instr(instr_in, enable, clock, reset, instr_out);

endmodule
