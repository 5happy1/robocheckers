# "Global" registers:
# $s0 - which player's turn it is (1 or 2)
# $s1 - board start location in memory
# $s2 - stack word size (4 for MARS, 1 for our processor)
# $s3 - previously seen op code ready flag
#
# Read-only registers:
# $27 - op code from Arduino via behavioral Verilog on FPGA, with ready flag
# $26 - data accompanying the op code

main:						# Main function
	addi $s2, $zero, 4		# Stack word size (4 for MARS, 1 for our processor)
	addi $s3, $zero, 0		# Previously seen op code ready flag starts at 0
	
	# Make space on stack for board state
	addi $s1, $sp, 0		# Save board start location to $s1
	addi $sp, $sp, -128		# Reserve 32 words on stack for board
	
	jal reset_game			# Reset game
	j game_loop				# Jump to game loop after setting up

reset_game:					# Function to reset the game
	# Create stack
	sub $sp, $sp, $s2		# Reserve 1 word on stack
	sw $ra, 0($sp)			# [$sp+0] = $ra (save return address)

	jal	init_board
	addi $s0, $0, 2			# Put player 2 in player register
	
	# Collapse stack
	lw $ra, 0($sp)			# $ra = [$sp+0]
	add $sp, $sp, $s2		# Move stack pointer back to original location
	
	jr $ra					# Return
	
init_board:					# Function to initialize overall board in dmem
	
	##### Board storage #####
	#
	# Board is stored as 32 integers in dmem, beginning at the position in $s1
	#
	# Position order from $s1 up:
	# A1, C1, E1, G1, B2, D2, F2, H2, A3, C3, E3, G3, B4, D4, F4, H4,
	# A5, C5, E5, G5, B6, D6, F6, H6, A7, C7, E7, G7, B8, D8, F8, H8
	#
	# Piece types:
	#
	# 0 = blank
	# 1 = player 1
	# 2 = player 2
	# 3 = player 1 king
	# 4 = player 2 king
	# 
	#########################
	
	# Create stack
	sub $sp, $sp, $s2		# Reserve 1 word on stack
	sw $ra, 0($sp)			# [$sp+0] = $ra (save return address)
	
	# Create board
	addi $t0, $s1, 0		# Board position in stack
	
	# Player 1 checkers
	addi $t1, $zero, 1		# Checker type = player 1
	addi $t2, $zero, 0		# Counter = 0
	addi $t3, $zero, 12		# Number of checkers = 12
	jal init_loop			# Loop to place checkers
	
	# Blank positions in middle
	addi $t1, $zero, 0		# Checker type = blank
	addi $t2, $zero, 0		# Counter = 0
	addi $t3, $zero, 8		# Number of checkers = 8
	jal init_loop			# Loop to place checkers
	
	# Player 2 checkers
	addi $t1, $zero, 2		# Checker type = player 2
	addi $t2, $zero, 0		# Counter = 0
	addi $t3, $zero, 12		# Number of checkers = 12
	jal init_loop			# Loop to place checkers
	
	j finish_init			# Board initialized, jump to end of function
	
	# Loop used to place checkers
	init_loop:				# Loop through placement of checkers
	sw $t1, 0($t0)			# [$t0+0] = $t1 (save checker in dmem board)
	sub $t0, $t0, $s2		# Increment board pos (-1 because stack goes backwards)
	addi $t2, $t2, 1		# Increment counter
	blt $t2, $t3, init_loop	# Keep looping while counter < num checkers
	jr $ra					# Go back for next checker type
	
	finish_init:
	# Collapse stack
	lw $ra, 0($sp)			# $ra = [$sp+0]
	add $sp, $sp, $s2		# Move stack pointer back to original location
	
	jr $ra					# Return
	
game_loop:
	#####
	# Game loop - wait for op code from behavioral Verilog via Arduino
	# $27 - will contain opcode in bits [4:1], bit 0 will contain flag
	#       that a new opcode is available (1) or not (0)
	# $26 - will contain data associated with opcode
	#
	##### Available op codes #####
	# 0000 - piece moved (not jumped)
	#        data contains space_from [9:5], space_to [4:0]
	
	#jal print_board
	
	addi $t0, $zero, 1		# $t0 = 1 for anding
	and $t0, $27, $t0		# $t0 = 1 iff least significant bit in $27 is 1
							# $t0 = 0 otherwise.
							# This is the new op code ready flag

	bne $s3, $t0, new_data	# Branch if flag set for new op code
	j game_loop				# Loop again if no new data found
	
	new_data:				# New op code flagged, check op code
	addi $s3, $t0, 0		# Set $s3 to new op code ready flag
	sra $t0, $27, 1			# $t0 = 4-bit op code
	bne $t0, $zero, not_move# Branch if op code != 0, i.e. not a move
	
	# Op code == 0000, so checker was moved
	addi $a0, $26, 0		# Move data that accompanies op code into $a0
	jal move_made			# Update board state to reflect new move
	jal find_move			# Find a move to make
	
	not_move:				# Not "move made" op code
	
	
	j game_loop

