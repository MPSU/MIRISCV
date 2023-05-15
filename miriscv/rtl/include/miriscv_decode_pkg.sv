/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

package  miriscv_decode_pkg;

  parameter WB_SRC_W   = 2;
  parameter ALU_DATA   = 2'd0;
  parameter MDU_DATA   = 2'd1;
  parameter LSU_DATA   = 2'd2;
  parameter CSR_DATA   = 2'd3;

  parameter OP1_SEL_W  = 2;
  parameter RS1_DATA   = 2'd0;
  parameter CURRENT_PC = 2'd1;
  parameter ZERO       = 2'd3;

  parameter OP2_SEL_W  = 2;
  parameter RS2_DATA   = 2'd0;
  parameter IMM_I      = 2'd1;
  parameter IMM_U      = 2'd2;
  parameter NEXT_PC    = 2'd3;

endpackage
