// ─────────────────────────────────────────────────────────────────────────────
//  EEE703128 — Bài kiểm tra số 2
//  Testbench cho Đề tài F06: FSM chống rung phím có tham số thời gian
//  Mã sinh viên: 24101349
// ─────────────────────────────────────────────────────────────────────────────
`default_nettype none
`timescale 1ns / 1ps

module tb;

    reg  [7:0] ui_in, uio_in;
    reg        ena, clk, rst_n;
    wire [7:0] uo_out, uio_out, uio_oe;

    integer so_ca  = 0;
    integer so_sai = 0;

    // Khởi tạo DUT (Device Under Test)
    tt_um_eee703128_24101349 dut (
        .ui_in   (ui_in),
        .uo_out  (uo_out),
        .uio_in  (uio_in),
        .uio_out (uio_out),
        .uio_oe  (uio_oe),
        .ena     (ena),
        .clk     (clk),
        .rst_n   (rst_n)
    );

    // Xung nhịp hệ thống: Chu kỳ 10 ns (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Phân rã các tín hiệu đầu ra để quan sát
    wire debounced_out = uo_out[0];
    wire pulse_rise    = uo_out[1];
    wire pulse_fall    = uo_out[2];

    // Task kiểm tra kết quả đồng bộ theo từng chu kỳ nhịp
    task kiem;
        input        ky_vong_deb;   // Mức debounced kỳ vọng
        input        ky_vong_rise;  // Xung sườn lên kỳ vọng
        input        ky_vong_fall;  // Xung sườn xuống kỳ vọng
        input [511:0] ten_ca;       // Tên mô tả ca kiểm thử (512 bit tránh tràn chuỗi)
        begin
            so_ca = so_ca + 1;
            #1; // Chờ tín hiệu ổn định sau sườn dương clock
            if (debounced_out === ky_vong_deb &&
                pulse_rise    === ky_vong_rise &&
                pulse_fall    === ky_vong_fall) begin
                $display("  [OK]   %-50s | deb=%b rise=%b fall=%b",
                         ten_ca, debounced_out, pulse_rise, pulse_fall);
            end else begin
                so_sai = so_sai + 1;
                $display("  [FAIL] %-50s | deb=%b rise=%b fall=%b (KY VONG: deb=%b rise=%b fall=%b)",
                         ten_ca, debounced_out, pulse_rise, pulse_fall,
                         ky_vong_deb, ky_vong_rise, ky_vong_fall);
            end
        end
    endtask

    initial begin
        `ifdef VCD_FILE
            $dumpfile(`VCD_FILE);
        `else
            $dumpfile("tb.vcd");
        `endif
        $dumpvars(0, tb);

        ena    = 1'b1;
        rst_n  = 1'b0;
        ui_in  = 8'd4; // Tham số mặc định N = 4 chu kỳ
        uio_in = 8'd0;

        // Giữ reset trong 2 chu kỳ nhịp
        repeat (2) @(posedge clk);
        #1;
        rst_n = 1'b1; // Nhả reset
        @(posedge clk);
        #1;

        $display("");
        $display("========================================================================");
        $display("  KIEM THU DE TAI F06: FSM CHONG RUNG PHIM CO THAM SO THOI GIAN");
        $display("  MSSV: 24101349 -- Mon hoc: EEE703128");
        $display("========================================================================");

        // ─────────────────────────────────────────────────────────────────────
        // NHÓM 1: Trạng thái ban đầu sau Reset
        // ─────────────────────────────────────────────────────────────────────
        $display("\n--- [Nhom 1] Trang thai ban dau sau Reset ---");
        kiem(1'b0, 1'b0, 1'b0, "Khoi tao sau reset");

        // ─────────────────────────────────────────────────────────────────────
        // NHÓM 2: Nhiễu ngắn hơn N chu kỳ (BẮT BUỘC PHẢI LỌC BỎ)
        // Cấu hình N = 4 chu kỳ.
        // Bơm các xung gai có độ dài 1 chu kỳ và 2 chu kỳ.
        // ─────────────────────────────────────────────────────────────────────
        $display("\n--- [Nhom 2] Nhieu ngan hon N chu ky (Phai loc bo hoan toan) ---");
        // Gai 1: Xung nhô lên 1 chu kỳ
        #1; uio_in[0] = 1'b1;
        @(posedge clk);
        #1; uio_in[0] = 1'b0;
        repeat (4) @(posedge clk);
        kiem(1'b0, 1'b0, 1'b0, "Nhieu gai 1 chu ky -> Phai loc bo");

        // Gai 2: Xung kéo dài 2 chu kỳ (vẫn < N=4)
        #1; uio_in[0] = 1'b1;
        repeat (2) @(posedge clk);
        #1; uio_in[0] = 1'b0;
        repeat (5) @(posedge clk);
        kiem(1'b0, 1'b0, 1'b0, "Nhieu gai 2 chu ky (N=4) -> Loc bo");

        // ─────────────────────────────────────────────────────────────────────
        // NHÓM 3: Nhấn phím ổn định (Đủ N chu kỳ)
        // N = 4 chu kỳ. Tín hiệu qua 2 DFF đồng bộ + 4 chu kỳ đếm = 6 sườn clock.
        // ─────────────────────────────────────────────────────────────────────
        $display("\n--- [Nhom 3] Nhan phim on dinh lien tuc >= N chu ky ---");
        #1; uio_in[0] = 1'b1;
        repeat (6) @(posedge clk); // 2 sync + 4 đếm -> chuyển STATE_HIGH tại sườn 6
        kiem(1'b1, 1'b1, 1'b0, "Dat N=4 chu ky: muc len 1, co pulse_rise");

        @(posedge clk);
        kiem(1'b1, 1'b0, 1'b0, "Chu ky tiep: pulse_rise tat, muc giu 1");

        repeat (3) @(posedge clk);
        kiem(1'b1, 1'b0, 1'b0, "Tiep tuc giu phim: muc giu 1 on dinh");

        // ─────────────────────────────────────────────────────────────────────
        // NHÓM 4: Nhiễu rung khi đang giữ phím (Phải lọc bỏ)
        // Nút bấm đang ở mức 1, bị rớt xuống 0 trong 2 chu kỳ rồi lên lại 1.
        // ─────────────────────────────────────────────────────────────────────
        $display("\n--- [Nhom 4] Nhieu rung khi dang nhan (Phai loc bo) ---");
        #1; uio_in[0] = 1'b0;
        repeat (2) @(posedge clk);
        #1; uio_in[0] = 1'b1;
        repeat (5) @(posedge clk);
        kiem(1'b1, 1'b0, 1'b0, "Rung rot 2 chu ky khi dang nhan -> Giu 1");

        // ─────────────────────────────────────────────────────────────────────
        // NHÓM 5: Nhả phím ổn định (Đủ N chu kỳ)
        // uio_in[0] về 0 và giữ ổn định >= N chu kỳ.
        // ─────────────────────────────────────────────────────────────────────
        $display("\n--- [Nhom 5] Nha phim on dinh lien tuc >= N chu ky ---");
        #1; uio_in[0] = 1'b0;
        repeat (6) @(posedge clk); // 2 sync + 4 đếm -> chuyển STATE_LOW
        kiem(1'b0, 1'b0, 1'b1, "Dat N=4 chu ky nha: muc ve 0, co pulse_fall");

        @(posedge clk);
        kiem(1'b0, 1'b0, 1'b0, "Chu ky tiep: pulse_fall tat, muc giu 0");

        repeat (3) @(posedge clk);
        kiem(1'b0, 1'b0, 1'b0, "Sau khi nha: muc giu 0 on dinh");

        // ─────────────────────────────────────────────────────────────────────
        // NHÓM 6: Kiểm tra ranh giới biên (Nhiễu đúng bằng N chu kỳ)
        // Thiết lập N = 5 chu kỳ.
        // 6.1: Giữ đúng N-1 = 4 chu kỳ xung nhịp -> PHẢI LỌC BỎ.
        // 6.2: Giữ đúng N = 5 chu kỳ xung nhịp -> ĐƯỢC CHẤP NHẬN.
        // ─────────────────────────────────────────────────────────────────────
        $display("\n--- [Nhom 6] Kiem tra ranh gioi bien: N-1 chu ky va dung N chu ky (N=5) ---");
        ui_in = 8'd5; // Cấu hình tham số N = 5
        repeat (2) @(posedge clk);

        // Ca 6.1: Xung nhô lên giữ đúng 4 chu kỳ clock (N-1) rồi về 0
        #1; uio_in[0] = 1'b1;
        repeat (4) @(posedge clk); // đúng 4 chu kỳ
        #1; uio_in[0] = 1'b0;
        repeat (6) @(posedge clk);
        kiem(1'b0, 1'b0, 1'b0, "Bien 1: Giu N-1 chu ky (4 chu ky) -> Loc bo");

        // Ca 6.2: Xung giữ ở mức 1 đúng N = 5 chu kỳ
        #1; uio_in[0] = 1'b1;
        repeat (2 + 5) @(posedge clk); // 2 sync + 5 đếm = 7 nhịp -> chuyển STATE_HIGH
        kiem(1'b1, 1'b1, 1'b0, "Bien 2: Giu dung N=5 chu ky -> Chap nhan 1");

        @(posedge clk);
        kiem(1'b1, 1'b0, 1'b0, "Chu ky sau bien: pulse_rise tat, muc giu 1");

        // Nhả phím để chuẩn bị cho nhóm sau
        #1; uio_in[0] = 1'b0;
        repeat (8) @(posedge clk);

        // ─────────────────────────────────────────────────────────────────────
        // NHÓM 7: Các ca kiểm thử tự nghĩ thêm (Biên cực trị & Đột biến nâng cao)
        // 7.1: Thay đổi N lúc đang chạy (Runtime reconfiguration)
        // 7.2: Mô phỏng chuỗi rung nảy cơ khí thực tế (Mechanical Bouncing)
        // 7.3: Reset bất đồng bộ giữa chừng khi đang đếm
        // 7.4: Biên cực tiểu N=1 (Bypass / Đáp ứng tức thời 1 chu kỳ)
        // 7.5: Biên cực đại N=255 (Full 8-bit dynamic range)
        // ─────────────────────────────────────────────────────────────────────
        $display("\n--- [Nhom 7] Cac ca kiem thu tu nghi them ---");

        // Ca 7.1: Thay đổi N lớn hơn (N=8) lúc đang chạy
        ui_in = 8'd8; // Cấu hình N = 8 chu kỳ
        repeat (2) @(posedge clk);
        #1; uio_in[0] = 1'b1;
        repeat (5) @(posedge clk); // Mới được 5 chu kỳ (< 8)
        #1; uio_in[0] = 1'b0;          // Rơi xuống 0
        repeat (6) @(posedge clk);
        kiem(1'b0, 1'b0, 1'b0, "Runtime N=8: Xung 5 chu ky bi xem la nhieu");

        // Ca 7.2: Mô phỏng rung phím cơ khí thực tế (Bouncing pattern)
        // Phím nảy: 0 -> 1(1 nhip) -> 0(2 nhip) -> 1(2 nhip) -> 0(1 nhip) -> 1 (giữ luôn)
        ui_in = 8'd4; // Đặt N = 4
        repeat (2) @(posedge clk);
        #1; uio_in[0] = 1'b1; @(posedge clk);
        #1; uio_in[0] = 1'b0; repeat (2) @(posedge clk);
        #1; uio_in[0] = 1'b1; repeat (2) @(posedge clk);
        #1; uio_in[0] = 1'b0; @(posedge clk);
        kiem(1'b0, 1'b0, 1'b0, "Rung co hoc: chua on dinh -> Van giu 0");

        // Bắt đầu ổn định mức 1 liên tục >= 4 chu kỳ
        #1; uio_in[0] = 1'b1;
        repeat (6) @(posedge clk); // 2 sync + 4 chu kỳ ổn định
        kiem(1'b1, 1'b1, 1'b0, "Sau khi het rung: on dinh N=4 -> Chap nhan 1");

        // Ca 7.3: Reset bất đồng bộ giữa chừng khi đang đếm nhả phím
        #1; uio_in[0] = 1'b0;
        repeat (3) @(posedge clk); // Đang đếm dở ở STATE_WAIT_LOW
        #2;
        rst_n = 1'b0; // Kích hoạt Reset bất đồng bộ giữa chu kỳ
        #2;
        @(posedge clk);
        #1;
        kiem(1'b0, 1'b0, 1'b0, "Reset bat dong bo giua chung -> Ve 0 an toan");

        rst_n = 1'b1;
        repeat (3) @(posedge clk);

        // Ca 7.4: Biên cực tiểu N=1 (Bypass mode)
        $display("\n--- [Kiem tra bo sung] Bien cuc tieu N=1 va cuc dai N=255 ---");
        ui_in = 8'd1;
        #1; uio_in[0] = 1'b0;
        repeat (4) @(posedge clk);

        // Nhấn N=1
        #1; uio_in[0] = 1'b1;
        repeat (3) @(posedge clk); // 2 sync + 1 chu kỳ đáp ứng = 3 edges
        kiem(1'b1, 1'b1, 1'b0, "Bien cuc tieu N=1: Dap ung tuc thoi len 1");

        @(posedge clk);
        kiem(1'b1, 1'b0, 1'b0, "Bien N=1: pulse_rise tat sau 1 nhip");
        repeat (3) @(posedge clk);

        // Nhả N=1
        #1; uio_in[0] = 1'b0;
        repeat (3) @(posedge clk); // 2 sync + 1 chu kỳ đáp ứng = 3 edges
        kiem(1'b0, 1'b0, 1'b1, "Bien cuc tieu N=1: Dap ung tuc thoi ve 0");

        @(posedge clk);
        kiem(1'b0, 1'b0, 1'b0, "Bien N=1: pulse_fall tat sau 1 nhip");
        repeat (4) @(posedge clk);

        // Ca 7.5: Biên cực đại N=255 (Full 8-bit dynamic range)
        ui_in = 8'd255;
        repeat (4) @(posedge clk);

        // Nhấn N=255
        #1; uio_in[0] = 1'b1;
        repeat (2 + 255) @(posedge clk); // 2 sync + 255 chu kỳ đếm = 257 edges
        kiem(1'b1, 1'b1, 1'b0, "Bien cuc dai N=255: Dem du 255 nhip len 1");

        @(posedge clk);
        kiem(1'b1, 1'b0, 1'b0, "Bien N=255: pulse_rise tat sau 1 nhip");
        repeat (4) @(posedge clk);

        // Nhả N=255
        #1; uio_in[0] = 1'b0;
        repeat (2 + 255) @(posedge clk); // 2 sync + 255 chu kỳ đếm = 257 edges
        kiem(1'b0, 1'b0, 1'b1, "Bien cuc dai N=255: Dem du 255 nhip ve 0");

        @(posedge clk);
        kiem(1'b0, 1'b0, 1'b0, "Bien N=255: pulse_fall tat sau 1 nhip");
        repeat (4) @(posedge clk);

        // ─────────────────────────────────────────────────────────────────────
        // TỔNG KẾT KẾT QUẢ KIỂM THỬ
        // ─────────────────────────────────────────────────────────────────────
        $display("");
        $display("========================================================================");
        $display("  KET QUA: %0d ca kiem thu, %0d sai", so_ca, so_sai);
        if (so_sai == 0)
            $display("  >>> TAT CA CA KIEM THU DEU DAT (ALL TESTS PASSED) <<<");
        else
            $display("  >>> CON %0d CA SAI -- CAN KIEM TRA LAI RTL <<<", so_sai);
        $display("========================================================================");
        $display("");

        #20 $finish;
    end

endmodule

`default_nettype wire
