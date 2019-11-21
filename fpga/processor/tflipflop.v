module tflipflop(d, clk, en, clr, q);

input d, clk, en, clr;
output q;

wire xor_out;

dflippymcflopface dflipper(xor_out, clk, en, clr, q);

xor xor0(xor_out, d, q);

endmodule
