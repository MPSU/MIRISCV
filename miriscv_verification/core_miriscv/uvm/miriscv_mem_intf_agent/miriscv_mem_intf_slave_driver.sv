//////////////////////////////////////////
// Miriscv core memory interface driver //
//////////////////////////////////////////

class miriscv_mem_intf_slave_driver extends uvm_driver #(miriscv_mem_intf_seq_item);

    `uvm_component_utils(miriscv_mem_intf_slave_driver)

    // Virtual memory inteface
    virtual miriscv_mem_intf vif;

    // Transaction queue for one-cycle delay on data memory read
    mailbox #(miriscv_mem_intf_seq_item) seq_item_queue;
  
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
  
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      seq_item_queue = new();
      if(!uvm_config_db#(virtual miriscv_mem_intf)::get(this, "", "vif", vif))
          `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    endfunction
  
    virtual task run_phase(uvm_phase phase);
      reset_signals();
      wait (vif.driver_cb.reset === 1'b0);
      forever begin
        fork : drive_stimulus
          get_and_drive();
          wait (vif.driver_cb.reset === 1'b1);
        join_any
        // Will only be reached after mid-test reset
        disable drive_stimulus;
        handle_reset();
      end
    endtask : run_phase
  
    virtual protected task handle_reset();
      miriscv_mem_intf_seq_item req;
      // Clear mailbox
      while (seq_item_queue.try_get(req));
      // Clear seq_item_port
      do begin
        seq_item_port.try_next_item(req);
        if (req != null) begin
          seq_item_port.item_done();
        end
      end while (req != null);
      reset_signals();
      wait (vif.driver_cb.reset === 1'b0);
    endtask
  
    virtual task reset_signals();
      vif.driver_cb.instr_rvalid <= 1'b0;
      vif.driver_cb.instr_rdata  <=  'b0;
      vif.driver_cb.data_rvalid  <= 1'b0;
      vif.driver_cb.data_rdata   <=  'b0;
    endtask : reset_signals
  
    virtual task get_and_drive();
      wait (vif.driver_cb.reset === 1'b0);
      fork
        begin
            forever begin
                miriscv_mem_intf_seq_item req, req_c;
                seq_item_port.get_next_item(req);
                $cast(req_c, req.clone());
                if(~vif.driver_cb.reset) begin
                    seq_item_queue.put(req_c);
                end
                seq_item_port.item_done();
            end
        end
        begin
            drive_data();
        end
      join
    endtask
  
    virtual task drive_data();
        miriscv_mem_intf_seq_item tr;
        vif.driver_cb.instr_rdata <= 'x;
        vif.driver_cb.data_rdata  <= 'x;
        forever begin
            seq_item_queue.get(tr);
            if(vif.driver_cb.reset) continue;
            // Here is very simple logic for data and instructions
            // We only use valid signals as flags and pass
            // them to the design. Note that sequence must
            // control this flags perfectly because we don't
            // hawe any additional checks here.
            vif.driver_cb.instr_rvalid <= tr.instr_rvalid;
            vif.driver_cb.instr_rdata  <= tr.instr_rdata;
            if(~vif.driver_cb.reset) begin
                vif.driver_cb.data_rvalid <= tr.data_rvalid;
                vif.driver_cb.data_rdata  <= tr.data_rdata;
            end
        end
    endtask
  
endclass
  