module trie_5bit(in, out_enable, out);

input [4:0] in;
input out_enable;
output [4:0] out;

assign out = out_enable ? in : 5'bz;

endmodule
