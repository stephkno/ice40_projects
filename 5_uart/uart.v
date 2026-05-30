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

  input wire cs,
  input wire rw,
  output wire rx_irq,
  output reg [7:0] status,  

  // uart -> FTDI
  output reg serial_txd,
  input wire serial_rxd,  

  // uart <-> cpu
  inout wire [7:0] data,

);  

  localparam CLOCKRATE = 12000000;
  localparam BAUDCYCLES = CLOCKRATE / BAUDRATE;  

  reg [31:0] uart_baud_counter;  

  reg [3:0] tx_state = 0;
  reg [7:0] tx_data = 0;  
  reg [3:0] rx_state = 0;
  reg [7:0] rx_data = 0;  

  reg cs_latched = 0;
  reg rw_latched = 0;
  reg prev_serial_rxd = 0;  

  wire uart_oe = cs && !rw;
  assign data = uart_oe ? rx_data : 8'bz;
  assign rx_irq = status[3];  

  // baudrate counter
  always @(posedge clk) begin  
    uart_baud_counter <= uart_baud_counter - 1;  

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
            
          // when RTS and cs and read mode  
          if(status[4] && cs && !rw) begin  

            tx_data <= data;
            status[4] <= 0; // set busy status  

          end else if(status[3] && cs && rw) begin  

            status[3] <= 0;  
              
          end  

      end  
        
      // on baud tick  
      if(uart_baud_counter == 0) begin  

        // -------- //  
        // Begin TX //  
        // -------- //  

        // reset baud counter  
        uart_baud_counter <= BAUDCYCLES;  
        prev_serial_rxd <= serial_rxd;
        
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
              serial_txd <= tx_data[tx_state-1];  
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
            
            if(serial_rxd == 0 && prev_serial_rxd == 1) begin  
              rx_state <= 1;  
            end  
          end  

          // data bits  
          1,2,3,4,5,6,7,8: begin  
            rx_data[rx_state-1] <= serial_rxd;
            rx_state <= rx_state + 1;  
          end  

          // stop bit  
          9: begin  
            rx_state <= rx_state + 1;  
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