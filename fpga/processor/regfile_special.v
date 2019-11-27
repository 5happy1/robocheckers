module regfile_special (
    clock,
    ctrl_writeEnable,
    ctrl_reset, ctrl_writeReg,
    ctrl_readRegA, ctrl_readRegB, data_writeReg,
    data_readRegA, data_readRegB,
	 r28_outraw, r1_outraw,
	 r27_inraw, r26_inraw
);

   input clock, ctrl_writeEnable, ctrl_reset;
   input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
   input [31:0] data_writeReg;
	input [31:0] r27_inraw, r26_inraw;
	
   output tri [31:0] data_readRegA, data_readRegB;
	output [31:0] r28_outraw, r1_outraw;
	
	tri [31:0] wire_readRegA, wire_readRegB;

   /* YOUR CODE HERE */
	
	wire en0, en1, en2, en3, en4, en5, en6, en7, en8, en9, en10, en11, en12, en13, en14, en15, 
		  en16, en17, en18, en19, en20, en21, en22, en23, en24, en25, en26, en27, en28, en29, en30, en31;
	wire [31:0] enable_write;
	
	wire [31:0] o_0, o_1, o_2, o_3, o_4, o_5, o_6, o_7, o_8, o_9, o_10, o_11, o_12, o_13, o_14, o_15,
					o_16, o_17, o_18, o_19, o_20, o_21, o_22, o_23, o_24, o_25, o_26, o_27, o_28, o_29, o_30, o_31;
	
	assign r28_outraw = o_28;
	
	decoder decode_writeReg(ctrl_writeReg, enable_write);
	
	and and_in_0(en0, enable_write[0], ctrl_writeEnable);
	and and_in_1(en1, enable_write[1], ctrl_writeEnable);
	and and_in_2(en2, enable_write[2], ctrl_writeEnable);
	and and_in_3(en3, enable_write[3], ctrl_writeEnable);
	and and_in_4(en4, enable_write[4], ctrl_writeEnable);
	and and_in_5(en5, enable_write[5], ctrl_writeEnable);
	and and_in_6(en6, enable_write[6], ctrl_writeEnable);
	and and_in_7(en7, enable_write[7], ctrl_writeEnable);
	and and_in_8(en8, enable_write[8], ctrl_writeEnable);
	and and_in_9(en9, enable_write[9], ctrl_writeEnable);
	and and_in_10(en10, enable_write[10], ctrl_writeEnable);
	and and_in_11(en11, enable_write[11], ctrl_writeEnable);
	and and_in_12(en12, enable_write[12], ctrl_writeEnable);
	and and_in_13(en13, enable_write[13], ctrl_writeEnable);
	and and_in_14(en14, enable_write[14], ctrl_writeEnable);
	and and_in_15(en15, enable_write[15], ctrl_writeEnable);
	and and_in_16(en16, enable_write[16], ctrl_writeEnable);
	and and_in_17(en17, enable_write[17], ctrl_writeEnable);
	and and_in_18(en18, enable_write[18], ctrl_writeEnable);
	and and_in_19(en19, enable_write[19], ctrl_writeEnable);
	and and_in_20(en20, enable_write[20], ctrl_writeEnable);
	and and_in_21(en21, enable_write[21], ctrl_writeEnable);
	and and_in_22(en22, enable_write[22], ctrl_writeEnable);
	and and_in_23(en23, enable_write[23], ctrl_writeEnable);
	and and_in_24(en24, enable_write[24], ctrl_writeEnable);
	and and_in_25(en25, enable_write[25], ctrl_writeEnable);
	and and_in_26(en26, enable_write[26], ctrl_writeEnable);
	and and_in_27(en27, enable_write[27], ctrl_writeEnable);
	and and_in_28(en28, enable_write[28], ctrl_writeEnable);
	and and_in_29(en29, enable_write[29], ctrl_writeEnable);
	and and_in_30(en30, enable_write[30], ctrl_writeEnable);
	and and_in_31(en31, enable_write[31], ctrl_writeEnable);
	
	register r0(32'b0, 1'b0, 1'b0, 1'b0, o_0);
	register r1(data_writeReg, en1, clock, ctrl_reset, o_1);
	register r2(data_writeReg, en2, clock, ctrl_reset, o_2);
	register r3(data_writeReg, en3, clock, ctrl_reset, o_3);
	register r4(data_writeReg, en4, clock, ctrl_reset, o_4);
	register r5(data_writeReg, en5, clock, ctrl_reset, o_5);
	register r6(data_writeReg, en6, clock, ctrl_reset, o_6);
	register r7(data_writeReg, en7, clock, ctrl_reset, o_7);
	register r8(data_writeReg, en8, clock, ctrl_reset, o_8);
	register r9(data_writeReg, en9, clock, ctrl_reset, o_9);
	register r10(data_writeReg, en10, clock, ctrl_reset, o_10);
	register r11(data_writeReg, en11, clock, ctrl_reset, o_11);
	register r12(data_writeReg, en12, clock, ctrl_reset, o_12);
	register r13(data_writeReg, en13, clock, ctrl_reset, o_13);
	register r14(data_writeReg, en14, clock, ctrl_reset, o_14);
	register r15(data_writeReg, en15, clock, ctrl_reset, o_15);
	register r16(data_writeReg, en16, clock, ctrl_reset, o_16);
	register r17(data_writeReg, en17, clock, ctrl_reset, o_17);
	register r18(data_writeReg, en18, clock, ctrl_reset, o_18);
	register r19(data_writeReg, en19, clock, ctrl_reset, o_19);
	register r20(data_writeReg, en20, clock, ctrl_reset, o_20);
	register r21(data_writeReg, en21, clock, ctrl_reset, o_21);
	register r22(data_writeReg, en22, clock, ctrl_reset, o_22);
	register r23(data_writeReg, en23, clock, ctrl_reset, o_23);
	register r24(data_writeReg, en24, clock, ctrl_reset, o_24);
	register r25(data_writeReg, en25, clock, ctrl_reset, o_25);
	register r26(r26_inraw, 1'b1, clock, ctrl_reset, o_26);
	register r27(r27_inraw, 1'b1, clock, ctrl_reset, o_27);
	register r28(data_writeReg, en28, clock, ctrl_reset, o_28);
	register r29(data_writeReg, en29, clock, ctrl_reset, o_29);
	register r30(data_writeReg, en30, clock, ctrl_reset, o_30);
	register r31(data_writeReg, en31, clock, ctrl_reset, o_31);

	wire [31:0] rega_choose, regb_choose;

	decoder decode_out_a(ctrl_readRegA, rega_choose);
	decoder decode_out_b(ctrl_readRegB, regb_choose);

	trie trie_a0(o_0, rega_choose[0], wire_readRegA);
	trie trie_a1(o_1, rega_choose[1], wire_readRegA);
	trie trie_a2(o_2, rega_choose[2], wire_readRegA);
	trie trie_a3(o_3, rega_choose[3], wire_readRegA);
	trie trie_a4(o_4, rega_choose[4], wire_readRegA);
	trie trie_a5(o_5, rega_choose[5], wire_readRegA);
	trie trie_a6(o_6, rega_choose[6], wire_readRegA);
	trie trie_a7(o_7, rega_choose[7], wire_readRegA);
	trie trie_a8(o_8, rega_choose[8], wire_readRegA);
	trie trie_a9(o_9, rega_choose[9], wire_readRegA);
	trie trie_a10(o_10, rega_choose[10], wire_readRegA);
	trie trie_a11(o_11, rega_choose[11], wire_readRegA);
	trie trie_a12(o_12, rega_choose[12], wire_readRegA);
	trie trie_a13(o_13, rega_choose[13], wire_readRegA);
	trie trie_a14(o_14, rega_choose[14], wire_readRegA);
	trie trie_a15(o_15, rega_choose[15], wire_readRegA);
	trie trie_a16(o_16, rega_choose[16], wire_readRegA);
	trie trie_a17(o_17, rega_choose[17], wire_readRegA);
	trie trie_a18(o_18, rega_choose[18], wire_readRegA);
	trie trie_a19(o_19, rega_choose[19], wire_readRegA);
	trie trie_a20(o_20, rega_choose[20], wire_readRegA);
	trie trie_a21(o_21, rega_choose[21], wire_readRegA);
	trie trie_a22(o_22, rega_choose[22], wire_readRegA);
	trie trie_a23(o_23, rega_choose[23], wire_readRegA);
	trie trie_a24(o_24, rega_choose[24], wire_readRegA);
	trie trie_a25(o_25, rega_choose[25], wire_readRegA);
	trie trie_a26(o_26, rega_choose[26], wire_readRegA);
	trie trie_a27(o_27, rega_choose[27], wire_readRegA);
	trie trie_a28(o_28, rega_choose[28], wire_readRegA);
	trie trie_a29(o_29, rega_choose[29], wire_readRegA);
	trie trie_a30(o_30, rega_choose[30], wire_readRegA);
	trie trie_a31(o_31, rega_choose[31], wire_readRegA);

	trie trie_b0(o_0, regb_choose[0], wire_readRegB);
	trie trie_b1(o_1, regb_choose[1], wire_readRegB);
	trie trie_b2(o_2, regb_choose[2], wire_readRegB);
	trie trie_b3(o_3, regb_choose[3], wire_readRegB);
	trie trie_b4(o_4, regb_choose[4], wire_readRegB);
	trie trie_b5(o_5, regb_choose[5], wire_readRegB);
	trie trie_b6(o_6, regb_choose[6], wire_readRegB);
	trie trie_b7(o_7, regb_choose[7], wire_readRegB);
	trie trie_b8(o_8, regb_choose[8], wire_readRegB);
	trie trie_b9(o_9, regb_choose[9], wire_readRegB);
	trie trie_b10(o_10, regb_choose[10], wire_readRegB);
	trie trie_b11(o_11, regb_choose[11], wire_readRegB);
	trie trie_b12(o_12, regb_choose[12], wire_readRegB);
	trie trie_b13(o_13, regb_choose[13], wire_readRegB);
	trie trie_b14(o_14, regb_choose[14], wire_readRegB);
	trie trie_b15(o_15, regb_choose[15], wire_readRegB);
	trie trie_b16(o_16, regb_choose[16], wire_readRegB);
	trie trie_b17(o_17, regb_choose[17], wire_readRegB);
	trie trie_b18(o_18, regb_choose[18], wire_readRegB);
	trie trie_b19(o_19, regb_choose[19], wire_readRegB);
	trie trie_b20(o_20, regb_choose[20], wire_readRegB);
	trie trie_b21(o_21, regb_choose[21], wire_readRegB);
	trie trie_b22(o_22, regb_choose[22], wire_readRegB);
	trie trie_b23(o_23, regb_choose[23], wire_readRegB);
	trie trie_b24(o_24, regb_choose[24], wire_readRegB);
	trie trie_b25(o_25, regb_choose[25], wire_readRegB);
	trie trie_b26(o_26, regb_choose[26], wire_readRegB);
	trie trie_b27(o_27, regb_choose[27], wire_readRegB);
	trie trie_b28(o_28, regb_choose[28], wire_readRegB);
	trie trie_b29(o_29, regb_choose[29], wire_readRegB);
	trie trie_b30(o_30, regb_choose[30], wire_readRegB);
	trie trie_b31(o_31, regb_choose[31], wire_readRegB);
	
	assign data_readRegA[31:0] = wire_readRegA[31:0];
	assign data_readRegB[31:0] = wire_readRegB[31:0];
	

endmodule
