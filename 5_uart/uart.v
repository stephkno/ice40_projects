// 6551 UART Status Bits
// ---------------------
// 0 | Parity error
// 1 | Framing error
// 2 | Overrun error
// 3 | RX Data Register Full  1=full
// 4 | TX Data Register Empty 1=empty
// 5 | Data carrier detect
// 6 | Data set ready
// 7 | Interrupt request

module uart #(parameter BAUDRATE = 9600) (
  input wire clk,
  input wire rst,

  output reg serial_txd,
  input wire serial_rxd, 

  // uart -> cpu
  input wire [7:0] tx_data,
  output reg [7:0] rx_data,
  output reg [7:0] status,

  input wire cs,
  input wire rw,
  output wire rx_irq
);


  localparam CLOCKRATE = 12000000;
  localparam BAUDCYCLES = CLOCKRATE / BAUDRATE;

  reg [31:0] uart_baud_counter;
  
  // tx
  reg [3:0] tx_state = 0;
  reg [7:0] uart_tx_data = 32;

  // rx
  reg [3:0] rx_state = 0;
  reg [7:0] uart_rx_data = 0;
  
  reg cs_latched = 0;
  reg rw_latched = 0;

  assign rx_irq = status[3];

  // baudrate counter
  always @(posedge clk) begin

    uart_baud_counter <= uart_baud_counter - 1;
    
    // on reset
    if(rst) begin

      serial_txd <= 1;
      cs_latched <= 0;
      status <= 8'b00000000;
      tx_state <= 0;
      rx_state <= 0;
      uart_baud_counter <= BAUDCYCLES;
    
    // on baud tick
    end else if(uart_baud_counter == 0) begin

      // -------- //
      // Begin TX //
      // -------- //
      // latch cs
      if (cs) begin
          cs_latched <= 1;
          rw_latched <= rw;
      end else begin
          cs_latched <= 0;
          rw_latched <= 0;
      end
      
      // reset baud counter
      uart_baud_counter <= BAUDCYCLES;
      
      // handle tx
      case(tx_state)

        // start bit
        0: begin
          if(cs_latched) begin
            uart_tx_data <= tx_data;
            status[4] <= 1; // set busy status
            serial_txd <= 0;
            tx_state <= 1;
          end
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
            status[4] <= 0; // free busy status
        end

      endcase
      
      // -------- // 
      // Begin RX //
      // -------- //

      // detect start bit
      if(rx_state == 0 && serial_rxd == 1 && cs_latched) begin

        status[3] <= 0; // set rx ready bit
        rx_state <= 1;
      
      // receive byte data
      end else if(rx_state > 1 && rx_state < 9) begin

        rx_data[rx_state - 1] <= serial_rxd;
        rx_state <= rx_state + 1;

      // stop bit
      end else begin

        // status[3] <= 1; // set rx ready bit
        rx_state <= 0;

      end 

    end

  end

endmodule
