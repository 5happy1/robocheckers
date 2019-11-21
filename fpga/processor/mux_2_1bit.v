module mux_2_1bit(in0, in1, select, out);

input in0, in1;
input select;
output out;

assign out = select ? in1 : in0;
	
endmodule
