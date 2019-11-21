module sll(in, shamt, out);

input [31:0] in;
input [4:0] shamt;
output[31:0] out;

wire [31:0] out_16, out_8, out_4, out_2, out_1;
wire [31:0] out_16m, out_8m, out_4m, out_2m, out;

sll16 s16(in, out_16);
mux_2 m16(in, out_16, shamt[4], out_16m);

sll8 s8(out_16m, out_8);
mux_2 m8(out_16m, out_8, shamt[3], out_8m);

sll4 s4(out_8m, out_4);
mux_2 m4(out_8m, out_4, shamt[2], out_4m);

sll2 s2(out_4m, out_2);
mux_2 m2(out_4m, out_2, shamt[1], out_2m);

sll1 s1(out_2m, out_1);
mux_2 m1(out_2m, out_1, shamt[0], out);

endmodule
