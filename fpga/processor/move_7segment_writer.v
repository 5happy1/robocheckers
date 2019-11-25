module move_7segment_writer(in, from1, from2, to1, to2);

input [19:0] in;
output [6:0] from1, from2, to1, to2;

digit_writer d0(in[19:15], from1);
digit_writer d0(in[19:15], from2);
digit_writer d0(in[19:15], to1);
digit_writer d0(in[19:15], to2);

endmodule
