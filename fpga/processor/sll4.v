module sll4(in, out);

input [31:0] in;
output [31:0] out;

assign out[31:4] = in[27:0];
assign out[3] = 0;
assign out[2] = 0;
assign out[1] = 0;
assign out[0] = 0;

endmodule
