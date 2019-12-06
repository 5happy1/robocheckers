/**
 * READ THIS DESCRIPTION!
 *
 * The processor takes in several inputs from a skeleton file.
 *
 * Inputs
 * clock: this is the clock for your processor at 50 MHz
 * reset: we should be able to assert a reset to start your pc from 0 (sync or
 * async is fine)
 *
 * Imem: input data from imem
 * Dmem: input data from dmem
 * Regfile: input data from regfile
 *
 * Outputs
 * Imem: output control signals to interface with imem
 * Dmem: output control signals and data to interface with dmem
 * Regfile: output control signals and data to interface with regfile
 *
 * Notes
 *
 * Ultimately, your processor will be tested by subsituting a master skeleton, imem, dmem, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file acts as a small wrapper around your processor for this purpose.
 *
 * You will need to figure out how to instantiate two memory elements, called
 * "syncram," in Quartus: one for imem and one for dmem. Each should take in a
 * 12-bit address and allow for storing a 32-bit value at each address. Each
 * should have a single clock.
 *
 * Each memory element should have a corresponding .mif file that initializes
 * the memory element to certain value on start up. These should be named
 * imem.mif and dmem.mif respectively.
 *
 * Importantly, these .mif files should be placed at the top level, i.e. there
 * should be an imem.mif and a dmem.mif at the same level as process.v. You
 * should figure out how to point your generated imem.v and dmem.v files at
 * these MIF files.
 *
 * imem
 * Inputs:  12-bit address, 1-bit clock enable, and a clock
 * Outputs: 32-bit instruction
 *
 * dmem
 * Inputs:  12-bit address, 1-bit clock, 32-bit data, 1-bit write enable
 * Outputs: 32-bit data at the given address
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for regfile
    ctrl_writeReg,                  // O: Register to write to in regfile
    ctrl_readRegA,                  // O: Register to read from port A of regfile
    ctrl_readRegB,                  // O: Register to read from port B of regfile
    data_writeReg,                  // O: Data to write to for regfile
    data_readRegA,                  // I: Data from port A of regfile
    data_readRegB                   // I: Data from port B of regfile
//	 test_out,
//	 test_out_2,
//	 test_out_3,
//	 test_out_4
);
    // Control signals
    input clock, reset;

    // Imem
    output [11:0] address_imem;
    input [31:0] q_imem;

    // Dmem
    output [11:0] address_dmem;
    output [31:0] data;
    output wren;
    input [31:0] q_dmem;

    // Regfile
    output ctrl_writeEnable;
    output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    output [31:0] data_writeReg;
    input [31:0] data_readRegA, data_readRegB;
//	 output test_out;
//	 output [31:0] test_out_2, test_out_4;
//	 output [4:0] test_out_3;

    /* YOUR CODE STARTS HERE */
	 
	 ///
	 //  Wires, lots of wires
	 ///
	 
	 // Transportation wires
	 wire [31:0] curr_pc, pc_in, curr_pc_plus_4, next_pc, fd_pc_out, dx_pc_out, xm_pc_out, mw_pc_out;
	 wire [31:0] curr_instr, fd_instr_out, dx_instr_out, xm_instr_out, mw_instr_out;
	 wire [31:0] dx_A_out, dx_B_out, xm_O_out, xm_B_out, mw_O_out, mw_D_out, dx_instr_in, fd_instr_in;
	 wire [31:0] reg_out_A, reg_out_B, alu_in_B, dmem_out, write_data, write_data_out, write_instr_out;
	 wire [31:0] alu_out, alu_in_A, alu_in_B4;
	 wire [31:0] dm_in;
	 wire [31:0] jump_choice, T_rd_choice, pI_sex, T_padded, dx_pc_plus_4, reg_din_beta_out, reg_write_in;
	 wire [31:0] mw_pc_plus_1, mw_T_padded;
	 wire [31:0] multdiv_result, pw_p_out, pw_instr_out;
	 wire alu_neq, rd_lt_rs;
	 
	 wire [4:0] alu_op, alu_addsub, regfile_s1, regfile_s2, reg_d_alpha_out, reg_d_beta_out;
	 wire [31:0] I_sex;
	 
	 wire md_rdy, md_exception, pw_r_out;
	 wire [31:0] md_result;
	 
	 wire [2:0] alu_ex, md_ex, xm_E_out, mw_E_out, pw_e_out, exception_data;
	 wire alu_overflow, exception;
	 wire [31:0] exception_data_extended, exception_din;
	 
	 // Control signals
	 wire ctrl_write_reg_file, ctrl_alu_op_choice, ctrl_alu_in_B, ctrl_dmem_wren, ctrl_write_data, ctrl_regfile_s1, ctrl_regfile_s2;
	 wire [1:0] ctrl_bypass_alu_in_A, ctrl_bypass_alu_in_B;
	 wire ctrl_bypass_dm, ctrl_nop_dx, ctrl_nop_fd, ctrl_disable_fd, ctrl_alu_addsub, ctrl_same_pc;
	 wire ctrl_mux_next_pc, ctrl_j_alpha, ctrl_j_beta, ctrl_reg_d_alpha, ctrl_reg_d_beta, ctrl_reg_din_alpha, ctrl_reg_din_beta;
	 wire ctrl_write_data_out, ctrl_write_instr, stall_from_multdiv, ctrl_MULT, ctrl_DIV, nops_xm_from_md, enable_pw_instr, ctrl_ex_choice;
	 
	 // Dummy wires
	 wire add_pc_cout, add_pc_overflow, add_pc_neq, add_pc_lt;
	 wire alu_isLessThan;
	 wire bla_out, bla_cout, bla_neq_out, bla_overflow;
	 wire boop_cout, boop_overflow_out, boop_neq_out, boop_lt_out;
	 wire beep_cout, beep_overflow_out, beep_neq_out, beep_lt_out;
	 wire buup_cout, buup_overflow_out, buup_neq_out, buup_lt_out;
	 
	 
	 ///
	 //  Main pipeline registers
	 ///
	 
	 reg_FD	pipe_reg_fd(curr_pc_plus_4, fd_instr_in, clock, reset, ~ctrl_disable_fd, fd_pc_out, fd_instr_out);
	 reg_DX	pipe_reg_dx(fd_pc_out, dx_instr_in, reg_out_A, reg_out_B, clock, reset, dx_pc_out, dx_instr_out, dx_A_out, dx_B_out);
	 reg_XM	pipe_reg_xm(dx_pc_out, dx_instr_out, alu_out, dx_B_out, alu_ex, clock, reset, nops_xm_from_md, xm_pc_out, xm_instr_out, xm_O_out, xm_B_out, xm_E_out);
	 reg_MW	pipe_reg_mw(xm_pc_out, xm_instr_out, xm_O_out, dmem_out, xm_E_out, clock, reset, mw_pc_out, mw_instr_out, mw_O_out, mw_D_out, mw_E_out);
	 reg_PW	pipe_reg_pw(dx_instr_out, md_result, md_rdy, md_ex, clock, reset, enable_pw_instr, pw_instr_out, pw_p_out, pw_r_out, pw_e_out);
	 
	 
	 ///
	 //  Controls
	 ///
	 
	 controls_D				ctrls_D(fd_instr_out[31:27], ctrl_regfile_s1, ctrl_regfile_s2);
	 controls_E				ctrls_E(dx_instr_out[31:27], ctrl_alu_op_choice, ctrl_alu_in_B, ctrl_j_alpha, ctrl_j_beta, ctrl_alu_addsub);
	 controls_M				ctrls_M(xm_instr_out[31:27], ctrl_dmem_wren);
	 controls_W				ctrls_W(write_instr_out[31:27], exception, ctrl_write_reg_file, ctrl_write_data, ctrl_reg_d_alpha, ctrl_reg_d_beta, ctrl_reg_din_alpha, ctrl_reg_din_beta);
	 controls_bypassing	ctrls_bypassing(fd_instr_out, dx_instr_out, xm_instr_out, write_instr_out, alu_neq, rd_lt_rs,
													 dx_A_out, reg_d_alpha_out, stall_from_multdiv,
													 ctrl_bypass_alu_in_A, ctrl_bypass_alu_in_B, ctrl_bypass_dm, ctrl_nop_dx,
													 ctrl_nop_fd, ctrl_disable_fd, ctrl_mux_next_pc, ctrl_same_pc);
	 controls_P				ctrls_P(dx_instr_out, md_rdy, pw_r_out, clock, reset, ctrl_write_data_out, ctrl_write_instr, stall_from_multdiv,
										  ctrl_MULT, ctrl_DIV, nops_xm_from_md, enable_pw_instr, ctrl_ex_choice);
	 
