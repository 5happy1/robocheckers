module trie(in, out_enable, out);

input [31:0] in;
input out_enable;
output [31:0] out;

assign out = out_enable ? in : 32'bz;

endmodule
