module controls_bypassing(fd_instr, dx_instr, xm_instr, mw_instr, alu_neq, rd_lt_rs, dx_A_out, mw_writing, stall_from_multdiv,
								  bypassing_alu_in_A, bypassing_alu_in_B, bypassing_dm,
								  nop_dx, nop_fd, disable_fd, mux_next_pc, same_pc);

input [31:0] fd_instr, dx_instr, xm_instr, mw_instr, dx_A_out;
input [4:0] mw_writing;
input alu_neq, rd_lt_rs, stall_from_multdiv;
output [1:0] bypassing_alu_in_A, bypassing_alu_in_B;
output bypassing_dm, nop_dx, nop_fd, mux_next_pc, disable_fd, same_pc;

wire [4:0] fd_op, fd_rs, fd_rt, fd_rd;
wire [4:0] dx_op, dx_rs, dx_rt, dx_rd;
wire [4:0] xm_op, xm_rs, xm_rt, xm_rd;
wire [4:0] mw_op, mw_rs, mw_rt, mw_rd;

assign fd_op = fd_instr[31:27];
assign fd_rs = fd_instr[21:17];
assign fd_rt = fd_instr[16:12];
assign fd_rd = fd_instr[26:22];

assign dx_op = dx_instr[31:27];
assign dx_rs = dx_instr[21:17];
assign dx_rt = dx_instr[16:12];
assign dx_rd = dx_instr[26:22];

assign xm_op = xm_instr[31:27];
assign xm_rs = xm_instr[21:17];
assign xm_rt = xm_instr[16:12];
assign xm_rd = xm_instr[26:22];

assign mw_op = mw_instr[31:27];
assign mw_rs = mw_instr[21:17];
assign mw_rt = mw_instr[16:12];
assign mw_rd = mw_writing;

// Inputs from execute stage
wire a, a_not, b, b_not, c, c_not, d, d_not, e, e_not;

assign a = dx_instr[31];
assign b = dx_instr[30];
assign c = dx_instr[29];
assign d = dx_instr[28];
assign e = dx_instr[27];

not not_a(a_not, a);
not not_b(b_not, b);
not not_c(c_not, c);
not not_d(d_not, d);
not not_e(e_not, e);

// rt(0) or rd (1) register coming from F/D B
wire rt_or_rd;
assign rt_or_rd = (a_not & b_not & c & d & e) | (a_not & b_not & c_not & d & e_not) | (a_not & b_not & c & e_not);

// no bypass on non writing jump instructions
wire dx_op_eq_jr, dx_op_eq_bne, dx_op_eq_j, dx_op_eq_blt, dx_op_eq_bex;

