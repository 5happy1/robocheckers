# "Global" registers:
# $s0 - which player's turn it is (1 or 2)
# $s1 - board start location in memory
# $s2 - stack word size (4 for MARS, 1 for our processor)
# $s3 - previously seen op code ready flag
#
# Read-only registers:
# $27 - op code from Arduino via behavioral Verilog on FPGA, with ready flag
# $26 - data accompanying the op code
#
# Registers for sending commands/data:
# $28 - op code to Arduino, with ready flag, and also with 7-segment display values
# $1  - data accompanying the op code

main:						# Main function
	addi $s2, $zero, 1		# Stack word size (4 for MARS, 1 for our processor)
	addi $s3, $zero, 0		# Previously seen op code ready flag starts at 0
	
	# Make space on stack for board state
	addi $s1, $sp, 0		# Save board start location to $s1
	addi $sp, $sp, -32		# Reserve 32 words on stack for board
	
	jal reset_game			# Reset game
	j game_loop				# Jump to game loop after setting up

reset_game:					# Function to reset the game
	# Create stack
	sub $sp, $sp, $s2		# Reserve 1 word on stack
	sw $ra, 0($sp)			# [$sp+0] = $ra (save return address)

	jal	init_board
	addi $s0, $0, 1			# Put player 1 in player register
	
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
	#       that a new opcode is available (toggled on every new opcode)
	# $26 - will contain data associated with opcode
	#
	##### Available op codes #####
	# 0000 - piece moved
	#        data contains space_jumped [14:10], space_from [9:5], space_to [4:0]
	#		 (space_jumped is 0 if no jump occurred (can't jump position A1))
	
	# START DEBUGGING
	# jal print_board
	# addi $27, $zero, 1		# $27 = op code for move and ready flag switch
	# addi $26, $zero, 300	# $26: space_from = 9, space_to = 12
	# j exit
	# END DEBUGGING
	
	# New op code ready flag
	addi $t0, $zero, 1		# $t0 = 1 for anding
	and $t0, $27, $t0		# $t0 = 1 iff least significant bit in $27 is 1
							# $t0 = 0 otherwise

	bne $s3, $t0, new_data	# Branch if flag set for new op code
	j game_loop				# Loop again if no new data found
	
	new_data:				# New op code flagged
	addi $t1, $26, 0		# $t1 = $26 - data that accompanies op code
	addi $s3, $t0, 0		# Set $s3 to previously seen op code ready flag
	sra $t0, $27, 1			# $t0 = 4-bit op code
	bne $t0, $zero, not_move# Branch if op code != 0, i.e. not a move
	
	# Op code == 0000, so checker was moved
	addi $a0, $s1, 0		# $a0 = board position in memory
	addi $t2, $zero, 31		# $t2 = 31 = 1111, "and" with data to get space
	
	and $a2, $t1, $t2		# $a2 = space_to
	sra $t1, $t1, 5			# Shift data right to get space_from
	and $a1, $t1, $t2		# $a1 = space_from
	sra $t1, $t1, 5			# Shift data right to get space_jumped
	and $a3, $t1, $t2		# $a3 = space_jumped

	# START DEBUGGING - display move made on 7sd displays
	# addi $a0, $a1, 0		# $a0 = space_from
	# addi $a1, $a2, 0		# $a1 = space_to
	# jal move_to_7sd
	# addi $28, $v0, 0
	# j game_loop
	# END DEBUGGING
	
	jal make_move			# Update board state to reflect new move

	# START DEBUGGING - display values of spaces 0-3 in memory on 7sd displays
	addi $t0, $s1, 0		# $t0 = board position in memory
	lw $t1, 0($t0)			# $t1 = checker in space 0
	addi $28, $t1, 0
	sll $28, $28, 5
	
	addi $t0, $t0, 1
	lw $t1, 0($t0)
	addi $28, $t1, 0
	sll $28, $28, 5

	addi $t0, $t0, 1
	lw $t1, 0($t0)
	addi $28, $t1, 0
	sll $28, $28, 5

	addi $t0, $t0, 1
	lw $t1, 0($t0)
	addi $28, $t1, 0
	sll $28, $28, 5

	j game_loop
	# END DEBUGGING
	
	# Check win
	addi $a0, $s1, 0		# $a0 = board position in memory
	jal check_win			# Check if one of the players has won
	bne $v0, $zero, win		# If check_win result is not 0, someone won!

	# Change current player
	addi $t0, $zero, 1		# $t0 = 1 for checking player
	bne $s0, $t0, to_p1		# If $s0 != 1, branch becaues current player is 2
	addi $s0, $zero, 2		# Change to player 2
	j done_changing_player
	to_p1:
	addi $s0, $zero, 1		# Change to player 1
	done_changing_player:	# After player changed

	# jal find_move			# Find a move to make

	# Convert and put move into $28 for seven-segment diplays
	addi $a0, $v0, 0		# Put space_from in $a0
	addi $a1, $v1, 0		# Put space_to in $a1
	jal move_to_7sd			# Convert move into seven-segment display
	addi $28, $v0, 0		# Put final value into $28 for display


	not_move:				# Not "move made" op code
	
	# START DEBUGGING
	# jal print_board
	# j exit
	# END DEBUGGING
	
	j game_loop
	
	win:					# Someone won! The winner is in $v0

	# Display winner on seven-segment display
	addi $28, $v0, 0
	sll $28, $28, 5

#print_board:
	##### REMOVE/COMMENT WHEN NOT USING MARS (i.e. actually using FPGA) #####
#	addi $t0, $s1, 0		# Board position in stack
#	addi $t2, $zero, 0		# Counter = 0
#	addi $t3, $zero, 32		# Board length = 32
#	addi $v0, $zero, 1		# Put 1 in $v0 - means syscall is print integer from $a0
#	test_init:
#	lw $a0, 0($t0)			# $a0 = [$t0+0] (load checker from dmem board)
#	syscall					# Print integer in $a0 (since $v0 == 1)
#	sub $t0, $t0, $s2		# Increment board pos (-1 because stack goes backwards)
#	addi $t2, $t2, 1		# Increment counter
#	blt $t2, $t3, test_init	# Keep looping while counter < num checkers
#	jr $ra

make_move:
	# Updates a board with a move made
	# args: $a0 - board position in memory
	#		$a1 - space_from
	#		$a2 - space_to
	#		$a3 - space_jumped
	
	# Create stack
	sub $sp, $sp, $s2		# Reserve 1 word on stack
	sw $ra, 0($sp)			# [$sp+0] = $ra (save return address)
	
	# Get locations of pieces in memory
	add $t1, $a0, $a1		# $t1 = location of space_from in memory
	add $t2, $a0, $a2		# $t2 = location of space_to in memory
	add $t3, $a0, $a3		# $t3 = location of space_jumped in memory
	
	# Perform swap
	lw $t4, 0($t1)			# $t4 = checker at space_from
	lw $t5, 0($t2)			# $t5 = checker at space_to
	sw $t4, 0($t2)			# [$t2] = checker formerly at space_to now at space_from
	sw $t5, 0($t1)			# [$t1] = checker formerly at space_from now at space_to
	
	# Remove jumped piece if needed
	bne $t3, $zero, jumped	# Branch if jumped
	j after_jump			# Skip jumping code if no jump

	jumped:
	add $t6, $a0, $t3		# $t6 = location of space_jumped in memory
	sw $zero, 0($t7)		# [$t6] = 0 (blank space) in memory
	
	after_jump:
	# Check for kings
	addi $a0, $s1, 0		# $a0 = $s1, arg0 has start location of main board
	addi $a1, $a2, 0		# $a1 = $a2, arg1 has space_to
	jal king_me				# Check for kings
	
	# Collapse stack
	lw $ra, 0($sp)			# $ra = [$sp+0]
	add $sp, $sp, $s2		# Move stack pointer back to original location
	
	jr $ra					# Return

king_me:
	# Checks if a given checker should be kinged, and if so, kings it
	# args: $a0 - start location of board in memory
	#		$a1 - space in [0, 31]
	
	# Create stack
	sub $sp, $sp, $s2		# Reserve 1 word on stack
	sw $ra, 0($sp)			# [$sp+0] = $ra (save return address)
	
	add $t0, $a0, $a1		# $t0 = location of space in memory
	lw $t1, 0($t0)			# $t1 = checker at space in memory
	
	# If checker == 1...
	addi $t2, $zero, 1		# $t2 = 1 for comparison
	bne $t1, $t2, k_not_1	# Branch if checker != 1
	
	# If checker is in top row...
	addi $t2, $zero, 28		# $t2 = 28 for comparison
	blt $a1, $t2, ret_king	# Branch if checker not in kingable position
							# because checker == 1 and pos < 28 (not in top row)
							
	# Make checker 1 a king!
	addi $t3, $zero, 3		# $t3 = 3 (king value for player 1)
	sw $t3, 0($t0)			# Store new king in memory
	j ret_king				# Return because done
	
	# If checker == 2...
	k_not_1:
	addi $t2, $zero, 2		# $t2 = 2 for comparison
	bne $t1, $t2, ret_king	# Branch if checker != 2
	
	# If checker is in bottom row...
	addi $t2, $zero, 3		# $t2 = 3 for comparison
	blt $t2, $a1, ret_king	# Branch if checker not in kingable position
							# because checker == 2 and pos > 3 (not in bottom row)
							
	# Make checker 2 a king!
	addi $t3, $zero, 3		# $t3 = 4 (king value for player 2)
	sw $t3, 0($t0)			# Store new king in memory
	j ret_king				# Return because done
	
	ret_king:
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

move_to_7sd:
	# Turn a move into a seven-segment display (7sd) output
	# Convert space_from and space_to into row and column and return formatted
	# args: $a0 - space_from in [0, 31]
	#		$a1 - space_to in [0, 31]
	# return: $v0 - finalized register for seven-segment display output
	
	# Create stack
	sub $sp, $sp, $s2		# Reserve 1 word on stack
	sw $ra, 0($sp)			# [$sp+0] = $ra (save return address)

	# space_from
	jal space_to_7sd		# space_from already in $a0
	sub $sp, $sp, $s2		# Reserve 1 word on stack
	sw $v0, 0($sp)			# [$sp+0] = $v0 (save space_from)

	# space_to
	addi $a0, $a1, 0		# $a0 = $a1
	jal space_to_7sd
	addi $t0, $v0, 0		# $t0 = $v0
	lw $v0, 0($sp)			# $v0 = [$sp+0] (space_from from memory)
	add $sp, $sp, $s2		# Move stack pointer back to original location
	sll $v0, $v0, 10		# Shift $v0 left 10 bits to prepare for space_to
	add $v0, $v0, $t0		# $v0 += $t0 (now $v0 has all moves)

	sll $v0, $v0, 5			# Shift $v0 left 5 bits to account for opcode+flag

	# Collapse stack
	lw $ra, 0($sp)			# $ra = [$sp+0]
	add $sp, $sp, $s2		# Move stack pointer back to original location
	
	jr $ra

