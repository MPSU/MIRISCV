/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

module miriscv_signextend
#(
  parameter IN_WIDTH  = 12,
  parameter OUT_WIDTH = 32
) (
  input  logic [IN_WIDTH-1:0]  data_i,
  output logic [OUT_WIDTH-1:0] data_o
);


  assign data_o = {{(OUT_WIDTH - IN_WIDTH){data_i[IN_WIDTH-1]}}, data_i};

endmodule
