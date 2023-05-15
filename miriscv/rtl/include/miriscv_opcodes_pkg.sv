/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

package  miriscv_opcodes_pkg;

    parameter logic [4:0] S_OPCODE_SYSTEM = 5'b11100;
    parameter logic [4:0] S_OPCODE_FENCE  = 5'b00011;
    parameter logic [4:0] S_OPCODE_OP     = 5'b01100;
    parameter logic [4:0] S_OPCODE_OPIMM  = 5'b00100;
    parameter logic [4:0] S_OPCODE_LOAD   = 5'b00000;
    parameter logic [4:0] S_OPCODE_STORE  = 5'b01000;
    parameter logic [4:0] S_OPCODE_BRANCH = 5'b11000;
    parameter logic [4:0] S_OPCODE_JAL    = 5'b11011;
    parameter logic [4:0] S_OPCODE_JALR   = 5'b11001;
    parameter logic [4:0] S_OPCODE_AUIPC  = 5'b00101;
    parameter logic [4:0] S_OPCODE_LUI    = 5'b01101;

    parameter logic [6:0] OPCODE_SYSTEM = {S_OPCODE_SYSTEM,2'b11};
    parameter logic [6:0] OPCODE_FENCE  = {S_OPCODE_FENCE ,2'b11};
    parameter logic [6:0] OPCODE_OP     = {S_OPCODE_OP    ,2'b11};
    parameter logic [6:0] OPCODE_OPIMM  = {S_OPCODE_OPIMM ,2'b11};
    parameter logic [6:0] OPCODE_LOAD   = {S_OPCODE_LOAD  ,2'b11};
    parameter logic [6:0] OPCODE_STORE  = {S_OPCODE_STORE ,2'b11};
    parameter logic [6:0] OPCODE_BRANCH = {S_OPCODE_BRANCH,2'b11};
    parameter logic [6:0] OPCODE_JAL    = {S_OPCODE_JAL   ,2'b11};
    parameter logic [6:0] OPCODE_JALR   = {S_OPCODE_JALR  ,2'b11};
    parameter logic [6:0] OPCODE_AUIPC  = {S_OPCODE_AUIPC ,2'b11};
    parameter logic [6:0] OPCODE_LUI    = {S_OPCODE_LUI   ,2'b11};

endpackage
