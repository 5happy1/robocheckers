module op_valid_for_bypass_back(opcode, out);

input [4:0] opcode;
output out;

wire sw, bne, blt, jr;

comp_2_5bit comp_1(opcode, 5'b00111, sw);
comp_2_5bit comp_2(opcode, 5'b00010, bne);
comp_2_5bit comp_3(opcode, 5'b00110, blt);
comp_2_5bit comp_4(opcode, 5'b00100, jr);

assign out = ~(sw | bne | blt | jr);

endmodule
