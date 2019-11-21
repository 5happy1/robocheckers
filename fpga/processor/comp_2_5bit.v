module comp_2_5bit(in1, in2, eq);

input[4:0] in1, in2;
output eq;

//wire [31:0] add_in1, add_in2;
//wire neq;
//wire d_cout, d_overflow_out, d_lt_out;
//wire [31:0] d_out;
//
//assign add_in1[31:5] = 27'b0;
//assign add_in1[4:0] = in1;
//
//assign add_in2[31:5] = 27'b0;
//assign add_in2[4:0] = in2;
//
//adder eq_alu_A_1(add_in1, add_in2, 1'b1, d_out, d_cout, d_overflow_out, neq, d_lt_out);
//
//assign eq = ~neq;

wire w0, w1, w2, w3, w4;

xnor x0(w0, in1[0], in2[0]);
xnor x1(w1, in1[1], in2[1]);
xnor x2(w2, in1[2], in2[2]);
xnor x3(w3, in1[3], in2[3]);
xnor x4(w4, in1[4], in2[4]);

and a(eq, w0, w1, w2, w3, w4);

endmodule
