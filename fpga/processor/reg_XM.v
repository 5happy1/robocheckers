module reg_XM(pc_in, instr_in, O_in, B_in, E_in, clock, reset, nops_from_md, pc_out, instr_out, O_out, B_out, E_out);

	input [31:0] pc_in, instr_in, O_in, B_in;
	input [2:0] E_in;
	input clock, nops_from_md, reset;
	output [31:0] pc_out, instr_out, O_out, B_out;
	output [2:0] E_out;
	
	wire [31:0] pc_in_m, instr_in_m, O_in_m, B_in_m, E_in_m;
	
	mux_2 m0(pc_in, 32'b0, nops_from_md, pc_in_m);
	mux_2 m1(instr_in, 32'b0, nops_from_md, instr_in_m);
	mux_2 m2(O_in, 32'b0, nops_from_md, O_in_m);
	mux_2 m3(B_in, 32'b0, nops_from_md, B_in_m);
	mux_2 m4(E_in, 3'b0, nops_from_md, E_in_m);

	register reg_pc(pc_in_m, 1'b1, clock, reset, pc_out);
	register reg_instr(instr_in_m, 1'b1, clock, reset, instr_out);
	register reg_O(O_in_m, 1'b1, clock, reset, O_out);
	register reg_B(B_in_m, 1'b1, clock, reset, B_out);
	register_3bit	reg_E(E_in_m, 1'b1, clock, reset, E_out);

endmodule
