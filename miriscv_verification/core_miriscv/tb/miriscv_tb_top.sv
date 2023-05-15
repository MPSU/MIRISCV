/////////////////////////////////////////////////////////////
//
// This file is original Ibex core top testbench module
// (core_ibex_tb_top), but it is changed fot Miriva 1f core
// testing.
//
/////////////////////////////////////////////////////////////

// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module miriscv_tb_top;

    import uvm_pkg::*;
    import miriscv_test_pkg::*;

    wire clk;
    wire rst_n;

    // Clock interface
    clk_if           miriscv_clk_if(.clk(clk), .rst_n(rst_n));

    // Memory interface
    miriscv_mem_intf mem_vif(.clk(clk));

    // RVFI interface
    miriscv_rvfi_if  rvfi_if(.clk(clk));

    miriscv_tracing dut (
        .clk_i          ( clk                 ),
        .rst_ni         ( rst_n               ),

        .hart_id_i      ( 32'b0               ),

        .boot_addr_i    ( `BOOT_ADDR          ),

        // Instruction memory interface
        .instr_rvalid_i ( mem_vif.instr_rvalid ),
        .instr_rdata_i  ( mem_vif.instr_rdata  ),
        .instr_req_o    ( mem_vif.instr_req    ),
        .instr_addr_o   ( mem_vif.instr_addr   ),

        // Data memory interface
        .data_rvalid_i  ( mem_vif.data_rvalid ),
        .data_rdata_i   ( mem_vif.data_rdata  ),
        .data_req_o     ( mem_vif.data_req    ),
        .data_we_o      ( mem_vif.data_we     ),
        .data_be_o      ( mem_vif.data_be     ),
        .data_addr_o    ( mem_vif.data_addr   ),
        .data_wdata_o   ( mem_vif.data_wdata  )
    );

    // Assign memory interface reset signal
    assign mem_vif.reset                   = ~rst_n;

    // Assign RVFI interface connections
    assign rvfi_if.valid                        = dut.rvfi_valid;
    assign rvfi_if.order                        = dut.rvfi_order;
    assign rvfi_if.insn                         = dut.rvfi_insn;
    assign rvfi_if.trap                         = dut.rvfi_trap;
    assign rvfi_if.intr                         = dut.rvfi_intr;
    assign rvfi_if.mode                         = dut.rvfi_mode;
    assign rvfi_if.ixl                          = dut.rvfi_ixl;
    assign rvfi_if.rs1_addr                     = dut.rvfi_rs1_addr;
    assign rvfi_if.rs2_addr                     = dut.rvfi_rs2_addr;
    assign rvfi_if.rs1_rdata                    = dut.rvfi_rs1_rdata;
    assign rvfi_if.rs2_rdata                    = dut.rvfi_rs2_rdata;
    assign rvfi_if.rd_addr                      = dut.rvfi_rd_addr;
    assign rvfi_if.rd_wdata                     = dut.rvfi_rd_wdata;
    assign rvfi_if.pc_rdata                     = dut.rvfi_pc_rdata;
    assign rvfi_if_pc_wdata                     = dut.rvfi_pc_wdata;
    assign rvfi_if.mem_addr                     = dut.rvfi_mem_addr;
    assign rvfi_if.mem_rmask                    = dut.rvfi_mem_rmask;
    assign rvfi_if.mem_rdata                    = dut.rvfi_mem_rdata;
    assign rvfi_if.mem_wdata                    = dut.rvfi_mem_wdata;

    initial begin
        uvm_config_db#(virtual clk_if)::set(null, "*", "clk_if", miriscv_clk_if);
        uvm_config_db#(virtual miriscv_rvfi_if)::set(null, "*", "rvfi_if", rvfi_if);
        uvm_config_db#(virtual miriscv_mem_intf)::set(null, "*mem_if_slave*", "vif", mem_vif);
        run_test();
    end

endmodule
