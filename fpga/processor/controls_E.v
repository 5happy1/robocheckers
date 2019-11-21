module controls_E(opcode, alu_op_choice, alu_in_B, j_alpha, j_beta, alu_addsub);

input [4:0] opcode;
output alu_op_choice, alu_in_B, j_alpha, j_beta, alu_addsub;

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

wire temp;
assign temp = (a_not & b_not & c & d_not & e) |
				  (a_not & b_not & c & d & e) |
				  (a_not & b & c_not & d_not & e_not);
				  
assign alu_op_choice = temp | (a_not & b_not & c_not & d & e_not);
assign alu_in_B = temp;

assign j_alpha = (a_not & b_not & c_not & d_not & e) | (a_not & b_not & c_not & d & e) |
					  (a_not & b_not & c & d_not & e_not) | (a & b_not & c & d & e_not);
assign j_beta = (a_not & b_not & c_not & d_not & e) | (a_not & b_not & c_not & d & e) | (a & b_not & c & d & e_not);

assign alu_addsub = (a_not & b_not & c & d & e_not) | (a_not & b_not & c_not & d & e_not);

endmodule
