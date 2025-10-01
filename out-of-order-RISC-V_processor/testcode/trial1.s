.section .text
.globl _start
_start:
    # Test addi with positive and negative immediate values
    addi x1, x0, 1024     # x1 = 1024
    nop                   # Prevent hazard
    nop                   # Prevent hazard
    nop                   # Prevent hazard
    nop                   # Prevent hazard
    addi x2, x1, -1024    # x2 = 0 (1024 - 1024)

    nop                   # Prevent hazard
    nop                   # Prevent hazard
    nop                   # Prevent hazard
    nop                   # Prevent hazard
    
    # Test bitwise AND with immediate values
    andi x3, x2, 255      # x3 = 0 & 255 = 0
    nop                   # Prevent hazard
    nop                   # Prevent hazard
    nop                   # Prevent hazard
    nop                   # Prevent hazard
    addi x4, x3, -1       # x4 = -1

    # Magic instruction to end the simulation
    slti x0, x0, -256
