/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

module miriscv_fetch_unit
  import miriscv_pkg::XLEN;
  import miriscv_pkg::ILEN;
(
  // Clock, reset
  input  logic            clk_i,
  input  logic            arstn_i,

  // Instruction memory interface
  input  logic            instr_rvalid_i,
  input  logic [XLEN-1:0] instr_rdata_i,
  output logic            instr_req_o,
  output logic [XLEN-1:0] instr_addr_o,

  // Core pipeline signals
  input  logic            cu_stall_f_i,
  input  logic [XLEN-1:0] cu_force_pc_i,
  input  logic            cu_force_f_i,

  output logic [XLEN-1:0] fetched_pc_addr_o,
  output logic [XLEN-1:0] fetched_pc_next_addr_o,
  output logic [ILEN-1:0] instr_o,
  output logic            fetch_rvalid_o
);


  ////////////////////////
  // Local declarations //
  ////////////////////////

  localparam BYTE_ADDR_W = $clog2(XLEN/8);

  logic [15:0]     instr_rdata_s;
  logic            misaligned_access;

  logic [XLEN-1:0] pc_ff;
  logic [XLEN-1:0] pc_next;
  logic [XLEN-1:0] pc_plus_inc;
  logic            fetch_en;
  logic            compr_instr;

  logic [XLEN-1:0] fetched_pc_ff;
  logic [XLEN-1:0] fetched_pc_next_ff;


  //////////////////
  // Fetch logics //
  //////////////////

  assign fetch_en = instr_req_o | cu_force_f_i | cu_stall_f_i;

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
      pc_ff <= {XLEN{1'b0}};
    end
    else if (fetch_en) begin
      pc_ff <= pc_next;
    end
  end

  assign pc_plus_inc  = pc_ff + 'd4;
  assign pc_next      = cu_force_f_i ? cu_force_pc_i :
                        cu_stall_f_i ? fetched_pc_ff : pc_plus_inc;

  assign instr_req_o  = ~cu_force_f_i & ~cu_stall_f_i;

  assign instr_addr_o = pc_ff;

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
      fetched_pc_ff      <= '0;
      fetched_pc_next_ff <= '0;
    end
    else if (instr_req_o) begin
      fetched_pc_ff      <= pc_ff;
      fetched_pc_next_ff <= pc_next;
    end
  end

  assign fetched_pc_addr_o       = fetched_pc_ff;
  assign fetched_pc_next_addr_o  = fetched_pc_next_ff;
  assign instr_o                 = instr_rdata_i;
  assign fetch_rvalid_o          = instr_rvalid_i & ~cu_force_f_i;

endmodule
