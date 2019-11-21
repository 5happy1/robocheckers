module exception_md(instr, md_exception, exception);

input [31:0] instr;
input md_exception;
output [2:0] exception;

wire [4:0] alu_opcode;
assign alu_opcode = instr[6:2];

wire mul, div, none;
wire mul_alu_op, div_alu_op;

comp_2_5bit	comp_mul_op(alu_opcode, 5'b00110, mul_alu_op);
comp_2_5bit	comp_div_op(alu_opcode, 5'b00111, div_alu_op);

assign mul = mul_alu_op & md_exception;
assign div = div_alu_op & md_exception;
assign none = ~(mul | div);

trie_3bit t0(3'd4, mul, exception);
trie_3bit t1(3'd5, div, exception);
trie_3bit t2(3'd0, none, exception);

endmodule
