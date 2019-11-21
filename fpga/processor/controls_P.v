module controls_P(instr, md_rdy, pw_r, clock, reset, write_data_out, write_instr, stall_from_multdiv, mult_out, div_out, nops_xm_from_md, enable_pw_instr, ex_choice);

input [31:0] instr; // Should be dx instr (instruction from execute stage)
input md_rdy, pw_r, clock, reset;
output write_data_out, write_instr, stall_from_multdiv, mult_out, div_out, nops_xm_from_md, enable_pw_instr, ex_choice;

wire [4:0] opcode, alu_op;
assign opcode = instr[31:27];
assign alu_op = instr[6:2];

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

// Send multiplier outputs to memory if there was a data ready
assign write_data_out = pw_r;
assign write_instr = pw_r;
assign ex_choice = pw_r;

// Stall from T-flip flop
wire toggle_stall, mult_tmp, mult, div_tmp, div, zeros;

comp_2_5bit	comp_zeros(opcode, 5'b0, zeros); // Check opcode is zeros
comp_2_5bit	comp_mult(alu_op, 5'b00110, mult_tmp);
comp_2_5bit	comp_div(alu_op, 5'b00111, div_tmp);
assign mult = zeros & mult_tmp;
assign div = zeros & div_tmp;

assign toggle_stall = mult | div | md_rdy;

tflipflop tff1(toggle_stall, ~clock, 1'b1, reset, stall_from_multdiv);

assign mult_out = mult;
assign div_out = div;

assign nops_xm_from_md = mult | div;

assign enable_pw_instr = mult | div;

endmodule
