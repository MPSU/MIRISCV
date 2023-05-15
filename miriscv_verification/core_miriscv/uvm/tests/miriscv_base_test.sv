///////////////////////////////////
// Miriscv core basic test class //
///////////////////////////////////

class miriscv_base_test extends uvm_test;

    `uvm_component_utils(miriscv_base_test)

    // Timeout calculation here:
    //    20 * <max instructions count> + 2 * <reset cycles count>
    //                  |                             |
    //  max 2-cycles execution (load/store)      see clk_if.sv
    //                  +
    //  rough delay on subprograms and etc.
    //
    // NOTE: Here <max instructions count> is supposed to be 10000.
    //       If greater amount is expected - change timeout.
    int unsigned                                       timeout_in_cycles = 200 * 10000 + 2 * 100;
    miriscv_env                                        env;
    virtual clk_if                                     clk_vif;
    virtual miriscv_rvfi_if                            rvfi_vif;
    mem_model_pkg::mem_model                           mem;
    miriscv_vseq                                       vseq;
    int unsigned                                       max_quit_count  = 1;
    uvm_tlm_analysis_fifo #(miriscv_mem_intf_seq_item) item_collected_port;
    uvm_phase                                          run;

    function new(string name="", uvm_component parent=null);
        miriscv_report_server report_server;
        super.new(name, parent);
        report_server = new();
        uvm_report_server::set_server(report_server);
        item_collected_port = new("item_collected_port_test", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      // Get clock interface
      if (!uvm_config_db#(virtual clk_if)::get(null, "", "clk_if", clk_vif)) begin
        `uvm_fatal(`gfn, "Cannot get clk_if")
      end
      // Get RVFI interface
      if (!uvm_config_db#(virtual miriscv_rvfi_if)::get(null, "", "rvfi_if", rvfi_vif)) begin
        `uvm_fatal(`gfn, "Cannot get rvfi_if")
      end
      $value$plusargs("timeout_in_cycles=%0d", timeout_in_cycles);
      // Create environment and memory model
      env = miriscv_env::type_id::create("env", this);
      mem = mem_model_pkg::mem_model#()::type_id::create("mem");
      // Create virtual sequence and assign memory handle
      vseq = miriscv_vseq::type_id::create("vseq");
      vseq.mem = mem;
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      env.mem_if_slave_agent.monitor.item_collected_port.connect(this.item_collected_port.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      run = phase;
      clk_vif.wait_clks(100);
      load_binary_to_mem();
      send_stimulus();
      wait_for_test_done();
      phase.drop_objection(this);
    endtask

    virtual function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      void'($value$plusargs("max_quit_count=%0d", max_quit_count));
      uvm_report_server::get_server().set_max_quit_count(max_quit_count);
    endfunction

    virtual function void report_phase(uvm_phase phase);
      super.report_phase(phase);
    endfunction

    virtual task send_stimulus();
        vseq.start(env.vseqr);
    endtask

    function void load_binary_to_mem();
      string      bin;
      bit [7:0]   r8;
      bit [31:0]  addr = `BOOT_ADDR;
      int         f_bin;
      void'($value$plusargs("bin=%0s", bin));
      if (bin == "")
        `uvm_fatal(get_full_name(), "Please specify test binary by +bin=binary_name")
      `uvm_info(get_full_name(), $sformatf("Running test : %0s", bin), UVM_LOW)
      f_bin = $fopen(bin,"rb");
      if (!f_bin)
        `uvm_fatal(get_full_name(), $sformatf("Cannot open file %0s", bin))
      while ($fread(r8,f_bin)) begin
        `uvm_info(`gfn, $sformatf("Init mem [0x%h] = 0x%0h", addr, r8), UVM_FULL)
        mem.write(addr, r8);
        addr++;
      end
    endfunction

    virtual task wait_for_test_done();
      logic [31:0] instr_stream [$];
      fork
        begin
          clk_vif.wait_clks(timeout_in_cycles);
          `uvm_info(`gfn, "Test was finished by timeout", UVM_NONE)
        end
        begin
          forever begin
            // Check status at every cycle
            clk_vif.wait_clks(1);
            if(rvfi_vif.valid) instr_stream.push_back(rvfi_vif.insn);
            if(check_jal_instr_loop(instr_stream, 1000, 10)) break;
          end
          // Wait some additional clocks
          clk_vif.wait_clks(100);
          `uvm_info(`gfn, "write_to_host program section done. Test was finished", UVM_NONE)
        end
      join_any
    endtask

    virtual protected function bit check_jal_instr_loop(
      inout logic [31:0] instr_stream [$],
      input int          jal_am,
      input int          ratio
    );
      // Instructions
      logic [31:0] jal_instr, instr;
      // AL instr flag and jump counter
      bit got_jal_instr; int jal_cnt;
      // Process instruction stream
      if(instr_stream.size() >= jal_am * ratio) begin
        while(instr_stream.size() != 0) begin
          instr = instr_stream.pop_front();
          // If already got JAL instr check equality
          if(got_jal_instr) begin
            if(instr == jal_instr) jal_cnt++;
          // Else check if there is JAL instr
          end else if(instr[6:0] == 7'b1101111) begin
            jal_instr = instr;
            got_jal_instr = 1; jal_cnt++;
          end
          // If reach specified amount return 1
          if(jal_cnt == jal_am) return 1;
        end
      end
      return 0;
    endfunction

    virtual protected function bit check_instr_test_end(inout logic [31:0] instr_stream [$]);
      // We must create some instruction templates here
      logic [31:0] jal   = 32'hFFFFFFEF; // JAL-instruction mask
      logic [31:0] auipc = 32'h00001F17; // AUIPC-instruction with rd = x30 and imm = 1 mask
      logic [31:0] sw    = 32'hFE3F2FA3; // SW-instruction with rs2 = x3 and rs1 = x30
      // Golden instruction stream will be:
      // ( jal 0xX, 0xX -> auipc x30, 0x1 -> sw x3, 0xX(x30) ) x 2
      // Here we doubling SW instruction because of two cycle execution
      logic [31:0] golden_instr_stream [$] = {jal, auipc, sw, sw, jal, auipc, sw, sw};
      // Check input instruction stream
      if( instr_stream.size() == golden_instr_stream.size() ) begin
        logic [31:0] instr, golden_instr;
        while( instr_stream.size() != 0 ) begin
          instr = instr_stream.pop_front();
          golden_instr = golden_instr_stream.pop_front();
          if( (instr & golden_instr) != instr ) begin
            // If we miss -> clear buffer until zero size or first
            // valid instruction and return 0.
            while( instr_stream.size() != 0 && (instr & jal) != instr ) begin
              instr = instr_stream.pop_front();
            end
            instr_stream.push_front(instr);
            return 0;
          end
        end
        return 1;
      end
      else begin
        return 0;
      end
    endfunction

endclass
