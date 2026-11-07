`timescale 1ns/1ps

module apb_master
(
  input  logic        pclk,
  input  logic        presetn,
  output logic        psel,
  output logic        penable,
  output logic        pwrite,
  output logic [31:0] paddr,
  output logic [31:0] pwdata,
  input  logic [31:0] prdata,
  input  logic        pready,
  input  logic        pslverr
);

  parameter [31:0] P_DEVICE_OFFSET = 32'h7000_0000;

  localparam [31:0] MY_NUMBER  = 32'd3;
  localparam [31:0] MY_DATE    = 32'h07112026;
  localparam [31:0] MY_SURNAME = "Vosk";
  localparam [31:0] MY_NAME    = "Mikh";

  logic [31:0] address;
  logic [31:0] data_from_device;
  logic        last_slverr;
  int          errors = 0;

  task apb_write(input [31:0] addr, input [31:0] data);
    wait ((penable == 0) && (pready == 0));
    @(posedge pclk);
    psel   <= 1'b1;
    paddr  <= addr;
    pwdata <= data;
    pwrite <= 1'b1;
    @(posedge pclk);
    penable <= 1'b1;
    @(posedge pclk);
    wait (pready == 1'b1);
    last_slverr = pslverr;
    if (pslverr) $display("[MASTER] PSLVERR=1 on write to 0x%08h", addr);
    @(posedge pclk);
    psel    <= 1'b0;
    penable <= 1'b0;
    pwrite  <= 1'b0;
    @(posedge pclk);
    $display("[MASTER] %t WRITE addr=0x%08h data=0x%08h", $time, addr, data);
  endtask

  task apb_read(input [31:0] addr, output logic [31:0] data);
    wait ((penable == 0) && (pready == 0));
    @(posedge pclk);
    psel   <= 1'b1;
    pwrite <= 1'b0;
    paddr  <= addr;
    @(posedge pclk);
    penable <= 1'b1;
    @(posedge pclk);
    wait (pready == 1'b1);
    last_slverr = pslverr;
    if (pslverr) $display("[MASTER] PSLVERR=1 on read from 0x%08h", addr);
    @(posedge pclk);
    data = prdata;
    psel    <= 1'b0;
    penable <= 1'b0;
    @(posedge pclk);
    $display("[MASTER] %t READ addr=0x%08h data=0x%08h", $time, addr, data);
  endtask

  task check(input [31:0] got, input [31:0] expected, input [8*24-1:0] what);
    if (got === expected)
      $display("[CHECK ] PASS %0s: 0x%08h", what, got);
    else begin
      $display("[CHECK ] FAIL %0s: got 0x%08h, expected 0x%08h", what, got, expected);
      errors++;
    end
  endtask

  initial begin
    psel = 0; penable = 0; pwrite = 0; paddr = 0; pwdata = 0;
    wait (presetn === 1'b1);
    repeat (5) @(posedge pclk);

    address = P_DEVICE_OFFSET + 32'h00;
    apb_write(address, 32'h1234_5678);
    apb_read (P_DEVICE_OFFSET + 32'h10, data_from_device);
    check(data_from_device, 32'hAAAA_AAAA, "bit0=0 -> AAAA_AAAA");

    apb_write(address, 32'h0000_0001);
    apb_read (P_DEVICE_OFFSET + 32'h10, data_from_device);
    check(data_from_device, 32'h5555_5555, "bit0=1 -> 5555_5555");

    apb_write(P_DEVICE_OFFSET + 32'h00, MY_NUMBER);
    apb_write(P_DEVICE_OFFSET + 32'h04, MY_DATE);
    apb_write(P_DEVICE_OFFSET + 32'h08, MY_SURNAME);
    apb_write(P_DEVICE_OFFSET + 32'h0C, MY_NAME);

    apb_read(P_DEVICE_OFFSET + 32'h00, data_from_device);
    check(data_from_device, MY_NUMBER,  "number @0x00");
    apb_read(P_DEVICE_OFFSET + 32'h04, data_from_device);
    check(data_from_device, MY_DATE,    "date @0x04");
    apb_read(P_DEVICE_OFFSET + 32'h08, data_from_device);
    check(data_from_device, MY_SURNAME, "surname @0x08");
    apb_read(P_DEVICE_OFFSET + 32'h0C, data_from_device);
    check(data_from_device, MY_NAME,    "name @0x0C");

    apb_write(P_DEVICE_OFFSET + 32'h20, 32'h0);
    check({31'b0, last_slverr}, 32'h1, "bad addr -> PSLVERR");

    repeat (10) @(posedge pclk);
    if (errors == 0) $display("[RESULT] ALL TESTS PASSED");
    else             $display("[RESULT] FAILED: %0d error(s)", errors);
    $finish;
  end
endmodule