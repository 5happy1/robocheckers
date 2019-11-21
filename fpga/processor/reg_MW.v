module reg_MW(pc_in, instr_in, O_in, D_in, E_in, clock, reset, pc_out, instr_out, O_out, D_out, E_out);
	
	input [31:0] pc_in, instr_in, O_in, D_in;
	input [2:0] E_in;
	input clock, reset;
	output [31:0] pc_out, instr_out, O_out, D_out;
	output [2:0] E_out;

	register reg_pc(pc_in, 1'b1, clock, reset, pc_out);
	register reg_instr(instr_in, 1'b1, clock, reset, instr_out);
	register reg_O(O_in, 1'b1, clock, reset, O_out);
	register reg_D(D_in, 1'b1, clock, reset, D_out);
	register_3bit reg_E(E_in, 1'b1, clock, reset, E_out);
	
endmodule
