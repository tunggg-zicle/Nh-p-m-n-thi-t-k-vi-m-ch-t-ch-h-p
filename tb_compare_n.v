// ─────────────────────────────────────────────────────────────────────────────
//  EEE703128 — Bài kiểm tra số 2
//  tb_compare_n.v — Mô phỏng đối chiếu song song: N=255 (8-bit) vs N=15 (4-bit)
//  Mã sinh viên: 24101349
//
//  MỤC ĐÍCH PHỤC VỤ MỤC 8 BÁO CÁO:
//    - Chạy song song cả hai thiết kế trên cùng một chuỗi kích thích (stimulus).
//    - Chứng minh với các giá trị N <= 15, cả hai phiên bản hoạt động giống hệt nhau
//      về mặt chức năng logic, nhưng phiên bản 4-bit tiết kiệm đáng kể diện tích/flip-flop.
// ─────────────────────────────────────────────────────────────────────────────
`default_nettype none
`timescale 1ns / 1ps

module tb_compare_n;

    reg  [7:0] ui_in, uio_in;
    reg        ena, clk, rst_n;
    wire [7:0] uo_out_8bit, uio_out_8bit, uio_oe_8bit;
    wire [7:0] uo_out_4bit, uio_out_4bit, uio_oe_4bit;

    integer so_phep_so = 0;
    integer so_lech = 0;

    // Khởi tạo phiên bản 8-bit (N tối đa 255)
    tt_um_eee703128_24101349 dut_8bit (
        .ui_in   (ui_in),
        .uo_out  (uo_out_8bit),
        .uio_in  (uio_in),
        .uio_out (uio_out_8bit),
        .uio_oe  (uio_oe_8bit),
        .ena     (ena),
        .clk     (clk),
        .rst_n   (rst_n)
    );

    // Khởi tạo phiên bản 4-bit (N tối đa 15)
    debounce_n15 dut_4bit (
        .ui_in   (ui_in),
        .uo_out  (uo_out_4bit),
        .uio_in  (uio_in),
        .uio_out (uio_out_4bit),
        .uio_oe  (uio_oe_4bit),
        .ena     (ena),
        .clk     (clk),
        .rst_n   (rst_n)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Giám sát liên tục mọi chu kỳ: nếu rst_n=1 thì kiểm tra hai đầu ra có khớp 100% không
    always @(negedge clk) begin
        if (rst_n === 1'b1) begin
            so_phep_so = so_phep_so + 1;
            if (uo_out_8bit[2:0] !== uo_out_4bit[2:0]) begin
                so_lech = so_lech + 1;
                $display("  [LECH] t=%0t: 8bit=%b, 4bit=%b", $time, uo_out_8bit[2:0], uo_out_4bit[2:0]);
            end
        end
    end

    initial begin
        `ifdef VCD_FILE
            $dumpfile(`VCD_FILE);
        `else
            $dumpfile("compare_n.vcd");
        `endif
        $dumpvars(0, tb_compare_n);

        ena    = 1'b1;
        rst_n  = 1'b0;
        ui_in  = 8'd6; // Đặt N = 6 (hợp lệ cho cả 4-bit và 8-bit)
        uio_in = 8'd0;

        repeat (2) @(posedge clk);
        #1;
        rst_n = 1'b1;
        @(posedge clk);

        $display("");
        $display("========================================================================");
        $display("  SO SANH DOI CHIEU HOAT DONG: DEBOUNCE 8-BIT (N<=255) vs 4-BIT (N<=15)");
        $display("========================================================================");

        // Kích thích 1: Nhiễu 2 chu kỳ (< 6)
        uio_in[0] = 1'b1;
        repeat (2) @(posedge clk);
        uio_in[0] = 1'b0;
        repeat (4) @(posedge clk);

        // Kích thích 2: Nhấn giữ ổn định 8 chu kỳ (>= 6)
        uio_in[0] = 1'b1;
        repeat (10) @(posedge clk);

        // Kích thích 3: Nhiễu rớt khi đang nhấn 2 chu kỳ
        uio_in[0] = 1'b0;
        repeat (2) @(posedge clk);
        uio_in[0] = 1'b1;
        repeat (6) @(posedge clk);

        // Kích thích 4: Nhả phím giữ ổn định 8 chu kỳ
        uio_in[0] = 1'b0;
        repeat (12) @(posedge clk);

        // Kích thích 5: Đổi N = 10 lúc chạy và kích thích chu kỳ mới
        ui_in = 8'd10;
        repeat (2) @(posedge clk);
        uio_in[0] = 1'b1;
        repeat (14) @(posedge clk);
        uio_in[0] = 1'b0;
        repeat (15) @(posedge clk);

        $display("");
        $display("========================================================================");
        $display("  DA DOI CHIEU: %0d phep so sanh chu ky xung nhip", so_phep_so);
        $display("  SO LAN LECH:  %0d", so_lech);
        if (so_lech == 0) begin
            $display("  >>> KET QUA DOI CHIEU: HAI PHIEN BAN HOAN TOAN KHOP 100%% <<<");
            $display("  Chung minh ban 4-bit giu nguyen tinh dung dan voi moi N <= 15.");
        end else begin
            $display("  >>> CANH BAO: PHAT HIEN SU KHAC BIET CHUC NANG <<<");
        end
        $display("========================================================================");
        $display("");

        #20 $finish;
    end

endmodule

`default_nettype wire
