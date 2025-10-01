.section .text
.globl _start
_start:
    # Load base address into x1
    lui x1, 0x1eceb
    addi x1, x1, 0x100

    # Initialize values in registers
    addi x2, x0, 50         # x2 = 50
    addi x3, x0, 50         # x3 = 50

    # First branch
    beq x2, x3, first_branch_taken # x2 == x3, should branch

    # If first branch not taken, store 0x0
    sw x0, 0(x1)

first_branch_taken:
    # Second branch (dependent on first branch result)
    addi x4, x0, 25
    bne x2, x4, second_branch_taken # x2 != x4, should branch

    # If second branch not taken, store 0x0
    sw x0, 4(x1)

second_branch_taken:
    # If second branch taken, store 0x1
    addi x5, x0, 1
    sw x5, 8(x1)

    # Magic instruction to end the simulation
    slti x0, x0, -256
