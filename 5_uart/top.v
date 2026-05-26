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

    reg rst = 1;

    wire clk;
    SB_HFOSC #(.CLKHF_DIV("0b10")) u_SB_HFOSC (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));

    // test data
    reg [7:0] tx_data = 0;
    wire [7:0] rx_data;
    reg en = 0;
    reg rw = 0;

    // echo char data
    reg [8:0] data = 0;

    // wire to read status port
    wire [7:0] status;
    
    // init uart
    uart #(115200) serial_port (
        
        .clk (clk),
        .rst (rst),

        // uart -> serial io
        .serial_txd (serial_txd),
        .serial_rxd (serial_rxd),

        // uart -> cpu
        .tx_data (tx_data),
        .rx_data (rx_data),

        // ctrl
        .status (status),
        .cs (en),
        .rw (rw),
        .rx_irq ()

    );

    reg waiting = 0;
    assign red = status[3];
    
    always @(posedge clk) begin
    
        rw <= 0;
        
        // on reset
        if(rst) begin
    
            rst <= 0;
            en <= 0;
            tx_data <= 0;
            waiting <= 0;

        end else begin
            
            // we are not waiting and rx has data
            if(!waiting && status[3]) begin
                
                // read data
                en <= 1;
                data <= rx_data;
                rw <= 1;
                
            // we are not waiting for tx to finish and uart is ready
            end else if(!waiting && !status[4]) begin

                tx_data <= data;

                en <= 1;
                waiting <= 1;

                if(ptr == 0) ptr <= 58;
                else ptr <= ptr - 1;
    
            end else if(status[4]) begin

                waiting <= 0;
                en <= 0;
            
            end
        end
    end

endmodule
