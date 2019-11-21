module block_add_8(in1, in2, cin, out, cout, cout_fast);

input [7:0] in1, in2;
input cin;
output [7:0] out;
output cout, cout_fast;

wire g0, g1, g2, g3, g4, g5, g6, g7;
wire p0, p1, p2, p3, p4, p5, p6, p7;

// cx is carry into x
wire c0, c1, c2, c3, c4, c5, c6, c7;

assign c0 = cin;


and and_g_0(g0, in1[0], in2[0]);
and and_g_1(g1, in1[1], in2[1]);
and and_g_2(g2, in1[2], in2[2]);
and and_g_3(g3, in1[3], in2[3]);
and and_g_4(g4, in1[4], in2[4]);
and and_g_5(g5, in1[5], in2[5]);
and and_g_6(g6, in1[6], in2[6]);
and and_g_7(g7, in1[7], in2[7]);

or or_p_0(p0, in1[0], in2[0]);
or or_p_1(p1, in1[1], in2[1]);
or or_p_2(p2, in1[2], in2[2]);
or or_p_3(p3, in1[3], in2[3]);
or or_p_4(p4, in1[4], in2[4]);
or or_p_5(p5, in1[5], in2[5]);
or or_p_6(p6, in1[6], in2[6]);
or or_p_7(p7, in1[7], in2[7]);


// c1
wire w_c1_0;

and and_c1_0(w_c1_0, c0, p0);

or or_c1(c1, w_c1_0, g0);


// c2
wire w_c2_0, w_c2_1;

and and_c2_0(w_c2_0, c0, p1, p0);
and and_c2_1(w_c2_1, g0, p1);

or or_c2(c2, w_c2_0, w_c2_1, g1);


// c3
wire w_c3_0, w_c3_1, w_c3_2;

and and_c3_0(w_c3_0, c0, p2, p1, p0);
and and_c3_1(w_c3_1, g0, p2, p1);
and and_c3_2(w_c3_2, g1, p2);

or or_c3(c3, w_c3_0, w_c3_1, w_c3_2, g2);

// c4
wire w_c4_0, w_c4_1, w_c4_2, w_c4_3;

and and_c4_0(w_c4_0, c0, p3, p2, p1, p0);
and and_c4_1(w_c4_1, g0, p3, p2, p1);
and and_c4_2(w_c4_2, g1, p3, p2);
and and_c4_3(w_c4_3, g2, p3);

or or_c4(c4, w_c4_0, w_c4_1, w_c4_2, w_c4_3, g3);

// c5
wire w_c5_0, w_c5_1, w_c5_2, w_c5_3, w_c5_4;

and and_c5_0(w_c5_0, c0, p4, p3, p2, p1, p0);
and and_c5_1(w_c5_1, g0, p4, p3, p2, p1);
and and_c5_2(w_c5_2, g1, p4, p3, p2);
and and_c5_3(w_c5_3, g2, p4, p3);
and and_c5_4(w_c5_4, g3, p4);

or or_c5(c5, w_c5_0, w_c5_1, w_c5_2, w_c5_3, w_c5_4, g4);

// c6
wire w_c6_0, w_c6_1, w_c6_2, w_c6_3, w_c6_4, w_c6_5;

and and_c6_0(w_c6_0, c0, p5, p4, p3, p2, p1, p0);
and and_c6_1(w_c6_1, g0, p5, p4, p3, p2, p1);
and and_c6_2(w_c6_2, g1, p5, p4, p3, p2);
and and_c6_3(w_c6_3, g2, p5, p4, p3);
and and_c6_4(w_c6_4, g3, p5, p4);
and and_c6_5(w_c6_5, g4, p5);

or or_c6(c6, w_c6_0, w_c6_1, w_c6_2, w_c6_3, w_c6_4, w_c6_5, g5);

// c7
wire w_c7_0, w_c7_1, w_c7_2, w_c7_3, w_c7_4, w_c7_5, w_c7_6;

and and_c7_0(w_c7_0, c0, p6, p5, p4, p3, p2, p1, p0);
and and_c7_1(w_c7_1, g0, p6, p5, p4, p3, p2, p1);
and and_c7_2(w_c7_2, g1, p6, p5, p4, p3, p2);
and and_c7_3(w_c7_3, g2, p6, p5, p4, p3);
and and_c7_4(w_c7_4, g3, p6, p5, p4);
and and_c7_5(w_c7_5, g4, p6, p5);
and and_c7_6(w_c7_6, g5, p6);

or or_c7(c7, w_c7_0, w_c7_1, w_c7_2, w_c7_3, w_c7_4, w_c7_5, w_c7_6, g6);

// Fast carry out
wire w_c8_0, w_c8_1, w_c8_2, w_c8_3, w_c8_4, w_c8_5, w_c8_6, w_c8_7;

and and_c8_0(w_c8_0, c0, p7, p6, p5, p4, p3, p2, p1, p0);
and and_c8_1(w_c8_1, g0, p7, p6, p5, p4, p3, p2, p1);
and and_c8_2(w_c8_2, g1, p7, p6, p5, p4, p3, p2);
and and_c8_3(w_c8_3, g2, p7, p6, p5, p4, p3);
and and_c8_4(w_c8_4, g3, p7, p6, p5, p4);
and and_c8_5(w_c8_5, g4, p7, p6, p5);
and and_c8_6(w_c8_6, g5, p7, p6);
and and_c8_7(w_c8_7, g6, p7);

or or_c8(cout_fast, w_c8_0, w_c8_1, w_c8_2, w_c8_3, w_c8_4, w_c8_5, w_c8_6, w_c8_7, g7);



// Adders
// Dummy wires for unused carry outs
wire d0, d1, d2, d3, d4, d5, d6;
add_1 adder_7(in1[7], in2[7], c7, out[7], cout);
add_1 adder_6(in1[6], in2[6], c6, out[6], d6);
add_1 adder_5(in1[5], in2[5], c5, out[5], d5);
add_1 adder_4(in1[4], in2[4], c4, out[4], d4);
add_1 adder_3(in1[3], in2[3], c3, out[3], d3);
add_1 adder_2(in1[2], in2[2], c2, out[2], d2);
add_1 adder_1(in1[1], in2[1], c1, out[1], d1);
add_1 adder_0(in1[0], in2[0], cin, out[0], d0);


endmodule
