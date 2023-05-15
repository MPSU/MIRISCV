// This module tests new_ibex_tracer

// Testbench creates 3 logs:
//   trace_core_00000000 - for the original Ibex tracer
//   trace_core_00000001 - for the new Ibex tracer with 1 instruction per cycle
//   trace_core_00000002 - for the new Ibex tracer with 2 instruction per cycle

// After run user must manually compare them

module tb_new_ibex_tracer;

    // Parameters
    parameter NRET1 = 1;
    parameter NRET2 = 2;

    // Clock and reset
    logic        clk_i;
    logic        rst_ni;

    // Memory
    logic [31:0] mem [16384];
    initial $readmemh("tb_new_ibex_tracer_mem.txt", mem);

    // Signals for NRET1
    logic [NRET1 *  1 - 1:0] rvfi_valid_1;
    logic [NRET1 * 64 - 1:0] rvfi_order_1;
    logic [NRET1 * 32 - 1:0] rvfi_insn_1;
    logic [NRET1 *  1 - 1:0] rvfi_trap_1;
    logic [NRET1 *  1 - 1:0] rvfi_halt_1;
    logic [NRET1 *  1 - 1:0] rvfi_intr_1;
    logic [NRET1 *  2 - 1:0] rvfi_mode_1;
    logic [NRET1 *  2 - 1:0] rvfi_ixl_1;
    logic [NRET1 *  5 - 1:0] rvfi_rs1_addr_1;
    logic [NRET1 *  5 - 1:0] rvfi_rs2_addr_1;
    logic [NRET1 *  5 - 1:0] rvfi_rs3_addr_1;
    logic [NRET1 * 32 - 1:0] rvfi_rs1_rdata_1;
    logic [NRET1 * 32 - 1:0] rvfi_rs2_rdata_1;
    logic [NRET1 * 32 - 1:0] rvfi_rs3_rdata_1;
    logic [NRET1 *  5 - 1:0] rvfi_rd_addr_1;
    logic [NRET1 * 32 - 1:0] rvfi_rd_wdata_1;
    logic [NRET1 * 32 - 1:0] rvfi_pc_rdata_1;
    logic [NRET1 * 32 - 1:0] rvfi_pc_wdata_1;
    logic [NRET1 * 32 - 1:0] rvfi_mem_addr_1;
    logic [NRET1 *  4 - 1:0] rvfi_mem_rmask_1;
    logic [NRET1 *  4 - 1:0] rvfi_mem_wmask_1;
    logic [NRET1 * 32 - 1:0] rvfi_mem_rdata_1;
    logic [NRET1 * 32 - 1:0] rvfi_mem_wdata_1;

    // Signals for NRET2
    logic [NRET2 *  1 - 1:0] rvfi_valid_2;
    logic [NRET2 * 64 - 1:0] rvfi_order_2;
    logic [NRET2 * 32 - 1:0] rvfi_insn_2;
    logic [NRET2 *  1 - 1:0] rvfi_trap_2;
    logic [NRET2 *  1 - 1:0] rvfi_halt_2;
    logic [NRET2 *  1 - 1:0] rvfi_intr_2;
    logic [NRET2 *  2 - 1:0] rvfi_mode_2;
    logic [NRET2 *  2 - 1:0] rvfi_ixl_2;
    logic [NRET2 *  5 - 1:0] rvfi_rs1_addr_2;
    logic [NRET2 *  5 - 1:0] rvfi_rs2_addr_2;
    logic [NRET2 *  5 - 1:0] rvfi_rs3_addr_2;
    logic [NRET2 * 32 - 1:0] rvfi_rs1_rdata_2;
    logic [NRET2 * 32 - 1:0] rvfi_rs2_rdata_2;
    logic [NRET2 * 32 - 1:0] rvfi_rs3_rdata_2;
    logic [NRET2 *  5 - 1:0] rvfi_rd_addr_2;
    logic [NRET2 * 32 - 1:0] rvfi_rd_wdata_2;
    logic [NRET2 * 32 - 1:0] rvfi_pc_rdata_2;
    logic [NRET2 * 32 - 1:0] rvfi_pc_wdata_2;
    logic [NRET2 * 32 - 1:0] rvfi_mem_addr_2;
    logic [NRET2 *  4 - 1:0] rvfi_mem_rmask_2;
    logic [NRET2 *  4 - 1:0] rvfi_mem_wmask_2;
    logic [NRET2 * 32 - 1:0] rvfi_mem_rdata_2;
    logic [NRET2 * 32 - 1:0] rvfi_mem_wdata_2;
    
    ibex_tracer DUT_0 (
      .clk_i          ( clk_i            ),
      .rst_ni         ( rst_ni           ),
      .hart_id_i      ( 32'd0            ),
      .rvfi_valid     ( rvfi_valid_1     ),
      .rvfi_order     ( rvfi_order_1     ),
      .rvfi_insn      ( rvfi_insn_1      ),
      .rvfi_trap      ( rvfi_trap_1      ),
      .rvfi_halt      ( rvfi_halt_1      ),
      .rvfi_intr      ( rvfi_intr_1      ),
      .rvfi_mode      ( rvfi_mode_1      ),
      .rvfi_ixl       ( rvfi_ixl_1       ),
      .rvfi_rs1_addr  ( rvfi_rs1_addr_1  ),
      .rvfi_rs2_addr  ( rvfi_rs2_addr_1  ),
      .rvfi_rs3_addr  ( rvfi_rs3_addr_1  ),
      .rvfi_rs1_rdata ( rvfi_rs1_rdata_1 ),
      .rvfi_rs2_rdata ( rvfi_rs2_rdata_1 ),
      .rvfi_rs3_rdata ( rvfi_rs3_rdata_1 ),
      .rvfi_rd_addr   ( rvfi_rd_addr_1   ),
      .rvfi_rd_wdata  ( rvfi_rd_wdata_1  ),
      .rvfi_pc_rdata  ( rvfi_pc_rdata_1  ),
      .rvfi_pc_wdata  ( rvfi_pc_wdata_1  ),
      .rvfi_mem_addr  ( rvfi_mem_addr_1  ),
      .rvfi_mem_rmask ( rvfi_mem_rmask_1 ),
      .rvfi_mem_wmask ( rvfi_mem_wmask_1 ),
      .rvfi_mem_rdata ( rvfi_mem_rdata_1 ),
      .rvfi_mem_wdata ( rvfi_mem_wdata_1 )
    );

    new_ibex_tracer #(
      .NRET           ( NRET1            )
    ) DUT_1 (
      .clk_i          ( clk_i            ),
      .rst_ni         ( rst_ni           ),
      .hart_id_i      ( 32'd1            ),
      .rvfi_valid     ( rvfi_valid_1     ),
      .rvfi_order     ( rvfi_order_1     ),
      .rvfi_insn      ( rvfi_insn_1      ),
      .rvfi_trap      ( rvfi_trap_1      ),
      .rvfi_halt      ( rvfi_halt_1      ),
      .rvfi_intr      ( rvfi_intr_1      ),
      .rvfi_mode      ( rvfi_mode_1      ),
      .rvfi_ixl       ( rvfi_ixl_1       ),
      .rvfi_rs1_addr  ( rvfi_rs1_addr_1  ),
      .rvfi_rs2_addr  ( rvfi_rs2_addr_1  ),
      .rvfi_rs3_addr  ( rvfi_rs3_addr_1  ),
      .rvfi_rs1_rdata ( rvfi_rs1_rdata_1 ),
      .rvfi_rs2_rdata ( rvfi_rs2_rdata_1 ),
      .rvfi_rs3_rdata ( rvfi_rs3_rdata_1 ),
      .rvfi_rd_addr   ( rvfi_rd_addr_1   ),
      .rvfi_rd_wdata  ( rvfi_rd_wdata_1  ),
      .rvfi_pc_rdata  ( rvfi_pc_rdata_1  ),
      .rvfi_pc_wdata  ( rvfi_pc_wdata_1  ),
      .rvfi_mem_addr  ( rvfi_mem_addr_1  ),
      .rvfi_mem_rmask ( rvfi_mem_rmask_1 ),
      .rvfi_mem_wmask ( rvfi_mem_wmask_1 ),
      .rvfi_mem_rdata ( rvfi_mem_rdata_1 ),
      .rvfi_mem_wdata ( rvfi_mem_wdata_1 )
    );

    new_ibex_tracer #(
      .NRET           ( NRET2            )
    ) DUT_2 (
      .clk_i          ( clk_i            ),
      .rst_ni         ( rst_ni           ),
      .hart_id_i      ( 32'd2            ),
      .rvfi_valid     ( rvfi_valid_2     ),
      .rvfi_order     ( rvfi_order_2     ),
      .rvfi_insn      ( rvfi_insn_2      ),
      .rvfi_trap      ( rvfi_trap_2      ),
      .rvfi_halt      ( rvfi_halt_2      ),
      .rvfi_intr      ( rvfi_intr_2      ),
      .rvfi_mode      ( rvfi_mode_2      ),
      .rvfi_ixl       ( rvfi_ixl_2       ),
      .rvfi_rs1_addr  ( rvfi_rs1_addr_2  ),
      .rvfi_rs2_addr  ( rvfi_rs2_addr_2  ),
      .rvfi_rs3_addr  ( rvfi_rs3_addr_2  ),
      .rvfi_rs1_rdata ( rvfi_rs1_rdata_2 ),
      .rvfi_rs2_rdata ( rvfi_rs2_rdata_2 ),
      .rvfi_rs3_rdata ( rvfi_rs3_rdata_2 ),
      .rvfi_rd_addr   ( rvfi_rd_addr_2   ),
      .rvfi_rd_wdata  ( rvfi_rd_wdata_2  ),
      .rvfi_pc_rdata  ( rvfi_pc_rdata_2  ),
      .rvfi_pc_wdata  ( rvfi_pc_wdata_2  ),
      .rvfi_mem_addr  ( rvfi_mem_addr_2  ),
      .rvfi_mem_rmask ( rvfi_mem_rmask_2 ),
      .rvfi_mem_wmask ( rvfi_mem_wmask_2 ),
      .rvfi_mem_rdata ( rvfi_mem_rdata_2 ),
      .rvfi_mem_wdata ( rvfi_mem_wdata_2 )
    );

    class rvfi_instr;

        rand logic [NRET2 *  1 - 1:0] rvfi_valid;
        rand logic [NRET2 * 64 - 1:0] rvfi_order;
        rand logic [NRET2 * 32 - 1:0] rvfi_insn;
        rand logic [NRET2 *  1 - 1:0] rvfi_trap;
        rand logic [NRET2 *  1 - 1:0] rvfi_halt;
        rand logic [NRET2 *  1 - 1:0] rvfi_intr;
        rand logic [NRET2 *  2 - 1:0] rvfi_mode;
        rand logic [NRET2 *  2 - 1:0] rvfi_ixl;
        rand logic [NRET2 *  5 - 1:0] rvfi_rs1_addr;
        rand logic [NRET2 *  5 - 1:0] rvfi_rs2_addr;
        rand logic [NRET2 *  5 - 1:0] rvfi_rs3_addr;
        rand logic [NRET2 * 32 - 1:0] rvfi_rs1_rdata;
        rand logic [NRET2 * 32 - 1:0] rvfi_rs2_rdata;
        rand logic [NRET2 * 32 - 1:0] rvfi_rs3_rdata;
        rand logic [NRET2 *  5 - 1:0] rvfi_rd_addr;
        rand logic [NRET2 * 32 - 1:0] rvfi_rd_wdata;
        rand logic [NRET2 * 32 - 1:0] rvfi_pc_rdata;
        rand logic [NRET2 * 32 - 1:0] rvfi_pc_wdata;
        rand logic [NRET2 * 32 - 1:0] rvfi_mem_addr;
        rand logic [NRET2 *  4 - 1:0] rvfi_mem_rmask;
        rand logic [NRET2 *  4 - 1:0] rvfi_mem_wmask;
        rand logic [NRET2 * 32 - 1:0] rvfi_mem_rdata;
        rand logic [NRET2 * 32 - 1:0] rvfi_mem_wdata;

        constraint valid_c {rvfi_valid == 2'b01;}
        constraint trap_c {rvfi_trap == 0;}
        constraint order_c {rvfi_order == 'b0;}

        constraint unused_c {{rvfi_halt, rvfi_intr, rvfi_mode, rvfi_ixl} == 'b0;};

        virtual function void copy2(rvfi_instr rhs2, rvfi_instr rhs1);
            this.rvfi_valid     = {rhs2.rvfi_valid    [     0], rhs1.rvfi_valid    [     0]};
            this.rvfi_order     = {rhs2.rvfi_order    [ 63: 0], rhs1.rvfi_order    [ 63: 0]};
            this.rvfi_insn      = {rhs2.rvfi_insn     [ 31: 0], rhs1.rvfi_insn     [ 31: 0]};
            this.rvfi_trap      = {rhs2.rvfi_trap     [     0], rhs1.rvfi_trap     [     0]};
            this.rvfi_halt      = {rhs2.rvfi_halt     [     0], rhs1.rvfi_halt     [     0]};
            this.rvfi_intr      = {rhs2.rvfi_intr     [     0], rhs1.rvfi_intr     [     0]};
            this.rvfi_mode      = {rhs2.rvfi_mode     [  1: 0], rhs1.rvfi_mode     [  1: 0]};
            this.rvfi_ixl       = {rhs2.rvfi_ixl      [  1: 0], rhs1.rvfi_ixl      [  1: 0]};
            this.rvfi_rs1_addr  = {rhs2.rvfi_rs1_addr [  4: 0], rhs1.rvfi_rs1_addr [  4: 0]};
            this.rvfi_rs2_addr  = {rhs2.rvfi_rs2_addr [  4: 0], rhs1.rvfi_rs2_addr [  4: 0]};
            this.rvfi_rs3_addr  = {rhs2.rvfi_rs3_addr [  4: 0], rhs1.rvfi_rs3_addr [  4: 0]};
            this.rvfi_rs1_rdata = {rhs2.rvfi_rs1_rdata[ 31: 0], rhs1.rvfi_rs1_rdata[ 31: 0]};
            this.rvfi_rs2_rdata = {rhs2.rvfi_rs2_rdata[ 31: 0], rhs1.rvfi_rs2_rdata[ 31: 0]};
            this.rvfi_rs3_rdata = {rhs2.rvfi_rs3_rdata[ 31: 0], rhs1.rvfi_rs3_rdata[ 31: 0]};
            this.rvfi_rd_addr   = {rhs2.rvfi_rd_addr  [  4: 0], rhs1.rvfi_rd_addr  [  4: 0]};
            this.rvfi_rd_wdata  = {rhs2.rvfi_rd_wdata [ 31: 0], rhs1.rvfi_rd_wdata [ 31: 0]};
            this.rvfi_pc_rdata  = {rhs2.rvfi_pc_rdata [ 31: 0], rhs1.rvfi_pc_rdata [ 31: 0]};
            this.rvfi_pc_wdata  = {rhs2.rvfi_pc_wdata [ 31: 0], rhs1.rvfi_pc_wdata [ 31: 0]};
            this.rvfi_mem_addr  = {rhs2.rvfi_mem_addr [ 31: 0], rhs1.rvfi_mem_addr [ 31: 0]};
            this.rvfi_mem_rmask = {rhs2.rvfi_mem_rmask[  3: 0], rhs1.rvfi_mem_rmask[  3: 0]};
            this.rvfi_mem_wmask = {rhs2.rvfi_mem_wmask[  3: 0], rhs1.rvfi_mem_wmask[  3: 0]};
            this.rvfi_mem_rdata = {rhs2.rvfi_mem_rdata[ 31: 0], rhs1.rvfi_mem_rdata[ 31: 0]};
            this.rvfi_mem_wdata = {rhs2.rvfi_mem_wdata[ 31: 0], rhs1.rvfi_mem_wdata[ 31: 0]};
        endfunction

        function void rand_change_order();
            // Randomly change order
            if($urandom_range(0,1)) begin
                rvfi_valid     = {rvfi_valid    [     0], rvfi_valid    [     0]};
                rvfi_order     = {rvfi_order    [ 63: 0], rvfi_order    [127:64]};
                rvfi_insn      = {rvfi_insn     [ 31: 0], rvfi_insn     [ 63:32]};
                rvfi_trap      = {rvfi_trap     [     0], rvfi_trap     [     1]};
                rvfi_halt      = {rvfi_halt     [     0], rvfi_halt     [     1]};
                rvfi_intr      = {rvfi_intr     [     0], rvfi_intr     [     1]};
                rvfi_mode      = {rvfi_mode     [  1: 0], rvfi_mode     [  3: 2]};
                rvfi_ixl       = {rvfi_ixl      [  1: 0], rvfi_ixl      [  3: 2]};
                rvfi_rs1_addr  = {rvfi_rs1_addr [  4: 0], rvfi_rs1_addr [  9: 5]};
                rvfi_rs2_addr  = {rvfi_rs2_addr [  4: 0], rvfi_rs2_addr [  9: 5]};
                rvfi_rs3_addr  = {rvfi_rs3_addr [  4: 0], rvfi_rs3_addr [  9: 5]};
                rvfi_rs1_rdata = {rvfi_rs1_rdata[ 31: 0], rvfi_rs1_rdata[ 63:32]};
                rvfi_rs2_rdata = {rvfi_rs2_rdata[ 31: 0], rvfi_rs2_rdata[ 63:32]};
                rvfi_rs3_rdata = {rvfi_rs3_rdata[ 31: 0], rvfi_rs3_rdata[ 63:32]};
                rvfi_rd_addr   = {rvfi_rd_addr  [  4: 0], rvfi_rd_addr  [  9: 5]};
                rvfi_rd_wdata  = {rvfi_rd_wdata [ 31: 0], rvfi_rd_wdata [ 63:32]};
                rvfi_pc_rdata  = {rvfi_pc_rdata [ 31: 0], rvfi_pc_rdata [ 63:32]};
                rvfi_pc_wdata  = {rvfi_pc_wdata [ 31: 0], rvfi_pc_wdata [ 63:32]};
                rvfi_mem_addr  = {rvfi_mem_addr [ 31: 0], rvfi_mem_addr [ 63:32]};
                rvfi_mem_rmask = {rvfi_mem_rmask[  3: 0], rvfi_mem_rmask[  7: 4]};
                rvfi_mem_wmask = {rvfi_mem_wmask[  3: 0], rvfi_mem_wmask[  7: 4]};
                rvfi_mem_rdata = {rvfi_mem_rdata[ 31: 0], rvfi_mem_rdata[ 63:32]};
                rvfi_mem_wdata = {rvfi_mem_wdata[ 31: 0], rvfi_mem_wdata[ 63:32]};
            end
        endfunction

    endclass

    rvfi_instr instr_queue [$];

    function automatic rvfi_instr rand_rvfi_instr_1(logic [NRET2 * 32 - 1:0] insn);
        rvfi_instr instr;
        instr = new();
        instr.randomize() with {rvfi_insn == insn;};
        return instr;
    endfunction

    function automatic rvfi_instr rand_rvfi_instr_2(logic [NRET2 * 32 - 1:0] insn);
        rvfi_instr instr;
        instr = new();
        instr.randomize() with {rvfi_insn == insn;};
        return instr;
    endfunction

    task set_rvfi_instr_1(rvfi_instr instr);
        rvfi_valid_1     <= instr.rvfi_valid;
        rvfi_order_1     <= instr.rvfi_order;
        rvfi_insn_1      <= instr.rvfi_insn;
        rvfi_trap_1      <= instr.rvfi_trap;
        rvfi_halt_1      <= instr.rvfi_halt;
        rvfi_intr_1      <= instr.rvfi_intr;
        rvfi_mode_1      <= instr.rvfi_mode;
        rvfi_ixl_1       <= instr.rvfi_ixl;
        rvfi_rs1_addr_1  <= instr.rvfi_rs1_addr;
        rvfi_rs2_addr_1  <= instr.rvfi_rs2_addr;
        rvfi_rs3_addr_1  <= instr.rvfi_rs3_addr;
        rvfi_rs1_rdata_1 <= instr.rvfi_rs1_rdata;
        rvfi_rs2_rdata_1 <= instr.rvfi_rs2_rdata;
        rvfi_rs3_rdata_1 <= instr.rvfi_rs3_rdata;
        rvfi_rd_addr_1   <= instr.rvfi_rd_addr;
        rvfi_rd_wdata_1  <= instr.rvfi_rd_wdata;
        rvfi_pc_rdata_1  <= instr.rvfi_pc_rdata;
        rvfi_pc_wdata_1  <= instr.rvfi_pc_wdata;
        rvfi_mem_addr_1  <= instr.rvfi_mem_addr;
        rvfi_mem_rmask_1 <= instr.rvfi_mem_rmask;
        rvfi_mem_wmask_1 <= instr.rvfi_mem_wmask;
        rvfi_mem_rdata_1 <= instr.rvfi_mem_rdata;
        rvfi_mem_wdata_1 <= instr.rvfi_mem_wdata;
    endtask

    task set_rvfi_instr_2(rvfi_instr instr);
        rvfi_valid_2     <= instr.rvfi_valid;
        rvfi_order_2     <= instr.rvfi_order;
        rvfi_insn_2      <= instr.rvfi_insn;
        rvfi_trap_2      <= instr.rvfi_trap;
        rvfi_halt_2      <= instr.rvfi_halt;
        rvfi_intr_2      <= instr.rvfi_intr;
        rvfi_mode_2      <= instr.rvfi_mode;
        rvfi_ixl_2       <= instr.rvfi_ixl;
        rvfi_rs1_addr_2  <= instr.rvfi_rs1_addr;
        rvfi_rs2_addr_2  <= instr.rvfi_rs2_addr;
        rvfi_rs3_addr_2  <= instr.rvfi_rs3_addr;
        rvfi_rs1_rdata_2 <= instr.rvfi_rs1_rdata;
        rvfi_rs2_rdata_2 <= instr.rvfi_rs2_rdata;
        rvfi_rs3_rdata_2 <= instr.rvfi_rs3_rdata;
        rvfi_rd_addr_2   <= instr.rvfi_rd_addr;
        rvfi_rd_wdata_2  <= instr.rvfi_rd_wdata;
        rvfi_pc_rdata_2  <= instr.rvfi_pc_rdata;
        rvfi_pc_wdata_2  <= instr.rvfi_pc_wdata;
        rvfi_mem_addr_2  <= instr.rvfi_mem_addr;
        rvfi_mem_rmask_2 <= instr.rvfi_mem_rmask;
        rvfi_mem_wmask_2 <= instr.rvfi_mem_wmask;
        rvfi_mem_rdata_2 <= instr.rvfi_mem_rdata;
        rvfi_mem_wdata_2 <= instr.rvfi_mem_wdata;
    endtask

    task set_rvfi_1();
        rvfi_instr instr; bit [NRET2 * 32 - 1:0] data;
        instr_queue.delete();
        for(int i = 0; i < 16384; i = i + 1) begin
            $display("Setting instruction [%5d]...", i);
            @(posedge clk_i);
            data = {32'b0, mem[i]};
            instr = rand_rvfi_instr_1(data);
            set_rvfi_instr_1(instr);
            instr_queue.push_back(instr);
        end
    endtask

    task set_rvfi_2();
        rvfi_instr instr; bit [NRET2 * 32 - 1:0] data; 
        for(int i = 0; i < 16384; i = i + 2) begin
            $display("Setting instruction [%5d]...", i);
            @(posedge clk_i);
            instr = rand_rvfi_instr_2(0);
            instr.copy2(instr_queue[i+1], instr_queue[i]);
            instr.rvfi_valid = 2'b11; instr.rvfi_order = {64'b1, 64'b0};
            instr.rand_change_order();
            set_rvfi_instr_2(instr);
        end
    endtask

    task reset();
        rst_ni <= 1'b0;
        repeat(2) @(posedge clk_i);
        rst_ni <= 1'b1;
    endtask


    initial begin
        clk_i <= 1'b0;
        forever #10 clk_i <= ~clk_i;
    end

    initial begin
        reset();
        set_rvfi_1();
        repeat(100) @(posedge clk_i);
        DUT_0.trace_log_enable = 0;
        DUT_1.trace_log_enable = 0;
        @(posedge clk_i);
        reset();
        set_rvfi_2();
        repeat(100) @(posedge clk_i);
        DUT_2.trace_log_enable = 0;
        $display("Sumulation done. Please, compare logs!");
        $stop();
    end

endmodule