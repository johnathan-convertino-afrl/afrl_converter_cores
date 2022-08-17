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
    // umft interface
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
  reg r_rdn;
  reg r_wrn;
  
  reg r_m_axis_tvalid;
  
  assign ft245_data = (r_oen ? s_axis_tdata : 'bz);
  assign ft245_ben  = (r_oen ? s_axis_tkeep : 'bz);
  assign ft245_wrn  = r_wrn;
  assign ft245_oen  = r_oen;
  assign ft245_rdn  = r_rdn;
  assign ft245_wakeupn = 1'b0;
  assign ft245_siwun   = 1'b0;
  assign ft245_rstn = rstn;
  
  assign s_axis_tready = ~r_wrn;
  
  assign m_axis_tdata = (r_oen ? 'b0 : ft245_data);
  assign m_axis_tkeep = (r_oen ? 'b0 : ft245_ben);
  assign m_axis_tvalid = r_m_axis_tvalid;
  
  always @(posedge ft245_dclk) begin
    if(rstn == 1'b0) begin
      // m_axis
      r_m_axis_tvalid <= 0;
      // regs
      r_oen <= 1;
      r_rdn <= 1;
      r_wrn <= 1;
    end else begin
      r_oen <= ft245_rxfn;
      r_rdn <= r_oen | ((~m_axis_tready ^ r_rdn) & ~m_axis_tready);
      r_wrn <= (~ft245_txen & ft245_rxfn) & ~s_axis_tvalid;
      
      r_m_axis_tvalid <= ~(r_oen & ft245_rxfn);
    end
  end
endmodule
