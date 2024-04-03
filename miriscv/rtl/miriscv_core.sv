/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

module miriscv_core
  import miriscv_pkg::XLEN;
  import miriscv_pkg::ILEN;
  import miriscv_gpr_pkg::GPR_ADDR_W;
  import miriscv_alu_pkg::ALU_OP_W;
  import miriscv_mdu_pkg::MDU_OP_W;
  import miriscv_lsu_pkg::MEM_ACCESS_W;
  import miriscv_decode_pkg::WB_SRC_W;
#(
  parameter bit RVFI = 1'b1
)
(
  // Clock, reset
  input  logic              clk_i,
  input  logic              arstn_i,

  input  logic [XLEN-1:0]   boot_addr_i,

  // Instruction memory interface
  input  logic              instr_rvalid_i,
  input  logic [XLEN-1:0]   instr_rdata_i,
  output logic              instr_req_o,
  output logic [XLEN-1:0]   instr_addr_o,

  // Data memory interface
  input  logic              data_rvalid_i,
  input  logic [XLEN-1:0]   data_rdata_i,
  output logic              data_req_o,
  output logic              data_we_o,
  output logic [XLEN/8-1:0] data_be_o,
  output logic [XLEN-1:0]   data_addr_o,
  output logic [XLEN-1:0]   data_wdata_o,

  // RVFI
  output logic              rvfi_valid_o,
  output logic [63:0]       rvfi_order_o,
  output logic [31:0]       rvfi_insn_o,
  output logic              rvfi_trap_o,
  output logic              rvfi_halt_o,
  output logic              rvfi_intr_o,
  output logic [ 1:0]       rvfi_mode_o,
  output logic [ 1:0]       rvfi_ixl_o,
  output logic [ 4:0]       rvfi_rs1_addr_o,
  output logic [ 4:0]       rvfi_rs2_addr_o,
  output logic [31:0]       rvfi_rs1_rdata_o,
  output logic [31:0]       rvfi_rs2_rdata_o,
  output logic [ 4:0]       rvfi_rd_addr_o,
  output logic [31:0]       rvfi_rd_wdata_o,
  output logic [31:0]       rvfi_pc_rdata_o,
  output logic [31:0]       rvfi_pc_wdata_o,
  output logic [31:0]       rvfi_mem_addr_o,
  output logic [ 3:0]       rvfi_mem_rmask_o,
  output logic [ 3:0]       rvfi_mem_wmask_o,
  output logic [31:0]       rvfi_mem_rdata_o,
  output logic [31:0]       rvfi_mem_wdata_o
);


  ////////////////////////
  // Local declarations //
  ////////////////////////

  localparam f = 3'd0; // fetch
  localparam d = 3'd1; // decode
  localparam e = 3'd2; // execute
  localparam m = 3'd3; // memory
  localparam mp = 3'd4; // memory plus
  localparam w = 3'd5; // writeback

  logic [XLEN-1:0]         current_pc      [f:f];
  logic [XLEN-1:0]         next_pc         [f:mp];

  logic [ILEN-1:0]         instr           [f:f];
  logic                    valid           [f:mp];

  logic                    gpr_wr_en       [d:mp];
  logic [GPR_ADDR_W-1:0]   gpr_wr_addr     [d:mp];
  logic [WB_SRC_W-1:0]     gpr_src_sel     [d:m];
  logic [XLEN-1:0]         gpr_wr_data     [mp:mp];

  logic [XLEN-1:0]         op1             [d:d];
  logic [XLEN-1:0]         op2             [d:d];

  logic [XLEN-1:0]         alu_result      [e:m];
  logic [XLEN-1:0]         mdu_result      [e:m];

  logic [ALU_OP_W-1:0]     alu_operation   [d:d];
  logic                    mdu_req         [d:d];
  logic [MDU_OP_W-1:0]     mdu_operation   [d:d];

  logic                    mem_req         [d:m];
  logic                    mem_we          [d:e];
  logic [MEM_ACCESS_W-1:0] mem_size        [d:m];
  logic [XLEN-1:0]         mem_addr        [d:m];
  logic [XLEN-1:0]         mem_data        [d:e];

  logic                    branch          [d:mp];
  logic                    jal             [d:mp];
  logic                    jalr            [d:mp];
  logic [XLEN-1:0]         target_pc       [d:mp];
  logic                    prediction      [d:mp];
  logic                    br_j_taken      [d:mp];

  logic                    cu_stall_req    [f:mp];
  logic                    cu_stall        [f:mp];
  logic                    cu_kill         [f:mp];
  logic                    cu_force        [f:f];
  logic [XLEN-1:0]         cu_force_pc     [f:f];

  logic [GPR_ADDR_W-1:0]   cu_rs1_addr     [f:f];
  logic                    cu_rs1_req      [f:f];
  logic [GPR_ADDR_W-1:0]   cu_rs2_addr     [f:f];
  logic                    cu_rs2_req      [f:f];

  logic [XLEN-1:0]         rvfi_wb_data    [mp:w];
  logic                    rvfi_wb_we      [f:w];
  logic [GPR_ADDR_W-1:0]   rvfi_wb_rd_addr [f:w];

  logic [ILEN-1:0]         rvfi_instr      [f:w];
  logic [GPR_ADDR_W-1:0]   rvfi_rs1_addr   [f:w];
  logic [GPR_ADDR_W-1:0]   rvfi_rs2_addr   [f:w];
  logic                    rvfi_op1_gpr    [f:w];
  logic                    rvfi_op2_gpr    [f:w];
  logic [XLEN-1:0]         rvfi_rs1_rdata  [f:w];
  logic [XLEN-1:0]         rvfi_rs2_rdata  [f:w];
  logic [XLEN-1:0]         rvfi_current_pc [f:w];
  logic [XLEN-1:0]         rvfi_next_pc    [f:w];
  logic                    rvfi_valid      [f:w];
  logic                    rvfi_trap       [f:w];
  logic                    rvfi_intr       [f:w];

  logic                    rvfi_mem_req    [f:w];
  logic                    rvfi_mem_we     [f:w];
  logic [MEM_ACCESS_W-1:0] rvfi_mem_size   [f:w];
  logic [XLEN-1:0]         rvfi_mem_addr   [f:w];
  logic [XLEN-1:0]         rvfi_mem_wdata  [f:w];
  logic [XLEN-1:0]         rvfi_mem_rdata  [mp:w];


  /////////////////
  // Fetch stage //
  /////////////////

  miriscv_fetch_stage
  #(
    .RVFI ( RVFI )
  )
  i_fetch_stage
  (
    .clk_i          ( clk_i              ),
    .arstn_i        ( arstn_i            ),

    .cu_kill_f_i    ( cu_kill        [f] ),
    .cu_stall_f_i   ( cu_stall       [f] ),
    .cu_force_f_i   ( cu_force       [f] ),
    .cu_force_pc_i  ( cu_force_pc    [f] ),
    .f_stall_req_o  ( cu_stall_req   [f] ),

    .instr_rvalid_i ( instr_rvalid_i     ),
    .instr_rdata_i  ( instr_rdata_i      ),
    .instr_req_o    ( instr_req_o        ),
    .instr_addr_o   ( instr_addr_o       ),

    .f_instr_o      ( instr          [f] ),
    .f_current_pc_o ( current_pc     [f] ),
    .f_next_pc_o    ( next_pc        [f] ),
    .f_valid_o      ( valid          [f] )
  );


  //////////////////
  // Decode stage //
  //////////////////

  miriscv_decode_stage
  #(
    .RVFI ( RVFI )
  )
  i_decode_stage
  (
    .clk_i               ( clk_i               ),
    .arstn_i             ( arstn_i             ),

    .cu_kill_d_i         ( cu_kill         [d] ),
    .cu_stall_d_i        ( cu_stall        [d] ),
    .cu_stall_f_i        ( cu_stall        [f] ),
    .d_stall_req_o       ( cu_stall_req    [d] ),

    .f_instr_i           ( instr           [f] ),
    .f_current_pc_i      ( current_pc      [f] ),
    .f_next_pc_i         ( next_pc         [f] ),
    .f_valid_i           ( valid           [f] ),

    .m_gpr_wr_en_i       ( gpr_wr_en       [mp] ),
    .m_gpr_wr_data_i     ( gpr_wr_data     [mp] ),
    .m_gpr_wr_addr_i     ( gpr_wr_addr     [mp] ),

    .d_valid_o           ( valid           [d] ),

    .d_op1_o             ( op1             [d] ),
    .d_op2_o             ( op2             [d] ),

    .d_alu_operation_o   ( alu_operation   [d] ),
    .d_mdu_req_o         ( mdu_req         [d] ),
    .d_mdu_operation_o   ( mdu_operation   [d] ),

    .d_mem_req_o         ( mem_req         [d] ),
    .d_mem_we_o          ( mem_we          [d] ),
    .d_mem_size_o        ( mem_size        [d] ),
    .d_mem_addr_o        ( mem_addr        [d] ),
    .d_mem_data_o        ( mem_data        [d] ),

    .d_gpr_wr_en_o       ( gpr_wr_en       [d] ),
    .d_gpr_wr_addr_o     ( gpr_wr_addr     [d] ),
    .d_gpr_src_sel_o     ( gpr_src_sel     [d] ),

    .d_branch_o          ( branch          [d] ),
    .d_jal_o             ( jal             [d] ),
    .d_jalr_o            ( jalr            [d] ),
    .d_target_pc_o       ( target_pc       [d] ),
    .d_next_pc_o         ( next_pc         [d] ),
    .d_prediction_o      ( prediction      [d] ),
    .d_br_j_taken_o      ( br_j_taken      [d] ),

    .f_cu_rs1_addr_o     ( cu_rs1_addr     [f] ),
    .f_cu_rs1_req_o      ( cu_rs1_req      [f] ),
    .f_cu_rs2_addr_o     ( cu_rs2_addr     [f] ),
    .f_cu_rs2_req_o      ( cu_rs2_req      [f] ),

    .d_rvfi_wb_we_o      ( rvfi_wb_we      [d] ),
    .d_rvfi_wb_rd_addr_o ( rvfi_wb_rd_addr [d] ),
    .d_rvfi_instr_o      ( rvfi_instr      [d] ),
    .d_rvfi_rs1_addr_o   ( rvfi_rs1_addr   [d] ),
    .d_rvfi_rs2_addr_o   ( rvfi_rs2_addr   [d] ),
    .d_rvfi_op1_gpr_o    ( rvfi_op1_gpr    [d] ),
    .d_rvfi_op2_gpr_o    ( rvfi_op2_gpr    [d] ),
    .d_rvfi_rs1_rdata_o  ( rvfi_rs1_rdata  [d] ),
    .d_rvfi_rs2_rdata_o  ( rvfi_rs2_rdata  [d] ),
    .d_rvfi_current_pc_o ( rvfi_current_pc [d] ),
    .d_rvfi_next_pc_o    ( rvfi_next_pc    [d] ),
    .d_rvfi_valid_o      ( rvfi_valid      [d] ),
    .d_rvfi_trap_o       ( rvfi_trap       [d] ),
    .d_rvfi_intr_o       ( rvfi_intr       [d] ),
    .d_rvfi_mem_req_o    ( rvfi_mem_req    [d] ),
    .d_rvfi_mem_we_o     ( rvfi_mem_we     [d] ),
    .d_rvfi_mem_size_o   ( rvfi_mem_size   [d] ),
    .d_rvfi_mem_addr_o   ( rvfi_mem_addr   [d] ),
    .d_rvfi_mem_wdata_o  ( rvfi_mem_wdata  [d] )
  );


  ///////////////////
  // Execute stage //
  ///////////////////

  miriscv_execute_stage
  #(
    .RVFI ( RVFI )
  )
  i_execute_stage
  (
    .clk_i               ( clk_i               ),
    .arstn_i             ( arstn_i             ),

    .cu_kill_e_i         ( cu_kill         [e] ),
    .cu_stall_e_i        ( cu_stall        [e] ),
    .e_stall_req_o       ( cu_stall_req    [e] ),

    .d_valid_i           ( valid           [d] ),

    .d_op1_i             ( op1             [d] ),
    .d_op2_i             ( op2             [d] ),

    .d_alu_operation_i   ( alu_operation   [d] ),
    .d_mdu_req_i         ( mdu_req         [d] ),
    .d_mdu_operation_i   ( mdu_operation   [d] ),

    .d_mem_req_i         ( mem_req         [d] ),
    .d_mem_we_i          ( mem_we          [d] ),
    .d_mem_size_i        ( mem_size        [d] ),
    .d_mem_addr_i        ( mem_addr        [d] ),
    .d_mem_data_i        ( mem_data        [d] ),

    .d_gpr_wr_en_i       ( gpr_wr_en       [d] ),
    .d_gpr_wr_addr_i     ( gpr_wr_addr     [d] ),
    .d_gpr_src_sel_i     ( gpr_src_sel     [d] ),

    .d_branch_i          ( branch          [d] ),
    .d_jal_i             ( jal             [d] ),
    .d_jalr_i            ( jalr            [d] ),
    .d_target_pc_i       ( target_pc       [d] ),
    .d_next_pc_i         ( next_pc         [d] ),
    .d_prediction_i      ( prediction      [d] ),
    .d_br_j_taken_i      ( br_j_taken      [d] ),

    .e_valid_o           ( valid           [e] ),

    .e_alu_result_o      ( alu_result      [e] ),
    .e_mdu_result_o      ( mdu_result      [e] ),

    .e_mem_req_o         ( mem_req         [e] ),
    .e_mem_we_o          ( mem_we          [e] ),
    .e_mem_size_o        ( mem_size        [e] ),
    .e_mem_addr_o        ( mem_addr        [e] ),
    .e_mem_data_o        ( mem_data        [e] ),

    .e_gpr_wr_en_o       ( gpr_wr_en       [e] ),
    .e_gpr_wr_addr_o     ( gpr_wr_addr     [e] ),
    .e_gpr_src_sel_o     ( gpr_src_sel     [e] ),

    .e_branch_o          ( branch          [e] ),
    .e_jal_o             ( jal             [e] ),
    .e_jalr_o            ( jalr            [e] ),
    .e_target_pc_o       ( target_pc       [e] ),
    .e_next_pc_o         ( next_pc         [e] ),
    .e_prediction_o      ( prediction      [e] ),
    .e_br_j_taken_o      ( br_j_taken      [e] ),

    .d_rvfi_wb_we_i      ( rvfi_wb_we      [d] ),
    .d_rvfi_wb_rd_addr_i ( rvfi_wb_rd_addr [d] ),
    .d_rvfi_instr_i      ( rvfi_instr      [d] ),
    .d_rvfi_rs1_addr_i   ( rvfi_rs1_addr   [d] ),
    .d_rvfi_rs2_addr_i   ( rvfi_rs2_addr   [d] ),
    .d_rvfi_op1_gpr_i    ( rvfi_op1_gpr    [d] ),
    .d_rvfi_op2_gpr_i    ( rvfi_op2_gpr    [d] ),
    .d_rvfi_rs1_rdata_i  ( rvfi_rs1_rdata  [d] ),
    .d_rvfi_rs2_rdata_i  ( rvfi_rs2_rdata  [d] ),
    .d_rvfi_current_pc_i ( rvfi_current_pc [d] ),
    .d_rvfi_next_pc_i    ( rvfi_next_pc    [d] ),
    .d_rvfi_valid_i      ( rvfi_valid      [d] ),
    .d_rvfi_trap_i       ( rvfi_trap       [d] ),
    .d_rvfi_intr_i       ( rvfi_intr       [d] ),
    .d_rvfi_mem_req_i    ( rvfi_mem_req    [d] ),
    .d_rvfi_mem_we_i     ( rvfi_mem_we     [d] ),
    .d_rvfi_mem_size_i   ( rvfi_mem_size   [d] ),
    .d_rvfi_mem_addr_i   ( rvfi_mem_addr   [d] ),
    .d_rvfi_mem_wdata_i  ( rvfi_mem_wdata  [d] ),

    .e_rvfi_wb_we_o      ( rvfi_wb_we      [e] ),
    .e_rvfi_wb_rd_addr_o ( rvfi_wb_rd_addr [e] ),
    .e_rvfi_instr_o      ( rvfi_instr      [e] ),
    .e_rvfi_rs1_addr_o   ( rvfi_rs1_addr   [e] ),
    .e_rvfi_rs2_addr_o   ( rvfi_rs2_addr   [e] ),
    .e_rvfi_op1_gpr_o    ( rvfi_op1_gpr    [e] ),
    .e_rvfi_op2_gpr_o    ( rvfi_op2_gpr    [e] ),
    .e_rvfi_rs1_rdata_o  ( rvfi_rs1_rdata  [e] ),
    .e_rvfi_rs2_rdata_o  ( rvfi_rs2_rdata  [e] ),
    .e_rvfi_current_pc_o ( rvfi_current_pc [e] ),
    .e_rvfi_next_pc_o    ( rvfi_next_pc    [e] ),
    .e_rvfi_valid_o      ( rvfi_valid      [e] ),
    .e_rvfi_trap_o       ( rvfi_trap       [e] ),
    .e_rvfi_intr_o       ( rvfi_intr       [e] ),
    .e_rvfi_mem_req_o    ( rvfi_mem_req    [e] ),
    .e_rvfi_mem_we_o     ( rvfi_mem_we     [e] ),
    .e_rvfi_mem_size_o   ( rvfi_mem_size   [e] ),
    .e_rvfi_mem_addr_o   ( rvfi_mem_addr   [e] ),
    .e_rvfi_mem_wdata_o  ( rvfi_mem_wdata  [e] )
  );


  //////////////////
  // Memory stage //
  //////////////////

  miriscv_mem_req_stage
  #(
    .RVFI ( RVFI )
  )
  i_memory_stage
  (
    .clk_i               ( clk_i               ),
    .arstn_i             ( arstn_i             ),

    .cu_kill_m_i         ( cu_kill         [m] ),
    .cu_stall_m_i        ( cu_stall        [m] ),
    .m_stall_req_o       ( cu_stall_req    [m] ),

    .e_valid_i           ( valid           [e] ),

    .e_alu_result_i      ( alu_result      [e] ),
    .e_mdu_result_i      ( mdu_result      [e] ),

    .e_mem_req_i         ( mem_req         [e] ),
    .e_mem_we_i          ( mem_we          [e] ),
    .e_mem_size_i        ( mem_size        [e] ),
    .e_mem_addr_i        ( mem_addr        [e] ),
    .e_mem_data_i        ( mem_data        [e] ),

    .e_gpr_wr_en_i       ( gpr_wr_en       [e] ),
    .e_gpr_wr_addr_i     ( gpr_wr_addr     [e] ),
    .e_gpr_src_sel_i     ( gpr_src_sel     [e] ),

    .e_branch_i          ( branch          [e] ),
    .e_jal_i             ( jal             [e] ),
    .e_jalr_i            ( jalr            [e] ),
    .e_target_pc_i       ( target_pc       [e] ),
    .e_next_pc_i         ( next_pc         [e] ),
    .e_prediction_i      ( prediction      [e] ),
    .e_br_j_taken_i      ( br_j_taken      [e] ),

    .m_valid_o           ( valid           [m] ),
    .m_gpr_wr_en_o       ( gpr_wr_en       [m] ),
    .m_gpr_wr_addr_o     ( gpr_wr_addr     [m] ),
    .m_gpr_src_sel_o     ( gpr_src_sel     [m] ),

    .m_alu_result_o      ( alu_result      [m] ),
    .m_mdu_result_o      ( mdu_result      [m] ),

    .m_branch_o          ( branch          [m] ),
    .m_jal_o             ( jal             [m] ),
    .m_jalr_o            ( jalr            [m] ),
    .m_target_pc_o       ( target_pc       [m] ),
    .m_next_pc_o         ( next_pc         [m] ),
    .m_prediction_o      ( prediction      [m] ),
    .m_br_j_taken_o      ( br_j_taken      [m] ),

    .m_mem_req_o         ( mem_req         [m] ),
    .m_mem_size_o        ( mem_size        [m] ),
    .m_mem_addr_o        ( mem_addr        [m] ),

    .data_req_o          ( data_req_o          ),
    .data_we_o           ( data_we_o           ),
    .data_be_o           ( data_be_o           ),
    .data_addr_o         ( data_addr_o         ),
    .data_wdata_o        ( data_wdata_o        ),

    .e_rvfi_wb_we_i      ( rvfi_wb_we      [e] ),
    .e_rvfi_wb_rd_addr_i ( rvfi_wb_rd_addr [e] ),
    .e_rvfi_instr_i      ( rvfi_instr      [e] ),
    .e_rvfi_rs1_addr_i   ( rvfi_rs1_addr   [e] ),
    .e_rvfi_rs2_addr_i   ( rvfi_rs2_addr   [e] ),
    .e_rvfi_op1_gpr_i    ( rvfi_op1_gpr    [e] ),
    .e_rvfi_op2_gpr_i    ( rvfi_op2_gpr    [e] ),
    .e_rvfi_rs1_rdata_i  ( rvfi_rs1_rdata  [e] ),
    .e_rvfi_rs2_rdata_i  ( rvfi_rs2_rdata  [e] ),
    .e_rvfi_current_pc_i ( rvfi_current_pc [e] ),
    .e_rvfi_next_pc_i    ( rvfi_next_pc    [e] ),
    .e_rvfi_valid_i      ( rvfi_valid      [e] ),
    .e_rvfi_trap_i       ( rvfi_trap       [e] ),
    .e_rvfi_intr_i       ( rvfi_intr       [e] ),
    .e_rvfi_mem_req_i    ( rvfi_mem_req    [e] ),
    .e_rvfi_mem_we_i     ( rvfi_mem_we     [e] ),
    .e_rvfi_mem_size_i   ( rvfi_mem_size   [e] ),
    .e_rvfi_mem_addr_i   ( rvfi_mem_addr   [e] ),
    .e_rvfi_mem_wdata_i  ( rvfi_mem_wdata  [e] ),

    .m_rvfi_wb_we_o      ( rvfi_wb_we      [m] ),
    .m_rvfi_wb_rd_addr_o ( rvfi_wb_rd_addr [m] ),
    .m_rvfi_instr_o      ( rvfi_instr      [m] ),
    .m_rvfi_rs1_addr_o   ( rvfi_rs1_addr   [m] ),
    .m_rvfi_rs2_addr_o   ( rvfi_rs2_addr   [m] ),
    .m_rvfi_op1_gpr_o    ( rvfi_op1_gpr    [m] ),
    .m_rvfi_op2_gpr_o    ( rvfi_op2_gpr    [m] ),
    .m_rvfi_rs1_rdata_o  ( rvfi_rs1_rdata  [m] ),
    .m_rvfi_rs2_rdata_o  ( rvfi_rs2_rdata  [m] ),
    .m_rvfi_current_pc_o ( rvfi_current_pc [m] ),
    .m_rvfi_next_pc_o    ( rvfi_next_pc    [m] ),
    .m_rvfi_valid_o      ( rvfi_valid      [m] ),
    .m_rvfi_trap_o       ( rvfi_trap       [m] ),
    .m_rvfi_intr_o       ( rvfi_intr       [m] ),
    .m_rvfi_mem_req_o    ( rvfi_mem_req    [m] ),
    .m_rvfi_mem_we_o     ( rvfi_mem_we     [m] ),
    .m_rvfi_mem_size_o   ( rvfi_mem_size   [m] ),
    .m_rvfi_mem_addr_o   ( rvfi_mem_addr   [m] ),
    .m_rvfi_mem_wdata_o  ( rvfi_mem_wdata  [m] )
  );

  ///////////////////////
  // Memory plus stage //
  ///////////////////////

  miriscv_mem_data_stage
  #(
    .RVFI ( RVFI )
  )
  i_memory_plus_stage
  (
    .clk_i               ( clk_i              ),
    .arstn_i             ( arstn_i            ),

    .cu_stall_mp_i       ( cu_stall       [mp]),
    .cu_kill_mp_i        ( cu_kill        [mp]),
    .mp_stall_req_o      ( cu_stall_req   [mp]),

    .m_valid_i           ( valid          [m] ),

    .m_gpr_wr_en_i       ( gpr_wr_en      [m] ),
    .m_gpr_wr_addr_i     ( gpr_wr_addr    [m] ),
    .m_gpr_src_sel_i     ( gpr_src_sel    [m] ),

    .m_alu_result_i      ( alu_result     [m] ),
    .m_mdu_result_i      ( mdu_result     [m] ),

    .m_branch_i          ( branch         [m] ),
    .m_jal_i             ( jal            [m] ),
    .m_jalr_i            ( jalr           [m] ),
    .m_target_pc_i       ( target_pc      [m] ),
    .m_next_pc_i         ( next_pc        [m] ),
    .m_prediction_i      ( prediction     [m] ),
    .m_br_j_taken_i      ( br_j_taken     [m] ),

    .m_mem_req_i         ( mem_req        [m] ),
    .m_mem_size_i        ( mem_size       [m] ),
    .m_mem_addr_i        ( mem_addr       [m] ),

    .mp_valid_o          ( valid          [mp]),
    .mp_gpr_wr_en_o      ( gpr_wr_en      [mp]),
    .mp_gpr_wr_addr_o    ( gpr_wr_addr    [mp]),
    .mp_gpr_wr_data_o    ( gpr_wr_data    [mp]),

    .mp_branch_o         ( branch         [mp]),
    .mp_jal_o            ( jal            [mp]),
    .mp_jalr_o           ( jalr           [mp]),
    .mp_target_pc_o      ( target_pc      [mp]),
    .mp_next_pc_o        ( next_pc        [mp]),
    .mp_prediction_o     ( prediction     [mp]),
    .mp_br_j_taken_o     ( br_j_taken     [mp]),

    .data_rvalid_i       ( data_rvalid_i      ),
    .data_rdata_i        ( data_rdata_i       ),

    .m_rvfi_wb_we_i       ( rvfi_wb_we      [m] ),
    .m_rvfi_wb_rd_addr_i  ( rvfi_wb_rd_addr [m] ),
    .m_rvfi_instr_i       ( rvfi_instr      [m] ),
    .m_rvfi_rs1_addr_i    ( rvfi_rs1_addr   [m] ),
    .m_rvfi_rs2_addr_i    ( rvfi_rs2_addr   [m] ),
    .m_rvfi_op1_gpr_i     ( rvfi_op1_gpr    [m] ),
    .m_rvfi_op2_gpr_i     ( rvfi_op2_gpr    [m] ),
    .m_rvfi_rs1_rdata_i   ( rvfi_rs1_rdata  [m] ),
    .m_rvfi_rs2_rdata_i   ( rvfi_rs2_rdata  [m] ),
    .m_rvfi_current_pc_i  ( rvfi_current_pc [m] ),
    .m_rvfi_next_pc_i     ( rvfi_next_pc    [m] ),
    .m_rvfi_valid_i       ( rvfi_valid      [m] ),
    .m_rvfi_trap_i        ( rvfi_trap       [m] ),
    .m_rvfi_intr_i        ( rvfi_intr       [m] ),
    .m_rvfi_mem_req_i     ( rvfi_mem_req    [m] ),
    .m_rvfi_mem_we_i      ( rvfi_mem_we     [m] ),
    .m_rvfi_mem_size_i    ( rvfi_mem_size   [m] ),
    .m_rvfi_mem_addr_i    ( rvfi_mem_addr   [m] ),
    .m_rvfi_mem_wdata_i   ( rvfi_mem_wdata  [m] ),

    .mp_rvfi_wb_data_o    ( rvfi_wb_data    [mp] ),
    .mp_rvfi_wb_we_o      ( rvfi_wb_we      [mp] ),
    .mp_rvfi_wb_rd_addr_o ( rvfi_wb_rd_addr [mp] ),
    .mp_rvfi_instr_o      ( rvfi_instr      [mp] ),
    .mp_rvfi_rs1_addr_o   ( rvfi_rs1_addr   [mp] ),
    .mp_rvfi_rs2_addr_o   ( rvfi_rs2_addr   [mp] ),
    .mp_rvfi_op1_gpr_o    ( rvfi_op1_gpr    [mp] ),
    .mp_rvfi_op2_gpr_o    ( rvfi_op2_gpr    [mp] ),
    .mp_rvfi_rs1_rdata_o  ( rvfi_rs1_rdata  [mp] ),
    .mp_rvfi_rs2_rdata_o  ( rvfi_rs2_rdata  [mp] ),
    .mp_rvfi_current_pc_o ( rvfi_current_pc [mp] ),
    .mp_rvfi_next_pc_o    ( rvfi_next_pc    [mp] ),
    .mp_rvfi_valid_o      ( rvfi_valid      [mp] ),
    .mp_rvfi_trap_o       ( rvfi_trap       [mp] ),
    .mp_rvfi_intr_o       ( rvfi_intr       [mp] ),
    .mp_rvfi_mem_req_o    ( rvfi_mem_req    [mp] ),
    .mp_rvfi_mem_we_o     ( rvfi_mem_we     [mp] ),
    .mp_rvfi_mem_size_o   ( rvfi_mem_size   [mp] ),
    .mp_rvfi_mem_addr_o   ( rvfi_mem_addr   [mp] ),
    .mp_rvfi_mem_wdata_o  ( rvfi_mem_wdata  [mp] ),
    .mp_rvfi_mem_rdata_o  ( rvfi_mem_rdata  [mp] )

  );


  //////////////////
  // Control Unit //
  //////////////////

  miriscv_control_unit
  i_control_unit
  (
    .clk_i              ( clk_i              ),
    .arstn_i            ( arstn_i            ),

    .boot_addr_i        ( boot_addr_i        ),

    .f_stall_req_i      ( cu_stall_req   [f] ),
    .d_stall_req_i      ( cu_stall_req   [d] ),
    .e_stall_req_i      ( cu_stall_req   [e] ),
    .m_stall_req_i      ( cu_stall_req   [m] ),
    .mp_stall_req_i     ( cu_stall_req   [mp]),

    .f_valid_i          ( valid          [f] ),
    .d_valid_i          ( valid          [d] ),
    .e_valid_i          ( valid          [e] ),
    .m_valid_i          ( valid          [m] ),
    .mp_valid_i         ( valid          [mp]),

    .f_cu_rs1_addr_i    ( cu_rs1_addr    [f] ),
    .f_cu_rs1_req_i     ( cu_rs1_req     [f] ),
    .f_cu_rs2_addr_i    ( cu_rs2_addr    [f] ),
    .f_cu_rs2_req_i     ( cu_rs2_req     [f] ),

    .d_cu_rd_addr_i     ( gpr_wr_addr    [d] ),
    .d_cu_rd_we_i       ( gpr_wr_en      [d] ),

    .e_cu_rd_addr_i     ( gpr_wr_addr    [e] ),
    .e_cu_rd_we_i       ( gpr_wr_en      [e] ),

    .m_cu_rd_addr_i     ( gpr_wr_addr    [m] ),
    .m_cu_rd_we_i       ( gpr_wr_en      [m] ),

    .mp_branch_i        ( branch         [mp]),
    .mp_jal_i           ( jal            [mp]),
    .mp_jalr_i          ( jalr           [mp]),
    .mp_target_pc_i     ( target_pc      [mp]),
    .mp_next_pc_i       ( next_pc        [mp]),
    .mp_prediction_i    ( prediction     [mp]),
    .mp_br_j_taken_i    ( br_j_taken     [mp]),

    .cu_stall_f_o       ( cu_stall       [f] ),
    .cu_stall_d_o       ( cu_stall       [d] ),
    .cu_stall_e_o       ( cu_stall       [e] ),
    .cu_stall_m_o       ( cu_stall       [m] ),
    .cu_stall_mp_o      ( cu_stall       [mp]),

    .cu_kill_f_o        ( cu_kill        [f] ),
    .cu_kill_d_o        ( cu_kill        [d] ),
    .cu_kill_e_o        ( cu_kill        [e] ),
    .cu_kill_m_o        ( cu_kill        [m] ),
    .cu_kill_mp_o       ( cu_kill        [mp]),

    .cu_force_pc_o      ( cu_force_pc    [f] ),
    .cu_force_f_o       ( cu_force       [f] )
  );


  //////////
  // RVFI //
  //////////

  assign rvfi_instr      [w] = rvfi_instr      [mp];
  assign rvfi_rs1_addr   [w] = rvfi_rs1_addr   [mp];
  assign rvfi_rs2_addr   [w] = rvfi_rs2_addr   [mp];
  assign rvfi_op1_gpr    [w] = rvfi_op1_gpr    [mp];
  assign rvfi_op2_gpr    [w] = rvfi_op2_gpr    [mp];
  assign rvfi_rs1_rdata  [w] = rvfi_rs1_rdata  [mp];
  assign rvfi_rs2_rdata  [w] = rvfi_rs2_rdata  [mp];
  assign rvfi_wb_rd_addr [w] = rvfi_wb_rd_addr [mp];
  assign rvfi_wb_we      [w] = rvfi_wb_we      [mp];
  assign rvfi_wb_data    [w] = rvfi_wb_data    [mp];
  assign rvfi_mem_we     [w] = rvfi_mem_we     [mp];
  assign rvfi_mem_req    [w] = rvfi_mem_req    [mp];
  assign rvfi_mem_size   [w] = rvfi_mem_size   [mp];
  assign rvfi_mem_addr   [w] = rvfi_mem_addr   [mp];
  assign rvfi_mem_wdata  [w] = rvfi_mem_wdata  [mp];
  assign rvfi_mem_rdata  [w] = rvfi_mem_rdata  [mp];
  assign rvfi_current_pc [w] = rvfi_current_pc [mp];
  assign rvfi_next_pc    [w] = rvfi_next_pc    [mp];
  assign rvfi_valid      [w] = rvfi_valid      [mp];
  assign rvfi_intr       [w] = rvfi_intr       [mp];
  assign rvfi_trap       [w] = rvfi_trap       [mp];


  if (RVFI) begin
    miriscv_rvfi_controller
    i_rvfi
    (
      .clk_i            ( clk_i                ),
      .aresetn_i        ( arstn_i              ),
      .w_instr_i        ( rvfi_instr       [w] ),
      .w_rs1_addr_i     ( rvfi_rs1_addr    [w] ),
      .w_rs2_addr_i     ( rvfi_rs2_addr    [w] ),
      .w_op1_gpr_i      ( rvfi_op1_gpr     [w] ),
      .w_op2_gpr_i      ( rvfi_op2_gpr     [w] ),
      .w_rs1_rdata_i    ( rvfi_rs1_rdata   [w] ),
      .w_rs2_rdata_i    ( rvfi_rs2_rdata   [w] ),
      .w_wb_rd_addr_i   ( rvfi_wb_rd_addr  [w] ),
      .w_wb_we_i        ( rvfi_wb_we       [w] ),
      .w_wb_data_i      ( rvfi_wb_data     [w] ),
      .w_data_we_i      ( rvfi_mem_we      [w] ),
      .w_data_req_i     ( rvfi_mem_req     [w] ),
      .w_data_size_i    ( rvfi_mem_size    [w] ),
      .w_data_addr_i    ( rvfi_mem_addr    [w] ),
      .w_data_wdata_i   ( rvfi_mem_wdata   [w] ),
      .w_data_rdata_i   ( rvfi_mem_rdata   [w] ),
      .w_current_pc_i   ( rvfi_current_pc  [w] ),
      .w_next_pc_i      ( rvfi_next_pc     [w] ),
      .w_valid_i        ( rvfi_valid       [w] ),
      .w_intr_i         ( rvfi_intr        [w] ),
      .w_trap_i         ( rvfi_trap        [w] ),
      .rvfi_valid_o     ( rvfi_valid_o         ),
      .rvfi_order_o     ( rvfi_order_o         ),
      .rvfi_insn_o      ( rvfi_insn_o          ),
      .rvfi_trap_o      ( rvfi_trap_o          ),
      .rvfi_halt_o      ( rvfi_halt_o          ),
      .rvfi_intr_o      ( rvfi_intr_o          ),
      .rvfi_mode_o      ( rvfi_mode_o          ),
      .rvfi_ixl_o       ( rvfi_ixl_o           ),
      .rvfi_rs1_addr_o  ( rvfi_rs1_addr_o      ),
      .rvfi_rs2_addr_o  ( rvfi_rs2_addr_o      ),
      .rvfi_rs1_rdata_o ( rvfi_rs1_rdata_o     ),
      .rvfi_rs2_rdata_o ( rvfi_rs2_rdata_o     ),
      .rvfi_rd_addr_o   ( rvfi_rd_addr_o       ),
      .rvfi_rd_wdata_o  ( rvfi_rd_wdata_o      ),
      .rvfi_pc_rdata_o  ( rvfi_pc_rdata_o      ),
      .rvfi_pc_wdata_o  ( rvfi_pc_wdata_o      ),
      .rvfi_mem_addr_o  ( rvfi_mem_addr_o      ),
      .rvfi_mem_rmask_o ( rvfi_mem_rmask_o     ),
      .rvfi_mem_wmask_o ( rvfi_mem_wmask_o     ),
      .rvfi_mem_rdata_o ( rvfi_mem_rdata_o     ),
      .rvfi_mem_wdata_o ( rvfi_mem_wdata_o     )
    );

  end
  else begin
    assign rvfi_valid_o     = '0;
    assign rvfi_order_o     = '0;
    assign rvfi_insn_o      = '0;
    assign rvfi_trap_o      = '0;
    assign rvfi_halt_o      = '0;
    assign rvfi_intr_o      = '0;
    assign rvfi_mode_o      = '0;
    assign rvfi_ixl_o       = '0;
    assign rvfi_rs1_addr_o  = '0;
    assign rvfi_rs2_addr_o  = '0;
    assign rvfi_rs1_rdata_o = '0;
    assign rvfi_rs2_rdata_o = '0;
    assign rvfi_rd_addr_o   = '0;
    assign rvfi_rd_wdata_o  = '0;
    assign rvfi_pc_rdata_o  = '0;
    assign rvfi_pc_wdata_o  = '0;
    assign rvfi_mem_addr_o  = '0;
    assign rvfi_mem_rmask_o = '0;
    assign rvfi_mem_wmask_o = '0;
    assign rvfi_mem_rdata_o = '0;
    assign rvfi_mem_wdata_o = '0;
  end

endmodule
