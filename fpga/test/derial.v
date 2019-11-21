module derial(data_in, clock_in, data_out, clock_out);

// Note: clock_in and clock_out are not the actual clock of the processor.
//			They are the clock pins from the communication wires.
input data_in, clock_in;
output data_out, clock_out;



// Opcodes
integer opcode_receive_valid_move;

initial begin
	

end // end initial



always @(posedge clock_in) begin

	

end // end posedge clock_in

endmodule
