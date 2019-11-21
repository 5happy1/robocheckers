module register_3bit(in, input_enable, clock, clear, out);

input [2:0] in;
input input_enable, clock, clear;
output [2:0] out;

dflippymcflopface dffe0(in[0], clock, input_enable, clear, out[0]);
dflippymcflopface dffe1(in[1], clock, input_enable, clear, out[1]);
dflippymcflopface dffe2(in[2], clock, input_enable, clear, out[2]);

endmodule
