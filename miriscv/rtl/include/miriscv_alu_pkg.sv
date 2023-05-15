/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

package  miriscv_alu_pkg;

  parameter ALU_OP_W = 5;

  parameter ALU_ADD  = 5'b00000;    // addition
  parameter ALU_SUB  = 5'b00001;    // substraction

  parameter ALU_EQ   = 5'b00010;    //           rs1 == rs2 (branch)
  parameter ALU_NE   = 5'b00011;    //           rs1 != rs2 (branch)
  parameter ALU_LT   = 5'b00100;    // signed,   rs1 <  rs2 (branch)
  parameter ALU_LTU  = 5'b00101;    // unsigned, rs1 <  rs2 (branch)
  parameter ALU_GE   = 5'b00110;    // signed,   rs1 >= rs2 (branch)
  parameter ALU_GEU  = 5'b00111;    // unsigned, rs1 >= rs2 (branch)

  parameter ALU_SLT  = 5'b01000;    // signed,   rs1 <  rs2 (reg-reg)
  parameter ALU_SLTU = 5'b01001;    // unsigned, rs1 <  rs2 (reg-reg)

  parameter ALU_SLL  = 5'b01010;    // logical left shift
  parameter ALU_SRL  = 5'b01011;    // logical right shift
  parameter ALU_SRA  = 5'b01100;    // arithmetic right shift

  parameter ALU_XOR  = 5'b01101;    // bitwise XOR
  parameter ALU_OR   = 5'b01110;    // bitwise OR
  parameter ALU_AND  = 5'b01111;    // bitwise AND

  parameter ALU_JAL  = 5'b10000;    // rs2 bypass for JAL and JALR

endpackage :  miriscv_alu_pkg
