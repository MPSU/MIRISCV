/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

module miriscv_fetch_unit_new
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

  logic [XLEN-1:0] pc_ff;
  logic [XLEN-1:0] pc_next;
  logic [XLEN-1:0] pc_plus_inc;
  logic            fetch_en;

  logic fetch_resp_valid_ff;
  logic fetch_resp_valid_next;
  logic fetch_resp_valid_en;

  logic [XLEN-1:0] fetch_resp_pc_ff;
  logic [XLEN-1:0] fetch_resp_pc_next;
  logic fetch_resp_fetch_en;

  logic stall_resp_valid_ff;
  logic stall_resp_valid_next;
  logic stall_resp_valid_en;


  //////////////////
  // Fetch logics //
  //////////////////



  // PC and fetch request

  assign pc_plus_inc  = pc_ff + 'd4;
  assign fetch_en = ~cu_stall_f_i
                  | cu_force_f_i /* 
                  | (fetch_resp_valid_ff & instr_rvalid_i) // request peding and rvalid
                  | ~fetch_resp_valid_ff*/;                  // no request pending

  assign pc_next = cu_force_f_i ? cu_force_pc_i :
                                  pc_plus_inc;

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
      pc_ff <= {XLEN{1'b0}};
    end
    else if (fetch_en) begin
      pc_ff <= pc_next;
    end
  end

  assign instr_req_o  = ~cu_force_f_i & ~cu_stall_f_i;
  assign instr_addr_o = pc_ff;

  // fetch response


  assign fetch_resp_valid_next = fetch_en & ~cu_force_pc_i;
  assign fetch_resp_valid_en   = 1;

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
      fetch_resp_valid_ff <= '0;
    end
    else if (fetch_resp_valid_en) begin
      fetch_resp_valid_ff <= fetch_resp_valid_next;
    end
  end



  assign fetch_resp_pc_next = pc_ff;
  assign fetch_resp_fetch_en   = 1;

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
      fetch_resp_pc_ff <= '0;
    end
    else if (fetch_resp_fetch_en) begin
      fetch_resp_pc_ff <= fetch_resp_pc_next;
    end
  end



  // Save imem response if CPU is stalled
  logic [XLEN-1:0] stall_resp_data_ff;
  logic stall_resp_data_en;

  assign stall_resp_data_en = instr_rvalid_i & cu_stall_f_i;

  always_ff @(posedge clk_i) begin
    if (fetch_resp_fetch_en) begin
      stall_resp_data_ff <= instr_rdata_i;
    end
  end




  assign stall_resp_valid_next = instr_rvalid_i & cu_stall_f_i; // flush??
  assign stall_resp_valid_en = (instr_rvalid_i & cu_stall_f_i)
                             | (stall_resp_valid_ff & ~cu_stall_f_i);


  always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
      stall_resp_valid_ff <= '0;
    end
    else if (stall_resp_valid_en) begin
      stall_resp_valid_ff <= stall_resp_valid_next;
    end
  end


  assign instr_o = stall_resp_valid_ff ? stall_resp_data_ff
                                       : instr_rdata_i;

  assign fetch_rvalid_o          = (instr_rvalid_i | stall_resp_valid_ff) 
                                 & ~cu_force_f_i
                                 & ~cu_stall_f_i; // temporary


  assign fetched_pc_addr_o = fetch_resp_pc_ff;
  assign fetched_pc_next_addr_o = fetch_resp_pc_ff + 4;


endmodule