space_to_7sd:
	# Turn a space into a seven-segment display (7sd) output
	# args: $a0 - space in [0, 31]
	# return: $v0 - space for seven-segment display output

	# Create stack
	sub $sp, $sp, $s2		# Reserve 1 word on stack
	sw $ra, 0($sp)			# [$sp+0] = $ra (save return address)

	# In Python 3, given that i is the space number,
	# here is how to obtain row and column:
	# r = i // 4 + 1  # Row numbering based on checker board, 1-indexed
    # c = (i % 4) * 2 + 2 - r % 2  # Columns are 1-indexed also

	# Row
	sra $t0, $a0, 2			# $t0 = floor($a0 / 4)
	addi $t0, $t0, 1		# $t0 += 1 (now $t0 == row of space_from)

	# Column
	addi $t4, $zero, 3		# $t4 = 3 for anding
	and $t1, $a0, $t4		# $t1 = $a0 & $t4 = $a0 % 4
	add $t1, $t1, $t1		# $t1 = $t1 + $t1 = $t1 * 2
	addi $t1, $t1, 2		# $t1 += 2
	addi $t4, $zero, 1		# $t4 = 1 for anding
	and $t4, $t0, $t4		# $t4 = $t0 & $t4 = $t0 % 2
	sub $t1, $t1, $t4		# $t1 -= $t4 (now $t1 == column of space_from)
	addi $t1, $t1, 9		# $t1 += 9 (adding to column to get letters on 7sd)

	# Put into $v0
	addi $v0, $t0, 0		# $v0 = $t0 (row)
	sll $v0, $v0, 5			# Shift $v0 left 5 bits to prepare for column
	add $v0, $v0, $t1		# $v0 += $t1 (column)

	# Collapse stack
	lw $ra, 0($sp)			# $ra = [$sp+0]
	add $sp, $sp, $s2		# Move stack pointer back to original location
	
	jr $ra

