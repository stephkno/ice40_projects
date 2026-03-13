module uart #(parameter CLOCKRATE = 12000000, parameter BAUDRATE = 2000000) (
  output reg serial_txd,
  input wire serial_rxd
);

  localparam BAUDCYCLES = CLOCKRATE / BAUDRATE;
  
  wire int_osc;

  SB_HFOSC #(.CLKHF_DIV("0b10")) u_SB_HFOSC (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));
  
  reg [31:0] pwm_counter = 0;
  reg [31:0] uart_baud_counter = BAUDCYCLES;

  reg [3:0] tx_state = 0;
  reg [3:0] rx_state = 0;

  reg [7:0] uart_data = 32;

  reg rx_ready = 0;

  reg [4:0] baudrate = 0;

  always @(posedge int_osc) begin
    
    pwm_counter <= pwm_counter + 1;
    uart_baud_counter <= uart_baud_counter - 1;

    if(uart_baud_counter == 0) begin
      
      serial_txd <= 1;
      uart_baud_counter <= BAUDCYCLES;

      case(tx_state)
        // start bit
        0: begin
          serial_txd <= 0;
          tx_state <= 1;
        end

        // data bits
        1,2,3,4,5,6,7,8: begin
          serial_txd <= uart_data[tx_state-1];
          tx_state <= tx_state + 1;
        end
        
        // stop bit
        9: begin

            serial_txd <= 1;
            tx_state <= 0;

            if(uart_data == 10) uart_data <= 32;
            else if(uart_data == 126) uart_data <= 10;
            else uart_data <= uart_data + 1;

        end
      
      endcase

    end

  end

endmodule
