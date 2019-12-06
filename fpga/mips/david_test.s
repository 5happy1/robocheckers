loop:
	addi $28, $26, 0
	sll $28, $28, 5
	j loop

addi $28, $0, 13
sll $28, $28, 5