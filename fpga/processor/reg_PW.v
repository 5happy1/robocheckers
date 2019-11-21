module reg_PW(instr_in, p_in, r_in, e_in, clock, reset, enable_instr, instr_out, p_out, r_out, e_out);

input [31:0] instr_in, p_in;
input [2:0] e_in;
input r_in, clock, enable_instr, reset;
output [31:0] instr_out, p_out;
output [2:0] e_out;
output r_out;

register reg_instr(instr_in, enable_instr, clock, reset, instr_out);
register reg_p(p_in, 1'b1, clock, reset, p_out);
dflippymcflopface reg_r(r_in, clock, 1'b1, reset, r_out);
register_3bit reg_e(e_in, 1'b1, clock, reset, e_out);

endmodule
