/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

 module miriscv_gpr
  import miriscv_pkg::XLEN;
  import miriscv_gpr_pkg::*;
(
  // Clock, reset
  input  logic                  clk_i,
  input  logic                  arstn_i,

  // Write port
  input  logic                  wr_en_i,
  input  logic [GPR_ADDR_W-1:0] wr_addr_i,
  input  logic [XLEN-1:0]       wr_data_i,

  // Read port 1
  input  logic [GPR_ADDR_W-1:0] r1_addr_i,
  output logic [XLEN-1:0]       r1_data_o,

  // Read port 2
  input  logic [GPR_ADDR_W-1:0] r2_addr_i,
  output logic [XLEN-1:0]       r2_data_o
  );


  ////////////////////////
  // Local declarations //
  ////////////////////////

  localparam NUM_WORDS = 2**GPR_ADDR_W;

  logic [NUM_WORDS-1:0][XLEN-1:0] rf_reg;
  logic [NUM_WORDS-1:0][XLEN-1:0] rf_reg_tmp_ff;
  logic [NUM_WORDS-1:0]           wr_en_dec;


  ///////////////////////////////
  // General purpose registers //
  ///////////////////////////////

  // Code to 1-hot convertation
  always_comb begin : wr_en_decoder
    for (int i = 0; i < NUM_WORDS; i++) begin
      if (wr_addr_i == i)
        wr_en_dec[i] = wr_en_i;
      else
        wr_en_dec[i] = 1'b0;
    end
  end

  // GPR write
  genvar i;
  generate
    for (i = 1; i < NUM_WORDS; i++) begin : rf_gen

      always_ff @(posedge clk_i or negedge arstn_i) begin : register_write_behavioral
        if (arstn_i==1'b0) begin
          rf_reg_tmp_ff[i] <= 'b0;
        end else begin
          if (wr_en_dec[i])
            rf_reg_tmp_ff[i] <= wr_data_i;
        end
      end
    end

    // R0 is nil
    assign rf_reg[0] = '0;
    assign rf_reg[NUM_WORDS-1:1] = rf_reg_tmp_ff[NUM_WORDS-1:1];

  endgenerate

  // GPR read
  assign r1_data_o = rf_reg[r1_addr_i];
  assign r2_data_o = rf_reg[r2_addr_i];

endmodule: miriscv_gpr
