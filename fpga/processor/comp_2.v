module comp_2(eq_in, gt_in, in1, in2, eq_out, gt_out);

input eq_in, gt_in;
input [1:0] in1, in2;
output eq_out, gt_out;

wire in2_0_not, eq_in_not, gt_in_not;
not not0(in2_0_not, in2[0]);
not not1(eq_in_not, eq_in);
not not2(gt_in_not, gt_in);

wire mux_eq_out, mux_gt_out;

wire [2:0] select;
assign select[2:1] = in1;
assign select[0] = in2[1];

mux_8 mux_eq(in2_0_not, 0, in2[0], 0, 0, in2_0_not, 0, in2[0], select, mux_eq_out);
mux_8 mux_gt(0, 0, in2_0_not, 0, 1, 0, 1, in2_0_not, select, mux_gt_out);

// EQ out
and and0(eq_out, eq_in, gt_in_not, mux_eq_out);

// GT out
wire w0, w1;
and and_gt_0(w0, eq_in_not, gt_in);
and and_gt_1(w1, eq_in, gt_in_not, mux_gt_out);
or or_gt(gt_out, w0, w1);

endmodule
