module uart (
  output wire led_red,
  output wire led_green,
  output wire led_blue,
  output reg serial_txd,
  input wire serial_rxd
);

  wire int_osc;
  
  SB_HFOSC #(.CLKHF_DIV("0b11")) u_SB_HFOSC (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));
  
  reg [31:0] pwm_counter = 0;
  reg [31:0] uart_baud_counter = 3;

  reg [3:0] tx_state = 0;
  reg [3:0] rx_state = 0;

  reg [7:0] uart_data = 32;

  reg rx_ready = 0;

  // color values
  reg [7:0] red = 255;
  reg [7:0] green = 0;
  reg [7:0] blue = 0;

  reg [4:0] baudrate = 0;

  always @(posedge int_osc) begin
    
    pwm_counter <= pwm_counter + 1;
    uart_baud_counter <= uart_baud_counter - 1;

    if(uart_baud_counter == 0) begin
      
      serial_txd <= 1;
      uart_baud_counter <= 3;

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

  SB_RGBA_DRV RGB_DRIVER (
    .RGBLEDEN(1'b1),
    .RGB0PWM (pwm_counter < green),
    .RGB1PWM (pwm_counter < blue),
    .RGB2PWM (pwm_counter < red),
    .CURREN  (1'b1),
    .RGB0 (led_red),
    .RGB1 (led_green),
    .RGB2 (led_blue)
  );

  defparam RGB_DRIVER.RGB0_CURRENT = "0b00000001";
  defparam RGB_DRIVER.RGB1_CURRENT = "0b00000001";
  defparam RGB_DRIVER.RGB2_CURRENT = "0b00000001";

endmodule
