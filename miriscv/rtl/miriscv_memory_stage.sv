/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

module miriscv_memory_stage
  import miriscv_pkg::XLEN;
  import miriscv_pkg::ILEN;
  import miriscv_gpr_pkg::GPR_ADDR_W;
  import miriscv_decode_pkg::LSU_DATA;
  import miriscv_decode_pkg::ALU_DATA;
  import miriscv_decode_pkg::MDU_DATA;
  import miriscv_lsu_pkg::MEM_ACCESS_W;
  import miriscv_decode_pkg::WB_SRC_W;
#(
  parameter bit RVFI = 1'b0
) (
  // Clock, reset
  input  logic                    clk_i,
  input  logic                    arstn_i,

  input  logic                    cu_kill_m_i,
  input  logic                    cu_stall_m_i,
  output logic                    m_stall_req_o,

  input  logic                    e_valid_i,

  input  logic [XLEN-1:0]         e_alu_result_i,
  input  logic [XLEN-1:0]         e_mdu_result_i,

  input  logic                    e_mem_req_i,
  input  logic                    e_mem_we_i,
  input  logic [MEM_ACCESS_W-1:0] e_mem_size_i,
  input  logic [XLEN-1:0]         e_mem_addr_i,
  input  logic [XLEN-1:0]         e_mem_data_i,

  input  logic                    e_gpr_wr_en_i,
  input  logic [GPR_ADDR_W-1:0]   e_gpr_wr_addr_i,
  input  logic [WB_SRC_W-1:0]     e_gpr_src_sel_i,

  input  logic                    e_branch_i,
  input  logic                    e_jal_i,
  input  logic                    e_jalr_i,
  input  logic [XLEN-1:0]         e_target_pc_i,
  input  logic [XLEN-1:0]         e_next_pc_i,
  input  logic                    e_prediction_i,
  input  logic                    e_br_j_taken_i,

  output logic                    m_valid_o,
  output logic                    m_gpr_wr_en_o,
  output logic [GPR_ADDR_W-1:0]   m_gpr_wr_addr_o,
  output logic [XLEN-1:0]         m_gpr_wr_data_o,

  output logic                    m_branch_o,
  output logic                    m_jal_o,
  output logic                    m_jalr_o,
  output logic [XLEN-1:0]         m_target_pc_o,
  output logic [XLEN-1:0]         m_next_pc_o,
  output logic                    m_prediction_o,
  output logic                    m_br_j_taken_o,

  // Data memory interface
  input  logic                    data_rvalid_i,
  input  logic [XLEN-1:0]         data_rdata_i,
  output logic                    data_req_o,
  output logic                    data_we_o,
  output logic [XLEN/8-1:0]       data_be_o,
  output logic [XLEN-1:0]         data_addr_o,
  output logic [XLEN-1:0]         data_wdata_o,

  // RVFI
  input  logic                    e_rvfi_wb_we_i,
  input  logic [GPR_ADDR_W-1:0]   e_rvfi_wb_rd_addr_i,
  input  logic [ILEN-1:0]         e_rvfi_instr_i,
  input  logic [GPR_ADDR_W-1:0]   e_rvfi_rs1_addr_i,
  input  logic [GPR_ADDR_W-1:0]   e_rvfi_rs2_addr_i,
  input  logic                    e_rvfi_op1_gpr_i,
  input  logic                    e_rvfi_op2_gpr_i,
  input  logic [XLEN-1:0]         e_rvfi_rs1_rdata_i,
  input  logic [XLEN-1:0]         e_rvfi_rs2_rdata_i,
  input  logic [XLEN-1:0]         e_rvfi_current_pc_i,
  input  logic [XLEN-1:0]         e_rvfi_next_pc_i,
  input  logic                    e_rvfi_valid_i,
  input  logic                    e_rvfi_trap_i,
  input  logic                    e_rvfi_intr_i,
  input  logic                    e_rvfi_mem_req_i,
  input  logic                    e_rvfi_mem_we_i,
  input  logic [MEM_ACCESS_W-1:0] e_rvfi_mem_size_i,
  input  logic [XLEN-1:0]         e_rvfi_mem_addr_i,
  input  logic [XLEN-1:0]         e_rvfi_mem_wdata_i,

  output logic [XLEN-1:0]         m_rvfi_wb_data_o,
  output logic                    m_rvfi_wb_we_o,
  output logic [GPR_ADDR_W-1:0]   m_rvfi_wb_rd_addr_o,
  output logic [ILEN-1:0]         m_rvfi_instr_o,
  output logic [GPR_ADDR_W-1:0]   m_rvfi_rs1_addr_o,
  output logic [GPR_ADDR_W-1:0]   m_rvfi_rs2_addr_o,
  output logic                    m_rvfi_op1_gpr_o,
  output logic                    m_rvfi_op2_gpr_o,
  output logic [XLEN-1:0]         m_rvfi_rs1_rdata_o,
  output logic [XLEN-1:0]         m_rvfi_rs2_rdata_o,
  output logic [XLEN-1:0]         m_rvfi_current_pc_o,
  output logic [XLEN-1:0]         m_rvfi_next_pc_o,
  output logic                    m_rvfi_valid_o,
  output logic                    m_rvfi_trap_o,
  output logic                    m_rvfi_intr_o,
  output logic                    m_rvfi_mem_req_o,
  output logic                    m_rvfi_mem_we_o,
  output logic [MEM_ACCESS_W-1:0] m_rvfi_mem_size_o,
  output logic [XLEN-1:0]         m_rvfi_mem_addr_o,
  output logic [XLEN-1:0]         m_rvfi_mem_wdata_o,
  output logic [XLEN-1:0]         m_rvfi_mem_rdata_o

);


  ////////////////////////
  // Local declarations //
  ////////////////////////

  logic [XLEN-1:0] lsu_result;
  logic            lsu_stall_req;
  logic            lsu_req;
  logic [XLEN-1:0] m_result;


  /////////////////////
  // Load-Store Unit //
  /////////////////////

  assign lsu_req = e_mem_req_i & e_valid_i;

  miriscv_lsu
  i_lsu
  (
    .clk_i                   ( clk_i         ),
    .arstn_i                 ( arstn_i       ),

    .data_rvalid_i           ( data_rvalid_i ),
    .data_rdata_i            ( data_rdata_i  ),
    .data_req_o              ( data_req_o    ),
    .data_we_o               ( data_we_o     ),
    .data_be_o               ( data_be_o     ),
    .data_addr_o             ( data_addr_o   ),
    .data_wdata_o            ( data_wdata_o  ),

    .lsu_req_i               ( lsu_req       ),
    .lsu_kill_i              ( cu_kill_m_i   ),
    .lsu_keep_i              ( 1'b0          ),
    .lsu_we_i                ( e_mem_we_i    ),
    .lsu_size_i              ( e_mem_size_i  ),
    .lsu_addr_i              ( e_mem_addr_i  ),
    .lsu_data_i              ( e_mem_data_i  ),
    .lsu_data_o              ( lsu_result    ),

    .lsu_stall_o             ( lsu_stall_req )
  );


  ////////////////////////
  // Writeback data MUX //
  ////////////////////////

  always_comb begin
    unique case (e_gpr_src_sel_i)
      LSU_DATA : m_result = lsu_result;
      ALU_DATA : m_result = e_alu_result_i;
      MDU_DATA : m_result = e_mdu_result_i;
      default  : m_result = e_alu_result_i;
    endcase
  end

  assign m_valid_o       = e_valid_i;
  assign m_gpr_wr_en_o   = e_gpr_wr_en_i & e_valid_i & ~cu_stall_m_i;
  assign m_gpr_wr_addr_o = e_gpr_wr_addr_i;
  assign m_gpr_wr_data_o = m_result;

  assign m_branch_o      = e_branch_i;
  assign m_jal_o         = e_jal_i;
  assign m_jalr_o        = e_jalr_i;
  assign m_target_pc_o   = e_target_pc_i;
  assign m_next_pc_o     = e_next_pc_i;
  assign m_prediction_o  = e_prediction_i;
  assign m_br_j_taken_o  = e_br_j_taken_i;

  assign m_stall_req_o   = lsu_stall_req;


  ////////////////////
  // RVFI interface //
  ////////////////////

  assign m_rvfi_wb_data_o        = m_result;
  assign m_rvfi_wb_we_o          = e_rvfi_wb_we_i;
  assign m_rvfi_wb_rd_addr_o     = e_rvfi_wb_rd_addr_i;
  assign m_rvfi_instr_o          = e_rvfi_instr_i;
  assign m_rvfi_rs1_addr_o       = e_rvfi_rs1_addr_i;
  assign m_rvfi_rs2_addr_o       = e_rvfi_rs2_addr_i;
  assign m_rvfi_op1_gpr_o        = e_rvfi_op1_gpr_i;
  assign m_rvfi_op2_gpr_o        = e_rvfi_op2_gpr_i;
  assign m_rvfi_rs1_rdata_o      = e_rvfi_rs1_rdata_i;
  assign m_rvfi_rs2_rdata_o      = e_rvfi_rs2_rdata_i;
  assign m_rvfi_current_pc_o     = e_rvfi_current_pc_i;
  assign m_rvfi_next_pc_o        = e_rvfi_next_pc_i;
  assign m_rvfi_valid_o          = e_rvfi_valid_i & ~cu_stall_m_i;
  assign m_rvfi_trap_o           = e_rvfi_trap_i;
  assign m_rvfi_intr_o           = e_rvfi_intr_i;
  assign m_rvfi_mem_req_o        = e_rvfi_mem_req_i;
  assign m_rvfi_mem_we_o         = e_rvfi_mem_we_i;
  assign m_rvfi_mem_size_o       = e_rvfi_mem_size_i;
  assign m_rvfi_mem_addr_o       = e_rvfi_mem_addr_i;
  assign m_rvfi_mem_wdata_o      = e_rvfi_mem_wdata_i;
  assign m_rvfi_mem_rdata_o      = lsu_result;


endmodule
