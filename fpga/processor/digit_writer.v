// Able to write digits 0-9 A-H

module digit_writer(digit_index, seven_seg_display);

input	[4:0]	digit_index;
output [6:0] seven_seg_display;

assign seven_seg_display =
		({7{(digit_index == 5'd0)}} & 7'b1000000) |	// 0
		({7{(digit_index == 5'd1)}} & 7'b1111001) |	// 1
		({7{(digit_index == 5'd2)}} & 7'b0100100) |	// 2
		({7{(digit_index == 5'd3)}} & 7'b0110000) |	// 3
		({7{(digit_index == 5'd4)}} & 7'b0011001) |	// 4
		({7{(digit_index == 5'd5)}} & 7'b0010010) |	// 5
		({7{(digit_index == 5'd6)}} & 7'b0000010) |	// 6
		({7{(digit_index == 5'd7)}} & 7'b1111000) |	// 7
		({7{(digit_index == 5'd8)}} & 7'b0000000) |	// 8
		({7{(digit_index == 5'd9)}} & 7'b0011000) |	// 9
		({7{(digit_index == 5'd10)}} & 7'b0001000) |	// A
		({7{(digit_index == 5'd11)}} & 7'b0000011) |	// B
		({7{(digit_index == 5'd12)}} & 7'b1000110) |	// C
		({7{(digit_index == 5'd13)}} & 7'b0100001) |	// D
		({7{(digit_index == 5'd14)}} & 7'b0000110) |	// E
		({7{(digit_index == 5'd15)}} & 7'b0001110) |	// F
		({7{(digit_index == 5'd16)}} & 7'b1000010) |	// G
		({7{(digit_index == 5'd17)}} & 7'b0001001);	// H


endmodule
