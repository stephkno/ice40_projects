module uart (
  output wire led_red,
  output wire led_green,
  output wire led_blue,
  output wire serial_txd,
  input wire serial_rxd
);

  wire int_osc;
  
  SB_HFOSC #(.CLKHF_DIV("0b00")) u_SB_HFOSC (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));
  
  reg [31:0] pwm_counter = 0;
  reg [31:0] uart_baud_counter = 160000;

  reg [3:0] tx_state = 0;
  reg [3:0] rx_state = 0;

  reg [7:0] uart_data = 0;

  reg rx_ready = 0;

  // color values
  reg [7:0] red = 255;
  reg [7:0] green = 0;
  reg [7:0] blue = 0;

  // 0 = 300, 1 = 600, 2 = 1200, 5 = 9600, 17 = 2m
  reg [4:0] baudrate = 0;

  always @(posedge int_osc) begin
    
    pwm_counter <= pwm_counter + 1;
    uart_baud_counter <= uart_baud_counter - 1;

    // 48,000,000 / 300 baud = 160000
    if(uart_baud_counter == 0)
    begin

      // reset counter
      uart_baud_counter <= 160000;
      
      // 1 start bit + 8 data bits + 1 stop bit = 10 bits total
      if(tx_state == 0 || tx_state == 9) begin
        
        // start or end bit
        serial_txd <= (tx_state == 9);
        
        if(tx_state == 9) begin

          tx_state <= 0;

          // set output data:
          // print ascii chars in order
          if(uart_data == 10)
            uart_data <= 32;
          else if(uart_data == 126)
            uart_data <= 10;
          else
            uart_data <= uart_data + 1;
        
        // increment tx state
        end else begin
          tx_state <= tx_state + 1;
        end

      // transmit data bits
      end else if(tx_state > 0 && tx_state < 9) begin

        serial_txd <= uart_data[tx_state-1];
        tx_state <= tx_state + 1;

      end

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
