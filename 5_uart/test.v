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

    reg rst = 1;

    output clk;
    reg clk = 0;

    // test data
    reg [7:0] tx_data = 0;
    wire [7:0] rx_data;
    reg en = 0;
    reg rw = 0;

    // echo char data
    reg [8:0] data = 8'b01100110;

    // wire to read status port
    wire [7:0] status;
    
    // init uart
    uart #(115200) serial_port (
        
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
        .tx_data (tx_data),
        .rx_data (rx_data)

    );

    reg waiting = 0;
    reg prev_status = 0;

    assign red = status[3];

    reg done = 0;

    reg [32:0] t = 0;
    
    initial begin
      
        #1 clk = 1;
        forever #41667 clk = ~clk;

    end

    always @(posedge clk) begin
        
        if(done == 1) begin
        end

        rw <= 0;
        en <= 0;
        t <= t + 1;

        // on reset
        if(rst) begin

            $display("reset");
    
            rst <= 0;
            en <= 0;
            tx_data <= 0;
            
            waiting <= 0;
            done <= 0;
            prev_status <= 0;

        end else begin
            prev_status <= status[4];

            // we are not waiting and rx has data
            if(!waiting && status[3]) begin

                $display("t=%d Wait", t);
                
                // read data
                en <= 1;
                data <= rx_data;
                rw <= 1;
                
            // we are not waiting for tx to finish and uart is ready
            end else if(!done && !waiting && status[4]) begin

                $display("t=%d status[4] = %d", t, serial_port.status[4]);

                // load tx data byte
                tx_data <= data;

                // enable tx
                en <= 1;
                waiting <= 1;

            end else if(waiting && status[4] && !prev_status) begin

                $display("t=%d done", t);
                waiting <= 0;
                en <= 0;
                done <= 1;
            
            end
        end
    end

endmodule
