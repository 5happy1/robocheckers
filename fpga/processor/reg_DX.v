module reg_DX(pc_in, instr_in, A_in, B_in, clock, reset, pc_out, instr_out, A_out, B_out);

	input [31:0] pc_in, instr_in, A_in, B_in;
	input clock, reset;
	output [31:0] pc_out, instr_out, A_out, B_out;

	register reg_pc(pc_in, 1'b1, clock, reset, pc_out);
	register reg_instr(instr_in, 1'b1, clock, reset, instr_out);
	register reg_A(A_in, 1'b1, clock, reset, A_out);
	register reg_B(B_in, 1'b1, clock, reset, B_out);

endmodule
