    .section .text
    .globl _start
_start:
    # Initialize register x1 with a value
    addi x1, x0, 10        # x1 = 0 + 10 = 10

    # nop                    # NOPs to prevent hazards
    # nop
    # nop
    # nop
    # nop

    # Store the value in x1 into memory address 0x1eceb100
    # lui x3, 0x1eceb        # Load upper immediate for address 0x1eceb000

    # nop                    # NOPs to prevent hazards
    # nop
    # nop
    # nop
    # nop

    add x2, x1, x0     # Adjust address to 0x1eceb100
    add x3, x2, x1
    add x4, x3, x1
    add x5, x4, x1
    add x6, x5, x4
    add x7, x6, x1
    add x8, x3, x2
    add x9, x7, x8


    mul x3, x1, x2

    # these instructions should  resolve before the multiply
    add x4, x3, x6
    xor x7, x8, x9
    sll x10, x11, x12
    and x13, x14, x15

    div x3, x5, x2
    
    add x7, x6, x1
    add x8, x3, x2
    add x9, x7, x8


    
    nop
    nop
    nop
    nop
    nop
    nop

    # this should take many cycles
    # if this writes back to the ROB after the following instructions, you get credit for CP2
    mul x3, x1, x2

    # these instructions should  resolve before the multiply
    add x4, x5, x6
    xor x7, x8, x9
    sll x10, x11, x12
    and x13, x14, x15

    halt:
        slti x0, x0, -256
  


    # nop                    # NOPs to prevent hazards
    # nop
    # nop
    # nop
    # nop

    # sw x1, 0(x3)           # Store word: MEM[0x1eceb100] = x1

    # nop                    # NOPs to prevent hazards
    # nop
    # nop
    # nop
    # nop
    # End simulation
    # slti x0, x0, -256      # Magic instruction to end the simulation
