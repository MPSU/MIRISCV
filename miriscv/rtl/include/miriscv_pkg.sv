/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

package  miriscv_pkg;

  parameter     XLEN       = 32;    // Data width, either 32 or 64 bit
  parameter     ILEN       = 32;    // Instruction width, 32 bit only
  parameter bit RV32M      = 1;     // whether design support M-extension or not
  parameter bit RV32C      = 1;     // whether design support C-extension or not
  parameter     DUAL_ISSUE = 0;     // whether design uses dual issue fetch and RVFI

endpackage :  miriscv_pkg
