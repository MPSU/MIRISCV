class miriscv_mem_intf_slave_seq extends uvm_sequence #(miriscv_mem_intf_seq_item);

    `uvm_object_utils(miriscv_mem_intf_slave_seq)

    // We must declare p_sequencer for getting transaction from
    // memory interface minitor
    `uvm_declare_p_sequencer(miriscv_mem_intf_slave_sequencer)

    // Memory model (must best externally assigned)
    mem_model m_mem;

    function new (string name = "");
        super.new(name);
    endfunction
  
    virtual task body();

        // Check if memory was set externally
        if(m_mem ==  null)
            `uvm_fatal(get_full_name(), "Cannot get memory model")

        // Main loop
        forever begin
            // Get transaction from sequencer
            p_sequencer.item_collected_port.get(rsp);
            // Create and fill request
            req = miriscv_mem_intf_seq_item::type_id::create("req");
            req.copy(rsp);
            // Check request addresses
            check_req_addr();
            // Get instruction from memory to request
            proc_req_instr();
            // Get or set data
            proc_req_data();
            `uvm_info(get_full_name(), $sformatf("Response transfer:\n%0s", req.convert2string()), UVM_HIGH)
            // Pass data to the driver
            start_item(req);
            finish_item(req);
        end

    endtask

    virtual function void proc_req_instr();

        // Temporary instruction word
        bit [DATA_WIDTH-1:0] instr_rdata;

        // Instruction address
        bit [ADDR_WIDTH-1:0] aligned_instr_addr;

        // Calculate instruction address
        // Address can be aligned by get_instr_addr_align()
        aligned_instr_addr = (req.instr_addr >> get_instr_addr_align()) << get_instr_addr_align();

        if(req.instr_req) begin
            // We must zero instruction in the beginning as it may
            // have some data and we do some logic ORs next
            req.instr_rdata = '0;
            // Read instruction word by word
            for(int i = 0; i < instr_amount; i++) begin
                // Read single instruction with offset
                instr_rdata = ( m_mem.read(aligned_instr_addr + (DATA_WIDTH / 8) * i) );
                // Do logic OR with final result
                req.instr_rdata = req.instr_rdata | ( instr_rdata << (DATA_WIDTH * i) );
            end
            req.instr_rvalid = 1;
        end else begin
            req.instr_rvalid = 0;
        end

    endfunction

    virtual function void proc_req_data();

        // Temporary write data word
        bit [DATA_WIDTH-1:0] write_data;

        // Data address
        bit [ADDR_WIDTH-1:0] aligned_data_addr;

        // Calculate data address
        aligned_data_addr  = {req.data_addr [ADDR_WIDTH-1:2], 2'b0};

        if(req.data_req) begin
            // Write data from memory to request
            if (req.data_we) begin
                write_data = req.data_wdata;
                for (int i = 0; i < DATA_WIDTH / 8; i++) begin
                    if (req.data_be[i])
                        m_mem.write_byte(aligned_data_addr + i, write_data[7:0]);
                    write_data = write_data >> 8;
                end
            end
            else begin
                // Get data from memory to request
                // Here we are't checking data_be assuming
                // that we always read the full word
                req.data_rdata = m_mem.read(aligned_data_addr);
            end
            req.data_rvalid = 1;
        end else begin
            req.data_rvalid = 0;
        end

    endfunction

    virtual function void check_req_addr();

        bit [ADDR_WIDTH-1:0] instr_addr_offset;
        
        instr_addr_offset = req.instr_addr << (ADDR_WIDTH - get_instr_addr_align());
        
        if(req.instr_req && |instr_addr_offset)
            `uvm_fatal(get_name(), $sformatf("Instruction address 0x%8h is not aligned!", req.instr_addr));

        // This will be applied only if core will generate
        // only aligned addresses for the data requests

        // if(req.data_req && |req.data_addr[1:0])
        //     `uvm_fatal(get_name(), $sformatf("Data address 0x%8h is not aligned!", req.data_addr));

    endfunction

    virtual function int get_instr_addr_align();
        // We depend on data bus width (DATA_WIDTH). Instruction bus can contain
        // more than one instruction of DATA_WIDTH, so we must align address in bytes
        return $clog2((DATA_WIDTH * instr_amount) / 8);
    endfunction

endclass