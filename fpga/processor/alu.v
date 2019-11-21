module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);

   input [31:0] data_operandA, data_operandB;
   input [4:0] ctrl_ALUopcode, ctrl_shiftamt;

   output [31:0] data_result;
   output isNotEqual, isLessThan, overflow;

   // YOUR CODE HERE //
	wire [31:0] adder_out, and_out, or_out, sll_out, sra_out;
	
	// Dummy wires
	wire d0;
	
	adder add(data_operandA, data_operandB, ctrl_ALUopcode[0], adder_out, d0, overflow, isNotEqual, isLessThan);
	and_32 and0(data_operandA, data_operandB, and_out);
	or_32 or0(data_operandA, data_operandB, or_out);
	sll sll0(data_operandA, ctrl_shiftamt, sll_out);
	sra sra0(data_operandA, ctrl_shiftamt, sra_out);
	
	mux_8 mux_final(adder_out, adder_out, and_out, or_out, sll_out, sra_out, 32'b0, 32'b0, ctrl_ALUopcode[2:0], data_result);

endmodule