print_board:
	##### REMOVE/COMMENT WHEN NOT USING MARS (i.e. actually using FPGA) #####
	addi $t0, $s1, 0		# Board position in stack
	addi $t2, $zero, 0		# Counter = 0
	addi $t3, $zero, 32		# Board length = 32
	addi $v0, $zero, 1		# Put 1 in $v0 - means syscall is print integer from $a0
	test_init:
	lw $a0, 0($t0)			# $a0 = [$t0+0] (load checker from dmem board)
	syscall					# Print integer in $a0 (since $v0 == 1)
	sub $t0, $t0, $s2		# Increment board pos (-1 because stack goes backwards)
	addi $t2, $t2, 1		# Increment counter
	blt $t2, $t3, test_init	# Keep looping while counter < num checkers
	jr $ra

move_made:
	# Updates board with move made as given by FPGA
	# args: $a0 - data that contains space_from [9:5], space_to [4:0]
	
	# Create stack
	sub $sp, $sp, $s2		# Reserve 1 word on stack
	sw $ra, 0($sp)			# [$sp+0] = $ra (save return address)
	
	# Get locations of pieces in memory
	addi $t2, $zero, 31		# $t2 = 31 = 1111, and with data to get space
	and $t1, $a0, $t2		# $t1 = space_to
	sra $a0, $a0, 5			# Shift data right to get space_from
	and $t0, $a0, $t2		# $t0 = space_from
	
	add $t2, $s1, $t0		# $t2 = location of space_from in memory
	add $t3, $s1, $t1		# $t3 = location of space_to in memory
	
	# Perform swap
	lw $t4, 0($t2)			# $t4 = checker at space_from
	lw $t5, 0($t3)			# $t5 = checker at space_to
	sw $t4, 0($t3)			# [$t3] = checker formerly at space_to now at space_from
	sw $t5, 0($t2)			# [$t2] = checker formerly at space_from now at space_to	
	
	# Collapse stack
	lw $ra, 0($sp)			# $ra = [$sp+0]
	add $sp, $sp, $s2		# Move stack pointer back to original location
	
	jr $ra					# Return

find_move:
	# Searches for the best move to make (this is the AI!)
	# return: $v0 - 5 bits, space_from in [0, 31]
	#		  $v1 - 5 bits, space_to in [0, 31]
	
	# Create stack
	sub $sp, $sp, $s2		# Reserve 1 word on stack
	sw $ra, 0($sp)			# [$sp+0] = $ra (save return address)
	
	# TODO: Implement the AI, Machine Learning, Blockchain, Quantum Computing, etc.
	
	# Collapse stack
	lw $ra, 0($sp)			# $ra = [$sp+0]
	add $sp, $sp, $s2		# Move stack pointer back to original location
	
	jr $ra					# Return

check_win:
	# Checks the win condition of the board
	# args: $a0 - board position in stack
	# return: $v0 - 0 for no win, 1 for player 1, 2 for player 2
	
	# Create stack
	sub $sp, $sp, $s2		# Reserve 1 word on stack
	sw $ra, 0($sp)			# [$sp+0] = $ra (save return address)
	
	# Create temp vars
	addi $t0, $a0, 0		# Board position in stack
	addi $t2, $zero, 0		# Counter = 0
	addi $t3, $zero, 32		# Board length = 32
	addi $t4, $zero, 0		# Player 1 checker counter = 0
	addi $t5, $zero, 0		# Player 2 checker counter = 0
	
	# Loop through board
	b_loop:

	lw $t1, 0($t0)			# $t1 = [$t0+0] (load checker from dmem board)
	sub $t0, $t0, $s2		# Increment board pos (-1 because stack goes backwards)
	addi $t2, $t2, 1		# Increment counter
	
	bne $t1, $zero, not_0	# Branch if checker is not 0, continue if it is
	j continue
	
	not_0:
	addi $t6, $zero, 1		# Temporary variable for comparison
	bne $t1, $t6, not_1		# Branch if checker is not 1, continue if it is
	addi $t4, $t4, 1		# Increment player 1 counter
	j continue
	
	not_1:
	addi $t6, $zero, 2		# Temporary variable for comparison
	bne $t1, $t6, not_2		# Branch if checker is not 2, continue if it is
	addi $t5, $t5, 1		# Increment player 2 counter
	j continue
	
	not_2:
	addi $t6, $zero, 3		# Temporary variable for comparison
	bne $t1, $t6, not_3		# Branch if checker is not 3, continue if it is
	addi $t4, $t4, 1		# Increment player 1 counter
	j continue
	
	not_3:					# Checker must be 4 by process of elimination
	addi $t5, $t5, 1		# Increment player 2 counter
	
	continue:
	blt $t2, $t3, b_loop	# Keep looping while counter < num checkers
	
	# Check counters and decide win
	bne $t4, $zero, p1_in	# Branch if player 1 has checkers
	addi $v0, $zero, 2		# Player 1 is out of checkers, player 2 wins!
	j return_check_win
	
	p1_in:
	bne $t5, $zero, p2_in	# Branch if player 2 has checkers
	addi $v0, $zero, 1		# Player 2 is out of checkers, player 1 wins!
	j return_check_win
	
	p2_in:
	addi $v0, $zero, 0		# Neither player has won yet
	
	return_check_win:
	# Collapse stack
	lw $ra, 0($sp)			# $ra = [$sp+0]
	add $sp, $sp, $s2		# Move stack pointer back to original location
	
	jr $ra					# Return

exit:						# Exit program by going to bottom
