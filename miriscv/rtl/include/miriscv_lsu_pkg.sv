/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

package  miriscv_lsu_pkg;

  parameter MEM_ACCESS_W     = 3;

  parameter MEM_ACCESS_WORD  = 3'd0; // sign-extension is needed
  parameter MEM_ACCESS_HALF  = 3'd1; // sign-extension is needed
  parameter MEM_ACCESS_BYTE  = 3'd2; // sign-extension is needed
  parameter MEM_ACCESS_UHALF = 3'd3; // allowed for read only
  parameter MEM_ACCESS_UBYTE = 3'd4; // allowed for read only

  parameter MEM_ACCESS_DWORD = 3'd5;
  parameter MEM_ACCESS_UWORD = 3'd6;

endpackage :  miriscv_lsu_pkg
