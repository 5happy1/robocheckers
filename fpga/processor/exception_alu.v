module exception_alu(instr, overflow, exception);

input [31:0] instr;
input overflow;
output [2:0] exception;

wire [4:0] opcode, alu_opcode;
assign opcode = instr[31:27];
assign alu_opcode = instr[6:2];

wire add, addi, sub, none;
wire zeros, add_alu_op, sub_alu_op, addi_tmp;

comp_2_5bit	comp_zeros(opcode, 5'b0, zeros);
comp_2_5bit	comp_add_op(alu_opcode, 5'b0, add_alu_op);
comp_2_5bit	comp_sub_op(alu_opcode, 5'b00001, sub_alu_op);

// Get signals for add, addi, and sub
assign add = zeros & add_alu_op & overflow;
assign sub = zeros & sub_alu_op & overflow;
comp_2_5bit	comp_addi(opcode, 5'b00101, addi_tmp);
assign addi = addi_tmp & overflow;

assign none = ~(add | addi | sub);

trie_3bit t_add(3'd1, add, exception);
trie_3bit t_addi(3'd2, addi, exception);
trie_3bit t_sub(3'd3, sub, exception);
trie_3bit t_none(3'd0, none, exception);

endmodule
