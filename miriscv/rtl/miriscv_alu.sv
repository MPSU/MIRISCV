/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

module miriscv_alu
  import miriscv_pkg::XLEN;
  import miriscv_alu_pkg::*;
(
  input  logic [XLEN-1:0]     alu_port_a_i,    // ALU operation first operand
  input  logic [XLEN-1:0]     alu_port_b_i,    // ALU operation second operand
  input  logic [ALU_OP_W-1:0] alu_op_i,        // ALU opcode
  output logic [XLEN-1:0]     alu_result_o,    // ALU result

  output logic                alu_branch_des_o // Comparison result for branch decision
);


  ////////////////////////
  // Local declarations //
  ////////////////////////

  logic [XLEN-1:0]         alu_sum;
  logic                    alu_cmp;
  logic [XLEN-1:0]         alu_shift;
  logic [XLEN-1:0]         alu_bit;

  logic                    carry_out;
  logic                    op_add;

  logic                    signs_eq;
  logic                    signed_op;

  logic                    cmp_ne;
  logic                    cmp_lt;

  logic [$clog2(XLEN)-1:0] shift;
  logic signed [XLEN-1:0]  sra_res;


  ///////////////////////////
  // Addition-substraction //
  ///////////////////////////

  assign op_add = (alu_op_i == ALU_ADD);

  assign {carry_out, alu_sum} = op_add ? (alu_port_a_i + alu_port_b_i)
                                       : (alu_port_a_i - alu_port_b_i);


  //////////////////////////////////
  // Comparison + Branch decision //
  //////////////////////////////////

  always_comb begin
    case (alu_op_i)
      ALU_LT,
      ALU_GE,
      ALU_SLT: signed_op = 1'b1;

      default: signed_op = 1'b0;
    endcase
  end

  assign signs_eq = (alu_port_a_i[XLEN-1] == alu_port_b_i[XLEN-1]);

  assign cmp_ne = |alu_bit;

  assign cmp_lt  = signs_eq ? carry_out
                            : (alu_port_a_i[XLEN-1] == signed_op);

  always_comb begin
    case (alu_op_i)
      ALU_EQ:  alu_branch_des_o = ~cmp_ne;

      ALU_NE:  alu_branch_des_o = cmp_ne;

      ALU_LT,
      ALU_LTU: alu_branch_des_o = cmp_lt;

      ALU_GE,
      ALU_GEU: alu_branch_des_o = ~cmp_lt;

      default: alu_branch_des_o = 1'b0;
    endcase
  end

  // SLT and SLTU
  assign alu_cmp = cmp_lt;


  ///////////
  // Shift //
  ///////////

  assign shift = alu_port_b_i[$clog2(XLEN)-1:0];

  assign sra_res = $signed(alu_port_a_i) >>> shift;

  always_comb begin
    case (alu_op_i)
      ALU_SLL: alu_shift = alu_port_a_i << shift;
      ALU_SRL: alu_shift = alu_port_a_i >> shift;
      default: alu_shift = sra_res; // ALU_SRA
   endcase
  end


  ////////////////////////
  // Bitwise operations //
  ////////////////////////

  always_comb begin
    case (alu_op_i)
      ALU_OR:  alu_bit = alu_port_a_i | alu_port_b_i;

      ALU_AND: alu_bit = alu_port_a_i & alu_port_b_i;

      default: alu_bit = alu_port_a_i ^ alu_port_b_i; // ALU_EQ, ALU_NE, ALU_XOR
    endcase
  end


  /////////
  // MUX //
  /////////

  always_comb begin
    case (alu_op_i)
      ALU_ADD,
      ALU_SUB:  alu_result_o = alu_sum;

      ALU_SLT,
      ALU_SLTU: alu_result_o = {{(XLEN-1){1'b0}}, alu_cmp};

      ALU_SLL,
      ALU_SRL,
      ALU_SRA:  alu_result_o = alu_shift;

      ALU_XOR,
      ALU_OR,
      ALU_AND:  alu_result_o = alu_bit;

      default: alu_result_o = alu_port_b_i; // ALU_JAL
    endcase
  end

endmodule
