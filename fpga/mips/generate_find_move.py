# Generates MIPS code for basic find_move function in checkers

def space(p, i):
    """
    Begin space by making sure piece is player's

    :param p: player (1 or 2)
    :param i: space (0 to 31)

    :return: string of MIPS code to begin space checking
    """
    s = f""
    # Start of space analysis
    s += f"\n# Space {i}\n"  # Initial comment
    s += f"p{p}s{i}:\n"

    # Load piece from memory into $t1
    s += f"addi $t0, $s1, {i}\n"
    s += f"lw $t1, 0($t0)\n"

    # Check if space is player's piece
    s += f"addi $t0, $zero, {p}\n"
    s += f"bne $t1, $t0, p{p}s{i}n{p}\n"  # Branch if != piece, check king
    s += f"j p{p}s{i}_{p}or{p+2}\n"
    s += f"p{p}s{i}n{p}:\n"
    s += f"addi $t0, $zero, {p+2}\n"
    s += f"bne $t1, $t0, p{p}s{i+1}\n"  # Branch if != king, go to next space
    s += f"p{p}s{i}_{p}or{p+2}:  # Space {i} is {p} or {p+2}\n"

    return s

def check_king(p, i, mo, d):
    """
    MIPS code to check if king, if needed

    :param p: player (1 or 2)
    :param i: space (0 or 31)
    :param mo: move offset, so i+mo = adjacent space piece is moving towards
    :param d: string that is direction of motion for making move commands
              in (ul, ur, dl, dr) for up left, up right, down left, down right

    :return: string of MIPS code to check king, if needed
    """
    s = f""

    if p == 1 and mo > 0 or p == 2 and mo < 0:
        # If moving in correct direction for player, no need to check for king
        return s

    s += f"addi $t0, $zero, {p+2}\n"
    s += f"bne $t1, $t0, p{p}s{i}{d}_end\n"  # Branch if != king, go to next dir

    return s

def move(p, i, mo, d):
    """
    :param p: player (1 or 2)
    :param i: space (0 to 31)
    :param mo: move offset, so i+mo = space enemy piece is in
    :param d: string that is direction of motion for making move commands
              in (ul, ur, dl, dr) for up left, up right, down left, down right

    :return: string of MIPS code to check for move
    """
    s = f""
    s += f"p{p}s{i}{d}:\n"

    # Load space to move to
    s += f"addi $t0, $s1, {i+mo}\n"
    s += f"lw $t2, 0($t0)\n"

    # Check if empty
    s += f"bne $t2, $zero, p{p}s{i}{d}j\n"

    # Move and score if yes
    s += f"addi $t0, $zero, {score(p, i+mo, 'm')}\n"
    s += f"blt $t{0 if p == 1 else 9}, $t{9 if p == 1 else 0}, p{p}s{i}{d}_end\n"
    s += f"addi $v0, $zero, {i}\n"
    s += f"addi $v1, $zero, {i+mo}\n"
    s += f"addi $t9, $zero, $t0\n"
    s += f"j p{p}s{i}{d}_end  # Skip check jump piece since space is empty for move\n"
    
    return s

def jump(p, e, i, mo, jo, d):
    """
    :param p: player (1 or 2)
    :param e: enemy (1 or 2, opposite player)
    :param i: space (0 to 31)
    :param mo: move offset, so i+mo = space enemy piece is in
    :param jo: jump offset, so i+jo = space to try to jump to
    :param d: string that is direction of motion for making move commands
              in (ul, ur, dl, dr) for up left, up right, down left, down right

    :return: string of MIPS code to check for jump
    """
    # TODO: add checks for kings
    s = f""
    # Check if space to jump over is enemy piece
    s += f"addi $t0, $zero, {e}\n"
    s += f"bne $t2, $t0, p{p}s{i}n{e}\n"  # Branch if != enemy piece, check king
    s += f"j p{p}s{i}s{i+mo}_{e}or{e+2}\n"
    s += f"p{p}s{i}n{e}:\n"
    s += f"addi $t0, $zero, {e+2}\n"
    s += f"bne $t2, $t0, p{p}s{i}{d}_end\n"  # Branch if != king, go to next space
    s += f"p{p}s{i}s{i+mo}_{e}or{e+2}:\n"
    s += f"addi $t0, $zero, {i+jo}\n"
    s += f"lw $t3, 0($t0)\n"
    s += f"bne $t3, $zero, p{p}s{i}{d}_end\n"  # Branch if jump to space is not empty
    s += f"addi $t0, $zero, {score(p, i+jo, 'j')}\n"
    s += f"blt $t{0 if p == 1 else 9}, $t{9 if p == 1 else 0}, p{p}s{i}{d}_end\n"
    s += f"addi $v0, $zero, {i}\n"
    s += f"addi $v1, $zero, {i+jo}\n"
    s += f"addi $t9, $zero, $t0\n"
    return s

