/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

module miriscv_mem_req_stage
  import miriscv_pkg::XLEN;
  import miriscv_gpr_pkg::GPR_ADDR_W;
  import miriscv_lsu_pkg::MEM_ACCESS_W;
  import miriscv_decode_pkg::WB_SRC_W;
  import miriscv_lsu_pkg::*;
(
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
  output logic [WB_SRC_W-1:0]     m_gpr_src_sel_o,

  output logic [XLEN-1:0]         m_alu_result_o,
  output logic [XLEN-1:0]         m_mdu_result_o,

  output logic                    m_branch_o,
  output logic                    m_jal_o,
  output logic                    m_jalr_o,
  output logic [XLEN-1:0]         m_target_pc_o,
  output logic [XLEN-1:0]         m_next_pc_o,
  output logic                    m_prediction_o,
  output logic                    m_br_j_taken_o,

  output logic                    m_mem_req_o,
  output logic [MEM_ACCESS_W-1:0] m_mem_size_o,
  output logic [1:0]              m_mem_addr_o,

  // Data memory interface
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

);




  ////////////////////////
  // Local declarations //
  ////////////////////////


  logic                    m_valid_ff;

  logic [XLEN-1:0]         m_alu_result_ff;
  logic [XLEN-1:0]         m_mdu_result_ff;

  logic                    m_mem_req_ff;
  logic [MEM_ACCESS_W-1:0] m_mem_size_ff;
  logic [1:0]              m_mem_addr_ff;

  logic                    m_gpr_wr_en_ff;
  logic [GPR_ADDR_W-1:0]   m_gpr_wr_addr_ff;
  logic [WB_SRC_W-1:0]     m_gpr_src_sel_ff;

  logic                    m_branch_ff;
  logic                    m_jal_ff;
  logic                    m_jalr_ff;
  logic [XLEN-1:0]         m_target_pc_ff;
  logic [XLEN-1:0]         m_next_pc_ff;
  logic                    m_prediction_ff;
  logic                    m_br_j_taken_ff;




  ///////////////////////////////////
  // Memory request and Data Store //
  ///////////////////////////////////


  always_comb begin
    case (e_mem_size_i)

      MEM_ACCESS_WORD: begin
        data_be_o = 4'b1111;
      end

      MEM_ACCESS_UHALF,
      MEM_ACCESS_HALF: begin
        data_be_o = (4'b0011 << e_mem_addr_i[1:0]);
      end

      MEM_ACCESS_UBYTE,
      MEM_ACCESS_BYTE: begin
        data_be_o = (4'b0001 << e_mem_addr_i[1:0]);
      end

      default: begin
        data_be_o = {(XLEN/8){1'b0}};
      end

    endcase


    case (e_mem_addr_i[1:0])
      2'b00:   data_wdata_o = {e_mem_data_i[31:0]};
      2'b01:   data_wdata_o = {e_mem_data_i[23:0], e_mem_data_i[31:24]};
      2'b10:   data_wdata_o = {e_mem_data_i[15:0], e_mem_data_i[31:16]};
      2'b11:   data_wdata_o = {e_mem_data_i[ 7:0], e_mem_data_i[31: 8]};
      default: data_wdata_o = {XLEN{1'b0}};
    endcase
  end

  assign lsu_req     = e_mem_req_i & e_valid_i;
  assign data_req_o  = lsu_req & ~cu_kill_m_i & ~cu_stall_m_i;
  assign data_addr_o = e_mem_addr_i;
  assign data_we_o   = e_mem_we_i;

  ///////////////////////
  // Pipeline register //
  ///////////////////////

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i)
      m_valid_ff <= '0;
    else if (cu_kill_m_i)
      m_valid_ff <= '0;
    else if (~cu_stall_m_i)
      m_valid_ff <= e_valid_i;
  end


  always_ff @(posedge clk_i) begin
    if (e_valid_i & ~cu_stall_m_i) begin
      m_gpr_wr_en_ff   <= e_gpr_wr_en_i;
      m_gpr_wr_addr_ff <= e_gpr_wr_addr_i;
      m_gpr_src_sel_ff <= e_gpr_src_sel_i;

      m_alu_result_ff  <= e_alu_result_i;
      m_mdu_result_ff  <= e_mdu_result_i;

      m_branch_ff      <= e_branch_i;
      m_jal_ff         <= e_jal_i;
      m_jalr_ff        <= e_jalr_i;
      m_target_pc_ff   <= e_target_pc_i;
      m_next_pc_ff     <= e_next_pc_i;
      m_prediction_ff  <= e_prediction_i;
      m_br_j_taken_ff  <= e_br_j_taken_i;

      m_mem_req_ff     <= e_mem_req_i;
      m_mem_size_ff    <= e_mem_size_i;
      m_mem_addr_ff    <= e_mem_addr_i[1:0];
    end
  end

  assign m_valid_o       = m_valid_ff;

  assign m_gpr_wr_en_o = m_gpr_wr_en_ff;
  assign m_gpr_wr_addr_o = m_gpr_wr_addr_ff;
  assign m_gpr_src_sel_o = m_gpr_src_sel_ff;

  assign m_alu_result_o = m_alu_result_ff;
  assign m_mdu_result_o = m_mdu_result_ff;

  assign m_branch_o     = m_branch_ff;
  assign m_jal_o        = m_jal_ff;
  assign m_jalr_o       = m_jalr_ff;
  assign m_target_pc_o  = m_target_pc_ff;
  assign m_next_pc_o    = m_next_pc_ff;
  assign m_prediction_o = m_prediction_ff;
  assign m_br_j_taken_o = m_br_j_taken_ff;

  assign m_mem_req_o    = m_mem_req_ff;
  assign m_mem_size_o   = m_mem_size_ff;
  assign m_mem_addr_o   = m_mem_addr_ff;

  assign m_stall_req_o = '0;


  ////////////////////
  // RVFI interface //
  ////////////////////

  if (RVFI) begin
    always_ff @(posedge clk_i or negedge arstn_i) begin
      if(~arstn_i) begin
        m_rvfi_wb_we_o          <= '0;
        m_rvfi_wb_rd_addr_o     <= '0;
        m_rvfi_instr_o          <= '0;
        m_rvfi_rs1_addr_o       <= '0;
        m_rvfi_rs2_addr_o       <= '0;
        m_rvfi_op1_gpr_o        <= '0;
        m_rvfi_op2_gpr_o        <= '0;
        m_rvfi_rs1_rdata_o      <= '0;
        m_rvfi_rs2_rdata_o      <= '0;
        m_rvfi_current_pc_o     <= '0;
        m_rvfi_next_pc_o        <= '0;
        m_rvfi_valid_o          <= '0;
        m_rvfi_trap_o           <= '0;
        m_rvfi_intr_o           <= '0;
        m_rvfi_mem_req_o        <= '0;
        m_rvfi_mem_we_o         <= '0;
        m_rvfi_mem_size_o       <= '0;
        m_rvfi_mem_addr_o       <= '0;
        m_rvfi_mem_wdata_o      <= '0;
      end

      else if (cu_kill_e_i) begin
        m_rvfi_wb_we_o          <= '0;
        m_rvfi_wb_rd_addr_o     <= '0;
        m_rvfi_instr_o          <= '0;
        m_rvfi_rs1_addr_o       <= '0;
        m_rvfi_rs2_addr_o       <= '0;
        m_rvfi_op1_gpr_o        <= '0;
        m_rvfi_op2_gpr_o        <= '0;
        m_rvfi_rs1_rdata_o      <= '0;
        m_rvfi_rs2_rdata_o      <= '0;
        m_rvfi_current_pc_o     <= '0;
        m_rvfi_next_pc_o        <= '0;
        m_rvfi_valid_o          <= '0;
        m_rvfi_trap_o           <= '0;
        m_rvfi_intr_o           <= '0;
        m_rvfi_mem_req_o        <= '0;
        m_rvfi_mem_we_o         <= '0;
        m_rvfi_mem_size_o       <= '0;
        m_rvfi_mem_addr_o       <= '0;
        m_rvfi_mem_wdata_o      <= '0;
      end

      else if (~cu_stall_e_i) begin
        m_rvfi_wb_we_o          <= e_rvfi_wb_we_i;
        m_rvfi_wb_rd_addr_o     <= e_rvfi_wb_rd_addr_i;
        m_rvfi_instr_o          <= e_rvfi_instr_i;
        m_rvfi_rs1_addr_o       <= e_rvfi_rs1_addr_i;
        m_rvfi_rs2_addr_o       <= e_rvfi_rs2_addr_i;
        m_rvfi_op1_gpr_o        <= e_rvfi_op1_gpr_i;
        m_rvfi_op2_gpr_o        <= e_rvfi_op2_gpr_i;
        m_rvfi_rs1_rdata_o      <= e_rvfi_rs1_rdata_i;
        m_rvfi_rs2_rdata_o      <= e_rvfi_rs2_rdata_i;
        m_rvfi_current_pc_o     <= e_rvfi_current_pc_i;
        m_rvfi_next_pc_o        <= e_rvfi_next_pc_i;
        m_rvfi_valid_o          <= e_rvfi_valid_i;
        m_rvfi_trap_o           <= e_rvfi_trap_i;
        m_rvfi_intr_o           <= e_rvfi_intr_i;
        m_rvfi_mem_req_o        <= e_rvfi_mem_req_i;
        m_rvfi_mem_we_o         <= e_rvfi_mem_we_i;
        m_rvfi_mem_size_o       <= e_rvfi_mem_size_i;
        m_rvfi_mem_addr_o       <= e_rvfi_mem_addr_i;
        m_rvfi_mem_wdata_o      <= e_rvfi_mem_wdata_i;
      end

    end
  end

  else begin
    assign m_rvfi_wb_we_o          = '0;
    assign m_rvfi_wb_rd_addr_o     = '0;
    assign m_rvfi_instr_o          = '0;
    assign m_rvfi_rs1_addr_o       = '0;
    assign m_rvfi_rs2_addr_o       = '0;
    assign m_rvfi_op1_gpr_o        = '0;
    assign m_rvfi_op2_gpr_o        = '0;
    assign m_rvfi_rs1_rdata_o      = '0;
    assign m_rvfi_rs2_rdata_o      = '0;
    assign m_rvfi_current_pc_o     = '0;
    assign m_rvfi_next_pc_o        = '0;
    assign m_rvfi_valid_o          = '0;
    assign m_rvfi_trap_o           = '0;
    assign m_rvfi_intr_o           = '0;
    assign m_rvfi_mem_req_o        = '0;
    assign m_rvfi_mem_we_o         = '0;
    assign m_rvfi_mem_size_o       = '0;
    assign m_rvfi_mem_addr_o       = '0;
    assign m_rvfi_mem_wdata_o      = '0;
  end

endmodule
