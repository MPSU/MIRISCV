///////////////////////////////////
// Miriscv core memory interface //
///////////////////////////////////

interface miriscv_mem_intf #(
    parameter int INSTR_WIDTH = 64,
    parameter int ADDR_WIDTH  = 32,
    parameter int DATA_WIDTH  = 32
) 
(
    input logic clk
);

    // Reset signal
    logic                    reset;

    // Instruction memory signals
    logic                    instr_rvalid;
    logic [INSTR_WIDTH-1:0]  instr_rdata;
    logic                    instr_req;
    logic [ADDR_WIDTH-1:0]   instr_addr;

    // Data memory signals
    logic                    data_rvalid;
    logic [DATA_WIDTH-1:0]   data_rdata;
    logic                    data_req;
    logic [DATA_WIDTH-1:0]   data_wdata;
    logic [ADDR_WIDTH-1:0]   data_addr;
    logic                    data_we;
    logic [DATA_WIDTH/8-1:0] data_be;

    // Driver clocking block
    clocking driver_cb @(posedge clk);
        input  reset;
        output instr_rvalid;
        output instr_rdata;
        input  instr_req;
        input  instr_addr;
        output data_rvalid;
        output data_rdata;
        input  data_req;
        input  data_wdata;
        input  data_addr;
        input  data_we;
        input  data_be;
    endclocking

    // Monitor negedge clocking block
    clocking monitor_neg_cb @(negedge clk);
        input reset;
        input instr_rvalid;
        input instr_rdata;
        input instr_req;
        input instr_addr;
        input data_rvalid;
        input data_rdata;
        input data_req;
        input data_wdata;
        input data_addr;
        input data_we;
        input data_be;
    endclocking

    // Monitor posedge clocking block
    clocking monitor_pos_cb @(posedge clk);
        input reset;
        input instr_rvalid;
        input instr_rdata;
        input instr_req;
        input instr_addr;
        input data_rvalid;
        input data_rdata;
        input data_req;
        input data_wdata;
        input data_addr;
        input data_we;
        input data_be;
    endclocking

    // Monitor negedge data task
    task automatic monitor_get_neg_data (
        output logic                    instr_rvalid,
        output logic [INSTR_WIDTH-1:0]  instr_rdata,
        output logic                    instr_req,
        output logic [ADDR_WIDTH-1:0]   instr_addr,
        output logic                    data_rvalid,
        output logic [DATA_WIDTH-1:0]   data_rdata,
        output logic                    data_req,
        output logic [DATA_WIDTH-1:0]   data_wdata,
        output logic [ADDR_WIDTH-1:0]   data_addr,
        output logic                    data_we,
        output logic [DATA_WIDTH/8-1:0] data_be
    );
        @(monitor_neg_cb);
        instr_rvalid = monitor_neg_cb.instr_rvalid;
        instr_rdata  = monitor_neg_cb.instr_rdata;
        instr_req    = monitor_neg_cb.instr_req;
        instr_addr   = monitor_neg_cb.instr_addr;
        data_rvalid  = monitor_neg_cb.data_rvalid;
        data_rdata   = monitor_neg_cb.data_rdata;
        data_req     = monitor_neg_cb.data_req;
        data_wdata   = monitor_neg_cb.data_wdata;
        data_addr    = monitor_neg_cb.data_addr;
        data_we      = monitor_neg_cb.data_we;
        data_be      = monitor_neg_cb.data_be;
    endtask

    // Monitor posedge data task
    task automatic monitor_get_pos_data (
        output logic                    instr_rvalid,
        output logic [INSTR_WIDTH-1:0]  instr_rdata,
        output logic                    instr_req,
        output logic [ADDR_WIDTH-1:0]   instr_addr,
        output logic                    data_rvalid,
        output logic [DATA_WIDTH-1:0]   data_rdata,
        output logic                    data_req,
        output logic [DATA_WIDTH-1:0]   data_wdata,
        output logic [ADDR_WIDTH-1:0]   data_addr,
        output logic                    data_we,
        output logic [DATA_WIDTH/8-1:0] data_be
    );
        @(monitor_pos_cb);
        instr_rvalid = monitor_pos_cb.instr_rvalid;
        instr_rdata  = monitor_pos_cb.instr_rdata;
        instr_req    = monitor_pos_cb.instr_req;
        instr_addr   = monitor_pos_cb.instr_addr;
        data_rvalid  = monitor_pos_cb.data_rvalid;
        data_rdata   = monitor_pos_cb.data_rdata;
        data_req     = monitor_pos_cb.data_req;
        data_wdata   = monitor_pos_cb.data_wdata;
        data_addr    = monitor_pos_cb.data_addr;
        data_we      = monitor_pos_cb.data_we;
        data_be      = monitor_pos_cb.data_be;
    endtask

    // Wait clocks tasks
    task automatic wait_clks(input int num);
      repeat (num) @(posedge clk);
    endtask

    task automatic wait_neg_clks(input int num);
      repeat (num) @(negedge clk);
    endtask
  
endinterface