///////////////////////////////////
// Miriscv core virtual sequence //
///////////////////////////////////

class miriscv_vseq extends uvm_sequence;

    `uvm_object_utils(miriscv_vseq)

    `uvm_declare_p_sequencer(miriscv_vseqr)

    // We need space for additional sequences on different sequencers
    // That's why we create virtual sequence
    miriscv_mem_intf_slave_seq                    mem_intf_seq;
    mem_model_pkg::mem_model                      mem;

    function new (string name = "");
        super.new(name);
    endfunction

    virtual task body();
        mem_intf_seq = miriscv_mem_intf_slave_seq::type_id::create("instr_intf_seq");
        mem_intf_seq.m_mem = mem;
        fork
            mem_intf_seq.start(p_sequencer.mem_if_seqr);
        join_none
    endtask

endclass
