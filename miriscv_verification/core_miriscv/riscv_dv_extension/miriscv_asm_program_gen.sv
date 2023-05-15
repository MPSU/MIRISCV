// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//-----------------------------------------------------------------------------------------
// RISC-V assembly program generator for Miriscv core - Experimental!
//-----------------------------------------------------------------------------------------

class miriscv_asm_program_gen extends riscv_asm_program_gen;

  `uvm_object_utils(miriscv_asm_program_gen)
  `uvm_object_new

  virtual function void gen_program_header();
    // Some Ibex core configurations
    // Now sure if it will work with Miriscv core
    cfg.mstatus_mprv = 0;
    cfg.mstatus_mxr  = 0;
    cfg.mstatus_sum  = 0;
    cfg.mstatus_tvm  = 0;
    cfg.check_misa_init_val = 1'b0;
    cfg.check_xstatus = 1'b0;
    // Set bare program mode for Miriscv core
    cfg.bare_program_mode = 1;
    instr_stream.push_back(".section .text");
    instr_stream.push_back(".globl _start");
    if (cfg.disable_compressed_instr) begin
      instr_stream.push_back(".option norvc;");
    end
    // Align the start section to 0x80
    instr_stream.push_back(".align 7");
    instr_stream.push_back("_start:");
  endfunction

endclass
