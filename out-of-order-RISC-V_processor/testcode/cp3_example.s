# .section .text
# .globl _start
# _start:

#     # Load a base address into x1
#     lui x1, 0x1eceb          # Load upper 20 bits of 0x1eceb100 into x1
#     addi x1, x1, 0x100       # x1 = 0x1eceb100
 
#     # Store a value in memory
#     addi x2, x0, 42          # x2 = 42
#     # sw x2, 0(x1)             # Store x2 at address x1

#     # Load-Use hazard test (loading and using value in next instruction)
#     lw x4, 0(x1)
#     lb x3, 0(x1)             # Load word from memory into x3 (should load 42)
#     # add x4, x3, x2           # x4 = x3 + x2 = 42 + 42 = 84 (Load-Use hazard, stall or forward)

#     lhu x6, 4(x1)
#     lbu x8, 4(x1)

#     lh x9, 8(x1)

#     xor x4, x3, x2
#     xor x4, x4, x4
#     xor x4, x2, x4

#     # Store result in memory
#     # sw x4, 4(x1)             # Store x4 = 84 at address x1 + 4

#     # Magic instruction to end the simulation
#     slti x0, x0, -256

.section .text
.globl _start
_start:

    # Load a base address into x1
    lui x1, 0x1eceb          # Load upper 20 bits of 0x1eceb100 into x1
    addi x1, x1, 0x100       # x1 = 0x1eceb100
 
    # Store a value in memory
    addi x2, x0, 42          # x2 = 42
    sw x2, 0(x1)             # Store x2 at address x1

    # Load-Use hazard test (loading and using value in next instruction)
    lw x4, 0(x1)
    lw x3, 0(x1)             # Load word from memory into x3 (should load 42)
    # add x4, x3, x2           # x4 = x3 + x2 = 42 + 42 = 84 (Load-Use hazard, stall or forward)
    xor x4, x3, x2
    xor x4, x4, x4
    xor x4, x2, x4

    # Store result in memory
    sw x4, 4(x1)             # Store x4 = 84 at address x1 + 4
    sb x4, 8(x1)             # Store x4 = 84 at address x1 + 4
    sh x4, 16(x1)             # Store x4 = 84 at address x1 + 4

    # Magic instruction to end the simulation
    slti x0, x0, -256