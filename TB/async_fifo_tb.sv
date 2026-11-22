`timescale 1ns/1ps
module async_fifo_tb;
    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 4;
    localparam DEPTH = (1 << ADDR_WIDTH);
    localparam RANDOM_TXNS = 200;
    localparam MAX_TXNS = 1024;
    reg wr_clk = 0, rd_clk = 0, rst_n = 0;
    reg wr_en = 0, rd_en = 0;
    reg [DATA_WIDTH-1:0] wr_data = 0;
    wire [DATA_WIDTH-1:0] rd_data;
    wire wr_full, rd_empty, rd_valid;
    reg [DATA_WIDTH-1:0] scoreboard [0:MAX_TXNS-1];
    integer write_count = 0, read_count = 0, pass_count = 0, fail_count = 0;
    integer i;
    always #5 wr_clk = ~wr_clk;
    always #7 rd_clk = ~rd_clk;
    async_fifo #(.DATA_WIDTH(DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH)) dut (
        .wr_clk(wr_clk), .rd_clk(rd_clk), .rst_n(rst_n),
        .wr_en(wr_en), .wr_data(wr_data), .wr_full(wr_full),
        .rd_en(rd_en), .rd_data(rd_data), .rd_empty(rd_empty), .rd_valid(rd_valid)
    );
    initial begin
        $dumpfile("async_fifo.vcd");
        $dumpvars(0,async_fifo_tb);
    end
    always @(posedge wr_clk) begin
        if (rst_n && wr_en && !wr_full) begin
            if (write_count >= MAX_TXNS) $fatal(1,"Scoreboard overflow");
            scoreboard[write_count] = wr_data;
            write_count = write_count + 1;
        end
    end
    always @(posedge rd_clk) begin : read_checker
        reg accepted_read;
        accepted_read = rst_n && rd_en && !rd_empty;
        #1;
        if (rst_n) begin
            if (rd_valid !== accepted_read) begin
                $display("[FAIL] rd_valid mismatch at %0t",$time);
                fail_count = fail_count + 1;
            end
            if (accepted_read) begin
                if (read_count >= write_count) begin
                    $display("[FAIL] Unexpected read");
                    fail_count = fail_count + 1;
                end else if (rd_data !== scoreboard[read_count]) begin
                    $display("[FAIL] DATA MISMATCH: index=%0d expected=%02h actual=%02h",read_count,scoreboard[read_count],rd_data);
                    fail_count = fail_count + 1;
                end else begin
                    pass_count = pass_count + 1;
                end
                read_count = read_count + 1;
            end
        end
    end
    task automatic check(input condition, input [255:0] message);
        begin
            if (condition === 1'b1) begin
                $display("[PASS] %0s",message);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s",message);
                fail_count = fail_count + 1;
            end
        end
    endtask
    task automatic write_data(input [DATA_WIDTH-1:0] data);
        begin
            @(negedge wr_clk);
            while (wr_full) @(negedge wr_clk);
            wr_data = data;
            wr_en = 1;
            @(negedge wr_clk);
            wr_en = 0;
        end
    endtask
    task automatic read_data;
        begin
            @(negedge rd_clk);
            while (rd_empty) @(negedge rd_clk);
            rd_en = 1;
            @(negedge rd_clk);
            rd_en = 0;
        end
    endtask
    initial begin
        repeat (5) @(negedge wr_clk);
        check(rd_empty && !wr_full,"Reset flags");
        rst_n = 1;
        repeat (4) @(negedge rd_clk);
        write_data(8'hA5);
        read_data();
        repeat (3) @(negedge rd_clk);
        check(write_count == 1 && read_count == 1 && fail_count == 0,"Single write/read");
        for (i=0;i<DEPTH;i=i+1) write_data(i+8'h10);
        check(wr_full,"FIFO full");
        begin : overflow_test
            integer old_count;
            old_count = write_count;
            @(negedge wr_clk);
            wr_data = 8'hFF;
            wr_en = 1;
            repeat (4) @(negedge wr_clk);
            wr_en = 0;
            check(wr_full && write_count == old_count,"Overflow blocked");
        end
        for (i=0;i<DEPTH;i=i+1) read_data();
        repeat (4) @(negedge rd_clk);
        check(rd_empty && fail_count == 0,"FIFO ordering and empty");
        begin : underflow_test
            integer old_count;
            old_count = read_count;
            @(negedge rd_clk);
            rd_en = 1;
            repeat (4) @(negedge rd_clk);
            rd_en = 0;
            check(rd_empty && read_count == old_count,"Underflow blocked");
        end
        fork
            begin : random_writer
                integer j;
                reg [DATA_WIDTH-1:0] random_data;
                for (j=0;j<RANDOM_TXNS;j=j+1) begin
                    repeat ($urandom_range(0,3)) @(negedge wr_clk);
                    random_data = $urandom;
                    write_data(random_data);
                end
            end
            begin : random_reader
                integer j;
                for (j=0;j<RANDOM_TXNS;j=j+1) begin
                    repeat ($urandom_range(0,4)) @(negedge rd_clk);
                    read_data();
                end
            end
        join
        repeat (6) @(negedge rd_clk);
        check(write_count == 1+DEPTH+RANDOM_TXNS,"All writes accepted");
        check(read_count == write_count,"All reads completed");
        check(rd_empty && !wr_full,"Final FIFO flags");
        check(write_count > 2*DEPTH && fail_count == 0,"Pointer wraparound and integrity");
        $display("Writes=%0d Reads=%0d Pass=%0d Fail=%0d",write_count,read_count,pass_count,fail_count);
        if (fail_count != 0) $fatal(1,"VERIFICATION FAILED");
        $display("ALL TESTS PASSED");
        $finish;
    end
    initial begin
        #200000;
        $fatal(1,"SIMULATION TIMEOUT");
    end
endmodule
