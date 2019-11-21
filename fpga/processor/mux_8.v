module mux_8(in0, in1, in2, in3, in4, in5, in6, in7, select, out);

input [31:0] in0, in1, in2, in3, in4, in5, in6, in7;
input [2:0] select;
output [31:0] out;

wire [31:0] mux_10_out, mux_11_out;

mux_4 mux_10(in0, in1, in2, in3, select[1:0], mux_10_out);
mux_4 mux_11(in4, in5, in6, in7, select[1:0], mux_11_out);
mux_2 mux_00(mux_10_out, mux_11_out, select[2], out);

endmodule
