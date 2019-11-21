module sll16(in, out);

input [31:0] in;
output [31:0] out;

assign out[31:16] = in[15:0];
assign out[15] = 0;
assign out[14] = 0;
assign out[13] = 0;
assign out[12] = 0;
assign out[11] = 0;
assign out[10] = 0;
assign out[9] = 0;
assign out[8] = 0;
assign out[7] = 0;
assign out[6] = 0;
assign out[5] = 0;
assign out[4] = 0;
assign out[3] = 0;
assign out[2] = 0;
assign out[1] = 0;
assign out[0] = 0;

endmodule