find_move:
	# Searches for the best move to make (this is the AI!)
	# As of now, just generate all moves for player 2 and choose a good one
	# without looking ahead (only counting single jumps)
	# return: $v0 - 5 bits, space_from in [0, 31]
	#		  $v1 - 5 bits, space_to in [0, 31]
	
	# Create stack
	sub $sp, $sp, $s2		# Reserve 1 word on stack
	sw $ra, 0($sp)			# [$sp+0] = $ra (save return address)
	
	# Implement the AI, Machine Learning, Blockchain, Quantum Computing, etc.

	# For this procedure, call $t9 the "score" of the best move
	# 100 is best for player 1
	# -100 is best for player 2
	# 0 is neutral
	#
	# As of now, scoring is as follows (make negative for player 2):
	# 1 - normal move
	# 2 - jump
	# 3 - move to side
	# 4 - jump to side
	# 5 - king
	# 6 - jump to king
	addi $t9, $zero, 0		# $t9 = 0 initializes best move score to 0

	# Check whose turn it is
	addi $t0, $zero, 1		# $t0 = 1 for checking player
	bne $s0, $t0, find2		# If $s0 != 1, branch becaues current player is 2
	
	### Find moves for player 1
	addi $v0, $zero, 0
	addi $v1, $zero, 0
	j return_find_move

	### Find moves for player 2
	find2:

	# Note to self: generally
	# $t0 is super temporary, for quick loading and comparison
	# $t1 has piece from space
	# $t2 has piece from move offset
	# $t3 has piece from jump offset


	##### BEGIN GENERATED CODE #####
	
	# Space 0
	p2s0:
	addi $t0, $s1, 0
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s0n2
	j p2s0_2or4
	p2s0n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s1
	p2s0_2or4:  # Space 0 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s0ur_end
	p2s0ur:
	addi $t0, $s1, 4
	lw $t2, 0($t0)
	bne $t2, $zero, p2s0urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s0ur_end
	addi $v0, $zero, 0
	addi $v1, $zero, 4
	add $t9, $zero, $t0
	j p2s0ur_end  # Skip check jump piece since space is empty for move
	p2s0urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s0ur_n1
	j p2s0s4_1or3
	p2s0ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s0ur_end
	p2s0s4_1or3:
	addi $t0, $zero, 9
	lw $t3, 0($t0)
	bne $t3, $zero, p2s0ur_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s0ur_end
	addi $v0, $zero, 0
	addi $v1, $zero, 9
	add $t9, $zero, $t0
	p2s0ur_end:  # End label for moving to next

	# Space 1
	p2s1:
	addi $t0, $s1, 1
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s1n2
	j p2s1_2or4
	p2s1n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s2
	p2s1_2or4:  # Space 1 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s1ul_end
	p2s1ul:
	addi $t0, $s1, 4
	lw $t2, 0($t0)
	bne $t2, $zero, p2s1ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s1ul_end
	addi $v0, $zero, 1
	addi $v1, $zero, 4
	add $t9, $zero, $t0
	j p2s1ul_end  # Skip check jump piece since space is empty for move
	p2s1ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s1ul_n1
	j p2s1s4_1or3
	p2s1ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s1ul_end
	p2s1s4_1or3:
	addi $t0, $zero, 8
	lw $t3, 0($t0)
	bne $t3, $zero, p2s1ul_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s1ul_end
	addi $v0, $zero, 1
	addi $v1, $zero, 8
	add $t9, $zero, $t0
	p2s1ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s1ur_end
	p2s1ur:
	addi $t0, $s1, 5
	lw $t2, 0($t0)
	bne $t2, $zero, p2s1urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s1ur_end
	addi $v0, $zero, 1
	addi $v1, $zero, 5
	add $t9, $zero, $t0
	j p2s1ur_end  # Skip check jump piece since space is empty for move
	p2s1urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s1ur_n1
	j p2s1s5_1or3
	p2s1ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s1ur_end
	p2s1s5_1or3:
	addi $t0, $zero, 10
	lw $t3, 0($t0)
	bne $t3, $zero, p2s1ur_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s1ur_end
	addi $v0, $zero, 1
	addi $v1, $zero, 10
	add $t9, $zero, $t0
	p2s1ur_end:  # End label for moving to next

	# Space 2
	p2s2:
	addi $t0, $s1, 2
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s2n2
	j p2s2_2or4
	p2s2n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s3
	p2s2_2or4:  # Space 2 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s2ul_end
	p2s2ul:
	addi $t0, $s1, 5
	lw $t2, 0($t0)
	bne $t2, $zero, p2s2ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s2ul_end
	addi $v0, $zero, 2
	addi $v1, $zero, 5
	add $t9, $zero, $t0
	j p2s2ul_end  # Skip check jump piece since space is empty for move
	p2s2ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s2ul_n1
	j p2s2s5_1or3
	p2s2ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s2ul_end
	p2s2s5_1or3:
	addi $t0, $zero, 9
	lw $t3, 0($t0)
	bne $t3, $zero, p2s2ul_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s2ul_end
	addi $v0, $zero, 2
	addi $v1, $zero, 9
	add $t9, $zero, $t0
	p2s2ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s2ur_end
	p2s2ur:
	addi $t0, $s1, 6
	lw $t2, 0($t0)
	bne $t2, $zero, p2s2urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s2ur_end
	addi $v0, $zero, 2
	addi $v1, $zero, 6
	add $t9, $zero, $t0
	j p2s2ur_end  # Skip check jump piece since space is empty for move
	p2s2urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s2ur_n1
	j p2s2s6_1or3
	p2s2ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s2ur_end
	p2s2s6_1or3:
	addi $t0, $zero, 11
	lw $t3, 0($t0)
	bne $t3, $zero, p2s2ur_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s2ur_end
	addi $v0, $zero, 2
	addi $v1, $zero, 11
	add $t9, $zero, $t0
	p2s2ur_end:  # End label for moving to next

	# Space 3
	p2s3:
	addi $t0, $s1, 3
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s3n2
	j p2s3_2or4
	p2s3n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s4
	p2s3_2or4:  # Space 3 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s3ul_end
	p2s3ul:
	addi $t0, $s1, 6
	lw $t2, 0($t0)
	bne $t2, $zero, p2s3ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s3ul_end
	addi $v0, $zero, 3
	addi $v1, $zero, 6
	add $t9, $zero, $t0
	j p2s3ul_end  # Skip check jump piece since space is empty for move
	p2s3ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s3ul_n1
	j p2s3s6_1or3
	p2s3ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s3ul_end
	p2s3s6_1or3:
	addi $t0, $zero, 10
	lw $t3, 0($t0)
	bne $t3, $zero, p2s3ul_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s3ul_end
	addi $v0, $zero, 3
	addi $v1, $zero, 10
	add $t9, $zero, $t0
	p2s3ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s3ur_end
	p2s3ur:
	addi $t0, $s1, 7
	lw $t2, 0($t0)
	bne $t2, $zero, p2s3urj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s3ur_end
	addi $v0, $zero, 3
	addi $v1, $zero, 7
	add $t9, $zero, $t0
	j p2s3ur_end  # Skip check jump piece since space is empty for move
	p2s3urj:
	p2s3ur_end:  # End label for moving to next

	# Space 4
	p2s4:
	addi $t0, $s1, 4
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s4n2
	j p2s4_2or4
	p2s4n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s5
	p2s4_2or4:  # Space 4 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s4ul_end
	p2s4ul:
	addi $t0, $s1, 8
	lw $t2, 0($t0)
	bne $t2, $zero, p2s4ulj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s4ul_end
	addi $v0, $zero, 4
	addi $v1, $zero, 8
	add $t9, $zero, $t0
	j p2s4ul_end  # Skip check jump piece since space is empty for move
	p2s4ulj:
	p2s4ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s4ur_end
	p2s4ur:
	addi $t0, $s1, 9
	lw $t2, 0($t0)
	bne $t2, $zero, p2s4urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s4ur_end
	addi $v0, $zero, 4
	addi $v1, $zero, 9
	add $t9, $zero, $t0
	j p2s4ur_end  # Skip check jump piece since space is empty for move
	p2s4urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s4ur_n1
	j p2s4s9_1or3
	p2s4ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s4ur_end
	p2s4s9_1or3:
	addi $t0, $zero, 13
	lw $t3, 0($t0)
	bne $t3, $zero, p2s4ur_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s4ur_end
	addi $v0, $zero, 4
	addi $v1, $zero, 13
	add $t9, $zero, $t0
	p2s4ur_end:  # End label for moving to next
	p2s4dl:
	addi $t0, $s1, 0
	lw $t2, 0($t0)
	bne $t2, $zero, p2s4dlj
	addi $t0, $zero, -5
	blt $t9, $t0, p2s4dl_end
	addi $v0, $zero, 4
	addi $v1, $zero, 0
	add $t9, $zero, $t0
	j p2s4dl_end  # Skip check jump piece since space is empty for move
	p2s4dlj:
	p2s4dl_end:  # End label for moving to next
	p2s4dr:
	addi $t0, $s1, 1
	lw $t2, 0($t0)
	bne $t2, $zero, p2s4drj
	addi $t0, $zero, -5
	blt $t9, $t0, p2s4dr_end
	addi $v0, $zero, 4
	addi $v1, $zero, 1
	add $t9, $zero, $t0
	j p2s4dr_end  # Skip check jump piece since space is empty for move
	p2s4drj:
	p2s4dr_end:  # End label for moving to next

	# Space 5
	p2s5:
	addi $t0, $s1, 5
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s5n2
	j p2s5_2or4
	p2s5n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s6
	p2s5_2or4:  # Space 5 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s5ul_end
	p2s5ul:
	addi $t0, $s1, 9
	lw $t2, 0($t0)
	bne $t2, $zero, p2s5ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s5ul_end
	addi $v0, $zero, 5
	addi $v1, $zero, 9
	add $t9, $zero, $t0
	j p2s5ul_end  # Skip check jump piece since space is empty for move
	p2s5ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s5ul_n1
	j p2s5s9_1or3
	p2s5ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s5ul_end
	p2s5s9_1or3:
	addi $t0, $zero, 12
	lw $t3, 0($t0)
	bne $t3, $zero, p2s5ul_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s5ul_end
	addi $v0, $zero, 5
	addi $v1, $zero, 12
	add $t9, $zero, $t0
	p2s5ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s5ur_end
	p2s5ur:
	addi $t0, $s1, 10
	lw $t2, 0($t0)
	bne $t2, $zero, p2s5urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s5ur_end
	addi $v0, $zero, 5
	addi $v1, $zero, 10
	add $t9, $zero, $t0
	j p2s5ur_end  # Skip check jump piece since space is empty for move
	p2s5urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s5ur_n1
	j p2s5s10_1or3
	p2s5ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s5ur_end
	p2s5s10_1or3:
	addi $t0, $zero, 14
	lw $t3, 0($t0)
	bne $t3, $zero, p2s5ur_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s5ur_end
	addi $v0, $zero, 5
	addi $v1, $zero, 14
	add $t9, $zero, $t0
	p2s5ur_end:  # End label for moving to next
	p2s5dl:
	addi $t0, $s1, 1
	lw $t2, 0($t0)
	bne $t2, $zero, p2s5dlj
	addi $t0, $zero, -5
	blt $t9, $t0, p2s5dl_end
	addi $v0, $zero, 5
	addi $v1, $zero, 1
	add $t9, $zero, $t0
	j p2s5dl_end  # Skip check jump piece since space is empty for move
	p2s5dlj:
	p2s5dl_end:  # End label for moving to next
	p2s5dr:
	addi $t0, $s1, 2
	lw $t2, 0($t0)
	bne $t2, $zero, p2s5drj
	addi $t0, $zero, -5
	blt $t9, $t0, p2s5dr_end
	addi $v0, $zero, 5
	addi $v1, $zero, 2
	add $t9, $zero, $t0
	j p2s5dr_end  # Skip check jump piece since space is empty for move
	p2s5drj:
	p2s5dr_end:  # End label for moving to next

	# Space 6
	p2s6:
	addi $t0, $s1, 6
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s6n2
	j p2s6_2or4
	p2s6n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s7
	p2s6_2or4:  # Space 6 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s6ul_end
	p2s6ul:
	addi $t0, $s1, 10
	lw $t2, 0($t0)
	bne $t2, $zero, p2s6ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s6ul_end
	addi $v0, $zero, 6
	addi $v1, $zero, 10
	add $t9, $zero, $t0
	j p2s6ul_end  # Skip check jump piece since space is empty for move
	p2s6ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s6ul_n1
	j p2s6s10_1or3
	p2s6ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s6ul_end
	p2s6s10_1or3:
	addi $t0, $zero, 13
	lw $t3, 0($t0)
	bne $t3, $zero, p2s6ul_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s6ul_end
	addi $v0, $zero, 6
	addi $v1, $zero, 13
	add $t9, $zero, $t0
	p2s6ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s6ur_end
	p2s6ur:
	addi $t0, $s1, 11
	lw $t2, 0($t0)
	bne $t2, $zero, p2s6urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s6ur_end
	addi $v0, $zero, 6
	addi $v1, $zero, 11
	add $t9, $zero, $t0
	j p2s6ur_end  # Skip check jump piece since space is empty for move
	p2s6urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s6ur_n1
	j p2s6s11_1or3
	p2s6ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s6ur_end
	p2s6s11_1or3:
	addi $t0, $zero, 15
	lw $t3, 0($t0)
	bne $t3, $zero, p2s6ur_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s6ur_end
	addi $v0, $zero, 6
	addi $v1, $zero, 15
	add $t9, $zero, $t0
	p2s6ur_end:  # End label for moving to next
	p2s6dl:
	addi $t0, $s1, 2
	lw $t2, 0($t0)
	bne $t2, $zero, p2s6dlj
	addi $t0, $zero, -5
	blt $t9, $t0, p2s6dl_end
	addi $v0, $zero, 6
	addi $v1, $zero, 2
	add $t9, $zero, $t0
	j p2s6dl_end  # Skip check jump piece since space is empty for move
	p2s6dlj:
	p2s6dl_end:  # End label for moving to next
	p2s6dr:
	addi $t0, $s1, 3
	lw $t2, 0($t0)
	bne $t2, $zero, p2s6drj
	addi $t0, $zero, -5
	blt $t9, $t0, p2s6dr_end
	addi $v0, $zero, 6
	addi $v1, $zero, 3
	add $t9, $zero, $t0
	j p2s6dr_end  # Skip check jump piece since space is empty for move
	p2s6drj:
	p2s6dr_end:  # End label for moving to next

	# Space 7
	p2s7:
	addi $t0, $s1, 7
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s7n2
	j p2s7_2or4
	p2s7n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s8
	p2s7_2or4:  # Space 7 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s7ul_end
	p2s7ul:
	addi $t0, $s1, 11
	lw $t2, 0($t0)
	bne $t2, $zero, p2s7ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s7ul_end
	addi $v0, $zero, 7
	addi $v1, $zero, 11
	add $t9, $zero, $t0
	j p2s7ul_end  # Skip check jump piece since space is empty for move
	p2s7ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s7ul_n1
	j p2s7s11_1or3
	p2s7ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s7ul_end
	p2s7s11_1or3:
	addi $t0, $zero, 14
	lw $t3, 0($t0)
	bne $t3, $zero, p2s7ul_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s7ul_end
	addi $v0, $zero, 7
	addi $v1, $zero, 14
	add $t9, $zero, $t0
	p2s7ul_end:  # End label for moving to next
	p2s7dl:
	addi $t0, $s1, 3
	lw $t2, 0($t0)
	bne $t2, $zero, p2s7dlj
	addi $t0, $zero, -5
	blt $t9, $t0, p2s7dl_end
	addi $v0, $zero, 7
	addi $v1, $zero, 3
	add $t9, $zero, $t0
	j p2s7dl_end  # Skip check jump piece since space is empty for move
	p2s7dlj:
	p2s7dl_end:  # End label for moving to next

	# Space 8
	p2s8:
	addi $t0, $s1, 8
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s8n2
	j p2s8_2or4
	p2s8n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s9
	p2s8_2or4:  # Space 8 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s8ur_end
	p2s8ur:
	addi $t0, $s1, 12
	lw $t2, 0($t0)
	bne $t2, $zero, p2s8urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s8ur_end
	addi $v0, $zero, 8
	addi $v1, $zero, 12
	add $t9, $zero, $t0
	j p2s8ur_end  # Skip check jump piece since space is empty for move
	p2s8urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s8ur_n1
	j p2s8s12_1or3
	p2s8ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s8ur_end
	p2s8s12_1or3:
	addi $t0, $zero, 17
	lw $t3, 0($t0)
	bne $t3, $zero, p2s8ur_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s8ur_end
	addi $v0, $zero, 8
	addi $v1, $zero, 17
	add $t9, $zero, $t0
	p2s8ur_end:  # End label for moving to next
	p2s8dr:
	addi $t0, $s1, 4
	lw $t2, 0($t0)
	bne $t2, $zero, p2s8drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s8dr_end
	addi $v0, $zero, 8
	addi $v1, $zero, 4
	add $t9, $zero, $t0
	j p2s8dr_end  # Skip check jump piece since space is empty for move
	p2s8drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s8dr_n1
	j p2s8s4_1or3
	p2s8dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s8dr_end
	p2s8s4_1or3:
	addi $t0, $zero, 1
	lw $t3, 0($t0)
	bne $t3, $zero, p2s8dr_end
	addi $t0, $zero, -6
	blt $t9, $t0, p2s8dr_end
	addi $v0, $zero, 8
	addi $v1, $zero, 1
	add $t9, $zero, $t0
	p2s8dr_end:  # End label for moving to next

	# Space 9
	p2s9:
	addi $t0, $s1, 9
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s9n2
	j p2s9_2or4
	p2s9n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s10
	p2s9_2or4:  # Space 9 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s9ul_end
	p2s9ul:
	addi $t0, $s1, 12
	lw $t2, 0($t0)
	bne $t2, $zero, p2s9ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s9ul_end
	addi $v0, $zero, 9
	addi $v1, $zero, 12
	add $t9, $zero, $t0
	j p2s9ul_end  # Skip check jump piece since space is empty for move
	p2s9ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s9ul_n1
	j p2s9s12_1or3
	p2s9ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s9ul_end
	p2s9s12_1or3:
	addi $t0, $zero, 16
	lw $t3, 0($t0)
	bne $t3, $zero, p2s9ul_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s9ul_end
	addi $v0, $zero, 9
	addi $v1, $zero, 16
	add $t9, $zero, $t0
	p2s9ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s9ur_end
	p2s9ur:
	addi $t0, $s1, 13
	lw $t2, 0($t0)
	bne $t2, $zero, p2s9urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s9ur_end
	addi $v0, $zero, 9
	addi $v1, $zero, 13
	add $t9, $zero, $t0
	j p2s9ur_end  # Skip check jump piece since space is empty for move
	p2s9urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s9ur_n1
	j p2s9s13_1or3
	p2s9ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s9ur_end
	p2s9s13_1or3:
	addi $t0, $zero, 18
	lw $t3, 0($t0)
	bne $t3, $zero, p2s9ur_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s9ur_end
	addi $v0, $zero, 9
	addi $v1, $zero, 18
	add $t9, $zero, $t0
	p2s9ur_end:  # End label for moving to next
	p2s9dl:
	addi $t0, $s1, 4
	lw $t2, 0($t0)
	bne $t2, $zero, p2s9dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s9dl_end
	addi $v0, $zero, 9
	addi $v1, $zero, 4
	add $t9, $zero, $t0
	j p2s9dl_end  # Skip check jump piece since space is empty for move
	p2s9dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s9dl_n1
	j p2s9s4_1or3
	p2s9dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s9dl_end
	p2s9s4_1or3:
	addi $t0, $zero, 0
	lw $t3, 0($t0)
	bne $t3, $zero, p2s9dl_end
	addi $t0, $zero, -6
	blt $t9, $t0, p2s9dl_end
	addi $v0, $zero, 9
	addi $v1, $zero, 0
	add $t9, $zero, $t0
	p2s9dl_end:  # End label for moving to next
	p2s9dr:
	addi $t0, $s1, 5
	lw $t2, 0($t0)
	bne $t2, $zero, p2s9drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s9dr_end
	addi $v0, $zero, 9
	addi $v1, $zero, 5
	add $t9, $zero, $t0
	j p2s9dr_end  # Skip check jump piece since space is empty for move
	p2s9drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s9dr_n1
	j p2s9s5_1or3
	p2s9dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s9dr_end
	p2s9s5_1or3:
	addi $t0, $zero, 2
	lw $t3, 0($t0)
	bne $t3, $zero, p2s9dr_end
	addi $t0, $zero, -6
	blt $t9, $t0, p2s9dr_end
	addi $v0, $zero, 9
	addi $v1, $zero, 2
	add $t9, $zero, $t0
	p2s9dr_end:  # End label for moving to next

	# Space 10
	p2s10:
	addi $t0, $s1, 10
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s10n2
	j p2s10_2or4
	p2s10n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s11
	p2s10_2or4:  # Space 10 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s10ul_end
	p2s10ul:
	addi $t0, $s1, 13
	lw $t2, 0($t0)
	bne $t2, $zero, p2s10ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s10ul_end
	addi $v0, $zero, 10
	addi $v1, $zero, 13
	add $t9, $zero, $t0
	j p2s10ul_end  # Skip check jump piece since space is empty for move
	p2s10ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s10ul_n1
	j p2s10s13_1or3
	p2s10ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s10ul_end
	p2s10s13_1or3:
	addi $t0, $zero, 17
	lw $t3, 0($t0)
	bne $t3, $zero, p2s10ul_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s10ul_end
	addi $v0, $zero, 10
	addi $v1, $zero, 17
	add $t9, $zero, $t0
	p2s10ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s10ur_end
	p2s10ur:
	addi $t0, $s1, 14
	lw $t2, 0($t0)
	bne $t2, $zero, p2s10urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s10ur_end
	addi $v0, $zero, 10
	addi $v1, $zero, 14
	add $t9, $zero, $t0
	j p2s10ur_end  # Skip check jump piece since space is empty for move
	p2s10urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s10ur_n1
	j p2s10s14_1or3
	p2s10ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s10ur_end
	p2s10s14_1or3:
	addi $t0, $zero, 19
	lw $t3, 0($t0)
	bne $t3, $zero, p2s10ur_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s10ur_end
	addi $v0, $zero, 10
	addi $v1, $zero, 19
	add $t9, $zero, $t0
	p2s10ur_end:  # End label for moving to next
	p2s10dl:
	addi $t0, $s1, 5
	lw $t2, 0($t0)
	bne $t2, $zero, p2s10dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s10dl_end
	addi $v0, $zero, 10
	addi $v1, $zero, 5
	add $t9, $zero, $t0
	j p2s10dl_end  # Skip check jump piece since space is empty for move
	p2s10dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s10dl_n1
	j p2s10s5_1or3
	p2s10dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s10dl_end
	p2s10s5_1or3:
	addi $t0, $zero, 1
	lw $t3, 0($t0)
	bne $t3, $zero, p2s10dl_end
	addi $t0, $zero, -6
	blt $t9, $t0, p2s10dl_end
	addi $v0, $zero, 10
	addi $v1, $zero, 1
	add $t9, $zero, $t0
	p2s10dl_end:  # End label for moving to next
	p2s10dr:
	addi $t0, $s1, 6
	lw $t2, 0($t0)
	bne $t2, $zero, p2s10drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s10dr_end
	addi $v0, $zero, 10
	addi $v1, $zero, 6
	add $t9, $zero, $t0
	j p2s10dr_end  # Skip check jump piece since space is empty for move
	p2s10drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s10dr_n1
	j p2s10s6_1or3
	p2s10dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s10dr_end
	p2s10s6_1or3:
	addi $t0, $zero, 3
	lw $t3, 0($t0)
	bne $t3, $zero, p2s10dr_end
	addi $t0, $zero, -6
	blt $t9, $t0, p2s10dr_end
	addi $v0, $zero, 10
	addi $v1, $zero, 3
	add $t9, $zero, $t0
	p2s10dr_end:  # End label for moving to next

	# Space 11
	p2s11:
	addi $t0, $s1, 11
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s11n2
	j p2s11_2or4
	p2s11n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s12
	p2s11_2or4:  # Space 11 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s11ul_end
	p2s11ul:
	addi $t0, $s1, 14
	lw $t2, 0($t0)
	bne $t2, $zero, p2s11ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s11ul_end
	addi $v0, $zero, 11
	addi $v1, $zero, 14
	add $t9, $zero, $t0
	j p2s11ul_end  # Skip check jump piece since space is empty for move
	p2s11ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s11ul_n1
	j p2s11s14_1or3
	p2s11ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s11ul_end
	p2s11s14_1or3:
	addi $t0, $zero, 18
	lw $t3, 0($t0)
	bne $t3, $zero, p2s11ul_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s11ul_end
	addi $v0, $zero, 11
	addi $v1, $zero, 18
	add $t9, $zero, $t0
	p2s11ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s11ur_end
	p2s11ur:
	addi $t0, $s1, 15
	lw $t2, 0($t0)
	bne $t2, $zero, p2s11urj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s11ur_end
	addi $v0, $zero, 11
	addi $v1, $zero, 15
	add $t9, $zero, $t0
	j p2s11ur_end  # Skip check jump piece since space is empty for move
	p2s11urj:
	p2s11ur_end:  # End label for moving to next
	p2s11dl:
	addi $t0, $s1, 6
	lw $t2, 0($t0)
	bne $t2, $zero, p2s11dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s11dl_end
	addi $v0, $zero, 11
	addi $v1, $zero, 6
	add $t9, $zero, $t0
	j p2s11dl_end  # Skip check jump piece since space is empty for move
	p2s11dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s11dl_n1
	j p2s11s6_1or3
	p2s11dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s11dl_end
	p2s11s6_1or3:
	addi $t0, $zero, 2
	lw $t3, 0($t0)
	bne $t3, $zero, p2s11dl_end
	addi $t0, $zero, -6
	blt $t9, $t0, p2s11dl_end
	addi $v0, $zero, 11
	addi $v1, $zero, 2
	add $t9, $zero, $t0
	p2s11dl_end:  # End label for moving to next
	p2s11dr:
	addi $t0, $s1, 7
	lw $t2, 0($t0)
	bne $t2, $zero, p2s11drj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s11dr_end
	addi $v0, $zero, 11
	addi $v1, $zero, 7
	add $t9, $zero, $t0
	j p2s11dr_end  # Skip check jump piece since space is empty for move
	p2s11drj:
	p2s11dr_end:  # End label for moving to next

	# Space 12
	p2s12:
	addi $t0, $s1, 12
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s12n2
	j p2s12_2or4
	p2s12n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s13
	p2s12_2or4:  # Space 12 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s12ul_end
	p2s12ul:
	addi $t0, $s1, 16
	lw $t2, 0($t0)
	bne $t2, $zero, p2s12ulj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s12ul_end
	addi $v0, $zero, 12
	addi $v1, $zero, 16
	add $t9, $zero, $t0
	j p2s12ul_end  # Skip check jump piece since space is empty for move
	p2s12ulj:
	p2s12ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s12ur_end
	p2s12ur:
	addi $t0, $s1, 17
	lw $t2, 0($t0)
	bne $t2, $zero, p2s12urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s12ur_end
	addi $v0, $zero, 12
	addi $v1, $zero, 17
	add $t9, $zero, $t0
	j p2s12ur_end  # Skip check jump piece since space is empty for move
	p2s12urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s12ur_n1
	j p2s12s17_1or3
	p2s12ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s12ur_end
	p2s12s17_1or3:
	addi $t0, $zero, 21
	lw $t3, 0($t0)
	bne $t3, $zero, p2s12ur_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s12ur_end
	addi $v0, $zero, 12
	addi $v1, $zero, 21
	add $t9, $zero, $t0
	p2s12ur_end:  # End label for moving to next
	p2s12dl:
	addi $t0, $s1, 8
	lw $t2, 0($t0)
	bne $t2, $zero, p2s12dlj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s12dl_end
	addi $v0, $zero, 12
	addi $v1, $zero, 8
	add $t9, $zero, $t0
	j p2s12dl_end  # Skip check jump piece since space is empty for move
	p2s12dlj:
	p2s12dl_end:  # End label for moving to next
	p2s12dr:
	addi $t0, $s1, 9
	lw $t2, 0($t0)
	bne $t2, $zero, p2s12drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s12dr_end
	addi $v0, $zero, 12
	addi $v1, $zero, 9
	add $t9, $zero, $t0
	j p2s12dr_end  # Skip check jump piece since space is empty for move
	p2s12drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s12dr_n1
	j p2s12s9_1or3
	p2s12dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s12dr_end
	p2s12s9_1or3:
	addi $t0, $zero, 5
	lw $t3, 0($t0)
	bne $t3, $zero, p2s12dr_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s12dr_end
	addi $v0, $zero, 12
	addi $v1, $zero, 5
	add $t9, $zero, $t0
	p2s12dr_end:  # End label for moving to next

	# Space 13
	p2s13:
	addi $t0, $s1, 13
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s13n2
	j p2s13_2or4
	p2s13n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s14
	p2s13_2or4:  # Space 13 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s13ul_end
	p2s13ul:
	addi $t0, $s1, 17
	lw $t2, 0($t0)
	bne $t2, $zero, p2s13ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s13ul_end
	addi $v0, $zero, 13
	addi $v1, $zero, 17
	add $t9, $zero, $t0
	j p2s13ul_end  # Skip check jump piece since space is empty for move
	p2s13ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s13ul_n1
	j p2s13s17_1or3
	p2s13ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s13ul_end
	p2s13s17_1or3:
	addi $t0, $zero, 20
	lw $t3, 0($t0)
	bne $t3, $zero, p2s13ul_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s13ul_end
	addi $v0, $zero, 13
	addi $v1, $zero, 20
	add $t9, $zero, $t0
	p2s13ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s13ur_end
	p2s13ur:
	addi $t0, $s1, 18
	lw $t2, 0($t0)
	bne $t2, $zero, p2s13urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s13ur_end
	addi $v0, $zero, 13
	addi $v1, $zero, 18
	add $t9, $zero, $t0
	j p2s13ur_end  # Skip check jump piece since space is empty for move
	p2s13urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s13ur_n1
	j p2s13s18_1or3
	p2s13ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s13ur_end
	p2s13s18_1or3:
	addi $t0, $zero, 22
	lw $t3, 0($t0)
	bne $t3, $zero, p2s13ur_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s13ur_end
	addi $v0, $zero, 13
	addi $v1, $zero, 22
	add $t9, $zero, $t0
	p2s13ur_end:  # End label for moving to next
	p2s13dl:
	addi $t0, $s1, 9
	lw $t2, 0($t0)
	bne $t2, $zero, p2s13dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s13dl_end
	addi $v0, $zero, 13
	addi $v1, $zero, 9
	add $t9, $zero, $t0
	j p2s13dl_end  # Skip check jump piece since space is empty for move
	p2s13dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s13dl_n1
	j p2s13s9_1or3
	p2s13dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s13dl_end
	p2s13s9_1or3:
	addi $t0, $zero, 4
	lw $t3, 0($t0)
	bne $t3, $zero, p2s13dl_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s13dl_end
	addi $v0, $zero, 13
	addi $v1, $zero, 4
	add $t9, $zero, $t0
	p2s13dl_end:  # End label for moving to next
	p2s13dr:
	addi $t0, $s1, 10
	lw $t2, 0($t0)
	bne $t2, $zero, p2s13drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s13dr_end
	addi $v0, $zero, 13
	addi $v1, $zero, 10
	add $t9, $zero, $t0
	j p2s13dr_end  # Skip check jump piece since space is empty for move
	p2s13drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s13dr_n1
	j p2s13s10_1or3
	p2s13dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s13dr_end
	p2s13s10_1or3:
	addi $t0, $zero, 6
	lw $t3, 0($t0)
	bne $t3, $zero, p2s13dr_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s13dr_end
	addi $v0, $zero, 13
	addi $v1, $zero, 6
	add $t9, $zero, $t0
	p2s13dr_end:  # End label for moving to next

	# Space 14
	p2s14:
	addi $t0, $s1, 14
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s14n2
	j p2s14_2or4
	p2s14n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s15
	p2s14_2or4:  # Space 14 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s14ul_end
	p2s14ul:
	addi $t0, $s1, 18
	lw $t2, 0($t0)
	bne $t2, $zero, p2s14ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s14ul_end
	addi $v0, $zero, 14
	addi $v1, $zero, 18
	add $t9, $zero, $t0
	j p2s14ul_end  # Skip check jump piece since space is empty for move
	p2s14ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s14ul_n1
	j p2s14s18_1or3
	p2s14ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s14ul_end
	p2s14s18_1or3:
	addi $t0, $zero, 21
	lw $t3, 0($t0)
	bne $t3, $zero, p2s14ul_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s14ul_end
	addi $v0, $zero, 14
	addi $v1, $zero, 21
	add $t9, $zero, $t0
	p2s14ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s14ur_end
	p2s14ur:
	addi $t0, $s1, 19
	lw $t2, 0($t0)
	bne $t2, $zero, p2s14urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s14ur_end
	addi $v0, $zero, 14
	addi $v1, $zero, 19
	add $t9, $zero, $t0
	j p2s14ur_end  # Skip check jump piece since space is empty for move
	p2s14urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s14ur_n1
	j p2s14s19_1or3
	p2s14ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s14ur_end
	p2s14s19_1or3:
	addi $t0, $zero, 23
	lw $t3, 0($t0)
	bne $t3, $zero, p2s14ur_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s14ur_end
	addi $v0, $zero, 14
	addi $v1, $zero, 23
	add $t9, $zero, $t0
	p2s14ur_end:  # End label for moving to next
	p2s14dl:
	addi $t0, $s1, 10
	lw $t2, 0($t0)
	bne $t2, $zero, p2s14dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s14dl_end
	addi $v0, $zero, 14
	addi $v1, $zero, 10
	add $t9, $zero, $t0
	j p2s14dl_end  # Skip check jump piece since space is empty for move
	p2s14dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s14dl_n1
	j p2s14s10_1or3
	p2s14dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s14dl_end
	p2s14s10_1or3:
	addi $t0, $zero, 5
	lw $t3, 0($t0)
	bne $t3, $zero, p2s14dl_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s14dl_end
	addi $v0, $zero, 14
	addi $v1, $zero, 5
	add $t9, $zero, $t0
	p2s14dl_end:  # End label for moving to next
	p2s14dr:
	addi $t0, $s1, 11
	lw $t2, 0($t0)
	bne $t2, $zero, p2s14drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s14dr_end
	addi $v0, $zero, 14
	addi $v1, $zero, 11
	add $t9, $zero, $t0
	j p2s14dr_end  # Skip check jump piece since space is empty for move
	p2s14drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s14dr_n1
	j p2s14s11_1or3
	p2s14dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s14dr_end
	p2s14s11_1or3:
	addi $t0, $zero, 7
	lw $t3, 0($t0)
	bne $t3, $zero, p2s14dr_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s14dr_end
	addi $v0, $zero, 14
	addi $v1, $zero, 7
	add $t9, $zero, $t0
	p2s14dr_end:  # End label for moving to next

	# Space 15
	p2s15:
	addi $t0, $s1, 15
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s15n2
	j p2s15_2or4
	p2s15n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s16
	p2s15_2or4:  # Space 15 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s15ul_end
	p2s15ul:
	addi $t0, $s1, 19
	lw $t2, 0($t0)
	bne $t2, $zero, p2s15ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s15ul_end
	addi $v0, $zero, 15
	addi $v1, $zero, 19
	add $t9, $zero, $t0
	j p2s15ul_end  # Skip check jump piece since space is empty for move
	p2s15ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s15ul_n1
	j p2s15s19_1or3
	p2s15ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s15ul_end
	p2s15s19_1or3:
	addi $t0, $zero, 22
	lw $t3, 0($t0)
	bne $t3, $zero, p2s15ul_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s15ul_end
	addi $v0, $zero, 15
	addi $v1, $zero, 22
	add $t9, $zero, $t0
	p2s15ul_end:  # End label for moving to next
	p2s15dl:
	addi $t0, $s1, 11
	lw $t2, 0($t0)
	bne $t2, $zero, p2s15dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s15dl_end
	addi $v0, $zero, 15
	addi $v1, $zero, 11
	add $t9, $zero, $t0
	j p2s15dl_end  # Skip check jump piece since space is empty for move
	p2s15dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s15dl_n1
	j p2s15s11_1or3
	p2s15dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s15dl_end
	p2s15s11_1or3:
	addi $t0, $zero, 6
	lw $t3, 0($t0)
	bne $t3, $zero, p2s15dl_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s15dl_end
	addi $v0, $zero, 15
	addi $v1, $zero, 6
	add $t9, $zero, $t0
	p2s15dl_end:  # End label for moving to next

	# Space 16
	p2s16:
	addi $t0, $s1, 16
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s16n2
	j p2s16_2or4
	p2s16n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s17
	p2s16_2or4:  # Space 16 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s16ur_end
	p2s16ur:
	addi $t0, $s1, 20
	lw $t2, 0($t0)
	bne $t2, $zero, p2s16urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s16ur_end
	addi $v0, $zero, 16
	addi $v1, $zero, 20
	add $t9, $zero, $t0
	j p2s16ur_end  # Skip check jump piece since space is empty for move
	p2s16urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s16ur_n1
	j p2s16s20_1or3
	p2s16ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s16ur_end
	p2s16s20_1or3:
	addi $t0, $zero, 25
	lw $t3, 0($t0)
	bne $t3, $zero, p2s16ur_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s16ur_end
	addi $v0, $zero, 16
	addi $v1, $zero, 25
	add $t9, $zero, $t0
	p2s16ur_end:  # End label for moving to next
	p2s16dr:
	addi $t0, $s1, 12
	lw $t2, 0($t0)
	bne $t2, $zero, p2s16drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s16dr_end
	addi $v0, $zero, 16
	addi $v1, $zero, 12
	add $t9, $zero, $t0
	j p2s16dr_end  # Skip check jump piece since space is empty for move
	p2s16drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s16dr_n1
	j p2s16s12_1or3
	p2s16dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s16dr_end
	p2s16s12_1or3:
	addi $t0, $zero, 9
	lw $t3, 0($t0)
	bne $t3, $zero, p2s16dr_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s16dr_end
	addi $v0, $zero, 16
	addi $v1, $zero, 9
	add $t9, $zero, $t0
	p2s16dr_end:  # End label for moving to next

	# Space 17
	p2s17:
	addi $t0, $s1, 17
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s17n2
	j p2s17_2or4
	p2s17n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s18
	p2s17_2or4:  # Space 17 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s17ul_end
	p2s17ul:
	addi $t0, $s1, 20
	lw $t2, 0($t0)
	bne $t2, $zero, p2s17ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s17ul_end
	addi $v0, $zero, 17
	addi $v1, $zero, 20
	add $t9, $zero, $t0
	j p2s17ul_end  # Skip check jump piece since space is empty for move
	p2s17ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s17ul_n1
	j p2s17s20_1or3
	p2s17ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s17ul_end
	p2s17s20_1or3:
	addi $t0, $zero, 24
	lw $t3, 0($t0)
	bne $t3, $zero, p2s17ul_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s17ul_end
	addi $v0, $zero, 17
	addi $v1, $zero, 24
	add $t9, $zero, $t0
	p2s17ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s17ur_end
	p2s17ur:
	addi $t0, $s1, 21
	lw $t2, 0($t0)
	bne $t2, $zero, p2s17urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s17ur_end
	addi $v0, $zero, 17
	addi $v1, $zero, 21
	add $t9, $zero, $t0
	j p2s17ur_end  # Skip check jump piece since space is empty for move
	p2s17urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s17ur_n1
	j p2s17s21_1or3
	p2s17ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s17ur_end
	p2s17s21_1or3:
	addi $t0, $zero, 26
	lw $t3, 0($t0)
	bne $t3, $zero, p2s17ur_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s17ur_end
	addi $v0, $zero, 17
	addi $v1, $zero, 26
	add $t9, $zero, $t0
	p2s17ur_end:  # End label for moving to next
	p2s17dl:
	addi $t0, $s1, 12
	lw $t2, 0($t0)
	bne $t2, $zero, p2s17dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s17dl_end
	addi $v0, $zero, 17
	addi $v1, $zero, 12
	add $t9, $zero, $t0
	j p2s17dl_end  # Skip check jump piece since space is empty for move
	p2s17dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s17dl_n1
	j p2s17s12_1or3
	p2s17dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s17dl_end
	p2s17s12_1or3:
	addi $t0, $zero, 8
	lw $t3, 0($t0)
	bne $t3, $zero, p2s17dl_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s17dl_end
	addi $v0, $zero, 17
	addi $v1, $zero, 8
	add $t9, $zero, $t0
	p2s17dl_end:  # End label for moving to next
	p2s17dr:
	addi $t0, $s1, 13
	lw $t2, 0($t0)
	bne $t2, $zero, p2s17drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s17dr_end
	addi $v0, $zero, 17
	addi $v1, $zero, 13
	add $t9, $zero, $t0
	j p2s17dr_end  # Skip check jump piece since space is empty for move
	p2s17drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s17dr_n1
	j p2s17s13_1or3
	p2s17dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s17dr_end
	p2s17s13_1or3:
	addi $t0, $zero, 10
	lw $t3, 0($t0)
	bne $t3, $zero, p2s17dr_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s17dr_end
	addi $v0, $zero, 17
	addi $v1, $zero, 10
	add $t9, $zero, $t0
	p2s17dr_end:  # End label for moving to next

	# Space 18
	p2s18:
	addi $t0, $s1, 18
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s18n2
	j p2s18_2or4
	p2s18n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s19
	p2s18_2or4:  # Space 18 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s18ul_end
	p2s18ul:
	addi $t0, $s1, 21
	lw $t2, 0($t0)
	bne $t2, $zero, p2s18ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s18ul_end
	addi $v0, $zero, 18
	addi $v1, $zero, 21
	add $t9, $zero, $t0
	j p2s18ul_end  # Skip check jump piece since space is empty for move
	p2s18ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s18ul_n1
	j p2s18s21_1or3
	p2s18ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s18ul_end
	p2s18s21_1or3:
	addi $t0, $zero, 25
	lw $t3, 0($t0)
	bne $t3, $zero, p2s18ul_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s18ul_end
	addi $v0, $zero, 18
	addi $v1, $zero, 25
	add $t9, $zero, $t0
	p2s18ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s18ur_end
	p2s18ur:
	addi $t0, $s1, 22
	lw $t2, 0($t0)
	bne $t2, $zero, p2s18urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s18ur_end
	addi $v0, $zero, 18
	addi $v1, $zero, 22
	add $t9, $zero, $t0
	j p2s18ur_end  # Skip check jump piece since space is empty for move
	p2s18urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s18ur_n1
	j p2s18s22_1or3
	p2s18ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s18ur_end
	p2s18s22_1or3:
	addi $t0, $zero, 27
	lw $t3, 0($t0)
	bne $t3, $zero, p2s18ur_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s18ur_end
	addi $v0, $zero, 18
	addi $v1, $zero, 27
	add $t9, $zero, $t0
	p2s18ur_end:  # End label for moving to next
	p2s18dl:
	addi $t0, $s1, 13
	lw $t2, 0($t0)
	bne $t2, $zero, p2s18dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s18dl_end
	addi $v0, $zero, 18
	addi $v1, $zero, 13
	add $t9, $zero, $t0
	j p2s18dl_end  # Skip check jump piece since space is empty for move
	p2s18dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s18dl_n1
	j p2s18s13_1or3
	p2s18dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s18dl_end
	p2s18s13_1or3:
	addi $t0, $zero, 9
	lw $t3, 0($t0)
	bne $t3, $zero, p2s18dl_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s18dl_end
	addi $v0, $zero, 18
	addi $v1, $zero, 9
	add $t9, $zero, $t0
	p2s18dl_end:  # End label for moving to next
	p2s18dr:
	addi $t0, $s1, 14
	lw $t2, 0($t0)
	bne $t2, $zero, p2s18drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s18dr_end
	addi $v0, $zero, 18
	addi $v1, $zero, 14
	add $t9, $zero, $t0
	j p2s18dr_end  # Skip check jump piece since space is empty for move
	p2s18drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s18dr_n1
	j p2s18s14_1or3
	p2s18dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s18dr_end
	p2s18s14_1or3:
	addi $t0, $zero, 11
	lw $t3, 0($t0)
	bne $t3, $zero, p2s18dr_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s18dr_end
	addi $v0, $zero, 18
	addi $v1, $zero, 11
	add $t9, $zero, $t0
	p2s18dr_end:  # End label for moving to next

	# Space 19
	p2s19:
	addi $t0, $s1, 19
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s19n2
	j p2s19_2or4
	p2s19n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s20
	p2s19_2or4:  # Space 19 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s19ul_end
	p2s19ul:
	addi $t0, $s1, 22
	lw $t2, 0($t0)
	bne $t2, $zero, p2s19ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s19ul_end
	addi $v0, $zero, 19
	addi $v1, $zero, 22
	add $t9, $zero, $t0
	j p2s19ul_end  # Skip check jump piece since space is empty for move
	p2s19ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s19ul_n1
	j p2s19s22_1or3
	p2s19ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s19ul_end
	p2s19s22_1or3:
	addi $t0, $zero, 26
	lw $t3, 0($t0)
	bne $t3, $zero, p2s19ul_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s19ul_end
	addi $v0, $zero, 19
	addi $v1, $zero, 26
	add $t9, $zero, $t0
	p2s19ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s19ur_end
	p2s19ur:
	addi $t0, $s1, 23
	lw $t2, 0($t0)
	bne $t2, $zero, p2s19urj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s19ur_end
	addi $v0, $zero, 19
	addi $v1, $zero, 23
	add $t9, $zero, $t0
	j p2s19ur_end  # Skip check jump piece since space is empty for move
	p2s19urj:
	p2s19ur_end:  # End label for moving to next
	p2s19dl:
	addi $t0, $s1, 14
	lw $t2, 0($t0)
	bne $t2, $zero, p2s19dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s19dl_end
	addi $v0, $zero, 19
	addi $v1, $zero, 14
	add $t9, $zero, $t0
	j p2s19dl_end  # Skip check jump piece since space is empty for move
	p2s19dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s19dl_n1
	j p2s19s14_1or3
	p2s19dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s19dl_end
	p2s19s14_1or3:
	addi $t0, $zero, 10
	lw $t3, 0($t0)
	bne $t3, $zero, p2s19dl_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s19dl_end
	addi $v0, $zero, 19
	addi $v1, $zero, 10
	add $t9, $zero, $t0
	p2s19dl_end:  # End label for moving to next
	p2s19dr:
	addi $t0, $s1, 15
	lw $t2, 0($t0)
	bne $t2, $zero, p2s19drj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s19dr_end
	addi $v0, $zero, 19
	addi $v1, $zero, 15
	add $t9, $zero, $t0
	j p2s19dr_end  # Skip check jump piece since space is empty for move
	p2s19drj:
	p2s19dr_end:  # End label for moving to next

	# Space 20
	p2s20:
	addi $t0, $s1, 20
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s20n2
	j p2s20_2or4
	p2s20n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s21
	p2s20_2or4:  # Space 20 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s20ul_end
	p2s20ul:
	addi $t0, $s1, 24
	lw $t2, 0($t0)
	bne $t2, $zero, p2s20ulj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s20ul_end
	addi $v0, $zero, 20
	addi $v1, $zero, 24
	add $t9, $zero, $t0
	j p2s20ul_end  # Skip check jump piece since space is empty for move
	p2s20ulj:
	p2s20ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s20ur_end
	p2s20ur:
	addi $t0, $s1, 25
	lw $t2, 0($t0)
	bne $t2, $zero, p2s20urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s20ur_end
	addi $v0, $zero, 20
	addi $v1, $zero, 25
	add $t9, $zero, $t0
	j p2s20ur_end  # Skip check jump piece since space is empty for move
	p2s20urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s20ur_n1
	j p2s20s25_1or3
	p2s20ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s20ur_end
	p2s20s25_1or3:
	addi $t0, $zero, 29
	lw $t3, 0($t0)
	bne $t3, $zero, p2s20ur_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s20ur_end
	addi $v0, $zero, 20
	addi $v1, $zero, 29
	add $t9, $zero, $t0
	p2s20ur_end:  # End label for moving to next
	p2s20dl:
	addi $t0, $s1, 16
	lw $t2, 0($t0)
	bne $t2, $zero, p2s20dlj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s20dl_end
	addi $v0, $zero, 20
	addi $v1, $zero, 16
	add $t9, $zero, $t0
	j p2s20dl_end  # Skip check jump piece since space is empty for move
	p2s20dlj:
	p2s20dl_end:  # End label for moving to next
	p2s20dr:
	addi $t0, $s1, 17
	lw $t2, 0($t0)
	bne $t2, $zero, p2s20drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s20dr_end
	addi $v0, $zero, 20
	addi $v1, $zero, 17
	add $t9, $zero, $t0
	j p2s20dr_end  # Skip check jump piece since space is empty for move
	p2s20drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s20dr_n1
	j p2s20s17_1or3
	p2s20dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s20dr_end
	p2s20s17_1or3:
	addi $t0, $zero, 13
	lw $t3, 0($t0)
	bne $t3, $zero, p2s20dr_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s20dr_end
	addi $v0, $zero, 20
	addi $v1, $zero, 13
	add $t9, $zero, $t0
	p2s20dr_end:  # End label for moving to next

	# Space 21
	p2s21:
	addi $t0, $s1, 21
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s21n2
	j p2s21_2or4
	p2s21n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s22
	p2s21_2or4:  # Space 21 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s21ul_end
	p2s21ul:
	addi $t0, $s1, 25
	lw $t2, 0($t0)
	bne $t2, $zero, p2s21ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s21ul_end
	addi $v0, $zero, 21
	addi $v1, $zero, 25
	add $t9, $zero, $t0
	j p2s21ul_end  # Skip check jump piece since space is empty for move
	p2s21ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s21ul_n1
	j p2s21s25_1or3
	p2s21ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s21ul_end
	p2s21s25_1or3:
	addi $t0, $zero, 28
	lw $t3, 0($t0)
	bne $t3, $zero, p2s21ul_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s21ul_end
	addi $v0, $zero, 21
	addi $v1, $zero, 28
	add $t9, $zero, $t0
	p2s21ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s21ur_end
	p2s21ur:
	addi $t0, $s1, 26
	lw $t2, 0($t0)
	bne $t2, $zero, p2s21urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s21ur_end
	addi $v0, $zero, 21
	addi $v1, $zero, 26
	add $t9, $zero, $t0
	j p2s21ur_end  # Skip check jump piece since space is empty for move
	p2s21urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s21ur_n1
	j p2s21s26_1or3
	p2s21ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s21ur_end
	p2s21s26_1or3:
	addi $t0, $zero, 30
	lw $t3, 0($t0)
	bne $t3, $zero, p2s21ur_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s21ur_end
	addi $v0, $zero, 21
	addi $v1, $zero, 30
	add $t9, $zero, $t0
	p2s21ur_end:  # End label for moving to next
	p2s21dl:
	addi $t0, $s1, 17
	lw $t2, 0($t0)
	bne $t2, $zero, p2s21dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s21dl_end
	addi $v0, $zero, 21
	addi $v1, $zero, 17
	add $t9, $zero, $t0
	j p2s21dl_end  # Skip check jump piece since space is empty for move
	p2s21dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s21dl_n1
	j p2s21s17_1or3
	p2s21dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s21dl_end
	p2s21s17_1or3:
	addi $t0, $zero, 12
	lw $t3, 0($t0)
	bne $t3, $zero, p2s21dl_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s21dl_end
	addi $v0, $zero, 21
	addi $v1, $zero, 12
	add $t9, $zero, $t0
	p2s21dl_end:  # End label for moving to next
	p2s21dr:
	addi $t0, $s1, 18
	lw $t2, 0($t0)
	bne $t2, $zero, p2s21drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s21dr_end
	addi $v0, $zero, 21
	addi $v1, $zero, 18
	add $t9, $zero, $t0
	j p2s21dr_end  # Skip check jump piece since space is empty for move
	p2s21drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s21dr_n1
	j p2s21s18_1or3
	p2s21dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s21dr_end
	p2s21s18_1or3:
	addi $t0, $zero, 14
	lw $t3, 0($t0)
	bne $t3, $zero, p2s21dr_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s21dr_end
	addi $v0, $zero, 21
	addi $v1, $zero, 14
	add $t9, $zero, $t0
	p2s21dr_end:  # End label for moving to next

	# Space 22
	p2s22:
	addi $t0, $s1, 22
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s22n2
	j p2s22_2or4
	p2s22n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s23
	p2s22_2or4:  # Space 22 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s22ul_end
	p2s22ul:
	addi $t0, $s1, 26
	lw $t2, 0($t0)
	bne $t2, $zero, p2s22ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s22ul_end
	addi $v0, $zero, 22
	addi $v1, $zero, 26
	add $t9, $zero, $t0
	j p2s22ul_end  # Skip check jump piece since space is empty for move
	p2s22ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s22ul_n1
	j p2s22s26_1or3
	p2s22ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s22ul_end
	p2s22s26_1or3:
	addi $t0, $zero, 29
	lw $t3, 0($t0)
	bne $t3, $zero, p2s22ul_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s22ul_end
	addi $v0, $zero, 22
	addi $v1, $zero, 29
	add $t9, $zero, $t0
	p2s22ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s22ur_end
	p2s22ur:
	addi $t0, $s1, 27
	lw $t2, 0($t0)
	bne $t2, $zero, p2s22urj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s22ur_end
	addi $v0, $zero, 22
	addi $v1, $zero, 27
	add $t9, $zero, $t0
	j p2s22ur_end  # Skip check jump piece since space is empty for move
	p2s22urj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s22ur_n1
	j p2s22s27_1or3
	p2s22ur_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s22ur_end
	p2s22s27_1or3:
	addi $t0, $zero, 31
	lw $t3, 0($t0)
	bne $t3, $zero, p2s22ur_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s22ur_end
	addi $v0, $zero, 22
	addi $v1, $zero, 31
	add $t9, $zero, $t0
	p2s22ur_end:  # End label for moving to next
	p2s22dl:
	addi $t0, $s1, 18
	lw $t2, 0($t0)
	bne $t2, $zero, p2s22dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s22dl_end
	addi $v0, $zero, 22
	addi $v1, $zero, 18
	add $t9, $zero, $t0
	j p2s22dl_end  # Skip check jump piece since space is empty for move
	p2s22dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s22dl_n1
	j p2s22s18_1or3
	p2s22dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s22dl_end
	p2s22s18_1or3:
	addi $t0, $zero, 13
	lw $t3, 0($t0)
	bne $t3, $zero, p2s22dl_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s22dl_end
	addi $v0, $zero, 22
	addi $v1, $zero, 13
	add $t9, $zero, $t0
	p2s22dl_end:  # End label for moving to next
	p2s22dr:
	addi $t0, $s1, 19
	lw $t2, 0($t0)
	bne $t2, $zero, p2s22drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s22dr_end
	addi $v0, $zero, 22
	addi $v1, $zero, 19
	add $t9, $zero, $t0
	j p2s22dr_end  # Skip check jump piece since space is empty for move
	p2s22drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s22dr_n1
	j p2s22s19_1or3
	p2s22dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s22dr_end
	p2s22s19_1or3:
	addi $t0, $zero, 15
	lw $t3, 0($t0)
	bne $t3, $zero, p2s22dr_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s22dr_end
	addi $v0, $zero, 22
	addi $v1, $zero, 15
	add $t9, $zero, $t0
	p2s22dr_end:  # End label for moving to next

	# Space 23
	p2s23:
	addi $t0, $s1, 23
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s23n2
	j p2s23_2or4
	p2s23n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s24
	p2s23_2or4:  # Space 23 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s23ul_end
	p2s23ul:
	addi $t0, $s1, 27
	lw $t2, 0($t0)
	bne $t2, $zero, p2s23ulj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s23ul_end
	addi $v0, $zero, 23
	addi $v1, $zero, 27
	add $t9, $zero, $t0
	j p2s23ul_end  # Skip check jump piece since space is empty for move
	p2s23ulj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s23ul_n1
	j p2s23s27_1or3
	p2s23ul_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s23ul_end
	p2s23s27_1or3:
	addi $t0, $zero, 30
	lw $t3, 0($t0)
	bne $t3, $zero, p2s23ul_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s23ul_end
	addi $v0, $zero, 23
	addi $v1, $zero, 30
	add $t9, $zero, $t0
	p2s23ul_end:  # End label for moving to next
	p2s23dl:
	addi $t0, $s1, 19
	lw $t2, 0($t0)
	bne $t2, $zero, p2s23dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s23dl_end
	addi $v0, $zero, 23
	addi $v1, $zero, 19
	add $t9, $zero, $t0
	j p2s23dl_end  # Skip check jump piece since space is empty for move
	p2s23dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s23dl_n1
	j p2s23s19_1or3
	p2s23dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s23dl_end
	p2s23s19_1or3:
	addi $t0, $zero, 14
	lw $t3, 0($t0)
	bne $t3, $zero, p2s23dl_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s23dl_end
	addi $v0, $zero, 23
	addi $v1, $zero, 14
	add $t9, $zero, $t0
	p2s23dl_end:  # End label for moving to next

	# Space 24
	p2s24:
	addi $t0, $s1, 24
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s24n2
	j p2s24_2or4
	p2s24n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s25
	p2s24_2or4:  # Space 24 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s24ur_end
	p2s24ur:
	addi $t0, $s1, 28
	lw $t2, 0($t0)
	bne $t2, $zero, p2s24urj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s24ur_end
	addi $v0, $zero, 24
	addi $v1, $zero, 28
	add $t9, $zero, $t0
	j p2s24ur_end  # Skip check jump piece since space is empty for move
	p2s24urj:
	p2s24ur_end:  # End label for moving to next
	p2s24dr:
	addi $t0, $s1, 20
	lw $t2, 0($t0)
	bne $t2, $zero, p2s24drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s24dr_end
	addi $v0, $zero, 24
	addi $v1, $zero, 20
	add $t9, $zero, $t0
	j p2s24dr_end  # Skip check jump piece since space is empty for move
	p2s24drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s24dr_n1
	j p2s24s20_1or3
	p2s24dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s24dr_end
	p2s24s20_1or3:
	addi $t0, $zero, 17
	lw $t3, 0($t0)
	bne $t3, $zero, p2s24dr_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s24dr_end
	addi $v0, $zero, 24
	addi $v1, $zero, 17
	add $t9, $zero, $t0
	p2s24dr_end:  # End label for moving to next

	# Space 25
	p2s25:
	addi $t0, $s1, 25
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s25n2
	j p2s25_2or4
	p2s25n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s26
	p2s25_2or4:  # Space 25 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s25ul_end
	p2s25ul:
	addi $t0, $s1, 28
	lw $t2, 0($t0)
	bne $t2, $zero, p2s25ulj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s25ul_end
	addi $v0, $zero, 25
	addi $v1, $zero, 28
	add $t9, $zero, $t0
	j p2s25ul_end  # Skip check jump piece since space is empty for move
	p2s25ulj:
	p2s25ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s25ur_end
	p2s25ur:
	addi $t0, $s1, 29
	lw $t2, 0($t0)
	bne $t2, $zero, p2s25urj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s25ur_end
	addi $v0, $zero, 25
	addi $v1, $zero, 29
	add $t9, $zero, $t0
	j p2s25ur_end  # Skip check jump piece since space is empty for move
	p2s25urj:
	p2s25ur_end:  # End label for moving to next
	p2s25dl:
	addi $t0, $s1, 20
	lw $t2, 0($t0)
	bne $t2, $zero, p2s25dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s25dl_end
	addi $v0, $zero, 25
	addi $v1, $zero, 20
	add $t9, $zero, $t0
	j p2s25dl_end  # Skip check jump piece since space is empty for move
	p2s25dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s25dl_n1
	j p2s25s20_1or3
	p2s25dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s25dl_end
	p2s25s20_1or3:
	addi $t0, $zero, 16
	lw $t3, 0($t0)
	bne $t3, $zero, p2s25dl_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s25dl_end
	addi $v0, $zero, 25
	addi $v1, $zero, 16
	add $t9, $zero, $t0
	p2s25dl_end:  # End label for moving to next
	p2s25dr:
	addi $t0, $s1, 21
	lw $t2, 0($t0)
	bne $t2, $zero, p2s25drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s25dr_end
	addi $v0, $zero, 25
	addi $v1, $zero, 21
	add $t9, $zero, $t0
	j p2s25dr_end  # Skip check jump piece since space is empty for move
	p2s25drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s25dr_n1
	j p2s25s21_1or3
	p2s25dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s25dr_end
	p2s25s21_1or3:
	addi $t0, $zero, 18
	lw $t3, 0($t0)
	bne $t3, $zero, p2s25dr_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s25dr_end
	addi $v0, $zero, 25
	addi $v1, $zero, 18
	add $t9, $zero, $t0
	p2s25dr_end:  # End label for moving to next

	# Space 26
	p2s26:
	addi $t0, $s1, 26
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s26n2
	j p2s26_2or4
	p2s26n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s27
	p2s26_2or4:  # Space 26 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s26ul_end
	p2s26ul:
	addi $t0, $s1, 29
	lw $t2, 0($t0)
	bne $t2, $zero, p2s26ulj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s26ul_end
	addi $v0, $zero, 26
	addi $v1, $zero, 29
	add $t9, $zero, $t0
	j p2s26ul_end  # Skip check jump piece since space is empty for move
	p2s26ulj:
	p2s26ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s26ur_end
	p2s26ur:
	addi $t0, $s1, 30
	lw $t2, 0($t0)
	bne $t2, $zero, p2s26urj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s26ur_end
	addi $v0, $zero, 26
	addi $v1, $zero, 30
	add $t9, $zero, $t0
	j p2s26ur_end  # Skip check jump piece since space is empty for move
	p2s26urj:
	p2s26ur_end:  # End label for moving to next
	p2s26dl:
	addi $t0, $s1, 21
	lw $t2, 0($t0)
	bne $t2, $zero, p2s26dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s26dl_end
	addi $v0, $zero, 26
	addi $v1, $zero, 21
	add $t9, $zero, $t0
	j p2s26dl_end  # Skip check jump piece since space is empty for move
	p2s26dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s26dl_n1
	j p2s26s21_1or3
	p2s26dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s26dl_end
	p2s26s21_1or3:
	addi $t0, $zero, 17
	lw $t3, 0($t0)
	bne $t3, $zero, p2s26dl_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s26dl_end
	addi $v0, $zero, 26
	addi $v1, $zero, 17
	add $t9, $zero, $t0
	p2s26dl_end:  # End label for moving to next
	p2s26dr:
	addi $t0, $s1, 22
	lw $t2, 0($t0)
	bne $t2, $zero, p2s26drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s26dr_end
	addi $v0, $zero, 26
	addi $v1, $zero, 22
	add $t9, $zero, $t0
	j p2s26dr_end  # Skip check jump piece since space is empty for move
	p2s26drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s26dr_n1
	j p2s26s22_1or3
	p2s26dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s26dr_end
	p2s26s22_1or3:
	addi $t0, $zero, 19
	lw $t3, 0($t0)
	bne $t3, $zero, p2s26dr_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s26dr_end
	addi $v0, $zero, 26
	addi $v1, $zero, 19
	add $t9, $zero, $t0
	p2s26dr_end:  # End label for moving to next

	# Space 27
	p2s27:
	addi $t0, $s1, 27
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s27n2
	j p2s27_2or4
	p2s27n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s28
	p2s27_2or4:  # Space 27 is 2 or 4
	addi $t0, $zero, 4
	bne $t1, $t0, p2s27ul_end
	p2s27ul:
	addi $t0, $s1, 30
	lw $t2, 0($t0)
	bne $t2, $zero, p2s27ulj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s27ul_end
	addi $v0, $zero, 27
	addi $v1, $zero, 30
	add $t9, $zero, $t0
	j p2s27ul_end  # Skip check jump piece since space is empty for move
	p2s27ulj:
	p2s27ul_end:  # End label for moving to next
	addi $t0, $zero, 4
	bne $t1, $t0, p2s27ur_end
	p2s27ur:
	addi $t0, $s1, 31
	lw $t2, 0($t0)
	bne $t2, $zero, p2s27urj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s27ur_end
	addi $v0, $zero, 27
	addi $v1, $zero, 31
	add $t9, $zero, $t0
	j p2s27ur_end  # Skip check jump piece since space is empty for move
	p2s27urj:
	p2s27ur_end:  # End label for moving to next
	p2s27dl:
	addi $t0, $s1, 22
	lw $t2, 0($t0)
	bne $t2, $zero, p2s27dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s27dl_end
	addi $v0, $zero, 27
	addi $v1, $zero, 22
	add $t9, $zero, $t0
	j p2s27dl_end  # Skip check jump piece since space is empty for move
	p2s27dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s27dl_n1
	j p2s27s22_1or3
	p2s27dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s27dl_end
	p2s27s22_1or3:
	addi $t0, $zero, 18
	lw $t3, 0($t0)
	bne $t3, $zero, p2s27dl_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s27dl_end
	addi $v0, $zero, 27
	addi $v1, $zero, 18
	add $t9, $zero, $t0
	p2s27dl_end:  # End label for moving to next
	p2s27dr:
	addi $t0, $s1, 23
	lw $t2, 0($t0)
	bne $t2, $zero, p2s27drj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s27dr_end
	addi $v0, $zero, 27
	addi $v1, $zero, 23
	add $t9, $zero, $t0
	j p2s27dr_end  # Skip check jump piece since space is empty for move
	p2s27drj:
	p2s27dr_end:  # End label for moving to next

	# Space 28
	p2s28:
	addi $t0, $s1, 28
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s28n2
	j p2s28_2or4
	p2s28n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s29
	p2s28_2or4:  # Space 28 is 2 or 4
	p2s28dl:
	addi $t0, $s1, 24
	lw $t2, 0($t0)
	bne $t2, $zero, p2s28dlj
	addi $t0, $zero, -3
	blt $t9, $t0, p2s28dl_end
	addi $v0, $zero, 28
	addi $v1, $zero, 24
	add $t9, $zero, $t0
	j p2s28dl_end  # Skip check jump piece since space is empty for move
	p2s28dlj:
	p2s28dl_end:  # End label for moving to next
	p2s28dr:
	addi $t0, $s1, 25
	lw $t2, 0($t0)
	bne $t2, $zero, p2s28drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s28dr_end
	addi $v0, $zero, 28
	addi $v1, $zero, 25
	add $t9, $zero, $t0
	j p2s28dr_end  # Skip check jump piece since space is empty for move
	p2s28drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s28dr_n1
	j p2s28s25_1or3
	p2s28dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s28dr_end
	p2s28s25_1or3:
	addi $t0, $zero, 21
	lw $t3, 0($t0)
	bne $t3, $zero, p2s28dr_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s28dr_end
	addi $v0, $zero, 28
	addi $v1, $zero, 21
	add $t9, $zero, $t0
	p2s28dr_end:  # End label for moving to next

	# Space 29
	p2s29:
	addi $t0, $s1, 29
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s29n2
	j p2s29_2or4
	p2s29n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s30
	p2s29_2or4:  # Space 29 is 2 or 4
	p2s29dl:
	addi $t0, $s1, 25
	lw $t2, 0($t0)
	bne $t2, $zero, p2s29dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s29dl_end
	addi $v0, $zero, 29
	addi $v1, $zero, 25
	add $t9, $zero, $t0
	j p2s29dl_end  # Skip check jump piece since space is empty for move
	p2s29dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s29dl_n1
	j p2s29s25_1or3
	p2s29dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s29dl_end
	p2s29s25_1or3:
	addi $t0, $zero, 20
	lw $t3, 0($t0)
	bne $t3, $zero, p2s29dl_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s29dl_end
	addi $v0, $zero, 29
	addi $v1, $zero, 20
	add $t9, $zero, $t0
	p2s29dl_end:  # End label for moving to next
	p2s29dr:
	addi $t0, $s1, 26
	lw $t2, 0($t0)
	bne $t2, $zero, p2s29drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s29dr_end
	addi $v0, $zero, 29
	addi $v1, $zero, 26
	add $t9, $zero, $t0
	j p2s29dr_end  # Skip check jump piece since space is empty for move
	p2s29drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s29dr_n1
	j p2s29s26_1or3
	p2s29dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s29dr_end
	p2s29s26_1or3:
	addi $t0, $zero, 22
	lw $t3, 0($t0)
	bne $t3, $zero, p2s29dr_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s29dr_end
	addi $v0, $zero, 29
	addi $v1, $zero, 22
	add $t9, $zero, $t0
	p2s29dr_end:  # End label for moving to next

	# Space 30
	p2s30:
	addi $t0, $s1, 30
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s30n2
	j p2s30_2or4
	p2s30n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s31
	p2s30_2or4:  # Space 30 is 2 or 4
	p2s30dl:
	addi $t0, $s1, 26
	lw $t2, 0($t0)
	bne $t2, $zero, p2s30dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s30dl_end
	addi $v0, $zero, 30
	addi $v1, $zero, 26
	add $t9, $zero, $t0
	j p2s30dl_end  # Skip check jump piece since space is empty for move
	p2s30dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s30dl_n1
	j p2s30s26_1or3
	p2s30dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s30dl_end
	p2s30s26_1or3:
	addi $t0, $zero, 21
	lw $t3, 0($t0)
	bne $t3, $zero, p2s30dl_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s30dl_end
	addi $v0, $zero, 30
	addi $v1, $zero, 21
	add $t9, $zero, $t0
	p2s30dl_end:  # End label for moving to next
	p2s30dr:
	addi $t0, $s1, 27
	lw $t2, 0($t0)
	bne $t2, $zero, p2s30drj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s30dr_end
	addi $v0, $zero, 30
	addi $v1, $zero, 27
	add $t9, $zero, $t0
	j p2s30dr_end  # Skip check jump piece since space is empty for move
	p2s30drj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s30dr_n1
	j p2s30s27_1or3
	p2s30dr_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s30dr_end
	p2s30s27_1or3:
	addi $t0, $zero, 23
	lw $t3, 0($t0)
	bne $t3, $zero, p2s30dr_end
	addi $t0, $zero, -4
	blt $t9, $t0, p2s30dr_end
	addi $v0, $zero, 30
	addi $v1, $zero, 23
	add $t9, $zero, $t0
	p2s30dr_end:  # End label for moving to next

	# Space 31
	p2s31:
	addi $t0, $s1, 31
	lw $t1, 0($t0)
	addi $t0, $zero, 2
	bne $t1, $t0, p2s31n2
	j p2s31_2or4
	p2s31n2:
	addi $t0, $zero, 4
	bne $t1, $t0, p2s32
	p2s31_2or4:  # Space 31 is 2 or 4
	p2s31dl:
	addi $t0, $s1, 27
	lw $t2, 0($t0)
	bne $t2, $zero, p2s31dlj
	addi $t0, $zero, -1
	blt $t9, $t0, p2s31dl_end
	addi $v0, $zero, 31
	addi $v1, $zero, 27
	add $t9, $zero, $t0
	j p2s31dl_end  # Skip check jump piece since space is empty for move
	p2s31dlj:
	addi $t0, $zero, 1
	bne $t2, $t0, p2s31dl_n1
	j p2s31s27_1or3
	p2s31dl_n1:
	addi $t0, $zero, 3
	bne $t2, $t0, p2s31dl_end
	p2s31s27_1or3:
	addi $t0, $zero, 22
	lw $t3, 0($t0)
	bne $t3, $zero, p2s31dl_end
	addi $t0, $zero, -2
	blt $t9, $t0, p2s31dl_end
	addi $v0, $zero, 31
	addi $v1, $zero, 22
	add $t9, $zero, $t0
	p2s31dl_end:  # End label for moving to next

	p2s32:

	##### END GENERATED CODE #####

	return_find_move:
	# Collapse stack
	lw $ra, 0($sp)			# $ra = [$sp+0]
	add $sp, $sp, $s2		# Move stack pointer back to original location
	
	jr $ra					# Return

exit:						# Exit program by going to bottom
