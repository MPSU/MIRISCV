/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

module miriscv_fetch_stage
  import miriscv_pkg::XLEN;
  import miriscv_pkg::ILEN;
#(
  parameter bit RVFI = 1'b0
) (
  // Clock, reset
  input  logic            clk_i,
  input  logic            arstn_i,

  // Control Unit
  input  logic            cu_kill_f_i,
  input  logic            cu_stall_f_i,
  input  logic            cu_force_f_i,
  input  logic [XLEN-1:0] cu_force_pc_i,
  output logic            f_stall_req_o,

  // Instruction memory interface
  input  logic            instr_rvalid_i,
  input  logic [XLEN-1:0] instr_rdata_i,
  output logic            instr_req_o,
  output logic [XLEN-1:0] instr_addr_o,

  // To Decode
  output logic [ILEN-1:0] f_instr_o,
  output logic [XLEN-1:0] f_current_pc_o,
  output logic [XLEN-1:0] f_next_pc_o,
  output logic            f_valid_o
);


  ////////////////////////
  // Local declarations //
  ////////////////////////

  logic [ILEN-1:0] fetch_instr;
  logic [XLEN-1:0] f_current_pc;
  logic [XLEN-1:0] f_next_pc;
  logic            fetch_instr_valid;

  logic [ILEN-1:0] f_instr_ff;
  logic [XLEN-1:0] f_current_pc_ff;
  logic [XLEN-1:0] f_next_pc_ff;
  logic            f_valid_ff;


  ////////////////
  // Fetch unit //
  ////////////////

  miriscv_fetch_unit
  i_fetch_unit
  (
    .clk_i                  ( clk_i             ),
    .arstn_i                ( arstn_i           ),

    .instr_rvalid_i         ( instr_rvalid_i    ),
    .instr_rdata_i          ( instr_rdata_i     ),
    .instr_req_o            ( instr_req_o       ),
    .instr_addr_o           ( instr_addr_o      ),

    .cu_stall_f_i           ( cu_stall_f_i      ),
    .cu_force_f_i           ( cu_force_f_i      ),
    .cu_force_pc_i          ( cu_force_pc_i     ),

    .fetched_pc_addr_o      ( f_current_pc      ),
    .fetched_pc_next_addr_o ( f_next_pc         ),
    .instr_o                ( fetch_instr       ),
    .fetch_rvalid_o         ( fetch_instr_valid )
  );


  ///////////////////////
  // Pipeline register //
  ///////////////////////

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if(~arstn_i)
      f_valid_ff <= '0;
    else if (cu_kill_f_i)
      f_valid_ff <= '0;
    else if (~cu_stall_f_i)
      f_valid_ff <= fetch_instr_valid;
  end

  always_ff @(posedge clk_i) begin
    if (~cu_stall_f_i) begin
      f_instr_ff      <= fetch_instr;
      f_current_pc_ff <= f_current_pc;
      f_next_pc_ff    <= f_next_pc;
    end
  end

  assign f_instr_o      = f_instr_ff;
  assign f_current_pc_o = f_current_pc_ff;
  assign f_next_pc_o    = f_next_pc_ff;
  assign f_valid_o      = f_valid_ff;

  assign f_stall_req_o  = '0;

endmodule
