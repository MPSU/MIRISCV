////////////////////////////////////
// Miriscv core virtual sequencer //
////////////////////////////////////

class miriscv_vseqr extends uvm_sequencer;

    `uvm_component_utils(miriscv_vseqr)

    // We need space for additional sequencers
    // That's why we create virtual sequencer
    miriscv_mem_intf_slave_sequencer mem_if_seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
