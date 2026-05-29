// 6551 UART Status Bits
// ---------------------
// 0 | Parity error
// 1 | Framing error
// 2 | Overrun error
// 3 | RX Data Register Full  1=CTS
// 4 | TX Data Register Empty 1=RTS
// 5 | Data carrier detect
// 6 | Data set ready
// 7 | Interrupt request

module uart #(parameter BAUDRATE = 115200) (

  // ctl
  input wire clk,
  input wire rst,
  
  // ctl
  input wire cs,
  input wire rw,
  output wire rx_irq,
  output reg [7:0] status,

  // uart -> FTDI
  output reg serial_txd,
  input wire serial_rxd, 

  // uart -> cpu
  input wire [7:0] tx_data,
  output reg [7:0] rx_data

);

  localparam CLOCKRATE = 12000000;
  localparam BAUDCYCLES = CLOCKRATE / BAUDRATE;

  reg [31:0] uart_baud_counter;
  
  // tx
  reg [3:0] tx_state = 0;
  reg [7:0] uart_tx_data = 0;

  // rx
  reg [3:0] rx_state = 0;
  reg [7:0] uart_rx_data = 0;
  
  reg [31:0] t = 0;

  reg cs_latched = 0;
  reg rw_latched = 0;

  assign rx_irq = status[3];
  
  // baudrate counter
  always @(posedge clk) begin

    uart_baud_counter <= uart_baud_counter - 1;
    t <= t + 1;

    // on reset
    if(rst) begin

      serial_txd <= 1;
      cs_latched <= 0;
      status <= 8'b00010000;
      tx_state <= 0;
      rx_state <= 0;
      uart_baud_counter <= BAUDCYCLES;

    end else begin
      
      // latch cs
      if (cs) begin
          cs_latched <= 1;
          rw_latched <= rw;
          
          if(status[4] && cs && !rw) begin
            $display("t=%d Load data reg data=%b", t, tx_data);
            uart_tx_data <= tx_data;
            status[4] <= 0; // set busy status
          end
      end
            
      // on baud tick
      if(uart_baud_counter == 0) begin

        // -------- //
        // Begin TX //
        // -------- //

        //$display(" rst=%b | cs=%b rw=%b | tx_state=%d rx_state=%d | cs_latched=%b rw_latched=%b status[4]=%b | uart_tx_data=%b serial_txd=%b | T=%d |",
        //      rst, cs, rw, tx_state, rx_state, cs_latched, rw_latched, status[4], uart_tx_data, serial_txd, t);

        // reset baud counter
        uart_baud_counter <= BAUDCYCLES;
        
        if(!rw_latched && cs_latched) begin

          // handle tx
          case(tx_state)

            // start bit
            0: begin
              serial_txd <= 0;
              tx_state <= 1;
            end

            // data bits
            1,2,3,4,5,6,7,8: begin
              serial_txd <= uart_tx_data[tx_state-1];
              tx_state <= tx_state + 1;
            end

            // stop bit
            9: begin
                serial_txd <= 1;
                tx_state <= 10;
            end

            // idle cycle
            10: begin
                tx_state <= 0;
                uart_tx_data <= 0;
                status[4] <= 1; // clear busy flag
                cs_latched <= 0;
                rw_latched <= 0;
            end

          endcase
        end

        // -------- // 
        // Begin RX //
        // -------- //

        // handle rx
        case(rx_state)

          // idle
          0: begin
            if(serial_rxd == 0) begin
              rx_state <= 1;
            end
          end

          // data bits
          1,2,3,4,5,6,7,8: begin
            uart_rx_data[rx_state-1] <= serial_rxd;
            rx_state <= rx_state + 1;
          end

          // stop bit
          9: begin
              rx_state <= 10;
          end

          // idle cycle
          10: begin
              rx_state <= 0;
              status[3] <= 1; // data avail
          end

        endcase
      
      end

    end

  end

endmodule