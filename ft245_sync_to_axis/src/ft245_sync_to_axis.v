/*******************************************************************************
 * @FILE    ft245_sync_to_axis.v
 * @AUTHOR  JAY CONVERTINO
 * @DATE    2022.08.09
 * @BRIEF   FT245 to AXIS
 * @DETAILS Converter FT245 sync FIFO interface to AXIS.
 *
 * @LICENSE MIT
 *  Copyright 2022 Jay Convertino
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to 
 *  deal in the Software without restriction, including without limitation the
 *  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
 *  sell copies of the Software, and to permit persons to whom the Software is 
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in 
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 *  IN THE SOFTWARE.
 * 
 ******************************************************************************/

`timescale 1ns/100ps

// ft245 to axis
module ft245_sync_to_axis #(
    parameter bus_width = 1
  ) 
  (
    // system
    input                       rstn,
    // ft245 interface
    input                       ft245_dclk,
    inout   [bus_width-1:0]     ft245_ben,
    inout   [(bus_width*8)-1:0] ft245_data,
    output                      ft245_rdn,
    output                      ft245_wrn,
    output                      ft245_siwun,
    input                       ft245_txen,
    input                       ft245_rxfn,
    output                      ft245_oen,
    output                      ft245_rstn,
    output                      ft245_wakeupn,
    // slave
    input   [(bus_width*8)-1:0] s_axis_tdata,
    input   [bus_width-1:0]     s_axis_tkeep,
    input                       s_axis_tvalid,
    output                      s_axis_tready,
    // master
    output  [(bus_width*8)-1:0] m_axis_tdata,
    output  [bus_width-1:0]     m_axis_tkeep,
    output                      m_axis_tvalid,
    input                       m_axis_tready
  );
  
  reg r_oen;
  reg rr_oen;
  reg rrr_oen;
  
  assign ft245_data = (rr_oen & r_oen ? s_axis_tdata : 'bz);
  assign ft245_ben  = (rr_oen & r_oen ? s_axis_tkeep : 'bz);
  assign ft245_wrn  = ft245_txen | ~ft245_rxfn | ~s_axis_tvalid | ~rr_oen;
  assign ft245_oen  = rr_oen;
  assign ft245_rdn  = ~m_axis_tready | rrr_oen | rr_oen & r_oen;
  assign ft245_wakeupn = 1'b0;
  assign ft245_siwun   = 1'b0;
  assign ft245_rstn = rstn;
  
  assign s_axis_tready = (~ft245_txen & ft245_rxfn) & rr_oen;
  
  assign m_axis_tdata  = (rr_oen | r_oen ? 'b0 : ft245_data);
  assign m_axis_tkeep  = (rr_oen | r_oen ? 'b0 : ft245_ben);
  assign m_axis_tvalid = ~(rrr_oen | ft245_rxfn);
  
  always @(posedge ft245_dclk) begin
    if(rstn == 1'b0) begin
      // regs
      r_oen   <= 1;
      rr_oen  <= 1;
      rrr_oen <= 1;
    end else begin
      // insert a delay so write can finish
      r_oen   <= ft245_rxfn;
      rr_oen  <= r_oen;
      rrr_oen <= rr_oen;
    end
  end
endmodule
