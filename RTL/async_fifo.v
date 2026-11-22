
`timescale 1ns/1ps
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input wire wr_clk, rd_clk, rst_n,
    input wire wr_en,
    input wire [DATA_WIDTH-1:0] wr_data,
    output reg wr_full,
    input wire rd_en,
    output reg [DATA_WIDTH-1:0] rd_data,
    output reg rd_empty,
    output reg rd_valid
);
    localparam DEPTH = (1 << ADDR_WIDTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] wr_ptr_bin, rd_ptr_bin;
    reg [PTR_WIDTH-1:0] wr_ptr_gray, rd_ptr_gray;
    (* async_reg = "true" *) reg [PTR_WIDTH-1:0] rd_gray_sync1, rd_gray_sync2;
    (* async_reg = "true" *) reg [PTR_WIDTH-1:0] wr_gray_sync1, wr_gray_sync2;
    wire wr_fire = wr_en && !wr_full;
    wire rd_fire = rd_en && !rd_empty;
    wire [PTR_WIDTH-1:0] wr_bin_next = wr_ptr_bin + wr_fire;
    wire [PTR_WIDTH-1:0] rd_bin_next = rd_ptr_bin + rd_fire;
    wire [PTR_WIDTH-1:0] wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
    wire [PTR_WIDTH-1:0] rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;
    wire wr_full_next = (wr_gray_next == {~rd_gray_sync2[PTR_WIDTH-1:PTR_WIDTH-2],rd_gray_sync2[PTR_WIDTH-3:0]});
    wire rd_empty_next = (rd_gray_next == wr_gray_sync2);
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
            wr_full <= 0;
        end else begin
            wr_ptr_bin <= wr_bin_next;
            wr_ptr_gray <= wr_gray_next;
            wr_full <= wr_full_next;
        end
    end
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
            rd_empty <= 1;
        end else begin
            rd_ptr_bin <= rd_bin_next;
            rd_ptr_gray <= rd_gray_next;
            rd_empty <= rd_empty_next;
        end
    end
    always @(posedge wr_clk)
        if (rst_n && wr_fire)
            mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data <= 0;
            rd_valid <= 0;
        end else begin
            rd_valid <= rd_fire;
            if (rd_fire)
                rd_data <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
        end
    end
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_gray_sync1 <= 0;
            rd_gray_sync2 <= 0;
        end else begin
            rd_gray_sync1 <= rd_ptr_gray;
            rd_gray_sync2 <= rd_gray_sync1;
        end
    end
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_gray_sync1 <= 0;
            wr_gray_sync2 <= 0;
        end else begin
            wr_gray_sync1 <= wr_ptr_gray;
            wr_gray_sync2 <= wr_gray_sync1;
        end
    end
endmodule