//	 assign test_out = exception;
//	 assign test_out_2 = dx_pc_out;
//	 assign test_out_3 = alu_overflow;
//	 assign test_out_4 = dx_instr_out;
	 
	 
	 
	 ///
	 // Jump Area
	 ///
	 
	 mux_2	mux_j_alpha(pI_sex, T_rd_choice, ctrl_j_alpha, jump_choice);
	 mux_2	mux_j_beta(alu_in_B4, T_padded, ctrl_j_beta, T_rd_choice);
	 assign 	T_padded[31:27] = 5'b0;
	 assign 	T_padded[26:0] = dx_instr_out[26:0];
	 adder	add_j1(I_sex, dx_pc_out, 0, pI_sex, boop_cout, boop_overflow_out, boop_neq_out, boop_lt_out);
	 
	 
	 
	 
	 ///
	 //  Program Counter / Instruction Memory Area
	 ///
	 
	 register 	reg_pc(pc_in, 1'b1, clock, reset, curr_pc);
	 adder    	adder_pc(curr_pc, 32'd1, 1'b0, curr_pc_plus_4, add_pc_cout, add_pc_overflow, add_pc_neq, add_pc_lt);
	 mux_2		mux_next_pc(curr_pc_plus_4, jump_choice, ctrl_mux_next_pc, next_pc);
	 mux_2		mux_pc_in(next_pc, curr_pc, ctrl_same_pc, pc_in);
	 assign address_imem = curr_pc[11:0];
    assign curr_instr = q_imem;
	 mux_2		mux_fd_instr_in(curr_instr, 32'b0, ctrl_nop_fd, fd_instr_in);
	 
	 
	 
	 ///
	 //  Decode
	 ///
	 
	 mux_2_5bit	mux_regfile_s1(fd_instr_out[21:17], 5'd30, ctrl_regfile_s1, regfile_s1);
	 mux_2_5bit	mux_regfile_s2(fd_instr_out[16:12], fd_instr_out[26:22], ctrl_regfile_s2, regfile_s2);
	 
	 mux_2		mux_dx_instr_in(fd_instr_out, 32'b0, ctrl_nop_dx, dx_instr_in);
	 
	 mux_2_5bit	mux_reg_d_alpha(write_instr_out[26:22], reg_d_beta_out, ctrl_reg_d_alpha, reg_d_alpha_out);
	 mux_2_5bit mux_reg_d_beta(5'd30, 5'd31, ctrl_reg_d_beta, reg_d_beta_out);
	 
	 assign reg_out_A = data_readRegA;
	 assign reg_out_B = data_readRegB;
	 assign data_writeReg = reg_write_in;
	 assign ctrl_writeEnable = ctrl_write_reg_file;
	 assign ctrl_writeReg = reg_d_alpha_out;		// rd or 30 or 31 from m/w register
	 assign ctrl_readRegA = regfile_s1; 			// rs or 30 from f/d register
    assign ctrl_readRegB = regfile_s2; 			// rt or rd from f/d register
	 
	 
	 ///
	 //  Execute
	 ///
	 
	 //mux_4			mux_alu_in_A(dx_A_out, xm_O_out, reg_write_in, xm_O_out, ctrl_bypass_alu_in_A, alu_in_A);
	 //mux_4			mux_alu_in_B4(dx_B_out, xm_O_out, reg_write_in, xm_O_out, ctrl_bypass_alu_in_B, alu_in_B4);
	 
	 wire ba_1, ba_2, ba_3, ba_4, bb_1, bb_2, bb_3, bb_4;
	 wire [4:0] decode_a_in, decode_b_in;
	 wire [31:0] decode_a_out, decode_b_out;
	 
	 assign decode_a_in[4:2] = 3'b0;
	 assign decode_a_in[1:0] = ctrl_bypass_alu_in_A;
	 assign decode_b_in[4:2] = 3'b0;
	 assign decode_b_in[1:0] = ctrl_bypass_alu_in_B;
	 
	 decoder	decode_ba(decode_a_in, decode_a_out);
	 decoder decode_bb(decode_b_in, decode_b_out);
	 
	 trie t1a(dx_A_out, decode_a_out[0], alu_in_A);
	 trie t2a(xm_O_out, decode_a_out[1], alu_in_A);
	 trie t3a(reg_write_in, decode_a_out[2], alu_in_A);
	 trie t4a(xm_O_out, decode_a_out[3], alu_in_A);
	 
	 trie t1b(dx_B_out, decode_b_out[0], alu_in_B4);
	 trie t2b(xm_O_out, decode_b_out[1], alu_in_B4);
	 trie t3b(reg_write_in, decode_b_out[2], alu_in_B4);
	 trie t4b(xm_O_out, decode_b_out[3], alu_in_B4);
	 
	 
	 alu 				alu_main(alu_in_A, alu_in_B, alu_op, dx_instr_out[11:7], alu_out, alu_neq, alu_isLessThan, alu_overflow);
	 
	 mux_2_5bit		mux_alu_op(dx_instr_out[6:2], alu_addsub, ctrl_alu_op_choice, alu_op);
	 //trie_5bit		t_aop1(dx_instr_out[6:2], ~ctrl_alu_op_choice, alu_op);
	 //trie_5bit		t_aop2(alu_addsub, ctrl_alu_op_choice, alu_op);
	 
	 mux_2_5bit		mux_alu_addsub(5'b0, 5'b00001, ctrl_alu_addsub, alu_addsub);
	 //trie_5bit		t_aaop1(5'b0, ~ctrl_alu_addsub, alu_addsub);
	 //trie_5bit		t_aaop2(5'b00001, ctrl_alu_addsub, alu_addsub);
	 
	 sex_17_32		sign_extender(dx_instr_out[16:0], I_sex);
	 
	 mux_2			mux_alu_in_B(alu_in_B4, I_sex, ctrl_alu_in_B, alu_in_B);
	 //trie				t_alub1(alu_in_B4, ~ctrl_alu_in_B, alu_in_B);
	 //trie				t_alub2(I_sex, ctrl_alu_in_B, alu_in_B);
	 
	 adder			add_rd_lt_rs(alu_in_B, alu_in_A, 1'b1, bla_out, bla_cout, bla_overflow, bla_neq_out, rd_lt_rs);
	 exception_alu	ex_alu(dx_instr_out, alu_overflow, alu_ex);
	 
	 
	 
	 
	 ///
	 // Memory
	 ///
	 
	 mux_2 mux_dm_in(xm_B_out, write_data_out, ctrl_bypass_dm, dm_in); // <--- should be write_data?
	 assign address_dmem = xm_O_out[11:0];
    assign data = dm_in;
    assign wren = ctrl_dmem_wren;
    assign dmem_out = q_dmem;
	 
	 
	 
	 ///
	 //  Writeback
	 ///
	 
	 //mux_2	mux_write_data(mw_O_out, mw_D_out, ctrl_write_data, write_data);
	 trie t_write0(mw_O_out, ~ctrl_write_data, write_data);
	 trie t_write1(mw_D_out, ctrl_write_data, write_data);
	 
	 //mux_2	mux_write_data_out(write_data, pw_p_out, ctrl_write_data_out, write_data_out);
	 trie t_pw0(write_data, ~ctrl_write_data_out, write_data_out);
	 trie t_pw1(pw_p_out, ctrl_write_data_out, write_data_out);
	 
	 
	 assign	exception_data_extended[31:3] = 29'b0;
	 assign	exception_data_extended[2:0] = exception_data;
	 
	 //mux_2	mux_ex_din(write_data_out, exception_data_extended, exception, exception_din);
	 trie t_ex0(write_data_out, ~exception, exception_din);
	 trie t_ex1(exception_data_extended, exception, exception_din);
	 
	 assign	mw_T_padded[31:27] = 5'b0;
	 assign	mw_T_padded[26:0] = write_instr_out[26:0];
	 
	 //mux_2	mux_write_instr(mw_instr_out, pw_instr_out, ctrl_write_instr, write_instr_out);
	 trie t_wi0(mw_instr_out, ~ctrl_write_instr, write_instr_out);
	 trie t_wi1(pw_instr_out, ctrl_write_instr, write_instr_out);
	 
	 mux_2	mux_reg_din_alpha(exception_din, reg_din_beta_out, ctrl_reg_din_alpha, reg_write_in);
	 //trie t_j0(exception_din, ~ctrl_reg_din_alpha, reg_write_in);
	 //trie t_j1(reg_din_beta_out, ctrl_reg_din_alpha, reg_write_in);
	 
	 mux_2	mux_reg_din_beta(mw_pc_out, mw_T_padded, ctrl_reg_din_beta, reg_din_beta_out);
	 //trie t_rdb0(mw_pc_out, ~ctrl_reg_din_beta, reg_din_beta_out);
	 //trie t_rdb1(mw_T_padded, ctrl_reg_din_beta, reg_din_beta_out);
	 
	 mux_2_3bit mux_ex_choice(mw_E_out, pw_e_out, ctrl_ex_choice, exception_data);
	 //trie_3bit t_ec0(mw_E_out, ~ctrl_ex_choice, exception_data);
	 //trie_3bit t_ec1(pw_e_out, ctrl_ex_choice, exception_data);
	 
	 
	 or or_exception(exception, exception_data[2], exception_data[1], exception_data[0]);
	 
	 
	 
	 
	 ///
	 //  Mult/Div
	 ///
	 
	 multdiv md(alu_in_A, alu_in_B, ctrl_MULT, ctrl_DIV, clock, md_result, md_exception, md_rdy);
	 exception_md emd(pw_instr_out, md_exception, md_ex);
	 
	 
	 

endmodule
