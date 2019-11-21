module adder(in1, in2, addsub, out, cout, overflow_out, neq_out, lt_out);

input [31:0] in1, in2;
input addsub;
output [31:0] out;
output cout, overflow_out, neq_out, lt_out;

// addsub: 0 is add, 1 is subtract

// Carry into adder_8
wire cin, c1, c2, c3;

// Dummy wires
wire d0, d1, d2, d3;

assign cin = addsub;

// Negated in2
// not_b is negated b
// in2_c is in2 choice for add or subtract
wire [31:0] not_b, in2_c;
not_32 not0(in2, not_b);
mux_2 mux0(in2, not_b, addsub, in2_c);
 

block_add_8 block_0(in1[7:0], in2_c[7:0], cin, out[7:0], d0, c1);
block_add_8 block_1(in1[15:8], in2_c[15:8], c1, out[15:8], d1, c2);
block_add_8 block_2(in1[23:16], in2_c[23:16], c2, out[23:16], d2, c3);
block_add_8 block_3(in1[31:24], in2_c[31:24], c3, out[31:24], d3, cout);

// Check for overflow

//xnor xnor0(overflow_out, in1[31], in2_c[31], out[31]);

wire w_v0, w_v1, in1_31_not, in2_31_not, out_31_not;
not n0(in1_31_not, in1[31]);
not n1(in2_31_not, in2_c[31]);
not n2(out_31_not, out[31]);
and a0(w_v0, in1_31_not, in2_31_not, out[31]);
and a1(w_v1, in1[31], in2_c[31], out_31_not);
or or_f(overflow_out, w_v0, w_v1);

//wire w_o0, w_o1, w_not;
//xnor xnor0(w_o0, in1[30], in2[30], out[30]);
//not noto0(w_not, out[31]);
//and (w_o1, in1[31], in2[31], w_not, cout);
//or (overflow_out, w_o0, w_o1);
// Here is a comment
//and and0(equal, out[31], in1[31]);
//and and1(overflow_out, same, equal);

// Check is not equal (only valid after subtraction)
or or_neq(neq_out, out[0], out[1], out[2], out[3], out[4], out[5], out[6], out[7],
								 out[8], out[9], out[10], out[11], out[12], out[13], out[14], out[15],
								 out[16], out[17], out[18], out[19], out[20], out[21], out[22], out[23],
								 out[24], out[25], out[26], out[27], out[28], out[29], out[30], out[31], overflow_out);

// Check for less than
xor xor_lt(lt_out, out[31], overflow_out);

endmodule
