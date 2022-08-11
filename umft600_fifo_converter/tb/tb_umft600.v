////////////////////////////////////////////////////////////////////////////////
// @file    tb_umft.v
// @author  JAY CONVERTINO
// @date    2022.08.11
// @brief   SIMPLE TEST BENCH FOR UMFT
////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns/10 ps

module tb_umft;
  
  //bench rst/clk
  reg         tb_data_clk = 0;
  reg         tb_rst = 0;

  //umft signals
  wire [1:0]  tb_umft_ben;
  wire [15:0] tb_umft_data;
  wire        tb_umft_rdn;
  wire        tb_umft_wrn;
  wire        tb_umft_siwun;
  reg         tb_umft_txen;
  reg         tb_umft_rxfn;
  wire        tb_umft_oen;
  wire        tb_umft_rstn;
  wire        tb_umft_wakeupn;
  
  //fifo signals
  reg  [15:0] tb_fifo_datai;
  wire [15:0] tb_fifo_datao;
  reg         tb_fifo_full;
  reg         tb_fifo_empty;
  wire        tb_fifo_wr;
  wire        tb_fifo_rd;
  
  //1ns
  localparam CLK_PERIOD = 20;
  localparam RST_PERIOD = 500;
  localparam CLK_SPEED_HZ = 1000000000/CLK_PERIOD;

  
  //device under test
  //umft600
  umft600_fifo_converter #(
    .data_bits(16)
  ) dut (
    //system
    .rstn(~tb_rst),
    // umft interface
    .umft_dclk(tb_data_clk),
    .umft_ben(tb_umft_ben),
    .umft_data(tb_umft_data),
    .umft_rdn(tb_umft_rdn),
    .umft_wrn(tb_umft_wrn),
    .umft_siwun(tb_umft_siwun),
    .umft_txen(tb_umft_txen),
    .umft_rxfn(tb_umft_rxfn),
    .umft_oen(tb_umft_oen),
    .umft_rstn(tb_umft_rstn),
    .umft_wakeupn(tb_umft_wakeupn),
    // fifo interface
    .fifo_datai(tb_fifo_datai),
    .fifo_datao(tb_fifo_datao),
    .fifo_full(tb_fifo_full),
    .fifo_empty(tb_fifo_empty),
    .fifo_wr(tb_fifo_wr),
    .fifo_rd(tb_fifo_rd)
  );
    
  //assign
  assign tb_m_tready = ~tb_rst;
  
  //reset
  initial
  begin
    tb_rst <= 1'b1;
    
    #RST_PERIOD;
    
    tb_rst <= 1'b0;
  end
  
  //copy pasta, vcd generation
  initial
  begin
    $dumpfile("tb_umft.vcd");
    $dumpvars(0,tb_umft);
  end
  
  //clock
  always
  begin
    tb_data_clk <= ~tb_data_clk;
    
    #(CLK_PERIOD/2);
  end
  
  //produce fifo data
  always @(posedge tb_data_clk)
  begin
    if (tb_rst == 1'b1) begin
      tb_fifo_datai <= 0;
      tb_fifo_full  <= 1'b0;
      tb_fifo_empty <= 1'b1;
      tb_umft_txen  <= 1'b1;
      tb_umft_rxfn  <= 1'b1;
    end else begin
      tb_fifo_empty <= 1'b0;
      tb_umft_txen  <= 1'b0;
      tb_umft_rxfn  <= 1'b0;
      
      if(tb_fifo_rd == 1'b1) begin
        tb_fifo_datai <= tb_fifo_datai + 1;
      end
    end
  end
  
  //copy pasta, no way to set runtime... this works in vivado as well.
  initial begin
    #1_000_000; // Wait a long time in simulation units (adjust as needed).
    $display("END SIMULATION");
    $finish;
  end
endmodule
