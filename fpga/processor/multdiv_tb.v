// set the timescale
`timescale 1 ns / 100 ps

module multdiv_tb(); // testbenches take no arguments


reg reset, test, t_ctrl_writeEnable;
reg [4:0] t_ctrl_writeReg, t_ctrl_readRegA, t_ctrl_readRegB;
reg [31:0]t_data_writeReg;
wire [31:0] t_data_readRegA, t_data_readRegB;

reg clock;
reg proc_done;

integer num_correct;
integer curr_test_num;
integer clock_count;
integer clock_count_max;

skeleton_test spooky(clock, reset, test, t_ctrl_writeEnable, t_ctrl_writeReg, t_ctrl_readRegA, t_ctrl_readRegB,
							t_data_writeReg, t_data_readRegA, t_data_readRegB);

// begin simulation
initial begin
	num_correct = 0;
	curr_test_num = 1;
	clock_count = 0;
	clock_count_max = 200;
	proc_done = 0;
	
	reset = 0;
	test = 0;
	
	
	$display("Starting tests");
	clock = 1'b0;
end



always @(posedge proc_done) begin
		
	t_ctrl_writeEnable = 0;
	test = 1;
	
	check_register("mult no bypass", 3, 42);
	check_register("mult ya bypass", 6, 80);
	check_register("div no bypass", 9, 4);
	check_register("div ya bypass", 12, 7);
	
	
	
	if (num_correct == curr_test_num - 1)
		$display("All tests passed!");
	else
		$display("Passed %0d/%0d tests.", num_correct, curr_test_num - 1);
	
	$stop;
		
end



always begin
	#10 clock = ~clock; // toggle clock every 10 timescale units
	clock_count = clock_count + 1;
	if (clock_count == clock_count_max * 2)
		proc_done = 1;
end
	
	
	
task check_register;
	input [8*18:1] test_name;
	input [4:0] read_reg;
	input [31:0] value;
	
	begin
	
		t_ctrl_readRegA = read_reg;
		
		@(negedge clock);
		if (t_data_readRegA == value) begin
			$display("Test %2d: %s passed", curr_test_num, test_name);
			num_correct = num_correct + 1;
		end else begin
			$display("Test %2d: %s failed. Expected: %3d\tActual: %3d", curr_test_num, test_name, value, t_data_readRegA);
		end
		
		curr_test_num = curr_test_num + 1;
	end
endtask
	
	
	
endmodule

