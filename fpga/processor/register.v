module register(in, input_enable, clock, clear, out);

input [31:0] in;
input input_enable , clock, clear;
output [31:0] out;

dflippymcflopface dffe0(in[0], clock, input_enable, clear, out[0]);
dflippymcflopface dffe1(in[1], clock, input_enable, clear, out[1]);
dflippymcflopface dffe2(in[2], clock, input_enable, clear, out[2]);
dflippymcflopface dffe3(in[3], clock, input_enable, clear, out[3]);
dflippymcflopface dffe4(in[4], clock, input_enable, clear, out[4]);
dflippymcflopface dffe5(in[5], clock, input_enable, clear, out[5]);
dflippymcflopface dffe6(in[6], clock, input_enable, clear, out[6]);
dflippymcflopface dffe7(in[7], clock, input_enable, clear, out[7]);
dflippymcflopface dffe8(in[8], clock, input_enable, clear, out[8]);
dflippymcflopface dffe9(in[9], clock, input_enable, clear, out[9]);
dflippymcflopface dffe10(in[10], clock, input_enable, clear, out[10]);
dflippymcflopface dffe11(in[11], clock, input_enable, clear, out[11]);
dflippymcflopface dffe12(in[12], clock, input_enable, clear, out[12]);
dflippymcflopface dffe13(in[13], clock, input_enable, clear, out[13]);
dflippymcflopface dffe14(in[14], clock, input_enable, clear, out[14]);
dflippymcflopface dffe15(in[15], clock, input_enable, clear, out[15]);
dflippymcflopface dffe16(in[16], clock, input_enable, clear, out[16]);
dflippymcflopface dffe17(in[17], clock, input_enable, clear, out[17]);
dflippymcflopface dffe18(in[18], clock, input_enable, clear, out[18]);
dflippymcflopface dffe19(in[19], clock, input_enable, clear, out[19]);
dflippymcflopface dffe20(in[20], clock, input_enable, clear, out[20]);
dflippymcflopface dffe21(in[21], clock, input_enable, clear, out[21]);
dflippymcflopface dffe22(in[22], clock, input_enable, clear, out[22]);
dflippymcflopface dffe23(in[23], clock, input_enable, clear, out[23]);
dflippymcflopface dffe24(in[24], clock, input_enable, clear, out[24]);
dflippymcflopface dffe25(in[25], clock, input_enable, clear, out[25]);
dflippymcflopface dffe26(in[26], clock, input_enable, clear, out[26]);
dflippymcflopface dffe27(in[27], clock, input_enable, clear, out[27]);
dflippymcflopface dffe28(in[28], clock, input_enable, clear, out[28]);
dflippymcflopface dffe29(in[29], clock, input_enable, clear, out[29]);
dflippymcflopface dffe30(in[30], clock, input_enable, clear, out[30]);
dflippymcflopface dffe31(in[31], clock, input_enable, clear, out[31]);

endmodule
