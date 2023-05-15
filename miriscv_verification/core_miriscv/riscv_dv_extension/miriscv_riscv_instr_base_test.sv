`include "riscv_instr_base_test.sv"

/////////////////////////////////////////////////////
// Miriscv core base program generation test class //
/////////////////////////////////////////////////////

class miriscv_riscv_instr_base_test extends riscv_instr_base_test;

    `uvm_component_utils(miriscv_riscv_instr_base_test)

    function new(string name="", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        // We must disable this constraint as Miriscv
        // core doesn't support any interruptions
        cfg.mtvec_c.constraint_mode(0);
        //---------------------------------------------------------
        // All instructions disabling/enabling must be listed here
        //---------------------------------------------------------
        // Disable CSR instructions for Miriscv core
        cfg.no_csr_instr = 1;
        super.run_phase(phase);
    endtask

    // We must redefine this method with stack and thread pointers additional
    // constraints as Spike simulator has bootloader, which uses registers t0, a1.
    // So in the main program GPRs are initialized with random values, but not
    // stack and thread pointer registers. And if we use t0 or a1 for any of
    // them we can get simulation mismatch between RTL and Spike as target core
    // doesn't know about additional program code inside Spike simulator.
    virtual function void randomize_cfg();
        `DV_CHECK_RANDOMIZE_WITH_FATAL(cfg, !(sp inside {T0, A1}); !(tp inside {T0, A1}););
        `uvm_info(`gfn, $sformatf("riscv_instr_gen_config is randomized:\n%0s",
                        cfg.sprint()), UVM_LOW)
    endfunction

endclass