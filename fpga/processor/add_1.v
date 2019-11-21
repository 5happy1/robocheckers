module add_1(in1, in2, cin, out, cout);

input in1, in2, cin;
output out, cout;

wire xor_1_out, and_1_out, and_2_out;

xor xor_1(xor_1_out, in1, in2);
xor xor_2(out, xor_1_out, cin);
and and_1(and_1_out, cin, xor_1_out);
and and_2(and_2_out, in1, in2);
or   or_1(cout, and_1_out, and_2_out);

endmodule