comp_2_5bit comp_alu_is_jr(dx_op, 5'b00100, dx_op_eq_jr);
comp_2_5bit comp_alu_is_bne(dx_op, 5'b00010, dx_op_eq_bne);
comp_2_5bit comp_alu_is_j(dx_op, 5'b00001, dx_op_eq_j);
comp_2_5bit comp_alu_is_blt(dx_op, 5'b00110, dx_op_eq_blt);
comp_2_5bit comp_alu_is_bex(dx_op, 5'b10110, dx_op_eq_bex);

wire no_bypass_rs = dx_op_eq_bex;
wire no_bypass_rt = dx_op_eq_bne | dx_op_eq_blt | dx_op_eq_bex;

/// ALU inputs
wire xm_op_valid, mw_op_valid;

// alu_in_A
wire one, two, rs_eq_zero, rs_neq_zero, bypass_A_1, bypass_A_2, rt_eq_zero, rt_neq_zero;
comp_2_5bit	comp_alu_in_A_1(dx_rs, xm_rd, one);
comp_2_5bit	comp_alu_in_A_2(dx_rs, mw_rd, two);

comp_2_5bit	comp_alu_in_A_3(dx_rs, 5'b0, rs_eq_zero);
not not_wow(rs_neq_zero, rs_eq_zero);
and and_one(bypass_A_1, one, rs_neq_zero);
and and_two(bypass_A_2, two, rs_neq_zero);

assign bypassing_alu_in_A[0] = bypass_A_1 & xm_op_valid; // & ~no_bypass_rt;
assign bypassing_alu_in_A[1] = bypass_A_2 & mw_op_valid; // & ~no_bypass_rt;

comp_2_5bit	comp_alu_in_A_4(dx_rt, 5'b0, rt_eq_zero);
not not_wow2(rt_neq_zero, rt_eq_zero);



// alu_in_B
//wire aiB_0_temp, aiB_1_temp, aiB_jr_rd_eq_xm, aiB_jr_rd_eq_mw;
////comp_2_5bit	comp_alu_in_B_1(dx_rt, xm_rd, bypassing_alu_in_B[0]);
////comp_2_5bit	comp_alu_in_B_2(dx_rt, mw_rd, bypassing_alu_in_B[1]);
//comp_2_5bit	comp_alu_in_B_1(dx_rt, xm_rd, aiB_0_temp);
//comp_2_5bit	comp_alu_in_B_2(dx_rt, mw_rd, aiB_1_temp);
//
//
//comp_2_5bit comp_alu_rd_eq_xm(dx_rd, xm_rd, aiB_jr_rd_eq_xm);
//comp_2_5bit comp_alu_rd_eq_mw(dx_rd, mw_rd, aiB_jr_rd_eq_mw);
//
//assign bypassing_alu_in_B[0] = (aiB_0_temp | (dx_op_eq_jr & aiB_jr_rd_eq_xm)) & rt_neq_zero; // & (~no_bypass_rt);
//assign bypassing_alu_in_B[1] = (aiB_1_temp | (dx_op_eq_jr & aiB_jr_rd_eq_mw)) & rt_neq_zero; // & (~no_bypass_rt);

wire rt_alpha, rd_alpha;
wire dx_rt_eq_zero, dx_rd_eq_zero;
wire dx_rt_eq_xm_rd, dx_rt_eq_mw_rd, dx_rd_eq_xm_rd, dx_rd_eq_mw_rd;

comp_2_5bit	comp_alu_in_B_1(dx_rt, 5'b0, dx_rt_eq_zero);
comp_2_5bit	comp_alu_in_B_2(dx_rd, 5'b0, dx_rd_eq_zero);

assign rt_alpha = ~rt_or_rd & ~dx_rt_eq_zero;
assign rd_alpha = rt_or_rd & ~dx_rd_eq_zero;

op_valid_for_bypass_back valid_xm(xm_op, xm_op_valid);
op_valid_for_bypass_back valid_mw(mw_op, mw_op_valid);

comp_2_5bit	comp_alu_in_B_3(dx_rt, xm_rd, dx_rt_eq_xm_rd);
comp_2_5bit	comp_alu_in_B_4(dx_rt, mw_rd, dx_rt_eq_mw_rd);
comp_2_5bit	comp_alu_in_B_5(dx_rd, xm_rd, dx_rd_eq_xm_rd);
comp_2_5bit	comp_alu_in_B_6(dx_rd, mw_rd, dx_rd_eq_mw_rd);

assign bypassing_alu_in_B[0] = ((rt_alpha & dx_rt_eq_xm_rd) | (rd_alpha & dx_rd_eq_xm_rd)) & xm_op_valid;
assign bypassing_alu_in_B[1] = ((rt_alpha & dx_rt_eq_mw_rd) | (rd_alpha & dx_rd_eq_mw_rd)) & mw_op_valid;


// dm
comp_2_5bit	comp_dm(xm_rd, mw_rd, bypassing_dm);

//// stall

// stall for bypassing
wire dx_op_eq_load, fd_op_eq_store, fd_op_neq_store, fd_rs_eq_dx_rd, fd_rt_eq_dx_rd, stall_bypassing;

comp_2_5bit comp_dx_load(dx_op, 5'b01000, dx_op_eq_load);
comp_2_5bit comp_fd_store(fd_op, 5'b00111, fd_op_eq_store);
not not_fd_store(fd_op_neq_store, fd_op_eq_store);
comp_2_5bit comp_fdrs_dxrd(fd_rs, dx_rd, fd_rs_eq_dx_rd);
comp_2_5bit comp_fdrt_dxrd(fd_rt, dx_rd, fd_rt_eq_dx_rd);

assign stall_bypassing = (dx_op_eq_load & (fd_rs_eq_dx_rd | (fd_rt_eq_dx_rd & fd_op_neq_store))) |
									stall_from_multdiv; // Regular stall, or stall from multdiv

// stall for jump hazard
wire jump, dx_A_out_neq_zero;

neq_zero_32 is_dx_A_out_zero(dx_A_out, dx_A_out_neq_zero);

assign jump = (a_not & b_not & c_not & d_not & e) | (a_not & b_not & c_not & d & e) | (a_not & b_not & c & d_not & e_not) |
				(a_not & b_not & c_not & d & e_not & alu_neq) | (a_not & b_not & c & d & e_not & rd_lt_rs) |
				(a & b_not & c & d & e_not & dx_A_out_neq_zero);

assign nop_dx = stall_bypassing | jump;

// disable_fd
assign disable_fd = stall_bypassing;

// stall_fd
assign nop_fd = jump;

// mux_next_pc
assign mux_next_pc = jump;

// same_pc
assign same_pc = stall_bypassing;

endmodule
