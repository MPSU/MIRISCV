/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

module miriscv_rvfi_controller
  import miriscv_pkg::XLEN;
  import miriscv_pkg::ILEN;
  import miriscv_gpr_pkg::GPR_ADDR_W;
  import miriscv_decode_pkg::*;
  import miriscv_lsu_pkg::*;
(
  input  logic                    clk_i,
  input  logic                    aresetn_i,
  input  logic [ILEN-1:0]         w_instr_i,

  input  logic [GPR_ADDR_W-1:0]   w_rs1_addr_i,
  input  logic [GPR_ADDR_W-1:0]   w_rs2_addr_i,
  input  logic                    w_op1_gpr_i,
  input  logic                    w_op2_gpr_i,
  input  logic [XLEN-1:0]         w_rs1_rdata_i,
  input  logic [XLEN-1:0]         w_rs2_rdata_i,
  input  logic [GPR_ADDR_W-1:0]   w_wb_rd_addr_i,
  input  logic [XLEN-1:0]         w_wb_data_i,
  input  logic                    w_wb_we_i,
  input  logic                    w_data_we_i,
  input  logic                    w_data_req_i,
  input  logic [MEM_ACCESS_W-1:0] w_data_size_i,
  input  logic [XLEN-1:0]         w_data_addr_i,
  input  logic [XLEN-1:0]         w_data_wdata_i,
  input  logic [XLEN-1:0]         w_data_rdata_i,

  input  logic [XLEN-1:0]         w_current_pc_i,
  input  logic [XLEN-1:0]         w_next_pc_i,
  input  logic                    w_valid_i,
  input  logic                    w_intr_i,

  input  logic                    w_trap_i,

  output logic                    rvfi_valid_o,
  output logic [63:0]             rvfi_order_o,
  output logic [31:0]             rvfi_insn_o,
  output logic                    rvfi_trap_o,
  output logic                    rvfi_halt_o,
  output logic                    rvfi_intr_o,
  output logic [ 1:0]             rvfi_mode_o,
  output logic [ 1:0]             rvfi_ixl_o,
  output logic [ 4:0]             rvfi_rs1_addr_o,
  output logic [ 4:0]             rvfi_rs2_addr_o,
  output logic [31:0]             rvfi_rs1_rdata_o,
  output logic [31:0]             rvfi_rs2_rdata_o,
  output logic [ 4:0]             rvfi_rd_addr_o,
  output logic [31:0]             rvfi_rd_wdata_o,
  output logic [31:0]             rvfi_pc_rdata_o,
  output logic [31:0]             rvfi_pc_wdata_o,
  output logic [31:0]             rvfi_mem_addr_o,
  output logic [ 3:0]             rvfi_mem_rmask_o,
  output logic [ 3:0]             rvfi_mem_wmask_o,
  output logic [31:0]             rvfi_mem_rdata_o,
  output logic [31:0]             rvfi_mem_wdata_o
);


  assign rvfi_mode_o = 2'd3; // <- Machine mode
  assign rvfi_ixl_o  = 2'd1;
  assign rvfi_halt_o = 1'b0;

  always_ff @(posedge clk_i, negedge aresetn_i) begin
    if (~aresetn_i) begin
      rvfi_rs1_addr_o  <= '0;
      rvfi_rs1_rdata_o <= '0;
    end
    else begin
      if (w_op1_gpr_i) begin
        rvfi_rs1_addr_o  <= w_rs1_addr_i;
        rvfi_rs1_rdata_o <= w_rs1_rdata_i;
      end
      else begin
        rvfi_rs1_addr_o  <= '0;
        rvfi_rs1_rdata_o <= '0;
      end
    end
  end

  always_ff @(posedge clk_i, negedge aresetn_i) begin
    if (~aresetn_i) begin
      rvfi_rs2_addr_o  <= '0;
      rvfi_rs2_rdata_o <= '0;
    end
    else begin
      if (w_op2_gpr_i) begin
        rvfi_rs2_addr_o  <= w_rs2_addr_i;
        rvfi_rs2_rdata_o <= w_rs2_rdata_i;
      end
      else begin
        rvfi_rs2_addr_o  <= '0;
        rvfi_rs2_rdata_o <= '0;
      end
    end
  end

  always_ff @(posedge clk_i, negedge aresetn_i) begin
    if (~aresetn_i) begin
      rvfi_rd_addr_o  <= '0;
      rvfi_rd_wdata_o <= '0;
    end
    else begin
      if (w_wb_we_i) begin
        rvfi_rd_addr_o  <= w_wb_rd_addr_i;
        if (w_wb_rd_addr_i == 0) begin
          rvfi_rd_wdata_o <=  '0;
        end
        else begin
          rvfi_rd_wdata_o <=  w_wb_data_i;
        end
      end
      else begin
        rvfi_rd_addr_o  <= '0;
        rvfi_rd_wdata_o <= '0;
      end
    end
  end

  always_ff @(posedge clk_i, negedge aresetn_i) begin
    if (~aresetn_i) begin
      rvfi_insn_o <= '0;
    end
    else begin
      rvfi_insn_o <= w_instr_i;
    end
  end

  logic [3:0] w_data_mask;
  always_comb begin
    if (w_data_size_i == MEM_ACCESS_WORD) begin
      w_data_mask = 4'b1111;
    end
    else if (w_data_size_i == MEM_ACCESS_HALF ||
             w_data_size_i == MEM_ACCESS_UHALF) begin
      w_data_mask = 4'b0011;
    end
    else if (w_data_size_i == MEM_ACCESS_BYTE ||
             w_data_size_i == MEM_ACCESS_UBYTE) begin
      w_data_mask = 4'b0001;
    end
    else begin
      w_data_mask = 'bx;
    end
  end

  always_ff @(posedge clk_i, negedge aresetn_i) begin
    if (~aresetn_i) begin
      rvfi_mem_addr_o  <= '0;
      rvfi_mem_rmask_o <= '0;
      rvfi_mem_wmask_o <= '0;
      rvfi_mem_rdata_o <= '0;
      rvfi_mem_wdata_o <= '0;
    end
    else begin
      if (w_data_req_i) begin
        rvfi_mem_addr_o  <= w_data_addr_i;
        rvfi_mem_wmask_o <= '0;
        rvfi_mem_wdata_o <= '0;
        rvfi_mem_rmask_o <= '0;
        rvfi_mem_rdata_o <= '0;
        if (w_data_we_i) begin
          rvfi_mem_wmask_o <= w_data_mask;
          rvfi_mem_wdata_o <= w_data_wdata_i;
        end
        else begin
          rvfi_mem_rmask_o <= w_data_mask;
          rvfi_mem_rdata_o <= w_data_rdata_i;
        end
      end
      else begin
        rvfi_mem_addr_o  <= '0;
        rvfi_mem_rmask_o <= '0;
        rvfi_mem_wmask_o <= '0;
        rvfi_mem_rdata_o <= '0;
        rvfi_mem_wdata_o <= '0;
      end
    end
  end

  always_ff @(posedge clk_i, negedge aresetn_i) begin
    if (~aresetn_i) begin
      rvfi_valid_o <= '0;
      rvfi_order_o <= '0;
    end
    else begin
      rvfi_valid_o <= w_valid_i;
      rvfi_order_o <= rvfi_order_o + rvfi_valid_o;
    end
  end

  always_ff @(posedge clk_i, negedge aresetn_i) begin
    if (~aresetn_i) begin
      rvfi_pc_rdata_o <= '0;
      rvfi_pc_wdata_o <= '0;
    end
    else begin
      rvfi_pc_rdata_o <= w_current_pc_i;
      rvfi_pc_wdata_o <= w_next_pc_i;
    end
  end

  always_ff @(posedge clk_i, negedge aresetn_i) begin
    if (~aresetn_i) begin
      rvfi_trap_o <= '0;
    end
    else begin
      rvfi_trap_o <= w_trap_i;
    end
  end

  always_ff @(posedge clk_i, negedge aresetn_i) begin
    if (~aresetn_i) begin
      rvfi_intr_o <= '0;
    end
    else begin
      rvfi_intr_o <= w_intr_i;
    end
  end

endmodule
