///////////////////////////////////////////////////
// Miriscv core memory interface slave sequencer //
///////////////////////////////////////////////////

class miriscv_mem_intf_slave_sequencer extends uvm_sequencer #(miriscv_mem_intf_seq_item);

    `uvm_component_utils(miriscv_mem_intf_slave_sequencer)

    // TLM port to peek the address phase from the slave monitor
    uvm_tlm_analysis_fifo #(miriscv_mem_intf_seq_item) item_collected_port;
  
    function new (string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction : new
  
    // On reset, empty the tlm fifo
    function void reset();
        item_collected_port.flush();
    endfunction
  
endclass
  