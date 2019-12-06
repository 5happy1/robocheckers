module derial(data_in, clock_in, data_out, clock_out, r26_out, r27_out);

// Note: clock_in and clock_out are not the actual clock of the processor.
//			They are the clock pins from the communication wires.
input data_in, clock_in;
output data_out, clock_out;
output [31:0] r26_out, r27_out;

assign data_out = data_in;
assign clock_out = clock_in;


// Data
reg [31:0] buffer;
integer buffer_pos = 31;

reg [3:0] curr_opcode;
integer curr_expected_length;

reg [31:0] r26;
reg [31:0] r27;

assign r26_out = r26;
assign r27_out = r27;

// When receive message: put opcode plus data bit in r27, put data in r26


// Opcodes and expected data length
integer opcode_receive_valid_move;
integer opcode_reset;

initial begin

	opcode_receive_valid_move = 0;
	opcode_reset = 1;
	buffer_pos = 31;
	
	r26 = 0;
	r27 = 0;
	

end // end initial



always @(posedge clock_in) begin
	
	buffer[buffer_pos] = data_in;
	buffer_pos = buffer_pos - 1;
	check_buffer();

end // end posedge clock_in

task check_buffer;

	integer length;
	begin
		
		// If there are 4 bits in the buffer, check the opcode and set the expected length
		if (buffer_pos == 27) begin
			curr_opcode = buffer[31:28];
			curr_expected_length = expected_data_length(curr_opcode);
		end
		
		
		if (buffer_pos == 27 - curr_expected_length) begin
			// Else if data in buffer is of correct length for the opcode, process it based on the opcode
			process_data();
			buffer_pos = 31;
		end
		
	
	end
endtask // end check_buffer task

task process_data;

	begin
		
		// Put opcode and signal bit in register 27
		if (r27[0] == 1) begin
			r27[0] = 0;
		end else begin
			r27[0] = 1;
		end
		
		r27[4:1] = curr_opcode;
		
		
		// Put data in register 26
		update_data_reg();
		
	end

endtask // end process_data task

task update_data_reg;

	begin
		case (curr_opcode)
			opcode_receive_valid_move : handle_valid_move();
			opcode_reset : handle_reset();
		endcase
	end

endtask // end update_data_reg

/////
///    Message handlers
/////

task handle_valid_move;

	begin
		r26[14:0] = buffer[27:13];
	end


endtask // end handle_valid_move


task handle_reset;

	begin
		
	end


endtask // end handle_valid_move






function integer expected_data_length;

	input opcode;
	begin
		expected_data_length = 0;
		case (opcode)
			opcode_receive_valid_move : expected_data_length = 15;
			opcode_reset : expected_data_length = 0;
		endcase
	
	end

endfunction // end expected_data_length function

endmodule