def movejump(p, e, i, mo, jo, d, r, c):
    """
    :param p: player (1 or 2)
    :param e: enemy (1 or 2, opposite player)
    :param i: space (0 to 31)
    :param mo: move offset, so i+mo = space enemy piece is in
    :param jo: jump offset, so i+jo = space to try to jump to
    :param d: string that is direction of motion for making move commands
              in (ul, ur, dl, dr) for up left, up right, down left, down right
    :param r: row of i on checker board, 1-indexed
    :param c: col of i on checker board, 1-indexed

    :return: string of MIPS code to check for kings, move, and jump
    """
    s = f""

    # Return if piece is on edge of board and trying to move off
    if (
        c == 1 and 'l' in d  # Moving left while in left column
        or
        c == 8 and 'r' in d  # Moving right while in right column
        or 
        r == 1 and 'd' in d  # Moving down while in bottom row
        or 
        r == 8 and 'u' in d  # Moving up while in top row
    ):
        return s

    s += check_king(p, i, mo, d)
    s += move(p, i, mo, d)
    s += f"p{p}s{i}{d}j:\n"

    # Only try jumping if piece is not too close to edge of board for jump
    if not (
        c <= 2 and 'l' in d  # Jumping left while next to left column
        or
        c >= 7 and 'r' in d  # Jumping right while next to right column
        or 
        r <= 2 and 'd' in d  # Jumping down while next to bottom row
        or 
        r >= 7 and 'u' in d  # Jumping up while next to top row
    ):
        s += jump(p, e, i, mo, jo, d)

    s += f"p{p}s{i}{d}_end:  # End label for moving to next\n"

    return s

def rowcol(i):
    """
    :param i: board space (0 to 31)
    :return: (r, c) - row and column, 1-indexed as on a checkerboard
    """
    r = i // 4 + 1  # Row numbering based on checker board, 1-indexed
    c = (i % 4) * 2 + 2 - r % 2  # Columns are 1-indexed also
    return r, c

def score(p, i, mj):
    """
    :param p: player (1 or 2)
    :param i: space to move/jump to (0 to 31)
    :param mj: 'm' or 'j' for move or jump

    :return: (int) move score
    """
    scores = {
        'NEUTRAL': 0,
        'MOVE': 1,
        'JUMP': 2,
        'MOVE_SIDE': 3,
        'JUMP_SIDE': 4,
        'MOVE_KING': 5,
        'JUMP_KING': 6
    }

    # Score multiplier
    sm = -1 if p == 2 else 1
    for k in scores:
        scores[k] *= sm

    r, c = rowcol(i)

    if p == 1 and r == 8 or p == 2 and r == 1:
        return scores['JUMP_KING'] if mj == 'j' else scores['MOVE_KING']
    if c == 1 or c == 8 or r == 1 or r == 8:
        return scores['JUMP_SIDE'] if mj == 'j' else scores['MOVE_SIDE']
    return scores['JUMP'] if mj == 'j' else scores['MOVE']

def main():
    p = 2  # Only player 2 for now
    e = 1  # Enemy is player 1
    s = f""  # Output string

    for i in range(0, 32):
        r, c = rowcol(i)

        # Set diagonal offsets, assuming even-numbered row, subtract 1 if odd
        # Second number of each tuple is for jump
        d = {
            'ul': (4 - r % 2, 7),  # up left
            'ur': (5 - r % 2, 9),  # up right
            'dl': (-4 - r % 2, -9),  # down left
            'dr': (-3 - r % 2, -7)  # down right
        }

        s += space(p, i)

        for k, v in d.items():
            s += movejump(p, e, i, v[0], v[1], k, r, c)

    s += f"\np2s32:\n"

    # Print final code
    print(s)


if __name__ == '__main__':
    main()
