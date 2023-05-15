/////////////////////////////////////////////////////////////
//
// This file is original Ibex core top tracing file
// (ibex_core_tracing), but it is changed fot Miriscv core
// tracing via Ibex core tracer.
//
// There is no certainty that this tracer is suitable for 
// Miriscv core, as several RVFI signals are missing and do 
// not connect to the Ibex tracer.
//
/////////////////////////////////////////////////////////////

// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module miriscv_tracing
    import miriscv_mem_intf_agent_pkg::*;
(
    // Clock and Reset
    input  logic                     clk_i,
    input  logic                     rst_ni,

    // Hart ID
    input  logic  [            31:0] hart_id_i,

    // Boot address
    input  logic  [            31:0] boot_addr_i,

    // Instruction memory interface
    input  logic                     instr_rvalid_i,
    input  logic  [ INSTR_WIDTH-1:0] instr_rdata_i,
    output logic                     instr_req_o,
    output logic  [  ADDR_WIDTH-1:0] instr_addr_o,

    // Data memory interface
    input   logic                    data_rvalid_i,
    input   logic [  DATA_WIDTH-1:0] data_rdata_i,
    output  logic                    data_req_o,
    output  logic                    data_we_o,
    output  logic [DATA_WIDTH/8-1:0] data_be_o,
    output  logic [  ADDR_WIDTH-1:0] data_addr_o,
    output  logic [  DATA_WIDTH-1:0] data_wdata_o
);

  // ibex_tracer relies on the signals from the RISC-V Formal Interface
  `ifndef RVFI
      $fatal("Fatal error: RVFI needs to be defined globally.");
  `endif

  // By default tracer is set for 2 instructions per cycle,
  // but it will work correctly if core supports only 1
  // instruction per cycle (only lower bits will be filled)
  parameter NRET = 2;

  logic [NRET *  1 - 1:0] rvfi_valid;
  logic [NRET * 64 - 1:0] rvfi_order;
  logic [NRET * 32 - 1:0] rvfi_insn;
  logic [NRET *  1 - 1:0] rvfi_trap;
  logic [NRET *  1 - 1:0] rvfi_halt;
  logic [NRET *  1 - 1:0] rvfi_intr;
  logic [NRET *  2 - 1:0] rvfi_mode;
  logic [NRET *  2 - 1:0] rvfi_ixl;
  logic [NRET *  5 - 1:0] rvfi_rs1_addr;
  logic [NRET *  5 - 1:0] rvfi_rs2_addr;
  logic [NRET *  5 - 1:0] rvfi_rs3_addr;
  logic [NRET * 32 - 1:0] rvfi_rs1_rdata;
  logic [NRET * 32 - 1:0] rvfi_rs2_rdata;
  logic [NRET * 32 - 1:0] rvfi_rs3_rdata;
  logic [NRET *  5 - 1:0] rvfi_rd_addr;
  logic [NRET * 32 - 1:0] rvfi_rd_wdata;
  logic [NRET * 32 - 1:0] rvfi_pc_rdata;
  logic [NRET * 32 - 1:0] rvfi_pc_wdata;
  logic [NRET * 32 - 1:0] rvfi_mem_addr;
  logic [NRET *  4 - 1:0] rvfi_mem_rmask;
  logic [NRET *  4 - 1:0] rvfi_mem_wmask;
  logic [NRET * 32 - 1:0] rvfi_mem_rdata;
  logic [NRET * 32 - 1:0] rvfi_mem_wdata;

  miriscv_core #(
    .RVFI                 ( 1              )
  ) u_miriscv_core (
    // Clock and Reset
    .clk_i                ( clk_i          ),
    .arstn_i              ( rst_ni         ),

    // Boot address
    .boot_addr_i          ( boot_addr_i    ),

    // Instruction memory interface
    .instr_rvalid_i       ( instr_rvalid_i ),
    .instr_rdata_i        ( instr_rdata_i  ),
    .instr_req_o          ( instr_req_o    ),
    .instr_addr_o         ( instr_addr_o   ),

    // Data memory interface
    .data_rvalid_i        ( data_rvalid_i  ),
    .data_rdata_i         ( data_rdata_i   ),
    .data_req_o           ( data_req_o     ),
    .data_we_o            ( data_we_o      ),
    .data_be_o            ( data_be_o      ),
    .data_addr_o          ( data_addr_o    ),
    .data_wdata_o         ( data_wdata_o   ),

    // RVFI
    .rvfi_valid_o         ( rvfi_valid     ),
    .rvfi_order_o         ( rvfi_order     ),
    .rvfi_insn_o          ( rvfi_insn      ),
    .rvfi_trap_o          ( rvfi_trap      ),
    .rvfi_halt_o          ( rvfi_halt      ),
    .rvfi_intr_o          ( rvfi_intr      ),
    .rvfi_mode_o          ( rvfi_mode      ),
    .rvfi_ixl_o           ( rvfi_ixl       ),
    .rvfi_rs1_addr_o      ( rvfi_rs1_addr  ),
    .rvfi_rs2_addr_o      ( rvfi_rs2_addr  ),
    .rvfi_rs1_rdata_o     ( rvfi_rs1_rdata ),
    .rvfi_rs2_rdata_o     ( rvfi_rs2_rdata ),
    .rvfi_rd_addr_o       ( rvfi_rd_addr   ),
    .rvfi_rd_wdata_o      ( rvfi_rd_wdata  ),
    .rvfi_pc_rdata_o      ( rvfi_pc_rdata  ),
    .rvfi_pc_wdata_o      ( rvfi_pc_wdata  ),
    .rvfi_mem_addr_o      ( rvfi_mem_addr  ),
    .rvfi_mem_rmask_o     ( rvfi_mem_rmask ),
    .rvfi_mem_wmask_o     ( rvfi_mem_wmask ),
    .rvfi_mem_rdata_o     ( rvfi_mem_rdata ),
    .rvfi_mem_wdata_o     ( rvfi_mem_wdata )
  );

  new_ibex_tracer #( 
    .NRET           ( NRET           )
  ) u_ibex_tracer (
    .clk_i          ( clk_i          ),
    .rst_ni         ( rst_ni         ),

    .hart_id_i      ( hart_id_i      ),

    .rvfi_valid     ( rvfi_valid     ),
    .rvfi_order     ( rvfi_order     ),
    .rvfi_insn      ( rvfi_insn      ),
    .rvfi_trap      ( rvfi_trap      ),
    .rvfi_halt      ( rvfi_halt      ),
    .rvfi_intr      ( rvfi_intr      ),
    .rvfi_mode      ( rvfi_mode      ),
    .rvfi_ixl       ( rvfi_ixl       ),
    .rvfi_rs1_addr  ( rvfi_rs1_addr  ),
    .rvfi_rs2_addr  ( rvfi_rs2_addr  ),
    .rvfi_rs3_addr  (   /* ? */      ),
    .rvfi_rs1_rdata ( rvfi_rs1_rdata ),
    .rvfi_rs2_rdata ( rvfi_rs2_rdata ),
    .rvfi_rs3_rdata (   /* ? */      ),
    .rvfi_rd_addr   ( rvfi_rd_addr   ),
    .rvfi_rd_wdata  ( rvfi_rd_wdata  ),
    .rvfi_pc_rdata  ( rvfi_pc_rdata  ),
    .rvfi_pc_wdata  ( rvfi_pc_wdata  ),
    .rvfi_mem_addr  ( rvfi_mem_addr  ),
    .rvfi_mem_rmask ( rvfi_mem_rmask ),
    .rvfi_mem_wmask ( rvfi_mem_wmask ),
    .rvfi_mem_rdata ( rvfi_mem_rdata ),
    .rvfi_mem_wdata ( rvfi_mem_wdata )
  );

endmodule
