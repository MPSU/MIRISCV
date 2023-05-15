/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

module miriscv_execute_stage
  import miriscv_pkg::XLEN;
  import miriscv_pkg::ILEN;
  import miriscv_gpr_pkg::GPR_ADDR_W;
  import miriscv_alu_pkg::ALU_OP_W;
  import miriscv_mdu_pkg::MDU_OP_W;
  import miriscv_lsu_pkg::MEM_ACCESS_W;
  import miriscv_decode_pkg::WB_SRC_W;
#(
  parameter bit RVFI = 1'b0
) (
  // Clock, reset
  input  logic                    clk_i,
  input  logic                    arstn_i,

  // Control unit
  input  logic                    cu_kill_e_i,
  input  logic                    cu_stall_e_i,
  output logic                    e_stall_req_o,

  // From Decode
  input  logic                    d_valid_i,

  input  logic [XLEN-1:0]         d_op1_i,
  input  logic [XLEN-1:0]         d_op2_i,

  input  logic [ALU_OP_W-1:0]     d_alu_operation_i,
  input  logic                    d_mdu_req_i,
  input  logic [MDU_OP_W-1:0]     d_mdu_operation_i,

  input  logic                    d_mem_req_i,
  input  logic                    d_mem_we_i,
  input  logic [MEM_ACCESS_W-1:0] d_mem_size_i,
  input  logic [XLEN-1:0]         d_mem_addr_i,
  input  logic [XLEN-1:0]         d_mem_data_i,

  input  logic                    d_gpr_wr_en_i,
  input  logic [GPR_ADDR_W-1:0]   d_gpr_wr_addr_i,
  input  logic [WB_SRC_W-1:0]     d_gpr_src_sel_i,

  input  logic                    d_branch_i,
  input  logic                    d_jal_i,
  input  logic                    d_jalr_i,
  input  logic [XLEN-1:0]         d_target_pc_i,
  input  logic [XLEN-1:0]         d_next_pc_i,
  input  logic                    d_prediction_i,
  input  logic                    d_br_j_taken_i,

  output logic                    e_valid_o,
  output logic [XLEN-1:0]         e_alu_result_o,
  output logic [XLEN-1:0]         e_mdu_result_o,

  // To Memory stage
  output logic                    e_mem_req_o,
  output logic                    e_mem_we_o,
  output logic [MEM_ACCESS_W-1:0] e_mem_size_o,
  output logic [XLEN-1:0]         e_mem_addr_o,
  output logic [XLEN-1:0]         e_mem_data_o,

  output logic                    e_gpr_wr_en_o,
  output logic [GPR_ADDR_W-1:0]   e_gpr_wr_addr_o,
  output logic [WB_SRC_W-1:0]     e_gpr_src_sel_o,

  output logic                    e_branch_o,
  output logic                    e_jal_o,
  output logic                    e_jalr_o,
  output logic [XLEN-1:0]         e_target_pc_o,
  output logic [XLEN-1:0]         e_next_pc_o,
  output logic                    e_prediction_o,
  output logic                    e_br_j_taken_o,

  // RVFI
  input  logic                    d_rvfi_wb_we_i,
  input  logic [GPR_ADDR_W-1:0]   d_rvfi_wb_rd_addr_i,
  input  logic [ILEN-1:0]         d_rvfi_instr_i,
  input  logic [GPR_ADDR_W-1:0]   d_rvfi_rs1_addr_i,
  input  logic [GPR_ADDR_W-1:0]   d_rvfi_rs2_addr_i,
  input  logic                    d_rvfi_op1_gpr_i,
  input  logic                    d_rvfi_op2_gpr_i,
  input  logic [XLEN-1:0]         d_rvfi_rs1_rdata_i,
  input  logic [XLEN-1:0]         d_rvfi_rs2_rdata_i,
  input  logic [XLEN-1:0]         d_rvfi_current_pc_i,
  input  logic [XLEN-1:0]         d_rvfi_next_pc_i,
  input  logic                    d_rvfi_valid_i,
  input  logic                    d_rvfi_trap_i,
  input  logic                    d_rvfi_intr_i,
  input  logic                    d_rvfi_mem_req_i,
  input  logic                    d_rvfi_mem_we_i,
  input  logic [MEM_ACCESS_W-1:0] d_rvfi_mem_size_i,
  input  logic [XLEN-1:0]         d_rvfi_mem_addr_i,
  input  logic [XLEN-1:0]         d_rvfi_mem_wdata_i,

  output logic                    e_rvfi_wb_we_o,
  output logic [GPR_ADDR_W-1:0]   e_rvfi_wb_rd_addr_o,
  output logic [ILEN-1:0]         e_rvfi_instr_o,
  output logic [GPR_ADDR_W-1:0]   e_rvfi_rs1_addr_o,
  output logic [GPR_ADDR_W-1:0]   e_rvfi_rs2_addr_o,
  output logic                    e_rvfi_op1_gpr_o,
  output logic                    e_rvfi_op2_gpr_o,
  output logic [XLEN-1:0]         e_rvfi_rs1_rdata_o,
  output logic [XLEN-1:0]         e_rvfi_rs2_rdata_o,
  output logic [XLEN-1:0]         e_rvfi_current_pc_o,
  output logic [XLEN-1:0]         e_rvfi_next_pc_o,
  output logic                    e_rvfi_valid_o,
  output logic                    e_rvfi_trap_o,
  output logic                    e_rvfi_intr_o,
  output logic                    e_rvfi_mem_req_o,
  output logic                    e_rvfi_mem_we_o,
  output logic [MEM_ACCESS_W-1:0] e_rvfi_mem_size_o,
  output logic [XLEN-1:0]         e_rvfi_mem_addr_o,
  output logic [XLEN-1:0]         e_rvfi_mem_wdata_o
);


  ////////////////////////
  // Local declarations //
  ////////////////////////

  logic [XLEN-1:0]         alu_result;
  logic                    branch_des;

  logic [XLEN-1:0]         mdu_result;
  logic                    mdu_stall_req;
  logic                    mdu_req;

  logic                    e_valid_ff;

  logic [XLEN-1:0]         e_alu_result_ff;
  logic [XLEN-1:0]         e_mdu_result_ff;

  logic                    e_mem_req_ff;
  logic                    e_mem_we_ff;
  logic [MEM_ACCESS_W-1:0] e_mem_size_ff;
  logic [XLEN-1:0]         e_mem_addr_ff;
  logic [XLEN-1:0]         e_mem_data_ff;

  logic                    e_gpr_wr_en_ff;
  logic [GPR_ADDR_W-1:0]   e_gpr_wr_addr_ff;
  logic [WB_SRC_W-1:0]     e_gpr_src_sel_ff;

  logic                    e_branch_ff;
  logic                    e_jal_ff;
  logic                    e_jalr_ff;
  logic [XLEN-1:0]         e_target_pc_ff;
  logic [XLEN-1:0]         e_next_pc_ff;
  logic                    e_prediction_ff;
  logic                    e_br_j_taken_ff;


  /////////////////
  // ALU and MDU //
  /////////////////

  miriscv_alu
  i_alu
  (
    .alu_port_a_i      ( d_op1_i           ),
    .alu_port_b_i      ( d_op2_i           ),
    .alu_op_i          ( d_alu_operation_i ),
    .alu_result_o      ( alu_result        ),
    .alu_branch_des_o  ( branch_des        )
  );

  assign mdu_req = d_mdu_req_i & d_valid_i;

  miriscv_mdu
  i_mdu
  (
    .clk_i           ( clk_i             ),
    .arstn_i         ( arstn_i           ),
    .mdu_req_i       ( mdu_req           ),
    .mdu_port_a_i    ( d_op1_i           ),
    .mdu_port_b_i    ( d_op2_i           ),
    .mdu_op_i        ( d_mdu_operation_i ),
    .mdu_kill_i      ( cu_kill_e_i       ),
    .mdu_keep_i      ( 1'b0              ),
    .mdu_result_o    ( mdu_result        ),
    .mdu_stall_req_o ( mdu_stall_req     )
  );


  ///////////////////////
  // Pipeline register //
  ///////////////////////

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i)
      e_valid_ff <= '0;
    else if (cu_kill_e_i)
      e_valid_ff <= '0;
    else if (~cu_stall_e_i)
      e_valid_ff <= d_valid_i;
  end


  always_ff @(posedge clk_i) begin
    if (d_valid_i & ~cu_stall_e_i) begin
      e_alu_result_ff  <= alu_result;
      e_mdu_result_ff  <= mdu_result;

      e_mem_req_ff     <= d_mem_req_i;
      e_mem_we_ff      <= d_mem_we_i;
      e_mem_size_ff    <= d_mem_size_i;
      e_mem_addr_ff    <= d_mem_addr_i;
      e_mem_data_ff    <= d_mem_data_i;

      e_gpr_wr_en_ff   <= d_gpr_wr_en_i;
      e_gpr_wr_addr_ff <= d_gpr_wr_addr_i;
      e_gpr_src_sel_ff <= d_gpr_src_sel_i;

      e_branch_ff      <= d_branch_i;
      e_jal_ff         <= d_jal_i;
      e_jalr_ff        <= d_jalr_i;
      e_target_pc_ff   <= d_target_pc_i;
      e_next_pc_ff     <= d_next_pc_i;
      e_prediction_ff  <= d_prediction_i;
      e_br_j_taken_ff  <= d_br_j_taken_i | (d_branch_i & branch_des);

    end
  end

  assign e_valid_o       = e_valid_ff;

  assign e_alu_result_o  = e_alu_result_ff;
  assign e_mdu_result_o  = e_mdu_result_ff;

  assign e_mem_req_o     = e_mem_req_ff;
  assign e_mem_we_o      = e_mem_we_ff;
  assign e_mem_size_o    = e_mem_size_ff;
  assign e_mem_addr_o    = e_mem_addr_ff;
  assign e_mem_data_o    = e_mem_data_ff;

  assign e_gpr_wr_en_o   = e_gpr_wr_en_ff;
  assign e_gpr_wr_addr_o = e_gpr_wr_addr_ff;
  assign e_gpr_src_sel_o = e_gpr_src_sel_ff;

  assign e_branch_o      = e_branch_ff;
  assign e_jal_o         = e_jal_ff;
  assign e_jalr_o        = e_jalr_ff;
  assign e_target_pc_o   = e_target_pc_ff;
  assign e_next_pc_o     = e_next_pc_ff;
  assign e_prediction_o  = e_prediction_ff;
  assign e_br_j_taken_o  = e_br_j_taken_ff;

  assign e_stall_req_o   = mdu_stall_req;


  ////////////////////
  // RVFI interface //
  ////////////////////

  if (RVFI) begin
    always_ff @(posedge clk_i or negedge arstn_i) begin
      if(~arstn_i) begin
        e_rvfi_wb_we_o          <= '0;
        e_rvfi_wb_rd_addr_o     <= '0;
        e_rvfi_instr_o          <= '0;
        e_rvfi_rs1_addr_o       <= '0;
        e_rvfi_rs2_addr_o       <= '0;
        e_rvfi_op1_gpr_o        <= '0;
        e_rvfi_op2_gpr_o        <= '0;
        e_rvfi_rs1_rdata_o      <= '0;
        e_rvfi_rs2_rdata_o      <= '0;
        e_rvfi_current_pc_o     <= '0;
        e_rvfi_next_pc_o        <= '0;
        e_rvfi_valid_o          <= '0;
        e_rvfi_trap_o           <= '0;
        e_rvfi_intr_o           <= '0;
        e_rvfi_mem_req_o        <= '0;
        e_rvfi_mem_we_o         <= '0;
        e_rvfi_mem_size_o       <= '0;
        e_rvfi_mem_addr_o       <= '0;
        e_rvfi_mem_wdata_o      <= '0;
      end

      else if (cu_kill_e_i) begin
        e_rvfi_wb_we_o          <= '0;
        e_rvfi_wb_rd_addr_o     <= '0;
        e_rvfi_instr_o          <= '0;
        e_rvfi_rs1_addr_o       <= '0;
        e_rvfi_rs2_addr_o       <= '0;
        e_rvfi_op1_gpr_o        <= '0;
        e_rvfi_op2_gpr_o        <= '0;
        e_rvfi_rs1_rdata_o      <= '0;
        e_rvfi_rs2_rdata_o      <= '0;
        e_rvfi_current_pc_o     <= '0;
        e_rvfi_next_pc_o        <= '0;
        e_rvfi_valid_o          <= '0;
        e_rvfi_trap_o           <= '0;
        e_rvfi_intr_o           <= '0;
        e_rvfi_mem_req_o        <= '0;
        e_rvfi_mem_we_o         <= '0;
        e_rvfi_mem_size_o       <= '0;
        e_rvfi_mem_addr_o       <= '0;
        e_rvfi_mem_wdata_o      <= '0;
      end

      else if (~cu_stall_e_i) begin
        e_rvfi_wb_we_o          <= d_rvfi_wb_we_i;
        e_rvfi_wb_rd_addr_o     <= d_rvfi_wb_rd_addr_i;
        e_rvfi_instr_o          <= d_rvfi_instr_i;
        e_rvfi_rs1_addr_o       <= d_rvfi_rs1_addr_i;
        e_rvfi_rs2_addr_o       <= d_rvfi_rs2_addr_i;
        e_rvfi_op1_gpr_o        <= d_rvfi_op1_gpr_i;
        e_rvfi_op2_gpr_o        <= d_rvfi_op2_gpr_i;
        e_rvfi_rs1_rdata_o      <= d_rvfi_rs1_rdata_i;
        e_rvfi_rs2_rdata_o      <= d_rvfi_rs2_rdata_i;
        e_rvfi_current_pc_o     <= d_rvfi_current_pc_i;
        e_rvfi_next_pc_o        <= d_rvfi_next_pc_i;
        e_rvfi_valid_o          <= d_rvfi_valid_i;
        e_rvfi_trap_o           <= d_rvfi_trap_i;
        e_rvfi_intr_o           <= d_rvfi_intr_i;
        e_rvfi_mem_req_o        <= d_rvfi_mem_req_i;
        e_rvfi_mem_we_o         <= d_rvfi_mem_we_i;
        e_rvfi_mem_size_o       <= d_rvfi_mem_size_i;
        e_rvfi_mem_addr_o       <= d_rvfi_mem_addr_i;
        e_rvfi_mem_wdata_o      <= d_rvfi_mem_wdata_i;
      end

    end
  end

  else begin
    assign e_rvfi_wb_we_o          = '0;
    assign e_rvfi_wb_rd_addr_o     = '0;
    assign e_rvfi_instr_o          = '0;
    assign e_rvfi_rs1_addr_o       = '0;
    assign e_rvfi_rs2_addr_o       = '0;
    assign e_rvfi_op1_gpr_o        = '0;
    assign e_rvfi_op2_gpr_o        = '0;
    assign e_rvfi_rs1_rdata_o      = '0;
    assign e_rvfi_rs2_rdata_o      = '0;
    assign e_rvfi_current_pc_o     = '0;
    assign e_rvfi_next_pc_o        = '0;
    assign e_rvfi_valid_o          = '0;
    assign e_rvfi_trap_o           = '0;
    assign e_rvfi_intr_o           = '0;
    assign e_rvfi_mem_req_o        = '0;
    assign e_rvfi_mem_we_o         = '0;
    assign e_rvfi_mem_size_o       = '0;
    assign e_rvfi_mem_addr_o       = '0;
    assign e_rvfi_mem_wdata_o      = '0;
  end

endmodule
