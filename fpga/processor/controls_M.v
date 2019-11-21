module controls_M(opcode, dmem_wren);

input [4:0] opcode;
output dmem_wren;

wire a, a_not, b, b_not, c, c_not, d, d_not, e, e_not;

assign a = opcode[4];
assign b = opcode[3];
assign c = opcode[2];
assign d = opcode[1];
assign e = opcode[0];

not not_a(a_not, a);
not not_b(b_not, b);
not not_c(c_not, c);
not not_d(d_not, d);
not not_e(e_not, e);

assign dmem_wren = a_not & b_not & c & d & e;

endmodule
