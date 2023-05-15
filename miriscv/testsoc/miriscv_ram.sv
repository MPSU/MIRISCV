`timescale 1ns / 1ps

module miriscv_ram
#(
  parameter RAM_SIZE       = 65536,
  parameter IRAM_INIT_FILE = "",
  parameter DRAM_INIT_FILE = "",
  parameter INST_PER_CYCLE = 1
) (
  input  logic 	                       clk_i,
  input  logic                         arstn_i,

  // Instruction memory interface
  output logic                         instr_rvalid_o,
  output logic [INST_PER_CYCLE*32-1:0] instr_rdata_o,
  input  logic                         instr_req_i,
  input  logic [31:0]                  instr_addr_i,

  // Data memory interface
  output logic                         data_rvalid_o,
  output logic [31:0]                  data_rdata_o,
  input  logic                         data_req_i,
  input  logic                         data_we_i,
  input  logic [3:0]                   data_be_i,
  input  logic [31:0]                  data_addr_i,
  input  logic [31:0]                  data_wdata_i
);


  ////////////////////////
  // Local declarations //
  ////////////////////////

  genvar 	                      i;

  logic [31:0]                  imem [0:RAM_SIZE/4-1];
  logic [31:0]                  dmem_ff [0:RAM_SIZE/4-1];

  integer                       f;
  integer                       addr;
  logic [31:0]                  data;
  logic [8*20-1:0]              cmd;

  integer                       iram_index;
  integer                       dram_index;

  logic                         instr_rvalid_ff;
  logic [31:0]                  instr_rdata_ff [INST_PER_CYCLE-1:0];

  logic                         data_rvalid_ff;
  logic [31:0]                  data_rdata_ff;

  generate
    if ( INST_PER_CYCLE != 1 && INST_PER_CYCLE != 2 ) begin
      illegal_inst_per_cycle_parameter_at_miriscv_ram non_existing_module();
    end
  endgenerate

  ///////////////
  // RAM logic //
  ///////////////

  initial begin
    for (iram_index = 0; iram_index < RAM_SIZE/4-1; iram_index = iram_index + 1)
      imem[iram_index] = {32{1'b0}};
    if(IRAM_INIT_FILE != "")
      $readmemh(IRAM_INIT_FILE, imem);
  end

  initial begin
    for (dram_index = 0; dram_index < RAM_SIZE/4-1; dram_index = dram_index + 1)
      dmem_ff[dram_index] = {32{1'b0}};
    if(DRAM_INIT_FILE != "")
      $readmemh(DRAM_INIT_FILE, dmem_ff);
  end

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i)
      instr_rvalid_ff <= '0;
    else
      instr_rvalid_ff <= instr_req_i;
  end

  always_ff @(posedge clk_i) begin
    if ( INST_PER_CYCLE == 2 ) begin
      instr_rdata_ff[1] <= imem[{instr_addr_i[15:3], 1'b1}];
      instr_rdata_ff[0] <= imem[{instr_addr_i[15:3], 1'b0}];
    end
    else begin
      instr_rdata_ff[0] <= imem[instr_addr_i[15:2]];
    end
  end


  always_ff @(posedge clk_i) begin
    if(data_req_i && data_we_i && data_be_i[0])
      dmem_ff [data_addr_i[15:2]] [7:0]   <= data_wdata_i[7:0];
    if(data_req_i && data_we_i && data_be_i[1])
      dmem_ff [data_addr_i[15:2]] [15:8]  <= data_wdata_i[15:8];
    if(data_req_i && data_we_i && data_be_i[2])
      dmem_ff [data_addr_i[15:2]] [23:16] <= data_wdata_i[23:16];
    if(data_req_i && data_we_i && data_be_i[3])
      dmem_ff [data_addr_i[15:2]] [31:24] <= data_wdata_i[31:24];
  end

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i)
      data_rvalid_ff <= '0;
    else
      data_rvalid_ff <= data_req_i;
  end

  always_ff @(posedge clk_i) begin
    data_rdata_ff <= dmem_ff[data_addr_i[15:2]];
  end


  assign instr_rdata_o  = INST_PER_CYCLE == 2 ? { instr_rdata_ff[1], instr_rdata_ff[0] } : instr_rdata_ff[0];
  assign instr_rvalid_o = instr_rvalid_ff;

  assign data_rdata_o  = data_rdata_ff;
  assign data_rvalid_o = data_rvalid_ff;

endmodule
