// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Boot address specified in decimal to avoid single quote in number, which
// causes parsing errors of this file in Riviera.
+define+BOOT_ADDR=2147483648 // 32'h8000_0000
+define+TRACE_EXECUTION
+define+RVFI

// Shared lowRISC code
+incdir+${PRJ_DIR}/ibex/vendor/lowrisc_ip/ip/prim/rtl
${PRJ_DIR}/ibex/vendor/lowrisc_ip/ip/prim/rtl/prim_assert.sv

// ibex CORE RTL files
+incdir+${PRJ_DIR}/ibex/rtl
${PRJ_DIR}/ibex/rtl/ibex_pkg.sv
${PRJ_DIR}/ibex/rtl/ibex_tracer_pkg.sv
${PRJ_DIR}/ibex/rtl/new_ibex_tracer.sv

// Miriscv core RTL-files
+incdir+${PRJ_DIR}/../miriscv/rtl/include/
+incdir+${PRJ_DIR}/../miriscv/rtl/
${PRJ_DIR}/../miriscv/rtl/include/*.sv
${PRJ_DIR}/../miriscv/rtl/*.sv

// Core DV files
${PRJ_DIR}/ibex/vendor/google_riscv-dv/src/riscv_signature_pkg.sv
+incdir+${PRJ_DIR}/core_miriscv/uvm/env
+incdir+${PRJ_DIR}/core_miriscv/uvm/tests
+incdir+${PRJ_DIR}/core_miriscv/uvm/miriscv_mem_intf_agent
+incdir+${PRJ_DIR}/core_miriscv/uvm/mem_model
+incdir+${PRJ_DIR}/core_miriscv/uvm/utils
${PRJ_DIR}/core_miriscv/uvm/utils/clk_if.sv
${PRJ_DIR}/core_miriscv/uvm/utils/dv_utils_pkg.sv
${PRJ_DIR}/core_miriscv/uvm/mem_model/mem_model_pkg.sv
${PRJ_DIR}/core_miriscv/uvm/miriscv_mem_intf_agent/miriscv_mem_intf.sv
${PRJ_DIR}/core_miriscv/uvm/miriscv_mem_intf_agent/miriscv_mem_intf_agent_pkg.sv
${PRJ_DIR}/core_miriscv/uvm/env/miriscv_rvfi_if.sv
${PRJ_DIR}/core_miriscv/uvm/env/miriscv_env_pkg.sv
${PRJ_DIR}/core_miriscv/uvm/tests/miriscv_test_pkg.sv

// Miriscv core top testbench and tracing modules
+incdir+${PRJ_DIR}/core_miriscv/tb
${PRJ_DIR}/core_miriscv/tb/miriscv_tb_top.sv
${PRJ_DIR}/core_miriscv/tb/miriscv_tracing.sv
