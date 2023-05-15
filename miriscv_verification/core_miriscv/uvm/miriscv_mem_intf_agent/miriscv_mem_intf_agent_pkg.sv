/////////////////////////////////////////////////
// Miriscv core memory interface agent package //
/////////////////////////////////////////////////

package miriscv_mem_intf_agent_pkg;

    import uvm_pkg::*;
    import mem_model_pkg::*;
  
    parameter int INSTR_WIDTH = 64; // 32, 64, 128 and so on are supported
    parameter int DATA_WIDTH  = 32; // Only 32 is supported
    parameter int ADDR_WIDTH  = 32;

    // -------------------------------------------------------------------------
    // Instructions amount at one cycle at the instruction bus.
    // You must ensure, that ( INSTR_WIDTH % (DATA_WIDTH * instr_amount) ) == 0.
    // For example:                 64            32            1
    //                              64            32            2
    //                              128           32            4
    //
    // This variable can be changed in run time like:
    //     miriscv_mem_intf_agent_pkg::instr_amount = ...;

    int instr_amount = miriscv_pkg::DUAL_ISSUE ? 2 : 1;
    // -------------------------------------------------------------------------

    `include "uvm_macros.svh"
    `include "miriscv_mem_intf_seq_item.sv"
    `include "miriscv_mem_intf_monitor.sv"
    `include "miriscv_mem_intf_slave_driver.sv"
    `include "miriscv_mem_intf_slave_sequencer.sv"
    `include "miriscv_mem_intf_slave_seq_lib.sv"
    `include "miriscv_mem_intf_slave_agent.sv"
  
endpackage