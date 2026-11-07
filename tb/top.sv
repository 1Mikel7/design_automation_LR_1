`timescale 1ns/1ps

module top;
  logic        pclk;
  logic        presetn;
  wire         psel, penable, pwrite;
  wire [31:0]  paddr, pwdata, prdata;
  wire         pready, pslverr;

  initial pclk = 1'b0;
  always #10 pclk = ~pclk;

  initial begin
    presetn = 1'b0;
    repeat (5) @(posedge pclk);
    presetn = 1'b1;
  end

  apb_master u_master (
    .pclk(pclk), .presetn(presetn), .psel(psel), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .prdata(prdata), .pready(pready), .pslverr(pslverr)
  );

  apb_slave u_slave (
    .pclk(pclk), .presetn(presetn), .paddr(paddr), .pwdata(pwdata),
    .psel(psel), .penable(penable), .pwrite(pwrite),
    .pready(pready), .pslverr(pslverr), .prdata(prdata)
  );

  initial begin
    $timeformat(-9, 0, " ns", 7);
    $dumpfile("build/apb.vcd");
    $dumpvars(0, top);
    if ($test$plusargs("MON"))
      $monitor("APB IF: PSEL=%b PENABLE=%b PREADY=%b PADDR=0x%h PWDATA=0x%h PRDATA=0x%h",
               psel, penable, pready, paddr, pwdata, prdata);
  end

  initial begin
    #100000;
    $display("[TOP ] TIMEOUT");
    $finish;
  end
endmodule