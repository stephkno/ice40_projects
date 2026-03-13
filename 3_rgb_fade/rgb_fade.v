module rgb_fade (
  // outputs
  output wire led_red,
  output wire led_green,
  output wire led_blue
);

  wire int_osc;
  SB_LFOSC u_SB_LFOSC (.CLKLFPU(1'b1), .CLKLFEN(1'b1), .CLKLF(int_osc));

  // clock divider
  reg [31:0] divider = 195;

  // color values
  reg [7:0] red;
  reg [7:0] green;
  reg [7:0] blue;

  // pwm counter
  reg [7:0] counter;

  // 3 bit color state
  reg [2:0] color;
  
  initial begin
    red <= 0;
    green <= 0;
    blue <= 0;
    color <= 0;
  end

  // 10k hz base clock
  always @(posedge int_osc) begin
  
    // pwm counter
    counter <= counter + 1;

    // clock divider
    divider <= divider - 1;

    // one color per second:
    // 255 cycles per color
    // 10k hz base clock / x = 255 cycles
    // 10k hz = 255 cycles * x
    // x = 10k/255 = 39.215686275 * 5 = 195

    // color fade 
    if(divider == 0) begin

      divider <= 195;

      case(color)

        // first step runs only once!
        0 : begin
          red <= red + 1; 
          if(red == 254) color <= color + 1;
        end

        // begin loop
        1 : begin
          green <= green + 1;
          if(green == 254) color <= color + 1;
        end

        2 : begin
          red <= red - 1;
          if(red == 1) color <= color + 1;
        end

        3 : begin
          blue <= blue + 1;
          if(blue == 254) color <= color + 1;
        end

        4 : begin
          green <= green - 1;
          if(green == 1) color <= color + 1;
        end

        5 : begin 
          red <= red + 1;
          if(red == 254) color <= color + 1;
        end

        6 : begin
          blue <= blue - 1;
          // return to state 1, not 0!
          if(blue == 1) color <= 1;
        end

      endcase

    end
    
  end

  SB_RGBA_DRV RGB_DRIVER (
    .RGBLEDEN(1'b1),
    .RGB0PWM (counter < green),
    .RGB1PWM (counter < blue),
    .RGB2PWM (counter < red),
    .CURREN  (1'b1),
    .RGB0 (led_red),
    .RGB1 (led_green),
    .RGB2 (led_blue)
  );

  defparam RGB_DRIVER.RGB0_CURRENT = "0b00000001";
  defparam RGB_DRIVER.RGB1_CURRENT = "0b00000001";
  defparam RGB_DRIVER.RGB2_CURRENT = "0b00000001";

endmodule
