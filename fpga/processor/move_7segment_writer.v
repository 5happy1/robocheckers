module move_7segment_writer(in, from1, from2, to1, to2);

input [19:0] in;
output [6:0] from1, from2, to1, to2;

digit_writer d0(in[19:15], from1);
digit_writer d1(in[14:10], from2);
digit_writer d2(in[9:5], to1);
digit_writer d3(in[4:0], to2);

endmodule
