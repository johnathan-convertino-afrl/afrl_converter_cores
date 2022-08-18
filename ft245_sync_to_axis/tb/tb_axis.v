////////////////////////////////////////////////////////////////////////////////
// @file    tb_axis.v
// @author  JAY CONVERTINO
// @date    2022.09.12
// @brief   Multi Configuration and Verification Test Bench for AXIS interfaces.
////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns/10 ps

module tb_main;
  
  reg         tb_data_clk = 0;
  reg         tb_rst = 0;
  //   wire        tb_rx;
  wire [7:0]  tb_m_tdata;
  wire [0:0]  tb_m_tkeep;
  wire        tb_m_tvalid;
  reg         tb_m_tready;
  //   wire        tb_tx;
  reg  [7:0]  tb_s_tdata;
  reg         tb_s_tvalid;
  wire        tb_s_tready;
  
  reg tb_txen = 0;
  reg tb_rxfn = 0;
  
  reg [0:0] tb_r_ben = 1;
  reg [7:0] tb_r_data = 'h55;
  
  wire [0:0] tb_ben;
  wire [7:0] tb_data;
  
  wire [0:0] ben;
  wire [7:0] data;
  
  wire tb_rdn;
  wire tb_wrn;
  wire tb_siwun;
  wire tb_oen;
  wire tb_rstn;
  wire tb_wakeupn;
  
  assign tb_ben     = (tb_oen == 1 ? ben  : 'bz);
  assign tb_data    = (tb_oen == 1 ? data : 'bz);
  
  assign ben    = (tb_oen == 0 ? tb_r_ben : 'bz);
  assign data   = (tb_oen == 0 ? tb_r_data : 'bz);
  
  //1ns
  localparam CLK_PERIOD = 20;
  localparam RST_PERIOD = 500;
  
  //device under test
  ft245_sync_to_axis #(
    .bus_width(1)
  ) dut (
    //reset
    .rstn(~tb_rst),
    .ft245_dclk(tb_data_clk),
    .ft245_ben(ben),
    .ft245_data(data),
    .ft245_rdn(tb_rdn),
    .ft245_wrn(tb_wrn),
    .ft245_siwun(tb_siwun),
    .ft245_txen(tb_txen),
    .ft245_rxfn(tb_rxfn),
    .ft245_oen(tb_oen),
    .ft245_rstn(tb_rstn),
    .ft245_wakeupn(tb_wakeupn),
    //master output
    .m_axis_tdata(tb_m_tdata),
    .m_axis_tkeep(tb_m_tkeep),
    .m_axis_tvalid(tb_m_tvalid),
    .m_axis_tready(tb_m_tready),
    //slave input
    .s_axis_tdata(tb_s_tdata),
    .s_axis_tkeep('b1),
    .s_axis_tvalid(tb_s_tvalid),
    .s_axis_tready(tb_s_tready)
  );
  
  //reset
  initial
  begin
    tb_rst <= 1'b1;
    
    #RST_PERIOD;
    
    tb_rst <= 1'b0;
  end
  
  //transmit data
  initial
  begin
    tb_txen <= 1'b1;
    
    #560
    
    tb_txen <= 1'b0;
    
    #5000
  
    tb_txen <= 1'b1;
  end
  
   //recv data
  initial
  begin
    tb_rxfn <= 1'b1;
    
    #2500
    
    tb_rxfn <= 1'b0;
    
    #500
  
    tb_rxfn <= 1'b1;
    
    #600
    
    tb_rxfn <= 1'b0;
    
    #1960
    
    tb_rxfn <= 1'b1;
    
    #40
    
    tb_rxfn <= 1'b0;
    
    #820
    
    tb_rxfn <= 1'b1;
  end
  
  //copy pasta, vcd generation
  initial
  begin
    $dumpfile("tb_sim.vcd");
    $dumpvars(0,tb_main);
  end
  
  //axis clock
  always
  begin
    tb_data_clk <= ~tb_data_clk;
    
    #(CLK_PERIOD/2);
  end
  
  //produce axis slave data for tx
  always @(posedge tb_data_clk)
  begin
    if (tb_rst == 1'b1) begin
      tb_s_tvalid     <= 1'b0;
      tb_s_tdata      <= 8'd65;
    end else begin
      tb_s_tvalid <= $random % 2;
      
      tb_s_tdata <= tb_s_tdata;
      
      if(tb_s_tready == 1'b1)
        tb_s_tdata <= tb_s_tdata + 1;
    end
  end
  
  //consume axis master data for rx
  always @(posedge tb_data_clk)
  begin
    if (tb_rst == 1'b1) begin
      tb_r_ben   <= 1'b0;
      tb_r_data  <= 8'd65;
      tb_m_tready<= 1'b0;
    end else begin
      tb_r_ben <= 1'b1;
      tb_m_tready <= $random % 2;
      
      tb_r_data <= tb_r_data;
      
      if(~tb_rxfn && ~tb_oen && ~tb_rdn)
        tb_r_data <= tb_r_data + 1;
    end
  end
  
  //copy pasta, no way to set runtime... this works in vivado as well.
  initial begin
    #1_000_000; // Wait a long time in simulation units (adjust as needed).
    $display("END SIMULATION");
    $finish;
  end
endmodule
