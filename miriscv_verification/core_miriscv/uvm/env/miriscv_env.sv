//////////////////////////////
// Miriscv core environment //
//////////////////////////////

class miriscv_env extends uvm_env;

    `uvm_component_utils(miriscv_env)

    miriscv_mem_intf_slave_agent mem_if_slave_agent;
    miriscv_vseqr                vseqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Create memory interface agent
        mem_if_slave_agent = miriscv_mem_intf_slave_agent::type_id::create("mem_if_slave_agent", this);
        // Create virtual sequencer
        vseqr = miriscv_vseqr::type_id::create("vseqr", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        vseqr.mem_if_seqr = mem_if_slave_agent.sequencer;
    endfunction : connect_phase

    function void reset();
        mem_if_slave_agent.reset();
    endfunction

endclass
