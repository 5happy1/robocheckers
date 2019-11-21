module controls_W(opcode, exception, write_reg_file, write_data, reg_d_alpha, reg_d_beta, reg_din_alpha, reg_din_beta);

input [4:0] opcode;
input exception;
output write_reg_file, write_data, reg_d_alpha, reg_d_beta, reg_din_alpha, reg_din_beta;

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

assign write_reg_file = (a | b | c_not | d_not | e_not) & (a | b | c | d | e_not) &
								(a | b | c | d_not | e) & (a | b | c_not | e) & (a_not | b | c_not | d_not | e);
assign write_data = a_not & b & c_not & d_not & e_not;

assign reg_d_alpha = (a_not & b_not & c_not & d & e) | (a & b_not & c & d_not & e) | exception;
assign reg_d_beta = (a_not & b_not & c_not & d & e) & ~exception;

assign reg_din_alpha = (a_not & b_not & c_not & d & e) | (a & b_not & c & d_not & e);
assign reg_din_beta = (a & b_not & c & d_not & e);

endmodule
