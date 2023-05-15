/////////////////////////////////////////////////
// Miriscv core memory interface sequence item //
/////////////////////////////////////////////////

class miriscv_mem_intf_seq_item extends uvm_sequence_item;

    `uvm_object_utils(miriscv_mem_intf_seq_item)

    logic                    instr_rvalid;
    logic [INSTR_WIDTH-1:0]  instr_rdata;
    logic                    instr_req;
    logic [ADDR_WIDTH-1:0]   instr_addr;

    logic                    data_rvalid;
    logic [DATA_WIDTH-1:0]   data_rdata;
    logic                    data_req;
    logic [DATA_WIDTH-1:0]   data_wdata;
    logic [ADDR_WIDTH-1:0]   data_addr;
    logic                    data_we;
    logic [DATA_WIDTH/8-1:0] data_be;

    function new (string name = "");
        super.new(name);
    endfunction
  
    virtual function void do_copy(uvm_object rhs);
        miriscv_mem_intf_seq_item that;
        if (!$cast(that, rhs)) begin
          `uvm_error( get_name(), "rhs is not an miriscv_mem_intf_seq_item" )
          return;
        end
        super.do_copy(rhs);
        this.instr_rvalid = that.instr_rvalid;
        this.instr_rdata  = that.instr_rdata;
        this.instr_req    = that.instr_req;
        this.instr_addr   = that.instr_addr;
        this.data_rvalid  = that.data_rvalid;
        this.data_rdata   = that.data_rdata;
        this.data_req     = that.data_req;
        this.data_wdata   = that.data_wdata;
        this.data_addr    = that.data_addr;
        this.data_we      = that.data_we;
        this.data_be      = that.data_be;
    endfunction

    virtual function string convert2string();
        string s = super.convert2string();
        s = {s, $sformatf("\nname : %s",        get_name() )};
        s = {s, $sformatf("\ninstr_rvalid: %h", instr_rvalid)};
        s = {s, $sformatf("\ninstr_rdata: %h",  instr_rdata)};
        s = {s, $sformatf("\ninstr_req: %h",    instr_req)};
        s = {s, $sformatf("\ninstr_addr: %h",   instr_addr )};
        s = {s, $sformatf("\ndata_rvalid: %h",  data_rvalid )};
        s = {s, $sformatf("\ndata_rdata: %h",   data_rdata )};
        s = {s, $sformatf("\ndata_req: %h",     data_req )};
        s = {s, $sformatf("\ndata_wdata: %h",   data_wdata )};
        s = {s, $sformatf("\ndata_addr: %h",    data_addr  )};
        s = {s, $sformatf("\ndata_we: %h",      data_we    )};
        s = {s, $sformatf("\ndata_be: %h",      data_be    )};
        return s;
    endfunction
  
endclass