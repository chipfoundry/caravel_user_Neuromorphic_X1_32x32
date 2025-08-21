//--------------------------------------------------------------------------------------------------
//  _  __  _       ___    _  __    ___  __   __  ___   _____   ___   __  __   ___
// | |/ / | |     / _ \  | |/ /   / __| \ \ / / / __| |_   _| | __| |  \/  | / __|
// | ' <  | |__  | (_) | | ' <    \__ \  \ V /  \__ \   | |   | _|  | |\/| | \__ \
// |_|\_\ |____|  \___/  |_|\_\   |___/   |_|   |___/   |_|   |___| |_|  |_| |___/
//
// This program is Confidential and Proprietary product of Klok Systems. Any unauthorized use,
// reproduction or transfer of this program is strictly prohibited unless written authorization
// from Klok Systems. (c) 2019 Klok Systems India Private Limited - All Rights Reserved
//--------------------------------------------------------------------------------------------------
// FILE NAME     : NEUROMORPHIC_X1_macro.v
// AUTHOR        :
//--------------------------------------------------------------------------------------------------
// Description:
//   Behavioral-only simulation model of a 32x32 ReRAM memory array using queues.
//   Not synthesizable. Supports programmable delays for read/write operations.
//--------------------------------------------------------------------------------------------------

