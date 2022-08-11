// ***************************************************************************
// ***************************************************************************
// @FILE    umft600_fifo_converter.v
// @AUTHOR  JAY CONVERTINO
// @DATE    2022.08.09
// @BRIEF   UMFT600 dev board fifo converter interface
// @DETAILS Converter UMFT600 FIFO interface to analog devices FIFO interface
//          for DMA interfacing.
//
// @LICENSE MIT
//  Copyright 2022 Jay Convertino
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to 
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
//  sell copies of the Software, and to permit persons to whom the Software is 
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in 
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

//umft600
module umft600_fifo_converter #(
    parameter data_bits   = 16
  )
  (
    //system
    input                     rstn,
    // umft interface
    input                     umft_dclk,
    inout  [data_bits/8-1:0]  umft_ben,
    inout  [data_bits-1:0]    umft_data,
    output                    umft_rdn,
    output                    umft_wrn,
    output                    umft_siwun,
    input                     umft_txen,
    input                     umft_rxfn,
    output                    umft_oen,
    output                    umft_rstn,
    output                    umft_wakeupn,
    // fifo interface
    input  [data_bits-1:0]    fifo_datai,
    output [data_bits-1:0]    fifo_datao,
    input                     fifo_full,
    input                     fifo_empty,
    output                    fifo_wr,
    output                    fifo_rd
  );
  
  // wait for diff        
  localparam read_state    = 1'b1;
  // data capture
  localparam write_state   = 1'b0;
  
  //umft 600
  reg           r_umft_oen;
  reg [1:0]     r_umft_beno;
  reg [1:0]     rr_umft_beno;
  reg           r_umft_rdn;
  reg           rr_umft_rdn;
  reg           r_umft_wrn;
  reg           rr_umft_wrn;
  reg           r_umft_fifo_wr;
  reg           rr_umft_fifo_wr;
  reg           r_umft_fifo_rd;
  
  reg           state;
  
  //tristate driver
  assign umft_data    = (r_umft_oen == 1'b1 ? fifo_datai : 16'bzzzzzzzzzzzzzzzz);
  assign umft_ben     = (r_umft_oen == 1'b1 ? rr_umft_beno : 2'bzz);
  assign fifo_datao   = umft_data;
  //assign fifo_beni  = umft_ben;
  
  //to usb
  assign umft_rstn    = rstn;
  assign umft_oen     = r_umft_oen  | fifo_full;
  assign umft_rdn     = rr_umft_rdn | fifo_full;
  assign umft_wrn     = rr_umft_wrn | r_umft_wrn;
  assign umft_siwun   = 1'b1;
  assign umft_wakeupn = 1'b0;
  
  //to fifo
  assign fifo_wr = rr_umft_fifo_wr & ~umft_rxfn & ~fifo_full;
  assign fifo_rd = r_umft_fifo_rd;
  
  // this is a mess, but it works. Need to cleanup and redo, hopefully its good enough to test with!
  always @(posedge umft_dclk) begin
    if(rstn == 1'b0) begin
      r_umft_oen  <= 1'b1;
      r_umft_rdn  <= 1;
      rr_umft_rdn <= 1;
      r_umft_wrn  <= 1;
      rr_umft_wrn <= 1;
      r_umft_fifo_wr  <= 0;
      rr_umft_fifo_wr <= 0;
      r_umft_fifo_rd  <= 0;
      
      r_umft_beno  <= 2'b00;
      rr_umft_beno <= 2'b00;
      
      state <= read_state;
    end else begin
              
      case (state)
      //read from USB fifo to FPGA fifo
      read_state: begin
        state <= write_state;
        
        r_umft_oen <= 1'b1;
        r_umft_rdn <= 1'b1;
        r_umft_wrn <= 1'b1;
        r_umft_beno  <= 2'b00;
        r_umft_fifo_rd <= 1'b0;
        r_umft_fifo_wr <= 1'b0;
        
        rr_umft_wrn <= 1'b1;
        rr_umft_rdn <= 1'b1;
        rr_umft_beno <= 2'b00;
        rr_umft_fifo_wr <= 1'b0;
        
        if((umft_rxfn == 1'b0) && (fifo_full == 1'b0)) begin
          state <= read_state;
          
          r_umft_oen <= 1'b0;
          
          r_umft_rdn <= 1'b0;
          
          r_umft_fifo_wr <= 1'b1;
          
          rr_umft_rdn <= r_umft_rdn;
          
          rr_umft_fifo_wr <= r_umft_fifo_wr;
        end
      end
      //write data to USB fifo from FPGA fifo
      write_state: begin
        state <= read_state;
        
        r_umft_oen <= 1'b1;
        r_umft_rdn <= 1'b1;
        r_umft_wrn <= 1'b1;
        r_umft_beno  <= 2'b00;
        r_umft_fifo_rd <= 1'b0;
        r_umft_fifo_wr <= 1'b0;
        
        //rr_umft_wrn <= 1'b1;
        rr_umft_rdn <= 1'b1;
        rr_umft_beno <= 2'b00;
        rr_umft_fifo_wr <= 1'b0;
        
        if((umft_txen == 1'b0) && (fifo_empty == 1'b0)) begin
          state <= write_state;
          
          r_umft_beno <= 2'b11;
          
          rr_umft_wrn <= r_umft_wrn;
          
          r_umft_wrn  <= 1'b0;
          
          rr_umft_beno <= r_umft_beno;
  
          r_umft_fifo_rd <= 1'b1;
        end
      end
      endcase
    end
  end
 
endmodule
