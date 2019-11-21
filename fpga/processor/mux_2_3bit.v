module mux_2_3bit(in0, in1, select, out);

input [2:0] in0, in1;
input select;
output [2:0] out;

assign out = select ? in1 : in0;
	
endmodule
