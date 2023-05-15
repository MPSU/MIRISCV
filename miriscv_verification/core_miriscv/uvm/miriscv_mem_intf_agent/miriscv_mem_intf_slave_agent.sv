/////////////////////////////////////////
// Miriscv core memory interface agent //
/////////////////////////////////////////

class miriscv_mem_intf_slave_agent extends uvm_agent;

    `uvm_component_utils(miriscv_mem_intf_slave_agent)

    miriscv_mem_intf_slave_driver     driver;
    miriscv_mem_intf_slave_sequencer  sequencer;
    miriscv_mem_intf_monitor          monitor;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
  
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = miriscv_mem_intf_monitor::type_id::create("monitor", this);
        if(get_is_active() == UVM_ACTIVE) begin
            driver = miriscv_mem_intf_slave_driver::type_id::create("driver", this);
            sequencer = miriscv_mem_intf_slave_sequencer::type_id::create("sequencer", this);
        end
    endfunction
  
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
            monitor.item_collected_port.connect(sequencer.item_collected_port.analysis_export);
        end
    endfunction

    function void reset();
        sequencer.reset();
    endfunction
  
endclass  