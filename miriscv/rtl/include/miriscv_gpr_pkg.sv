/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

package  miriscv_gpr_pkg;

  parameter RISCV_E         = 0;
  parameter GPR_ADDR_W      = 5 - RISCV_E;
  parameter GPR_DEPTH       = 2**GPR_ADDR_W;

endpackage:  miriscv_gpr_pkg
