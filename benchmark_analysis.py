import re
from collections import defaultdict

# Funct3 values for branch instructions
BRANCH_FUNCT3 = {
    0b000,  # beq
    0b001,  # bne
    0b100,  # blt
    0b101,  # bge
    0b110,  # bltu
    0b111,  # bgeu
}

# Magic instruction hex value
MAGIC_INSTRUCTION_HEX = 0xf0002013

def is_branch_instruction(instruction_hex):
    """
    Check if the instruction is a branch instruction based on its funct3 field.
    """
    # Extract funct3 from the instruction hex
    funct3 = (instruction_hex >> 12) & 0b111  # funct3 is bits 12-14
    opcode = instruction_hex & 0b1111111      # opcode is bits 0-6
    # Opcode for branch instructions in RISC-V is 0b1100011
    return opcode == 0b1100011 and funct3 in BRANCH_FUNCT3

def parse_log_file(file_path):
    """
    Parse the log file and calculate statistics.
    """
    # Initialize counters and data structures
    stats = {
        "branch_taken": 0,
        "branch_not_taken": 0,
        "instruction_counts": defaultdict(int),
        "load_store_dependencies": [],
    }
    log_lines = []
    
    # Read the log file into a list of lines
    with open(file_path, 'r') as file:
        log_lines = file.readlines()
    
    load_store_distances = []

    last_store = {}  # Tracks the last store PC for each memory address
    last_load = {}   # Tracks the last load PC for each memory address
    load_store_distances = []    
    
    # Iterate over log lines and parse
    for i, line in enumerate(log_lines):
        # Extract relevant fields using regex
        match = re.match(
            r'core\s+\d+: \d+ (0x[0-9a-fA-F]+) \((0x[0-9a-fA-F]+)\)(?:\s+(\S+.*))?',
            line
        )
        if not match:
            continue
        
        pc, instruction, changes = match.groups()
        pc = int(pc, 16)
        instruction_hex = int(instruction, 16)

        # print(pc, instruction, changes)
        
        # Skip the magic instruction
        if instruction_hex == MAGIC_INSTRUCTION_HEX:
            print("Magic instruction encountered. Stopping analysis.")
            break
        
        # Update instruction type count
        if changes:
            if "mem" in changes:
                if re.match(r"mem\s+0x[0-9a-fA-F]+\s+0x[0-9a-fA-F]+", changes):
                    # Store instruction
                    stats["instruction_counts"]["store"] += 1
                    mem_match = re.search(r"mem\s+(0x[0-9a-fA-F]+)", changes)
                    if mem_match:
                        mem_address = int(mem_match.group(1), 16)
                        # Dependency with the previous store
                        if mem_address in last_store:
                            distance = pc - last_store[mem_address]
                            load_store_distances.append(distance)
                        # Dependency with the previous load (WAR)
                        if mem_address in last_load:
                            distance = pc - last_load[mem_address]
                            load_store_distances.append(distance)
                        # Update last_store
                        last_store[mem_address] = pc
                elif re.match(r"x\d+\s+0x[0-9a-fA-F]+\s+mem\s+0x[0-9a-fA-F]+", changes):
                    # Load instruction
                    stats["instruction_counts"]["load"] += 1
                    mem_match = re.search(r"mem\s+(0x[0-9a-fA-F]+)", changes)
                    if mem_match:
                        mem_address = int(mem_match.group(1), 16)
                        # Dependency with the previous store (RAW)
                        if mem_address in last_store:
                            distance = pc - last_store[mem_address]
                            load_store_distances.append(distance)
                        # Update last_load
                        last_load[mem_address] = pc
            else:
                stats["instruction_counts"]["arithmetic"] += 1
        # else:
        #     stats["instruction_counts"]["branch"] += 1
        
        # Handle branch statistics only for branch instructions
        if is_branch_instruction(instruction_hex) and i + 1 < len(log_lines):
            # Get the PC of the next instruction
            stats["instruction_counts"]["branch"] += 1
            next_match = re.match(
                r'core\s+\d+: \d+ (0x[0-9a-fA-F]+)',
                log_lines[i + 1]
            )
            if next_match:
                next_pc = int(next_match.group(1), 16)
                if next_pc != pc + 4:
                    # print("Br taken")
                    stats["branch_taken"] += 1
                else:
                    # print("Br not taken")
                    stats["branch_not_taken"] += 1
        
        # # Handle dependencies and distances
        # if changes and "mem" in changes:
        #     mem_match = re.search(r"mem\s+(0x[0-9a-fA-F]+)", changes)
        #     if mem_match:
        #         mem_address = int(mem_match.group(1), 16)
        #         if mem_address in dependent_load_store:
        #             distance = pc - dependent_load_store[mem_address]
        #             load_store_distances.append(distance)
        #         dependent_load_store[mem_address] = pc
        
        last_commit_pc = pc
        # print("--------")
    
    # Calculate average distance
    avg_distance = sum(load_store_distances) / len(load_store_distances) if load_store_distances else 0
    stats["avg_load_store_distance"] = avg_distance
    
    return stats


def print_statistics(stats):
    """
    Print the calculated statistics.
    """
    print("Branch Statistics:")
    total_branches = stats["branch_taken"] + stats["branch_not_taken"]
    print(f"Total branches: {total_branches}")
    
    if (total_branches == 0):
        print("  No branches")
    else:
        print(f"  Branch Taken: {stats['branch_taken']} ({(stats['branch_taken'] / total_branches * 100):.2f}%)")
        print(f"  Branch Not Taken: {stats['branch_not_taken']} ({(stats['branch_not_taken'] / total_branches * 100):.2f}%)")
    
    print("\nInstruction Type Percentages:")
    total_instructions = sum(stats["instruction_counts"].values())
    for instr_type, count in stats["instruction_counts"].items():
        percentage = (count / total_instructions) * 100
        print(f"  {instr_type.capitalize()}: {count} ({percentage:.2f}%)")
    
    print(f"\nAverage Distance Between Dependent Loads/Stores: {stats['avg_load_store_distance']:.2f}")


if __name__ == "__main__":
    # Path to the log file
    log_file_path = "/home/ribhavs2/ece_411_complete/mp_411_new_proj/fa24_ece411_TLB_Flushers/mp_ooo/sim/spike/spike.log"
    
    # Parse the log file
    statistics = parse_log_file(log_file_path)
    
    # Print the statistics
    print_statistics(statistics)
