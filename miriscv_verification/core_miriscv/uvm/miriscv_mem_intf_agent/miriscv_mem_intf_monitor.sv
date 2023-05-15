///////////////////////////////////////////
// Miriscv core memory interface monitor //
///////////////////////////////////////////

class miriscv_mem_intf_monitor extends uvm_monitor;

    `uvm_component_utils(miriscv_mem_intf_monitor)

    // Virtual memory inteface
    virtual miriscv_mem_intf vif;

    // Memory interface transaction port
    uvm_analysis_port#(miriscv_mem_intf_seq_item) item_collected_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
  
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      item_collected_port = new("item_collected_port", this);
      if(!uvm_config_db#(virtual miriscv_mem_intf)::get(this, "", "vif", vif)) begin
         `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
      end
    endfunction
  
    virtual task run_phase(uvm_phase phase);
      wait (vif.monitor_neg_cb.reset === 1'b0);
      forever begin
        fork : check_mem_intf
          collect_item();
          wait (vif.monitor_neg_cb.reset === 1'b1);
        join_any
        // Will only reach this point when mid-test reset is asserted
        disable check_mem_intf;
      end
    endtask
  
    virtual task collect_item();
        miriscv_mem_intf_seq_item trans_collected;
        forever begin
            // Get transaction
            trans_collected = miriscv_mem_intf_seq_item::type_id::create("negedge_trans");
            vif.monitor_get_pos_data (
                trans_collected.instr_rvalid,
                trans_collected.instr_rdata,
                trans_collected.instr_req,
                trans_collected.instr_addr,
                trans_collected.data_rvalid,
                trans_collected.data_rdata,
                trans_collected.data_req,
                trans_collected.data_wdata,
                trans_collected.data_addr,
                trans_collected.data_we,
                trans_collected.data_be
            );
            // Write transaction to the analysis port
            item_collected_port.write(trans_collected);
        end
    endtask
  
endclass