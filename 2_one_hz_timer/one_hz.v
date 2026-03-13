// one_hz.v
//
// timing practice: blink one per second
//
module rgb_blink #(parameter CLOCKRATE = 10000, parameter TICKRATE = 1)
(
  output wire led_red,
  output wire led_blue,
  output wire led_green
);

  localparam TICKCYCLES = CLOCKRATE / TICKRATE;

  wire red, green, blue;
  wire int_osc;
  reg [15:0] counter = TICKCYCLES;

  SB_LFOSC u_SB_LFOSC (.CLKLFPU(1'b1), .CLKLFEN(1'b1), .CLKLF(int_osc)); 
 
  assign red = blink_state;
  
  // 10 khz base clock 
  always @(posedge int_osc) begin

    counter <= counter -1;

    if(counter == 0)
      begin
      
        blink_state <= ~blink_state;
        counter <= TICKCYCLES;
      
      end

  end
  
  
  SB_RGBA_DRV RGB_DRIVER (
    .RGBLEDEN(1'b1),
    .RGB0PWM (green),
    .RGB1PWM (blue),
    .RGB2PWM (red),
    .CURREN  (1'b1),
    .RGB0    (led_green),
    .RGB1    (led_blue),
    .RGB2    (led_red)
  );
  defparam RGB_DRIVER.RGB0_CURRENT = "0b00000001";
  defparam RGB_DRIVER.RGB1_CURRENT = "0b00000001";
  defparam RGB_DRIVER.RGB2_CURRENT = "0b00000001";

endmodule
