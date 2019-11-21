module testhex(hexout);

output[6:0] hexout;

hex_to_7digit_display h(4'hd, hexout);

endmodule
