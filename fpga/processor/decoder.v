module decoder(in, out);

input [4:0] in;
output [31:0] out;

wire in_0, in_1, in_2, in_3, in_4;
wire not_in_0, not_in_1, not_in_2, not_in_3, not_in_4;

assign in_0 = in[0];
assign in_1 = in[1];
assign in_2 = in[2];
assign in_3 = in[3];
assign in_4 = in[4];

not not_0(not_in_0, in_0);
not not_1(not_in_1, in_1);
not not_2(not_in_2, in_2);
not not_3(not_in_3, in_3);
not not_4(not_in_4, in_4);

and and_0(out[0],   not_in_4, not_in_3, not_in_2, not_in_1, not_in_0);
and and_1(out[1],   not_in_4, not_in_3, not_in_2, not_in_1,     in_0);
and and_2(out[2],   not_in_4, not_in_3, not_in_2,     in_1, not_in_0);
and and_3(out[3],   not_in_4, not_in_3, not_in_2,     in_1,     in_0);
and and_4(out[4],   not_in_4, not_in_3,     in_2, not_in_1, not_in_0);
and and_5(out[5],   not_in_4, not_in_3,     in_2, not_in_1,     in_0);
and and_6(out[6],   not_in_4, not_in_3,     in_2,     in_1, not_in_0);
and and_7(out[7],   not_in_4, not_in_3,     in_2,     in_1,     in_0);
and and_8(out[8],   not_in_4,     in_3, not_in_2, not_in_1, not_in_0);
and and_9(out[9],   not_in_4,     in_3, not_in_2, not_in_1,     in_0);
and and_10(out[10], not_in_4,     in_3, not_in_2,     in_1, not_in_0);
and and_11(out[11], not_in_4,     in_3, not_in_2,     in_1,     in_0);
and and_12(out[12], not_in_4,     in_3,     in_2, not_in_1, not_in_0);
and and_13(out[13], not_in_4,     in_3,     in_2, not_in_1,     in_0);
and and_14(out[14], not_in_4,     in_3,     in_2,     in_1, not_in_0);
and and_15(out[15], not_in_4,     in_3,     in_2,     in_1,     in_0);
and and_16(out[16],     in_4, not_in_3, not_in_2, not_in_1, not_in_0);
and and_17(out[17],     in_4, not_in_3, not_in_2, not_in_1,     in_0);
and and_18(out[18],     in_4, not_in_3, not_in_2,     in_1, not_in_0);
and and_19(out[19],     in_4, not_in_3, not_in_2,     in_1,     in_0);
and and_20(out[20],     in_4, not_in_3,     in_2, not_in_1, not_in_0);
and and_21(out[21],     in_4, not_in_3,     in_2, not_in_1,     in_0);
and and_22(out[22],     in_4, not_in_3,     in_2,     in_1, not_in_0);
and and_23(out[23],     in_4, not_in_3,     in_2,     in_1,     in_0);
and and_24(out[24],     in_4,     in_3, not_in_2, not_in_1, not_in_0);
and and_25(out[25],     in_4,     in_3, not_in_2, not_in_1,     in_0);
and and_26(out[26],     in_4,     in_3, not_in_2,     in_1, not_in_0);
and and_27(out[27],     in_4,     in_3, not_in_2,     in_1,     in_0);
and and_28(out[28],     in_4,     in_3,     in_2, not_in_1, not_in_0);
and and_29(out[29],     in_4,     in_3,     in_2, not_in_1,     in_0);
and and_30(out[30],     in_4,     in_3,     in_2,     in_1, not_in_0);
and and_31(out[31],     in_4,     in_3,     in_2,     in_1,     in_0);

endmodule
