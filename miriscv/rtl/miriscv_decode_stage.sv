/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

module miriscv_decode_stage
  import miriscv_pkg::XLEN;
  import miriscv_pkg::ILEN;
  import miriscv_gpr_pkg::GPR_ADDR_W;
  import miriscv_alu_pkg::ALU_OP_W;
  import miriscv_mdu_pkg::MDU_OP_W;
  import miriscv_lsu_pkg::MEM_ACCESS_W;
  import miriscv_decode_pkg::*;
#(
  parameter bit RVFI = 1'b0
) (
  // Clock, reset
  input  logic                    clk_i,
  input  logic                    arstn_i,

  // Control unit
  input  logic                    cu_kill_d_i,
  input  logic                    cu_stall_d_i,
  input  logic                    cu_stall_f_i,
  output logic                    d_stall_req_o,

  output logic                    d_taken_o,
  output logic [XLEN-1:0]         d_target_o,

  // From Fetch
  input  logic [ILEN-1:0]         f_instr_i,
  input  logic [XLEN-1:0]         f_current_pc_i,
  input  logic [XLEN-1:0]         f_next_pc_i,
  input  logic                    f_valid_i,

  input  logic                    m_gpr_wr_en_i,
  input  logic [XLEN-1:0]         m_gpr_wr_data_i,
  input  logic [GPR_ADDR_W-1:0]   m_gpr_wr_addr_i,

  output logic                    d_valid_o,

  output logic [XLEN-1:0]         d_op1_o,
  output logic [XLEN-1:0]         d_op2_o,

  output logic [ALU_OP_W-1:0]     d_alu_operation_o,
  output logic                    d_mdu_req_o,
  output logic [MDU_OP_W-1:0]     d_mdu_operation_o,

  output logic                    d_mem_req_o,

  output logic                    d_mem_we_o,
  output logic [MEM_ACCESS_W-1:0] d_mem_size_o,
  output logic [XLEN-1:0]         d_mem_addr_o,
  output logic [XLEN-1:0]         d_mem_data_o,

  output logic                    d_gpr_wr_en_o,
  output logic [GPR_ADDR_W-1:0]   d_gpr_wr_addr_o,
  output logic [WB_SRC_W-1:0]     d_gpr_src_sel_o,

  output logic                    d_branch_o,
  output logic                    d_jal_o,
  output logic                    d_jalr_o,
  output logic [XLEN-1:0]         d_target_pc_o,
  output logic [XLEN-1:0]         d_next_pc_o,
  output logic                    d_prediction_o,
  output logic                    d_br_j_taken_o,

  output logic [GPR_ADDR_W-1:0]   f_cu_rs1_addr_o,
  output logic                    f_cu_rs1_req_o,
  output logic [GPR_ADDR_W-1:0]   f_cu_rs2_addr_o,
  output logic                    f_cu_rs2_req_o,

  // RVFI
  output logic                    d_rvfi_wb_we_o,
  output logic [GPR_ADDR_W-1:0]   d_rvfi_wb_rd_addr_o,
  output logic [ILEN-1:0]         d_rvfi_instr_o,
  output logic [GPR_ADDR_W-1:0]   d_rvfi_rs1_addr_o,
  output logic [GPR_ADDR_W-1:0]   d_rvfi_rs2_addr_o,
  output logic                    d_rvfi_op1_gpr_o,
  output logic                    d_rvfi_op2_gpr_o,
  output logic [XLEN-1:0]         d_rvfi_rs1_rdata_o,
  output logic [XLEN-1:0]         d_rvfi_rs2_rdata_o,
  output logic [XLEN-1:0]         d_rvfi_current_pc_o,
  output logic [XLEN-1:0]         d_rvfi_next_pc_o,
  output logic                    d_rvfi_valid_o,
  output logic                    d_rvfi_trap_o,
  output logic                    d_rvfi_intr_o,
  output logic                    d_rvfi_mem_req_o,
  output logic                    d_rvfi_mem_we_o,
  output logic [MEM_ACCESS_W-1:0] d_rvfi_mem_size_o,
  output logic [XLEN-1:0]         d_rvfi_mem_addr_o,
  output logic [XLEN-1:0]         d_rvfi_mem_wdata_o
);


  ////////////////////////
  // Local declarations //
  ////////////////////////

  logic                    decode_rs1_re;
  logic                    decode_rs2_re;

  logic [OP1_SEL_W-1:0]    decode_ex_op1_sel;
  logic [OP2_SEL_W-1:0]    decode_ex_op2_sel;

  logic [ALU_OP_W-1:0]     decode_alu_operation;
  logic [MDU_OP_W-1:0]     decode_mdu_operation;

  logic                    decode_ex_mdu_req;
  logic                    decode_ex_result_sel;

  logic                    decode_mem_we;
  logic [MEM_ACCESS_W-1:0] decode_mem_size;
  logic                    decode_mem_req;

  logic [WB_SRC_W-1:0]     decode_wb_src_sel;
  logic                    decode_wb_we;

  logic [XLEN-1:0]         decode_mem_addr_imm;
  logic [XLEN-1:0]         decode_mem_addr;
  logic [XLEN-1:0]         decode_mem_data;
  logic                    decode_load;

  logic                    d_illegal_instr;

  logic                    d_ebreak;
  logic                    d_ecall;
  logic                    d_mret;
  logic                    d_fence;
  logic                    d_branch;
  logic                    d_jal;
  logic                    d_jalr;

  logic [GPR_ADDR_W-1:0]   r1_addr;
  logic [XLEN-1:0]         r1_data;
  logic [GPR_ADDR_W-1:0]   r2_addr;
  logic [XLEN-1:0]         r2_data;
  logic [GPR_ADDR_W-1:0]   rd_addr;

  logic                    gpr_wr_en;
  logic [GPR_ADDR_W-1:0]   gpr_wr_addr;
  logic [XLEN-1:0]         gpr_wr_data;

  logic [XLEN-1:0]         imm_i;
  logic [XLEN-1:0]         imm_u;
  logic [XLEN-1:0]         imm_s;
  logic [XLEN-1:0]         imm_b;
  logic [XLEN-1:0]         imm_j;

  logic [XLEN-1:0]         op1;
  logic [XLEN-1:0]         op2;

  logic [XLEN-1:0]         jalr_pc;
  logic [XLEN-1:0]         branch_pc;
  logic [XLEN-1:0]         jal_pc;

  logic [XLEN-1:0]         d_target_pc;
  logic                    f_handshake;

  logic                    d_valid_ff;

  logic [XLEN-1:0]         d_op1_ff;
  logic [XLEN-1:0]         d_op2_ff;

  logic [ALU_OP_W-1:0]     d_alu_operation_ff;
  logic                    d_mdu_req_ff;
  logic [MDU_OP_W-1:0]     d_mdu_operation_ff;

  logic                    d_mem_req_ff;

  logic                    d_mem_we_ff;
  logic [MEM_ACCESS_W-1:0] d_mem_size_ff;
  logic [XLEN-1:0]         d_mem_addr_ff;
  logic [XLEN-1:0]         d_mem_data_ff;

  logic                    d_gpr_wr_en_ff;
  logic [GPR_ADDR_W-1:0]   d_gpr_wr_addr_ff;
  logic [WB_SRC_W-1:0]     d_gpr_src_sel_ff;

  logic                    d_branch_ff;
  logic                    d_jal_ff;
  logic                    d_jalr_ff;
  logic [XLEN-1:0]         d_target_pc_ff;
  logic [XLEN-1:0]         d_next_pc_ff;
  logic                    d_prediction_ff;
  logic                    d_br_j_taken_ff;

  enum logic [3:0] {
    PC_INCR,
    PC_JAL,
    PC_JALR,
    PC_BRANCH,
    PC_MRET,
    PC_ECALL,
    PC_FENCE,
    PC_WFI,
    PC_IRQ,
    PC_EXCEPT
  } next_pc_sel;


  /////////////
  // Decoder //
  /////////////

  miriscv_decoder
  i_decoder
  (
    .decode_instr_i         ( f_instr_i            ),

    .decode_rs1_re_o        ( decode_rs1_re        ),
    .decode_rs2_re_o        ( decode_rs2_re        ),

    .decode_ex_op1_sel_o    ( decode_ex_op1_sel    ),
    .decode_ex_op2_sel_o    ( decode_ex_op2_sel    ),

    .decode_alu_operation_o ( decode_alu_operation ),

    .decode_mdu_operation_o ( decode_mdu_operation ),
    .decode_ex_mdu_req_o    ( decode_ex_mdu_req    ),

    .decode_mem_we_o        ( decode_mem_we        ),
    .decode_mem_size_o      ( decode_mem_size      ),
    .decode_mem_req_o       ( decode_mem_req       ),

    .decode_wb_src_sel_o    ( decode_wb_src_sel    ),
    .decode_wb_we_o         ( decode_wb_we         ),

    .decode_fence_o         ( d_fence              ),
    .decode_branch_o        ( d_branch             ),
    .decode_jal_o           ( d_jal                ),
    .decode_jalr_o          ( d_jalr               ),
    .decode_load_o          ( decode_load          ),

    .decode_illegal_instr_o ( d_illegal_instr      )
  );


  ///////////////////
  // Register File //
  ///////////////////

  assign gpr_wr_en   = m_gpr_wr_en_i;
  assign gpr_wr_addr = m_gpr_wr_addr_i;
  assign gpr_wr_data = m_gpr_wr_data_i;

  assign r1_addr = f_instr_i[19:15];
  assign r2_addr = f_instr_i[24:20];
  assign rd_addr = f_instr_i[11:7];


  miriscv_gpr
  i_gpr
  (
    .clk_i      ( clk_i       ),
    .arstn_i    ( arstn_i     ),

    .wr_en_i    ( gpr_wr_en   ),
    .wr_addr_i  ( gpr_wr_addr ),
    .wr_data_i  ( gpr_wr_data ),

    .r1_addr_i  ( r1_addr     ),
    .r1_data_o  ( r1_data     ),
    .r2_addr_i  ( r2_addr     ),
    .r2_data_o  ( r2_data     )
  );


  //////////////////////////////
  // Immediate and signextend //
  //////////////////////////////

  miriscv_signextend
  #(
    .IN_WIDTH  ( 12   ),
    .OUT_WIDTH ( XLEN )
  )
  extend_imm_i
  (
    .data_i ( f_instr_i[31:20] ),
    .data_o ( imm_i            )
  );

  assign imm_u = {f_instr_i[31:12], 12'd0};

  miriscv_signextend
  #(
    .IN_WIDTH  ( 12   ),
    .OUT_WIDTH ( XLEN )
  )
  extend_imm_s
  (
    .data_i ( {f_instr_i[31:25], f_instr_i[11:7]} ),
    .data_o ( imm_s                               )
  );

  miriscv_signextend
  #(
    .IN_WIDTH  ( 13   ),
    .OUT_WIDTH ( XLEN )
  )
  extend_imm_b
  (
    .data_i ( {f_instr_i[31], f_instr_i[7], f_instr_i[30:25], f_instr_i[11:8], 1'b0} ),
    .data_o ( imm_b                                                                  )
  );

  miriscv_signextend
  #(
    .IN_WIDTH  ( 21   ),
    .OUT_WIDTH ( XLEN )
  )
  extend_imm_j
  (
    .data_i ( {f_instr_i[31], f_instr_i[19:12], f_instr_i[20], f_instr_i[30:21], 1'b0} ),
    .data_o ( imm_j                                                                    )
  );


  //////////////
  // Datapath //
  //////////////

  always_comb begin
    unique case (decode_ex_op1_sel)
      RS1_DATA:   op1 = r1_data;
      CURRENT_PC: op1 = f_current_pc_i;
      ZERO:       op1 = {XLEN{1'b0}};
    endcase
  end

  always_comb begin
    unique case (decode_ex_op2_sel)
      RS2_DATA: op2 = r2_data;
      IMM_I:    op2 = imm_i;
      IMM_U:    op2 = imm_u;
      NEXT_PC:  op2 = f_next_pc_i;
    endcase
  end

  assign decode_mem_data     = op2;
  assign decode_mem_addr_imm = decode_load ? imm_i : imm_s;
  assign decode_mem_addr     = op1 + decode_mem_addr_imm;


  // precompute PC values in case of jump
  assign jalr_pc   = (op1 + imm_i) & (~'b1);
  assign branch_pc = f_current_pc_i  + imm_b;
  assign jal_pc    = f_current_pc_i  + imm_j;

  always_comb begin
    case ({d_branch, d_jalr, d_jal}) inside
      3'b100:  next_pc_sel = PC_BRANCH;
      3'b010:  next_pc_sel = PC_JALR;
      3'b001:  next_pc_sel = PC_JAL;
      default: next_pc_sel = PC_INCR;
    endcase
  end

  always_comb begin
    case (next_pc_sel)
      PC_JAL:    d_target_pc = jal_pc;
      PC_JALR:   d_target_pc = jalr_pc;
      PC_BRANCH: d_target_pc = branch_pc;
      default:   d_target_pc = branch_pc; // any value can be placed here
    endcase
  end

  /////////////////////
  // Simple BTFN BPU //
  /////////////////////

  logic instr_jump;
  assign instr_jump = /*d_jalr |*/ d_jal;


  logic bpu_prediction;
  assign bpu_prediction = instr_jump;

  assign d_taken_o = bpu_prediction;
  assign d_target_o = d_target_pc;

  ///////////////////////
  // Pipeline register //
  ///////////////////////

  assign f_handshake = f_valid_i & ~cu_stall_f_i;

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i)
      d_valid_ff <= '0;
    else if (cu_kill_d_i)
      d_valid_ff <= '0;
    else if (~cu_stall_d_i)
      d_valid_ff <= f_handshake;
  end


  always_ff @(posedge clk_i) begin
    if (f_handshake & ~cu_stall_d_i) begin
      d_op1_ff           <= op1;
      d_op2_ff           <= op2;

      d_alu_operation_ff <= decode_alu_operation;
      d_mdu_req_ff       <= decode_ex_mdu_req;
      d_mdu_operation_ff <= decode_mdu_operation;

      d_mem_req_ff       <= decode_mem_req;
      d_mem_we_ff        <= decode_mem_we;
      d_mem_size_ff      <= decode_mem_size;
      d_mem_addr_ff      <= decode_mem_addr;
      d_mem_data_ff      <= decode_mem_data;

      d_gpr_wr_en_ff     <= decode_wb_we;
      d_gpr_wr_addr_ff   <= rd_addr;
      d_gpr_src_sel_ff   <= decode_wb_src_sel;

      d_branch_ff        <= d_branch;
      d_jal_ff           <= d_jal;
      d_jalr_ff          <= d_jalr;
      d_target_pc_ff     <= d_target_pc;
      d_next_pc_ff       <= f_next_pc_i;
      d_prediction_ff    <= bpu_prediction;
      d_br_j_taken_ff    <= d_jal | d_jalr;

    end
  end

  assign d_valid_o         = d_valid_ff;

  assign d_op1_o           = d_op1_ff;
  assign d_op2_o           = d_op2_ff;

  assign d_alu_operation_o = d_alu_operation_ff;
  assign d_mdu_req_o       = d_mdu_req_ff;
  assign d_mdu_operation_o = d_mdu_operation_ff;

  assign d_mem_req_o       = d_mem_req_ff;
  assign d_mem_we_o        = d_mem_we_ff;
  assign d_mem_size_o      = d_mem_size_ff;
  assign d_mem_addr_o      = d_mem_addr_ff;
  assign d_mem_data_o      = d_mem_data_ff;

  assign d_gpr_wr_en_o     = d_gpr_wr_en_ff;
  assign d_gpr_wr_addr_o   = d_gpr_wr_addr_ff;
  assign d_gpr_src_sel_o   = d_gpr_src_sel_ff;

  assign d_branch_o        = d_branch_ff;
  assign d_jal_o           = d_jal_ff;
  assign d_jalr_o          = d_jalr_ff;
  assign d_target_pc_o     = d_target_pc_ff;
  assign d_next_pc_o       = d_next_pc_ff;
  assign d_prediction_o    = d_prediction_ff;
  assign d_br_j_taken_o    = d_br_j_taken_ff;

  assign d_stall_req_o     = '0;

  assign f_cu_rs1_addr_o   = r1_addr;
  assign f_cu_rs1_req_o    = decode_rs1_re;

  assign f_cu_rs2_addr_o   = r2_addr;
  assign f_cu_rs2_req_o    = decode_rs2_re;


  ////////////////////
  // RVFI interface //
  ////////////////////

  if (RVFI) begin
    always_ff @(posedge clk_i or negedge arstn_i) begin
      if(~arstn_i) begin
        d_rvfi_wb_we_o          <= '0;
        d_rvfi_wb_rd_addr_o     <= '0;
        d_rvfi_instr_o          <= '0;
        d_rvfi_rs1_addr_o       <= '0;
        d_rvfi_rs2_addr_o       <= '0;
        d_rvfi_op1_gpr_o        <= '0;
        d_rvfi_op2_gpr_o        <= '0;
        d_rvfi_rs1_rdata_o      <= '0;
        d_rvfi_rs2_rdata_o      <= '0;
        d_rvfi_current_pc_o     <= '0;
        d_rvfi_next_pc_o        <= '0;
        d_rvfi_valid_o          <= '0;
        d_rvfi_trap_o           <= '0;
        d_rvfi_intr_o           <= '0;
        d_rvfi_mem_req_o        <= '0;
        d_rvfi_mem_we_o         <= '0;
        d_rvfi_mem_size_o       <= '0;
        d_rvfi_mem_addr_o       <= '0;
        d_rvfi_mem_wdata_o      <= '0;
      end

      else if (cu_kill_d_i) begin
        d_rvfi_wb_we_o          <= '0;
        d_rvfi_wb_rd_addr_o     <= '0;
        d_rvfi_instr_o          <= '0;
        d_rvfi_rs1_addr_o       <= '0;
        d_rvfi_rs2_addr_o       <= '0;
        d_rvfi_op1_gpr_o        <= '0;
        d_rvfi_op2_gpr_o        <= '0;
        d_rvfi_rs1_rdata_o      <= '0;
        d_rvfi_rs2_rdata_o      <= '0;
        d_rvfi_current_pc_o     <= '0;
        d_rvfi_next_pc_o        <= '0;
        d_rvfi_valid_o          <= '0;
        d_rvfi_trap_o           <= '0;
        d_rvfi_intr_o           <= '0;
        d_rvfi_mem_req_o        <= '0;
        d_rvfi_mem_we_o         <= '0;
        d_rvfi_mem_size_o       <= '0;
        d_rvfi_mem_addr_o       <= '0;
        d_rvfi_mem_wdata_o      <= '0;
      end

      else if (~cu_stall_d_i) begin
        d_rvfi_wb_we_o          <= decode_wb_we;
        d_rvfi_wb_rd_addr_o     <= rd_addr;
        d_rvfi_instr_o          <= f_instr_i;
        d_rvfi_rs1_addr_o       <= r1_addr;
        d_rvfi_rs2_addr_o       <= r2_addr;
        d_rvfi_op1_gpr_o        <= decode_rs1_re;
        d_rvfi_op2_gpr_o        <= decode_rs2_re;
        d_rvfi_rs1_rdata_o      <= op1;
        d_rvfi_rs2_rdata_o      <= op2;
        d_rvfi_current_pc_o     <= f_current_pc_i;
        d_rvfi_next_pc_o        <= f_next_pc_i;
        d_rvfi_valid_o          <= f_handshake;
        d_rvfi_trap_o           <= '0;
        d_rvfi_intr_o           <= '0;
        d_rvfi_mem_req_o        <= decode_mem_req;
        d_rvfi_mem_we_o         <= decode_mem_we;
        d_rvfi_mem_size_o       <= decode_mem_size;
        d_rvfi_mem_addr_o       <= decode_mem_addr;
        d_rvfi_mem_wdata_o      <= decode_mem_data;
      end

    end
  end
  else begin
    assign d_rvfi_wb_we_o          = '0;
    assign d_rvfi_wb_rd_addr_o     = '0;
    assign d_rvfi_instr_o          = '0;
    assign d_rvfi_rs1_addr_o       = '0;
    assign d_rvfi_rs2_addr_o       = '0;
    assign d_rvfi_op1_gpr_o        = '0;
    assign d_rvfi_op2_gpr_o        = '0;
    assign d_rvfi_rs1_rdata_o      = '0;
    assign d_rvfi_rs2_rdata_o      = '0;
    assign d_rvfi_current_pc_o     = '0;
    assign d_rvfi_next_pc_o        = '0;
    assign d_rvfi_valid_o          = '0;
    assign d_rvfi_trap_o           = '0;
    assign d_rvfi_intr_o           = '0;
    assign d_rvfi_mem_req_o        = '0;
    assign d_rvfi_mem_we_o         = '0;
    assign d_rvfi_mem_size_o       = '0;
    assign d_rvfi_mem_addr_o       = '0;
    assign d_rvfi_mem_wdata_o      = '0;
  end

endmodule
