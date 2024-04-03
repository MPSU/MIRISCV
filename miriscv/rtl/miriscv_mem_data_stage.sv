module miriscv_mem_data_stage
  import miriscv_pkg::XLEN;
  import miriscv_pkg::ILEN;
  import miriscv_gpr_pkg::GPR_ADDR_W;
  import miriscv_decode_pkg::LSU_DATA;
  import miriscv_decode_pkg::ALU_DATA;
  import miriscv_decode_pkg::MDU_DATA;
  import miriscv_lsu_pkg::MEM_ACCESS_W;
  import miriscv_decode_pkg::WB_SRC_W;
  import miriscv_lsu_pkg::*;
#(
  parameter bit RVFI = 1'b0
) (
  input  logic                    clk_i,
  input  logic                    arstn_i,

  input  logic                    cu_stall_mp_i,
  input  logic                    cu_kill_mp_i,
  output logic                    mp_stall_req_o,

  input  logic                    m_valid_i,

  input  logic                    m_gpr_wr_en_i,
  input  logic [GPR_ADDR_W-1:0]   m_gpr_wr_addr_i,
  input  logic [WB_SRC_W-1:0]     m_gpr_src_sel_i,

  input  logic [XLEN-1:0]         m_alu_result_i,
  input  logic [XLEN-1:0]         m_mdu_result_i,

  input  logic                    m_branch_i,
  input  logic                    m_jal_i,
  input  logic                    m_jalr_i,
  input  logic [XLEN-1:0]         m_target_pc_i,
  input  logic [XLEN-1:0]         m_next_pc_i,
  input  logic                    m_prediction_i,
  input  logic                    m_br_j_taken_i,

  input  logic                    m_mem_req_i,
  input  logic [MEM_ACCESS_W-1:0] m_mem_size_i,
  input  logic [1:0]              m_mem_addr_i,

  output logic                    mp_valid_o,
  output logic                    mp_gpr_wr_en_o,
  output logic [GPR_ADDR_W-1:0]   mp_gpr_wr_addr_o,
  output logic [XLEN-1:0]         mp_gpr_wr_data_o,

  output logic                    mp_branch_o,
  output logic                    mp_jal_o,
  output logic                    mp_jalr_o,
  output logic [XLEN-1:0]         mp_target_pc_o,
  output logic [XLEN-1:0]         mp_next_pc_o,
  output logic                    mp_prediction_o,
  output logic                    mp_br_j_taken_o,

  // Data memory interface
  input  logic                    data_rvalid_i,
  input  logic [XLEN-1:0]         data_rdata_i,

  // RVFI
  input  logic                    m_rvfi_wb_we_i,
  input  logic [GPR_ADDR_W-1:0]   m_rvfi_wb_rd_addr_i,
  input  logic [ILEN-1:0]         m_rvfi_instr_i,
  input  logic [GPR_ADDR_W-1:0]   m_rvfi_rs1_addr_i,
  input  logic [GPR_ADDR_W-1:0]   m_rvfi_rs2_addr_i,
  input  logic                    m_rvfi_op1_gpr_i,
  input  logic                    m_rvfi_op2_gpr_i,
  input  logic [XLEN-1:0]         m_rvfi_rs1_rdata_i,
  input  logic [XLEN-1:0]         m_rvfi_rs2_rdata_i,
  input  logic [XLEN-1:0]         m_rvfi_current_pc_i,
  input  logic [XLEN-1:0]         m_rvfi_next_pc_i,
  input  logic                    m_rvfi_valid_i,
  input  logic                    m_rvfi_trap_i,
  input  logic                    m_rvfi_intr_i,
  input  logic                    m_rvfi_mem_req_i,
  input  logic                    m_rvfi_mem_we_i,
  input  logic [MEM_ACCESS_W-1:0] m_rvfi_mem_size_i,
  input  logic [XLEN-1:0]         m_rvfi_mem_addr_i,
  input  logic [XLEN-1:0]         m_rvfi_mem_wdata_i,

  output logic [XLEN-1:0]         mp_rvfi_wb_data_o,
  output logic                    mp_rvfi_wb_we_o,
  output logic [GPR_ADDR_W-1:0]   mp_rvfi_wb_rd_addr_o,
  output logic [ILEN-1:0]         mp_rvfi_instr_o,
  output logic [GPR_ADDR_W-1:0]   mp_rvfi_rs1_addr_o,
  output logic [GPR_ADDR_W-1:0]   mp_rvfi_rs2_addr_o,
  output logic                    mp_rvfi_op1_gpr_o,
  output logic                    mp_rvfi_op2_gpr_o,
  output logic [XLEN-1:0]         mp_rvfi_rs1_rdata_o,
  output logic [XLEN-1:0]         mp_rvfi_rs2_rdata_o,
  output logic [XLEN-1:0]         mp_rvfi_current_pc_o,
  output logic [XLEN-1:0]         mp_rvfi_next_pc_o,
  output logic                    mp_rvfi_valid_o,
  output logic                    mp_rvfi_trap_o,
  output logic                    mp_rvfi_intr_o,
  output logic                    mp_rvfi_mem_req_o,
  output logic                    mp_rvfi_mem_we_o,
  output logic [MEM_ACCESS_W-1:0] mp_rvfi_mem_size_o,
  output logic [XLEN-1:0]         mp_rvfi_mem_addr_o,
  output logic [XLEN-1:0]         mp_rvfi_mem_wdata_o,
  output logic [XLEN-1:0]         mp_rvfi_mem_rdata_o

);


  ////////////////////////
  // Local declarations //
  ////////////////////////

  logic [XLEN-1:0] lsu_result;
  logic [XLEN-1:0] m_result;


  //////////
  // Load //
  //////////

  always_comb begin
    case (m_mem_size_i)

      MEM_ACCESS_WORD: begin
        case (m_mem_addr_i[1:0])
          2'b00:   lsu_result = data_rdata_i[31:0];
          default: lsu_result = {XLEN{1'b0}};
        endcase
      end

      MEM_ACCESS_HALF: begin
        case (m_mem_addr_i[1:0])
          2'b00:   lsu_result = {{(XLEN-16){data_rdata_i[15]}}, data_rdata_i[15: 0]};
          2'b01:   lsu_result = {{(XLEN-16){data_rdata_i[23]}}, data_rdata_i[23: 8]};
          2'b10:   lsu_result = {{(XLEN-16){data_rdata_i[31]}}, data_rdata_i[31:16]};
          default: lsu_result = {XLEN{1'b0}};
        endcase
      end

      MEM_ACCESS_BYTE: begin
        case (m_mem_addr_i[1:0])
          2'b00:   lsu_result = {{(XLEN-8){data_rdata_i[ 7]}}, data_rdata_i[ 7: 0]};
          2'b01:   lsu_result = {{(XLEN-8){data_rdata_i[15]}}, data_rdata_i[15: 8]};
          2'b10:   lsu_result = {{(XLEN-8){data_rdata_i[23]}}, data_rdata_i[23:16]};
          2'b11:   lsu_result = {{(XLEN-8){data_rdata_i[31]}}, data_rdata_i[31:24]};
          default: lsu_result = {XLEN{1'b0}};
        endcase
      end

      MEM_ACCESS_UHALF: begin
        case (m_mem_addr_i[1:0])
          2'b00:   lsu_result = {{(XLEN-16){1'b0}}, data_rdata_i[15: 0]};
          2'b01:   lsu_result = {{(XLEN-16){1'b0}}, data_rdata_i[23: 8]};
          2'b10:   lsu_result = {{(XLEN-16){1'b0}}, data_rdata_i[31:16]};
          default: lsu_result = {XLEN{1'b0}};
        endcase
      end

      MEM_ACCESS_UBYTE: begin
        case (m_mem_addr_i[1:0])
          2'b00:   lsu_result = {{(XLEN-8){1'b0}}, data_rdata_i[ 7: 0]};
          2'b01:   lsu_result = {{(XLEN-8){1'b0}}, data_rdata_i[15: 8]};
          2'b10:   lsu_result = {{(XLEN-8){1'b0}}, data_rdata_i[23:16]};
          2'b11:   lsu_result = {{(XLEN-8){1'b0}}, data_rdata_i[31:24]};
          default: lsu_result = {XLEN{1'b0}};
        endcase
      end

      default: begin
        lsu_result = {XLEN{1'b0}};
      end

    endcase
  end


  ////////////////////////
  // Writeback data MUX //
  ////////////////////////

  always_comb begin
    unique case (m_gpr_src_sel_i)
      LSU_DATA : m_result = lsu_result;
      ALU_DATA : m_result = m_alu_result_i;
      MDU_DATA : m_result = m_mdu_result_i;
      default  : m_result = m_alu_result_i;
    endcase
  end

  assign mp_valid_o       = m_valid_i;
  assign mp_gpr_wr_en_o   = m_gpr_wr_en_i & m_valid_i & ~cu_stall_mp_i;
  assign mp_gpr_wr_addr_o = m_gpr_wr_addr_i;
  assign mp_gpr_wr_data_o = m_result;

  assign mp_branch_o      = m_branch_i;
  assign mp_jal_o         = m_jal_i;
  assign mp_jalr_o        = m_jalr_i;
  assign mp_target_pc_o   = m_target_pc_i;
  assign mp_next_pc_o     = m_next_pc_i;
  assign mp_prediction_o  = m_prediction_i;
  assign mp_br_j_taken_o  = m_br_j_taken_i;

  assign mp_stall_req_o   = m_valid_i & m_mem_req_i & ~cu_kill_mp_i & ~data_rvalid_i;



  ////////////////////
  // RVFI interface //
  ////////////////////

  assign mp_rvfi_wb_data_o        = m_result;
  assign mp_rvfi_wb_we_o          = m_rvfi_wb_we_i;
  assign mp_rvfi_wb_rd_addr_o     = m_rvfi_wb_rd_addr_i;
  assign mp_rvfi_instr_o          = m_rvfi_instr_i;
  assign mp_rvfi_rs1_addr_o       = m_rvfi_rs1_addr_i;
  assign mp_rvfi_rs2_addr_o       = m_rvfi_rs2_addr_i;
  assign mp_rvfi_op1_gpr_o        = m_rvfi_op1_gpr_i;
  assign mp_rvfi_op2_gpr_o        = m_rvfi_op2_gpr_i;
  assign mp_rvfi_rs1_rdata_o      = m_rvfi_rs1_rdata_i;
  assign mp_rvfi_rs2_rdata_o      = m_rvfi_rs2_rdata_i;
  assign mp_rvfi_current_pc_o     = m_rvfi_current_pc_i;
  assign mp_rvfi_next_pc_o        = m_rvfi_next_pc_i;
  assign mp_rvfi_valid_o          = m_rvfi_valid_i & ~cu_stall_mp_i;
  assign mp_rvfi_trap_o           = m_rvfi_trap_i;
  assign mp_rvfi_intr_o           = m_rvfi_intr_i;
  assign mp_rvfi_mem_req_o        = m_rvfi_mem_req_i;
  assign mp_rvfi_mem_we_o         = m_rvfi_mem_we_i;
  assign mp_rvfi_mem_size_o       = m_rvfi_mem_size_i;
  assign mp_rvfi_mem_addr_o       = m_rvfi_mem_addr_i;
  assign mp_rvfi_mem_wdata_o      = m_rvfi_mem_wdata_i;
  assign mp_rvfi_mem_rdata_o      = lsu_result;



endmodule
