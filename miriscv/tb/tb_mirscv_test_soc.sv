`timescale 1ns / 1ps
//---------------------------------------------------------
// Module: tb_miriscv_test_soc
//---------------------------------------------------------

// Testbench module for Miriscv SoC Coremark test

module tb_miriscv_test_soc;

    import miriscv_pkg::*;

    //---------------------------------------------------------
    // Parameters
    //---------------------------------------------------------

    // Clock period

    parameter real CLOCK_PERIOD = 10;

    // UART baudrate

    parameter int UART_BAUDRATE = 6250000;


    //---------------------------------------------------------
    // Typedefs: ubytearr_t, ubytearr_q_t
    //---------------------------------------------------------

    typedef byte unsigned ubytearr_t   [ ];
    typedef byte unsigned ubytearr_q_t [$];


    //---------------------------------------------------------
    // Fields
    //---------------------------------------------------------

    // DUT

    logic            clk_i;
    logic            arstn_i;
    logic [XLEN-1:0] boot_addr_i;
    logic            uart_rx_i;
    logic            uart_tx_o;


    //---------------------------------------------------------
    // Variables
    //---------------------------------------------------------

    // UART timeframe

    int unsigned uart_time_frame = 1000000000/UART_BAUDRATE;

    // UART data and UART data queue

    byte uart_data;

    // Coremark info byte representation

    ubytearr_q_t coremark_info_byte;

    // Coremark info string

    string coremark_info_str;

    // Coremark finish message

    string coremark_finish_msg = "CoreMark test finished\n";


    //---------------------------------------------------------
    // Instance: miriscv_test_soc
    //---------------------------------------------------------

    // DUT instance

    miriscv_test_soc DUT (
        .clk_i       ( clk_i       ),
        .arstn_i     ( arstn_i     ),
        .boot_addr_i ( boot_addr_i ),
        .uart_rx_i   ( uart_rx_i   ),
        .uart_tx_o   ( uart_tx_o   )
    );


    //---------------------------------------------------------
    // Task: get_uart_transaction
    //---------------------------------------------------------

    // Task for getting UART transaction

    task automatic get_uart_transaction(output byte data);
        forever begin
            @(negedge uart_tx_o);
            #(uart_time_frame/2);
            if(uart_tx_o == 0) begin
                for(int i = 0; i < 8; i++) begin
                    #uart_time_frame;
                    data += uart_tx_o << i;
                end
                #uart_time_frame;
                if(uart_tx_o != ^data) begin
                    $error("Parity check failed");
                    continue;
                end
                #uart_time_frame;
                if(uart_tx_o != 1) begin
                    $error("Stop bit didn't found");
                    continue;
                end
                break;
            end
        end
    endtask


    //---------------------------------------------------------
    // Function: ascii_to_str
    //---------------------------------------------------------

    // Converts bytearray to string

    function string ascii_to_str(ubytearr_t ascii);
        automatic string str = "";
        foreach(ascii[i]) begin
            str = {str, string'(ascii[i])};
        end
        return str;
    endfunction


    //---------------------------------------------------------
    // Stimulus
    //---------------------------------------------------------

    // Clock

    initial begin
        clk_i <= 1'b0;
        forever begin
            #(CLOCK_PERIOD/2) clk_i <= ~clk_i;
        end
    end

    // Reset

    initial begin
        arstn_i <= 1'b0;
        #(5 * CLOCK_PERIOD);
        arstn_i <= 1'b1;
    end

    // Boot address

    assign boot_addr_i = 32'h0000008C;

    // UART

    assign uart_rx_i = 1'b1;

    initial begin
        forever begin
            get_uart_transaction(uart_data);
            coremark_info_byte.push_back(uart_data);
            if( ascii_to_str('{uart_data}) == "\n" ) begin
                coremark_info_str = ascii_to_str(coremark_info_byte);
                $write("CoreMark: ", coremark_info_str);
                coremark_info_byte = '{};
            end
            if( coremark_info_str == coremark_finish_msg) begin
                $finish();
            end
        end
    end


endmodule
