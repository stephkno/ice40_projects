module rgb_blink #(parameter CLOCKRATE = 10000, parameter TICKRATE = 100)
(
  output wire led_red  ,
  output wire led_blue ,
  output wire led_green,
  output wire gpio_23
);

  localparam TICKCYCLES = CLOCKRATE / TICKRATE;

  wire        int_osc;
  reg  [15:0] frequency_counter_i = TICKCYCLES;
  reg [7:0] fade = 0;
  reg fade_dir = 1;
  reg [7:0] pwm_counter = 0;

  SB_LFOSC u_SB_LFOSC (.CLKLFPU(1'b1), .CLKLFEN(1'b1), .CLKLF(int_osc));

  always @(posedge int_osc) begin

    frequency_counter_i <= frequency_counter_i - 1;
    pwm_counter <= pwm_counter + 1;

    if(frequency_counter_i == 0) begin
      frequency_counter_i <= TICKCYCLES;

      if(fade_dir) begin
        fade <= fade + 1;
      end else begin
        fade <= fade - 1;
      end
      
      if(fade == 254 && fade_dir) fade_dir <= 0;
      if(fade == 1 && !fade_dir) fade_dir <= 1;
      
    end
      
  end

  SB_RGBA_DRV RGB_DRIVER (
    .RGBLEDEN(1'b1),
    .RGB0PWM (pwm_counter < fade),
    .RGB1PWM (pwm_counter < fade),
    .RGB2PWM (pwm_counter < fade),
    .CURREN  (1'b1),
    .RGB0    (led_green),
    .RGB1    (led_blue),
    .RGB2    (led_red)
  );

  defparam RGB_DRIVER.RGB0_CURRENT = "0b00000001";
  defparam RGB_DRIVER.RGB1_CURRENT = "0b00000001";
  defparam RGB_DRIVER.RGB2_CURRENT = "0b00000001";

endmodule
