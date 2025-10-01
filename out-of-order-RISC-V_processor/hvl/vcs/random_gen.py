import random

# Instruction types
reg_imm_instructions = [
    'addi', 'andi', 'ori', 'xori', 'slti', 'sltiu', 'slli', 'srli', 'srai'
]

reg_reg_instructions = [
    'add', 'sub', 'and', 'or', 'xor', 'sll', 'srl', 'sra', 'slt', 'sltu'
]

load_instructions = ['lb', 'lh', 'lw', 'lbu', 'lhu']

lui_instruction = ['lui']

mul_div_instructions = [
    'mul', 'mulh', 'mulhsu', 'mulhu', 'div', 'divu', 'rem', 'remu'
]

# Exclude registers x5, x10, x11
excluded_registers = [5, 10, 11]
registers = [f'x{i}' for i in range(32) if i not in excluded_registers]

# Memory parameters
memory_start = 0x1ECEB000
memory_length = memory_start + 0xE1315000
memory_end = memory_start + memory_length

# Adjust base address to allow for offset range
# Set x1 to the middle of the memory range
base_address = memory_start + (memory_length // 2)
upper_20_bits = base_address >> 12  # Upper 20 bits
lower_12_bits = base_address & 0xFFF  # Lower 12 bits

# Adjust lower_12_bits and upper_20_bits if lower_12_bits >= 2048
if lower_12_bits >= 2048:
    upper_20_bits += 1
    lower_12_bits -= 4096

def random_immediate():
    # Immediate values for I-type instructions (-2048 to 2047)
    return random.randint(-2048, 2047)

def random_unsigned_immediate():
    # Unsigned immediate values (0 to 4095)
    return random.randint(0, 4095)

def random_shift_amount():
    # Shift amounts for shift instructions (0 to 31)
    return random.randint(0, 31)

def generate_random_offset(instr):
    # Immediate offset for load instructions (-2048 to 2047)
    # Adjusted to ensure effective address is within valid memory range
    max_positive_offset = min(2047, memory_end - base_address - 1)
    max_negative_offset = max(-2048, memory_start - base_address)
    if instr == 'lw':
        # Word-aligned offsets
        max_pos = (max_positive_offset // 4) * 4
        max_neg = (max_negative_offset // 4) * 4
        offset = random.choice(range(max_neg, max_pos + 1, 4))
    elif instr in ['lh', 'lhu']:
        # Halfword-aligned offsets
        max_pos = (max_positive_offset // 2) * 2
        max_neg = (max_negative_offset // 2) * 2
        offset = random.choice(range(max_neg, max_pos + 1, 2))
    else:
        # Byte-aligned offsets
        offset = random.randint(max_negative_offset, max_positive_offset)
    return offset

def generate_random_reg_imm_instruction():
    instr = random.choice(reg_imm_instructions)
    rd = random.choice([reg for reg in registers if reg != 'x0'])  # x0 cannot be the destination
    rs1 = random.choice(registers)
    if instr in ['slli', 'srli', 'srai']:
        # Shift instructions use a 5-bit immediate
        imm = random_shift_amount()
    else:
        imm = random_immediate()
    return f'    {instr} {rd}, {rs1}, {imm}'

def generate_random_reg_reg_instruction():
    instr = random.choice(reg_reg_instructions)
    rd = random.choice([reg for reg in registers if reg != 'x0'])
    rs1 = random.choice(registers)
    rs2 = random.choice(registers)
    return f'    {instr} {rd}, {rs1}, {rs2}'

def generate_random_load_instruction():
    instr = random.choice(load_instructions)
    rd = random.choice([reg for reg in registers if reg != 'x0'])
    rs1 = 'x1'  # Use x1 as the base register for all load instructions
    offset = generate_random_offset(instr)
    return f'    {instr} {rd}, {offset}({rs1})'

def generate_random_lui_instruction():
    rd = random.choice([reg for reg in registers if reg != 'x0'])
    imm = random.randint(0, 0xFFFFF)  # 20-bit immediate
    return f'    lui {rd}, 0x{imm:X}'

def generate_random_mul_div_instruction():
    instr = random.choice(mul_div_instructions)
    rd = random.choice([reg for reg in registers if reg != 'x0'])
    rs1 = random.choice(registers)
    rs2 = random.choice(registers)
    return f'    {instr} {rd}, {rs1}, {rs2}'

def generate_random_instruction():
    instruction_type = random.choice([
        'reg_imm', 'reg_reg', 'load', 'lui', 'mul_div'
    ])
    if instruction_type == 'reg_imm':
        return generate_random_reg_imm_instruction()
    elif instruction_type == 'reg_reg':
        return generate_random_reg_reg_instruction()
    elif instruction_type == 'load':
        return generate_random_load_instruction()
    elif instruction_type == 'lui':
        return generate_random_lui_instruction()
    elif instruction_type == 'mul_div':
        return generate_random_mul_div_instruction()

def main():
    print('.section .text')
    print('.globl _start')
    print('_start:\n')

    # Load the adjusted base address into x1
    print('    # Load the base address into x1')
    print(f'    lui x1, 0x1eceb          # Load upper 20 bits into x1')
    print(f'    addi x1, x1, 0x100        # Add lower 12 bits to x1\n')

    # Number of random instructions to generate
    num_instructions = 1000

    for _ in range(num_instructions):
        instr = generate_random_instruction()
        print(instr)

    # Magic instruction to end the simulation
    print('\n    # Magic instruction to end the simulation')
    print('    slti x0, x0, -256')

if __name__ == '__main__':
    main()
