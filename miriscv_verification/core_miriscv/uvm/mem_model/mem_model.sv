class mem_model#(parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32) extends uvm_object;

    `uvm_object_param_utils(mem_model#(ADDR_WIDTH, DATA_WIDTH))

    typedef bit [ADDR_WIDTH-1:0] mem_addr_t;
    typedef bit [DATA_WIDTH-1:0] mem_data_t;

    bit [7:0] system_memory[mem_addr_t];

    function new(string name="");
        super.new(name);
    endfunction

    function bit [7:0] read_byte(mem_addr_t addr);
        bit [7:0] data;
        if(system_memory.exists(addr)) begin
        data = system_memory[addr];
        `uvm_info(get_full_name(),
           $sformatf("Read Mem  : Addr[0x%0h], Data[0x%0h]", addr, data), UVM_HIGH)
        end
        else begin
        data = 'x;
        `uvm_info(get_full_name(), $sformatf("read to uninitialzed addr 0x%0h, this may corrupt trace log file", addr), UVM_NONE)
        end
        return data;
    endfunction

    function void write_byte(mem_addr_t addr, bit[7:0] data);
        `uvm_info(get_full_name(),
        $sformatf("Write Mem : Addr[0x%0h], Data[0x%0h]", addr, data), UVM_HIGH)
        system_memory[addr] = data;
    endfunction

    function void write(input mem_addr_t addr, mem_data_t data);
        bit [7:0] byte_data;
        for(int i=0; i<DATA_WIDTH/8; i++) begin
            byte_data = data[7:0];
            write_byte(addr+i, byte_data);
            data = data >> 8;
        end
    endfunction

    function mem_data_t read(mem_addr_t addr);
        mem_data_t data;
        for(int i=DATA_WIDTH/8-1; i>=0;  i--) begin
            data = data << 8;
            data[7:0] = read_byte(addr+i);
        end
        return data;
    endfunction

endclass
