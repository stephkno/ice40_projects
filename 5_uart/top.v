// very simple uart driver
//
// echo RX byte -> TX
module top (

    output wire led_red,
    output wire led_blue,
    output wire led_green,

    // uart -> serial io
    output wire serial_txd,
    input wire serial_rxd
);

    defparam RGB_DRIVER.RGB0_CURRENT = "0b00000001";
    defparam RGB_DRIVER.RGB1_CURRENT = "0b00000001";
    defparam RGB_DRIVER.RGB2_CURRENT = "0b00000001";

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

    wire red;
    wire blue;
    wire green;

    reg [2:0] color = 0;

    assign red = echo[0];
    assign green = echo[1];
    assign blue = echo[2];
 
    reg rst = 1;

    wire clk;

    SB_HFOSC #(.CLKHF_DIV("0b10")) u_SB_HFOSC (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));

    reg en = 0;
    reg rw = 0;

    // data port
    wire [7:0] data;
    wire uart_oe = cs && rw;
    assign data = uart_oe ? echo : 8'bz;

    // echo char data
    reg [7:0] echo = 0;
    
    wire [7:0] status;

    // init uart
    uart #(115200) serial_port (

        // ctrl
        .clk (clk),
        .rst (rst),
        .cs (en),

        .rw (rw),
        .rx_irq (),
        .status (status),

        // uart -> serial io
        .serial_txd (serial_txd),
        .serial_rxd (serial_rxd),

        // uart -> cpu
        .data (data)

    );

    reg [3:0] uart_driver_state = 0;
    // 0 = WAIT
    // 1 = READ
    // 2 = ECHO

    always @(posedge clk) begin
        
        rw <= 0;
        en <= 0;
        
        // on reset
        if(rst) begin
    
            rst <= 0;
            en <= 0;
            color <= 0;

        end else begin

            // we are not waiting and rx has data
            case (uart_driver_state)

                0: begin

                    if(status[3]) begin
                        
                        uart_driver_state <= 1;
                        rw <= 1;
                        en <= 1;
                        color <= 1;

                    end

                end

                // read data from rx
                1: begin

                    // load rx data byte
                    uart_driver_state <= 2;
                    echo <= data;
                    rw <= 1;
                    color <= 2;

                end

                // write back data
                2: begin

                    if(status[4]) begin

                        en <= 1;
                        color <= 3;

                        uart_driver_state <= 0;

                    end
                
                end
            
            endcase

        end

    end

endmodule
