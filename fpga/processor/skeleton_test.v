/**
 * NOTE: you should not need to change this file! This file will be swapped out for a grading
 * "skeleton" for testing. We will also remove your imem and dmem file.
 *
 * NOTE: skeleton should be your top-level module!
 *
 * This skeleton file serves as a wrapper around the processor to provide certain control signals
 * and interfaces to memory elements. This structure allows for easier testing, as it is easier to
 * inspect which signals the processor tries to assert when.
 */

module skeleton_test(clock, reset, test, t_ctrl_writeEnable, t_ctrl_writeReg, t_ctrl_readRegA, t_ctrl_readRegB,
							t_data_writeReg, t_data_readRegA, t_data_readRegB, t_test_out, t_test2_out, t_test3_out, t_test4_out,
							o_ctrl_writeEnable, o_ctrl_writeReg, o_data_writeReg);
    input clock, reset, test;
	 
	 // Test reg file
	 input t_ctrl_writeEnable;
    input [4:0] t_ctrl_writeReg, t_ctrl_readRegA, t_ctrl_readRegB;
    input [31:0] t_data_writeReg;
    output [31:0] t_data_readRegA, t_data_readRegB;
	 output t_test_out;
	 output [31:0] t_test2_out, t_test4_out;
	 output [4:0] t_test3_out;
	 output o_ctrl_writeEnable;
	 output [4:0] o_ctrl_writeReg;
	 output [31:0] o_data_writeReg;
	 
	 // More wires
	 wire ctrl_writeEnable;
    wire [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    wire [31:0] data_writeReg;

    /** IMEM **/
    // Figure out how to generate a Quartus syncram component and commit the generated verilog file.
    // Make sure you configure it correctly!
    wire [11:0] address_imem;
    wire [31:0] q_imem;
    imem my_imem(
        .address    (address_imem),            // address of data
		  .clken		  (1'b1),
        .clock      (~clock),                  // you may need to invert the clock
        .q          (q_imem)                   // the raw instruction
    );

    /** DMEM **/
    // Figure out how to generate a Quartus syncram component and commit the generated verilog file.
    // Make sure you configure it correctly!
    wire [11:0] address_dmem;
    wire [31:0] data;
    wire wren;
    wire [31:0] q_dmem;
    dmem my_dmem(
        .address    (address_dmem),       // address of data
        .clock      (~clock),                  // may need to invert the clock
        .data	    (data),    // data you want to write
        .wren	    (wren),      // write enable
        .q          (q_dmem)    // data from dmem
    );

    /** REGFILE **/
    // Instantiate your regfile
    wire r_ctrl_writeEnable, r_reset;
    wire [4:0] r_ctrl_writeReg, r_ctrl_readRegA, r_ctrl_readRegB;
    wire [31:0] r_data_writeReg;
    wire [31:0] r_data_readRegA, r_data_readRegB;
	 
	 mux_2_1bit	mux0(ctrl_writeEnable, t_ctrl_writeEnable, test, r_ctrl_writeEnable);
	 mux_2_5bit mux1(ctrl_writeReg, t_ctrl_writeReg, test, r_ctrl_writeReg);
	 mux_2_5bit mux2(ctrl_readRegA, t_ctrl_readRegA, test, r_ctrl_readRegA);
	 mux_2_5bit mux3(ctrl_readRegB, t_ctrl_readRegB, test, r_ctrl_readRegB);
	 mux_2 		mux4(data_writeReg, t_data_writeReg, test, r_data_writeReg);
	 assign t_data_readRegA = r_data_readRegA;
	 assign t_data_readRegB = r_data_readRegB;
	 
    regfile my_regfile(
        ~clock,
        r_ctrl_writeEnable,
        r_reset,
        r_ctrl_writeReg,
        r_ctrl_readRegA,
        r_ctrl_readRegB,
        r_data_writeReg,
        r_data_readRegA,
        r_data_readRegB
    );
	 //assign t_test2_out = r_data_writeReg;

    /** PROCESSOR **/
    processor my_processor(
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
        r_data_readRegA,                  // I: Data from port A of regfile
        r_data_readRegB,                   // I: Data from port B of regfile
		  t_test_out,
		  t_test2_out,
		  t_test3_out,
		  t_test4_out
    );
	 
	 assign o_ctrl_writeEnable = ctrl_writeEnable;
	 assign o_ctrl_writeReg = ctrl_writeReg;
	 assign o_data_writeReg = data_writeReg;

endmodule
