package rv32i_types;

    localparam DATA_WIDTH = 64;
    localparam QUEUE_DEPTH = 16; 
    localparam DATA_WIDTH_FL = 6;
    localparam QUEUE_DEPTH_FL = 32;
    localparam DATA_WIDTH_ROB = 12;
    localparam QUEUE_DEPTH_ROB = 16;
    localparam RES_ADD_ENTRIES = 5;
    localparam RES_DIV_ENTRIES = 5;
    localparam RES_MUL_ENTRIES = 5;
    localparam RES_LS_ENTRIES = 5;
    localparam LHT_LENGTH = 6;   
    localparam PHT_LENGTH = 11;
    localparam GHR_LENGTH = 6;


    // Pipeline struct
    typedef struct packed {
        // logic   [31:0]      inst;
        logic   [3:0]       addr_reg;
        logic   [3:0]       rmask_reg;
        logic   [3:0]       wmask_reg;       
        logic [31:0]        wdata_reg;
        logic [22:0]        tag_reg;
        logic [4:0]         offset_reg;
        logic               commit_reg;
        
    } pipeline_reg_t;


    typedef enum logic [1:0] {
        idle = 2'b0,
        clean_miss = 2'b01,
        dirty_miss = 2'b10
    } fsm_bhai_t;

    typedef enum logic [1:0] {
        idle_cache = 2'b0,
        bursting = 2'b01,
        done = 2'b10
    } cache_adapter_t;

    typedef enum logic [1:0] {
        idle_arbiter = 2'b00,
        i_cache = 2'b01,
        d_cache = 2'b10 
    } arbiter_t;

    typedef enum logic {
        rs1_out = 1'b0,
        pc_out  = 1'b1
    } alu_m1_sel_t;

    typedef enum logic {
        imm_out = 1'b0,
        rs2_out = 1'b1
    } alu_m2_sel_t;
    
    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic   [31:0]      pc_next;
        logic   [4:0]       rs1_s;
        logic   [4:0]       rs2_s;
        logic   [4:0]       rd_s;
        logic   [31:0]      imm_gen;
        logic   [6:0]       opcode;
        logic   [2:0]       aluop;
        logic   [2:0]       cmpop;
        logic   [2:0]       funct3;
        logic   [6:0]       funct7;
        alu_m1_sel_t        alu_m1_sel;
        alu_m2_sel_t        alu_m2_sel;

        // RVFI
        logic   [31:0]      rs1_rdata;
        logic   [31:0]      rs2_rdata;
        logic   [31:0]      rd_wdata;
        logic   [31:0]      order;
        
    } id_ex_stage_reg_t;


    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic   [31:0]      pc_next;
        logic   [4:0]       rs1_s;
        logic   [4:0]       rs2_s;
        logic   [4:0]       rd_s;     

        logic   [31:0]      rs1_rdata;
        logic   [31:0]      rs2_rdata;
        logic   [31:0]      rd_wdata;
        logic   [31:0]      order; 

        logic   [31:0]      mem_addr;
        logic   [3:0]       mem_rmask;
        logic   [3:0]       mem_wmask;
        logic   [31:0]      mem_rdata;
        logic   [31:0]      mem_wdata;

    } rvfi_t;

    typedef struct packed {
        logic [LHT_LENGTH-1:0] lht_index;
        logic [PHT_LENGTH-1:0] pht_index;
        logic [1:0] b_counter;
    } predictor_t;

    typedef struct packed {
        logic [GHR_LENGTH-1:0] ghr;
        logic [1:0] b_counter_gshare;
        logic [GHR_LENGTH-1:0] pht_index;
        logic [31:0] pc;
    } predictor_gshare_t;

    typedef struct packed {
        logic final_prediction;
        logic [31:0] pc;
        logic branch_used;
    }  tournament_t;  

    typedef struct packed {

        logic [$clog2(QUEUE_DEPTH_ROB)-1:0] rob_entry_res;
        logic [5:0] ps1_res;
        logic       ps1_v_res;
        logic [5:0] ps2_res;
        logic       ps2_v_res;
        logic [5:0] pd_res;
        logic [4:0] rd_res;
        id_ex_stage_reg_t decode_packet;

        predictor_t branch_pred;
        predictor_gshare_t branch_pred_gshare;
        tournament_t tournament_predictor;

    } reservation_station_t;

    typedef struct packed {

        // logic [2:0] rob_entry_res;
        logic [5:0] ps1_res;
        logic       ps1_v_res;
        logic [5:0] ps2_res;
        logic       ps2_v_res;
        logic [5:0] pd_res;
        // logic [4:0] rd_res;
        id_ex_stage_reg_t decode_packet;
        logic [2:0] lsq_entry_res;

    } reservation_station_ls_t;

    typedef struct packed {

        logic [$clog2(QUEUE_DEPTH_ROB)-1:0] rob_entry_res;
        logic [5:0] phys_reg;
        logic [4:0] arch_reg;
        logic [31:0] result;
        logic regf_we;
        logic flush_rob;
        logic [31:0] address_br;
    } cdb_t;

    typedef struct packed {

        logic rob_commit;
        logic [4:0] rd_rob;
        logic [5:0] pd_rob;
        logic       flush_rob;
        logic [31:0] order_br;
        logic [31:0] pc_br;
        // id_ex_stage_reg_t decode_packet;
        logic [6:0] opcode_b_pred;
        rvfi_t rvfi_packet;

        predictor_t branch_pred;
        predictor_gshare_t branch_pred_gshare;
        tournament_t tournament_pred;
    } rob_t;

    typedef struct packed {

        logic lsq_commit;
        logic [4:0] rd_lsq;
        logic [31:0] address_lsq;
        logic [5:0] pd_lsq;
        logic [31:0] ps2_val_to_lsq;
        logic [31:0] ps1_val_to_lsq;
        logic [$clog2(QUEUE_DEPTH_ROB)-1:0] rob_entry_res;
        // id_ex_stage_reg_t decode_packet;
        // logic   [2:0]       funct3;
        rvfi_t rvfi_packet;
    } lsq_t;

    typedef struct packed {
        logic valid;
        logic [31:0] data;
        logic [31:0] addr;
        logic [3:0] wmask;
    } pcsb_t;


    typedef enum logic [1:0] {
        IDLE = 2'b00,
        READ_LHT = 2'b01,
        READ_PHT = 2'b10,
        WRITE = 2'b11
    } arbiter_pred_t;

    // arbiter_pred_t state;


    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] pc_next;
        logic [31:0] instruction;
        predictor_t branch_pred;
        predictor_gshare_t branch_pred_gshare;
        tournament_t tournament_pred;
    } instr_fifo_t;    

    typedef enum logic [6:0] {
        op_b_lui       = 7'b0110111, // load upper immediate (U type)
        op_b_auipc     = 7'b0010111, // add upper immediate PC (U type)
        op_b_jal       = 7'b1101111, // jump and link (J type)
        op_b_jalr      = 7'b1100111, // jump and link register (I type)
        op_b_br        = 7'b1100011, // branch (B type)
        op_b_load      = 7'b0000011, // load (I type)
        op_b_store     = 7'b0100011, // store (S type)
        op_b_imm       = 7'b0010011, // arith ops with register/immediate operands (I type)
        op_b_reg       = 7'b0110011  // arith ops with register operands (R type)
    } rv32i_opcode;

    typedef enum logic [2:0] {
        arith_f3_add   = 3'b000, // check logic 30 for sub if op_reg op
        arith_f3_sll   = 3'b001,
        arith_f3_slt   = 3'b010,
        arith_f3_sltu  = 3'b011,
        arith_f3_xor   = 3'b100,
        arith_f3_sr    = 3'b101, // check logic 30 for logical/arithmetic
        arith_f3_or    = 3'b110,
        arith_f3_and   = 3'b111
        // mul_f3         = 3'b000, // funct3 for MUL in RV32M (same as ADD but with different funct7)
        // div_f3         = 3'b100, // funct3 for DIV in RV32M
        // rem_f3         = 3'b110  // funct3 for REM in RV32M
    } arith_f3_t;

    typedef enum logic [2:0] {
        load_f3_lb     = 3'b000,
        load_f3_lh     = 3'b001,
        load_f3_lw     = 3'b010,
        load_f3_lbu    = 3'b100,
        load_f3_lhu    = 3'b101
    } load_f3_t;

    typedef enum logic [2:0] {
        store_f3_sb    = 3'b000,
        store_f3_sh    = 3'b001,
        store_f3_sw    = 3'b010
    } store_f3_t;

    typedef enum logic [2:0] {
        branch_f3_beq  = 3'b000,
        branch_f3_bne  = 3'b001,
        branch_f3_blt  = 3'b100,
        branch_f3_bge  = 3'b101,
        branch_f3_bltu = 3'b110,
        branch_f3_bgeu = 3'b111
    } branch_f3_t;

    typedef enum logic [2:0] {
        alu_op_add     = 3'b000,
        alu_op_sll     = 3'b001,
        alu_op_sra     = 3'b010,
        alu_op_sub     = 3'b011,
        alu_op_xor     = 3'b100,
        alu_op_srl     = 3'b101,
        alu_op_or      = 3'b110,
        alu_op_and     = 3'b111
    } alu_ops;

    typedef enum logic [6:0] {
        base           = 7'b0000000,
        variant        = 7'b0100000,
        extension_var  = 7'b0000001
        // mul_funct7     = 7'b0000001, // funct7 for MUL instructions in RV32M
        // divrem_funct7  = 7'b0000001  // funct7 for DIV/REM instructions in RV32M
    } funct7_t;

    typedef union packed {
        logic [31:0] word;

        struct packed {
            logic [11:0] i_imm;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } i_type;

        struct packed {
            logic [6:0]  funct7;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } r_type;

        struct packed {
            logic [11:5] imm_s_top;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  imm_s_bot;
            rv32i_opcode opcode;
        } s_type;


        struct packed {
            logic [6:0] imm_t_top;
            logic [4:0] rs2;
            logic [4:0] rs1;
            logic [2:0] funct3;
            logic [4:0] imm_t_bot;
            rv32i_opcode opcode;
        } b_type;

        struct packed {
            logic [31:12] imm;
            logic [4:0]   rd;
            rv32i_opcode  opcode;
        } j_type;

    } instr_t;

endpackage
