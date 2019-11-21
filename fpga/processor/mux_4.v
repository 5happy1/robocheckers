module mux_4(in0, in1, in2, in3, select, out);

input [31:0] in0, in1, in2, in3;
input [1:0] select;
output [31:0] out;

wire [31:0] mux_10_out, mux_11_out;

mux_2 mux_10(in0, in1, select[0], mux_10_out);
mux_2 mux_11(in2, in3, select[0], mux_11_out);
mux_2 mux_00(mux_10_out, mux_11_out, select[1], out);

endmodule
