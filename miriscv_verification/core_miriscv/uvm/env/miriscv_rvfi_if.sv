/////////////////////////////////
// Miriscv core RVFI interface //
/////////////////////////////////

interface miriscv_rvfi_if #(
    parameter NRET = 2
)
(
    input logic clk
);
    logic [NRET *  1 - 1:0] valid;
    logic [NRET * 64 - 1:0] order;
    logic [NRET * 32 - 1:0] insn;
    logic [NRET *  1 - 1:0] trap;
    logic [NRET *  1 - 1:0] halt;
    logic [NRET *  1 - 1:0] intr;
    logic [NRET *  2 - 1:0] mode;
    logic [NRET *  2 - 1:0] ixl;
    logic [NRET *  5 - 1:0] rs1_addr;
    logic [NRET *  5 - 1:0] rs2_addr;
    logic [NRET * 32 - 1:0] rs1_rdata;
    logic [NRET * 32 - 1:0] rs2_rdata;
    logic [NRET *  5 - 1:0] rd_addr;
    logic [NRET * 32 - 1:0] rd_wdata;
    logic [NRET * 32 - 1:0] pc_rdata;
    logic [NRET * 32 - 1:0] pc_wdata;
    logic [NRET * 32 - 1:0] mem_addr;
    logic [NRET *  4 - 1:0] mem_rmask;
    logic [NRET *  4 - 1:0] mem_wmask;
    logic [NRET * 32 - 1:0] mem_rdata;
    logic [NRET * 32 - 1:0] mem_wdata;
endinterface
