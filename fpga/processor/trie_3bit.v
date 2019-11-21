module trie_3bit(in, out_enable, out);

input [2:0] in;
input out_enable;
output [2:0] out;

assign out = out_enable ? in : 3'bz;

endmodule
