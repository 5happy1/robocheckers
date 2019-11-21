module trie_1bit(in, out_enable, out);

input in;
input out_enable;
output out;

assign out = out_enable ? in : 1'bz;

endmodule
