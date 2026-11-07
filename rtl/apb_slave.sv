`timescale 1ns/1ps

module apb_slave
(
  input  logic        pclk,
  input  logic        presetn,
  input  logic [31:0] paddr,
  input  logic [31:0] pwdata,
  input  logic        psel,
  input  logic        penable,
  input  logic        pwrite,
  output logic        pready,
  output logic        pslverr,
  output logic [31:0] prdata
);

  logic [31:0] reg_number;
  logic [31:0] reg_date;
  logic [31:0] reg_surname;
  logic [31:0] reg_name;
  logic [31:0] register_with_some_name;

  enum logic [1:0] {
    APB_SETUP,
    APB_W_ENABLE,
    APB_R_ENABLE
  } apb_st;

  always @(posedge pclk)
    if (!presetn) begin
      prdata                  <= '0;
      pslverr                 <= 1'b0;
      pready                  <= 1'b0;
      reg_number              <= '0;
      reg_date                <= '0;
      reg_surname             <= '0;
      reg_name                <= '0;
      register_with_some_name <= 32'hAAAA_AAAA;
      apb_st                  <= APB_SETUP;
    end
    else begin
      case (apb_st)
        APB_SETUP: begin : apb_setup_st
          prdata  <= '0;
          pready  <= 1'b0;
          pslverr <= 1'b0;
          if (psel && !penable) begin
            if (pwrite == 1'b1) apb_st <= APB_W_ENABLE;
            else                apb_st <= APB_R_ENABLE;
          end
        end : apb_setup_st
        APB_W_ENABLE: begin : apb_w_en_st
          if (psel && penable && pwrite) begin
            pready <= 1'b1;
            case (paddr[7:0])
              8'h00: begin
                reg_number <= pwdata;
                if (pwdata[0] == 1'b0) register_with_some_name <= 32'hAAAA_AAAA;
                else                   register_with_some_name <= 32'h5555_5555;
                $display("[SLAVE ] %t WRITE reg_number (0x00) = 0x%08h, bit0=%b",
                         $time, pwdata, pwdata[0]);
              end
              8'h04: begin
                reg_date <= pwdata;
                $display("[SLAVE ] %t WRITE reg_date (0x04) = 0x%08h", $time, pwdata);
              end
              8'h08: begin
                reg_surname <= pwdata;
                $display("[SLAVE ] %t WRITE reg_surname (0x08) = 0x%08h", $time, pwdata);
              end
              8'h0C: begin
                reg_name <= pwdata;
                $display("[SLAVE ] %t WRITE reg_name (0x0C) = 0x%08h", $time, pwdata);
              end
              default: begin
                pslverr <= 1'b1;
                $display("[SLAVE ] %t WRITE to bad addr=0x%02h -> PSLVERR", $time, paddr[7:0]);
              end
            endcase
            apb_st <= APB_SETUP;
          end
        end : apb_w_en_st
        APB_R_ENABLE: begin : apb_r_en_st
          if (psel && penable && !pwrite) begin
            pready <= 1'b1;
            $display("[SLAVE ] %t READ addr=0x%02h", $time, paddr[7:0]);
            case (paddr[7:0])
              8'h00:  prdata <= reg_number;
              8'h04:  prdata <= reg_date;
              8'h08:  prdata <= reg_surname;
              8'h0C:  prdata <= reg_name;
              8'h10:  prdata <= register_with_some_name;
              default: begin
                pslverr <= 1'b1;
                $display("[SLAVE ] %t READ from bad addr=0x%02h -> PSLVERR", $time, paddr[7:0]);
              end
            endcase
            apb_st <= APB_SETUP;
          end
        end : apb_r_en_st
        default: begin
          pslverr <= 1'b1;
          apb_st  <= APB_SETUP;
        end
      endcase
    end
endmodule