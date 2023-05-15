//////////////////////////////////////////////////////////////////////
// Self-checking test for the two instruction fetch at single cycle //
//////////////////////////////////////////////////////////////////////

class miriscv_two_instr_fetch_check extends uvm_test;

    `uvm_component_utils(miriscv_two_instr_fetch_check)


    // ** Fields

    // Typedefs
    typedef uvm_seq_item_pull_port #(miriscv_mem_intf_seq_item) miriscv_pull_port_t;
    typedef uvm_analysis_port      #(miriscv_mem_intf_seq_item) miriscv_analysis_port_t;

    typedef bit [ADDR_WIDTH -1:0] addr_t;
    typedef bit [DATA_WIDTH -1:0] data_t;
    typedef bit [INSTR_WIDTH-1:0] instr_t;

    // Interface
    virtual miriscv_mem_intf intf;

    // Item
    miriscv_mem_intf_seq_item        item;

    // Components
    miriscv_mem_intf_slave_sequencer seqr;
    miriscv_mem_intf_slave_seq       seq;

    // TLM
    miriscv_pull_port_t     seq_item_port;
    miriscv_analysis_port_t item_collected_port;

    // Memory model
    mem_model_pkg::mem_model mem;

    // Address and write data queues
    addr_t addr_queue  [$];
    data_t wdata_queue [$];


    // ** UVM phases

    function new(string name="", uvm_component parent=null);
        miriscv_report_server report_server;
        super.new(name, parent);
        report_server = new();
        uvm_report_server::set_server(report_server);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        // Create memory model
        mem = mem_model_pkg::mem_model#(ADDR_WIDTH, DATA_WIDTH)::type_id::create("mem");
        // Create TLM
        seq_item_port       = new("seq_item_port", this);
        item_collected_port = new("item_collected_port", this);
        // Create components
        seqr = miriscv_mem_intf_slave_sequencer::type_id::create("seqr", this);
        seq  = miriscv_mem_intf_slave_seq      ::type_id::create("seq");
        // Initialize sequence with memory model
        seq.m_mem = mem;
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        seq_item_port.connect(seqr.seq_item_export);
        item_collected_port.connect(seqr.item_collected_port.analysis_export);
    endfunction

    task main_phase(uvm_phase phase);
        phase.raise_objection(this);
        // Start sequence to obtain data from
        // sequencer after this
        fork
            seq.start(seqr);
        join_none
        // Do some random single and double runs
        for(int i = 0; i < 100; i++) begin
            if($urandom_range(0, 1))
                do_single_run(i);
            else
                do_double_run(i);
        end
        // Do runs, but not clean memory
        for(int i = 0; i < 50; i++) begin
            if($urandom_range(0, 1))
                do_single_run(i, 0);
            else
                do_double_run(i, 0);
        end
        // Create dummy trace file for valid
        // test check with no_post_compare: 1
        create_dummy_trace_file();
        phase.drop_objection(this);
    endtask


    // ** Common

    virtual function void create_dummy_trace_file();
        string file_name, file_name_base = "trace_core"; int file_handle, hart_id_i = 0;;
        $value$plusargs("ibex_tracer_file_base=%s", file_name_base);
        $sformat(file_name, "%s_%h.log", file_name_base, hart_id_i);
        file_handle = $fopen(file_name, "w");
        $fwrite(file_handle,
            "This is dummy trace file for valid test check with no_post_compare: 1\n");
        $fwrite(file_handle, "2130000 6 80000000 80000037 lui x0,0x80000 x0=0x00000000\n");
    endfunction


    // ** Runs

    virtual task do_single_run(int iter = -1, bit clear_mem = 1);
        if(iter >= 0) `uvm_info(get_name(),
            $sformatf("\n\nSingle run no. %5d", iter), UVM_LOW);
        if(clear_mem) seq.m_mem.system_memory.delete();
        miriscv_mem_intf_agent_pkg::instr_amount = 1;
        // Create addresses pool
        form_addr_queue();
        // Write and read from memory
        write_mem_queue(addr_queue);
        read_mem_queue(addr_queue); // 1 instruction at read
    endtask

    virtual task do_double_run(int iter = -1, bit clear_mem = 0);
        if(iter >= 0) `uvm_info(get_name(),
            $sformatf("\n\nDouble run no. %5d", iter), UVM_LOW);
        if(clear_mem) seq.m_mem.system_memory.delete();
        miriscv_mem_intf_agent_pkg::instr_amount = 2;
        // Create addresses pool
        form_daddr_queue();
        // Write and read from memory
        write_mem_queue(addr_queue);
        read_dmem_queue(addr_queue); // 2 instructions at read
    endtask


    // ** Write routines

    virtual function void init_write_item(addr_t addr);
        item = miriscv_mem_intf_seq_item::type_id::create("item_write");
        item.data_req = 1;
        item.data_we = 1;
        item.data_be = '1;
        item.data_wdata = $urandom();
        item.data_addr = addr;
    endfunction

    virtual task write_mem(addr_t addr);
        init_write_item(addr);
        item_collected_port.write(item);
        seq_item_port.get_next_item(item);
        seq_item_port.item_done();
        wdata_queue.push_back(item.data_wdata);
        `uvm_info(get_name(), $sformatf(
            "Write [0x%8h] = %8h", addr, item.data_wdata), UVM_LOW);
    endtask

    virtual task write_mem_queue(addr_t addr []);
        foreach(addr[i]) write_mem(addr[i]);
    endtask


    // ** Read routines

    virtual function void init_read_item(addr_t addr);
        item = miriscv_mem_intf_seq_item::type_id::create("item_read");
        item.instr_req = 1;
        item.instr_addr = addr;
    endfunction

    virtual task read_mem(addr_t addr);
        init_read_item(addr);
        item_collected_port.write(item);
        seq_item_port.get_next_item(item);
        seq_item_port.item_done();
        `uvm_info(get_name(), $sformatf(
            "Read [0x%8h] = %16h", addr, item.instr_rdata), UVM_LOW);
        item.data_wdata = wdata_queue.pop_front();
        check_read(item);
    endtask

    virtual task read_dmem(addr_t addr);
        instr_t data;
        init_read_item(addr);
        item_collected_port.write(item);
        seq_item_port.get_next_item(item);
        seq_item_port.item_done();
        `uvm_info(get_name(), $sformatf("Read [0x%8h] = %16h", addr, item.instr_rdata), UVM_LOW);
        // Returned instruction here will be {instr1, instr0}
        // So we must concatenate data for comparison
        data[  DATA_WIDTH-1:         0] = wdata_queue.pop_front();
        data[2*DATA_WIDTH-1:DATA_WIDTH] = wdata_queue.pop_front();
        check_dread(data, item);
    endtask

    virtual task read_mem_queue(addr_t addr []);
        foreach(addr[i]) read_mem(addr[i]);
    endtask

    virtual task read_dmem_queue(addr_t addr []);
        foreach(addr[i]) if((i % 2) == 0) read_dmem(addr[i]);
    endtask


    // ** Addresses generation routines

    virtual function void form_addr_queue();
        addr_t addr;
        addr_queue.delete();
        repeat(32) begin
            addr = $urandom(); addr[1:0] = '0;
            addr_queue.push_back(addr);
        end
    endfunction

    virtual function void form_daddr_queue();
        addr_t addr;
        addr_queue.delete();
        repeat(16) begin
            addr = $urandom(); addr[2:0] = '0;
            addr_queue.push_back(addr);
            addr_queue.push_back(addr + 4);
        end
    endfunction


    // ** Checks

    virtual function void check_read(miriscv_mem_intf_seq_item item);
        if(item.instr_rdata != item.data_wdata) begin
            `uvm_error(get_name(), $sformatf(
                "Invalid Read [0x%8h]: Real: %16h Expected: %16h", item.instr_addr, item.instr_rdata, item.data_wdata));
        end else
            `uvm_info(get_name(), $sformatf("Valid Read [0x%8h]", item.instr_addr), UVM_LOW);
    endfunction

    virtual function void check_dread(instr_t data, miriscv_mem_intf_seq_item item);
        if(item.instr_rdata != data) begin
            `uvm_error(get_name(), $sformatf(
                "Invalid Read [0x%8h]: Real: %16h Expected: %16h", item.instr_addr, item.instr_rdata, data));
        end else
            `uvm_info(get_name(), $sformatf("Valid Read [0x%8h]", item.instr_addr), UVM_LOW);
    endfunction


endclass
