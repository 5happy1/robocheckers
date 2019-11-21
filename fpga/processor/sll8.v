module sll8(in, out);

input [31:0] in;
output [31:0] out;

assign out[31:8] = in[23:0];
assign out[7] = 0;
assign out[6] = 0;
assign out[5] = 0;
assign out[4] = 0;
assign out[3] = 0;
assign out[2] = 0;
assign out[1] = 0;
assign out[0] = 0;

endmodule