`timescale 1ns / 1ps

module NEUROMORPHIC_X1_macro (
    CLKin,
    RSTin,
    EN,
    R_WB,
    DI,
    AD,
    SEL,
    DO,
    func_ack,
    TM,
    SM,
    ScanInCC,
    ScanInDL,
    ScanInDR,
    ScanOutCC,
    VDDC,
    VDDA,
    VSS,
    Iref,
    Vbias,
    Vcomp,
    Bias_comp1,
    Bias_comp2,
    Ramp,
    Vcc_L,
    Vcc_Body,
    VCC_reset,
    VCC_set,
    VCC_wl_reset,
    VCC_wl_set,
    VCC_wl_read,
    VCC_read
);
    input  wire        CLKin;
    input  wire        RSTin;
    input  wire        EN;
    input  wire        R_WB;
    input  wire [31:0] DI;
    input  wire [31:0] AD;
    input  wire [3:0]  SEL;
    output reg  [31:0] DO;
    output reg         func_ack;

    // Scan/test
    input  wire TM;
    input  wire SM;
    input  wire ScanInCC;
    input  wire ScanInDL;
    input  wire ScanInDR;
    output wire ScanOutCC;

    // Analog / supplies (pass-through for sim context)
    input  wire VDDC;
    input  wire VDDA;
    input  wire VSS;
    input  wire Iref;
    input  wire Vbias;
    input  wire Vcomp;
    input  wire Bias_comp1;
    input  wire Bias_comp2;
    input  wire Ramp;
    input  wire Vcc_L;
    input  wire Vcc_Body;
    input  wire VCC_reset;
    input  wire VCC_set;
    input  wire VCC_wl_reset;
    input  wire VCC_wl_set;
    input  wire VCC_wl_read;
    input  wire VCC_read;

    // Always drive scan-out to a known value (unused)
    assign ScanOutCC = 1'b0;

`ifndef SYNTHESIS
    // =========================================================================
    // SIMULATION-ONLY IMPLEMENTATION (timed behavior, $display, event waits)
    // =========================================================================

    // Configurable simulation delays
    parameter RD_Dly       = 44;  // cycles from read request to data valid
    parameter WR_Dly       = 10;  // cycles per pending write after EN deasserts
    parameter RD_Data_hold = 1;   // cycles to hold DO asserted after read

    // Internal ReRAM array and simple queues
    reg [7:0]  array_mem [0:31][0:31];   // 32x32 8-bit cells
    reg [31:0] ip_queue_data   [0:31];   // write queue
    reg [31:0] array_mem_queue [0:31];   // readback queue

    reg [31:0] ip_reg, op_reg;

    // queue pointers and sizes
    reg [5:0] ip_queue_head,   ip_queue_tail,   ip_queue_size;
    reg [5:0] array_queue_head,array_queue_tail,array_queue_size;

    integer count;     // outstanding transactions in model
    integer wr_count;  // pending writes to age out after EN low
    integer i, j, k;

    // --- queue helpers ------------------------------------------------------
    task push_ip_queue(input [31:0] data);
      begin
        if (ip_queue_size < 32) begin
          ip_queue_data[ip_queue_head] = data;
          ip_queue_head = (ip_queue_head + 1) % 32;
          ip_queue_size = ip_queue_size + 1;
        end
      end
    endtask

    task pop_ip_queue(output reg [31:0] data);
      begin
        if (ip_queue_size > 0) begin
          data = ip_queue_data[ip_queue_tail];
          ip_queue_tail = (ip_queue_tail + 1) % 32;
          ip_queue_size = ip_queue_size - 1;
        end
      end
    endtask

    task push_array_queue(input [31:0] data);
      begin
        if (array_queue_size < 32) begin
          array_mem_queue[array_queue_head] = data;
          array_queue_head = (array_queue_head + 1) % 32;
          array_queue_size = array_queue_size + 1;
        end
      end
    endtask

    task pop_array_queue(output reg [31:0] data);
      begin
        if (array_queue_size > 0) begin
          data = array_mem_queue[array_queue_tail];
          array_queue_tail = (array_queue_tail + 1) % 32;
          array_queue_size = array_queue_size - 1;
        end
      end
    endtask

    // --- main timed model ---------------------------------------------------
    always @(posedge CLKin or negedge RSTin) begin
      if (!RSTin) begin
        func_ack <= 1'b0;
        DO       <= 32'd0;

        ip_queue_head    <= 6'd0;
        ip_queue_tail    <= 6'd0;
        ip_queue_size    <= 6'd0;
        array_queue_head <= 6'd0;
        array_queue_tail <= 6'd0;
        array_queue_size <= 6'd0;

        count    <= 0;
        wr_count <= 0;

      end else begin
        func_ack <= 1'b0;

        // WRITE request
        if (EN && !R_WB && (count < 32)) begin
          push_ip_queue(DI);
          count    = count + 1;
          wr_count = wr_count + 1;
          func_ack <= 1'b1;

          if (ip_queue_size > 0) begin
            pop_ip_queue(ip_reg);
            push_array_queue(ip_reg);
            array_mem[ip_reg[29:25]][ip_reg[24:20]] = ip_reg[7:0];
          end

          $display("[WRITE] @%0t: Pushed %h | Count=%0d", $realtime, DI, count);
          if (count == 32) $display("[INFO] FIFO Full, Cannot Perform Write Operation");

        // READ request
        end else if (EN && R_WB && (array_queue_size > 0)) begin
          // read latency
          for (i = 0; i < RD_Dly; i = i + 1) begin
            @(posedge CLKin);
            if (!EN) begin
              $display("[READ] Aborted early @%0t", $realtime);
              i = RD_Dly; // break
            end
          end

          if (EN) begin
            pop_array_queue(op_reg);
            DO       <= {24'd0, array_mem[op_reg[29:25]][op_reg[24:20]]};
            func_ack <= 1'b1;
            count    = count - 1;

            $display("[READ]  @%0t: DO=%h | Count=%0d", $realtime, DO, count);

            // hold time
            for (j = 0; j < RD_Data_hold; j = j + 1) @(posedge CLKin);
            func_ack <= 1'b0;

            if (count == 0) $display("[INFO] FIFO Empty, Cannot Perform Read Operation");
          end

        // post-write aging when EN low
        end else if (!EN && (wr_count > 0)) begin
          for (k = wr_count; k > 0; k = k - 1) begin
            repeat (WR_Dly) @(posedge CLKin);
          end
          wr_count = 0;
        end
      end
    end

`else  // SYNTHESIS
    // =========================================================================
    // SYNTHESIS-STUB (no timing, no queues) â keeps interface, safe defaults
    // =========================================================================
    always @(*) begin
      DO       = 32'd0;
      func_ack = 1'b0;
    end
`endif

endmodule
