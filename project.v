// ─────────────────────────────────────────────────────────────────────────────
//  EEE703128 — Nhập môn Thiết kế Vi mạch Tích hợp
//  Đề tài: F06 — FSM chống rung phím có tham số thời gian (Debounce FSM)
//  Mã sinh viên: 24101349
//
//  ĐẶC TẢ THIẾT KẾ:
//    - Nhiệm vụ: Lọc nhiễu cơ khí của nút bấm, chỉ chấp nhận thay đổi mức khi
//      tín hiệu ổn định liên tục N chu kỳ xung nhịp.
//    - Tham số N cấu hình được lúc chạy (Runtime Configurable) qua ui_in[7:0].
//    - Xuất mức đã lọc (debounced level), xung sườn lên (rising pulse), và
//      xung sườn xuống (falling pulse).
//    - Tích hợp 2 tầng flip-flop đồng bộ đầu vào chống hiện tượng siêu ổn định
//      (metastability synchronizer).
//
//  ÁNH XẠ CHÂN TINY TAPEOUT:
//    - uio_in[0] : Nút thô (raw button input từ nút bấm cơ khí bên ngoài)
//    - ui_in[7:0]: Tham số thời gian N (thời gian yêu cầu ổn định liên tục N chu kỳ)
//    - uo_out[0] : Mức đã lọc (debounced output level)
//    - uo_out[1] : Xung sườn lên (posedge pulse: tích cực 1 chu kỳ khi mức 0 -> 1)
//    - uo_out[2] : Xung sườn xuống (negedge pulse: tích cực 1 chu kỳ khi mức 1 -> 0)
//    - uo_out[7:3]: 5'b00000 (dự phòng, gán cố định mức 0)
//    - uio_out   : 8'b00000000 (không xuất dữ liệu hai chiều)
//    - uio_oe    : 8'b00000000 (toàn bộ chân uio cấu hình làm đầu vào)
// ─────────────────────────────────────────────────────────────────────────────
`default_nettype none

module tt_um_eee703128_24101349 (
    input  wire [7:0] ui_in,    // 8 chân vào riêng: ui_in[7:0] = N
    output wire [7:0] uo_out,   // 8 chân ra riêng: [0]=debounced, [1]=pulse_rise, [2]=pulse_fall
    input  wire [7:0] uio_in,   // 8 chân hai chiều (chiều vào): uio_in[0] = nút thô
    output wire [7:0] uio_out,  // 8 chân hai chiều (chiều ra)
    output wire [7:0] uio_oe,   // 8 chân điều khiển hướng (1 = ra, 0 = vào)
    input  wire       ena,      // Tín hiệu enable khối thiết kế
    input  wire       clk,      // Xung nhịp hệ thống (clock)
    input  wire       rst_n     // Reset tích cực mức THẤP (active-low)
);

    // ── 1. Hai tầng Flip-Flop đồng bộ hóa đầu vào (Input Synchronizer) ───────
    // Nút cơ khí là tín hiệu bất đồng bộ bên ngoài chip. Hai tầng D-FF giúp
    // loại bỏ nguy cơ siêu ổn định (metastability) trước khi đưa vào FSM.
    reg btn_sync_0;
    reg btn_sync_1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_sync_0 <= 1'b0;
            btn_sync_1 <= 1'b0;
        end else begin
            btn_sync_0 <= uio_in[0];
            btn_sync_1 <= btn_sync_0;
        end
    end

    wire btn_clean = btn_sync_1;

    // ── 2. Tham số thời gian N hữu hiệu ──────────────────────────────────────
    // N được nạp lúc chạy qua ui_in[7:0].
    // Nếu N = 0 thì quy ước thời gian ổn định tối thiểu là 1 chu kỳ.
    wire [7:0] eff_N = (ui_in == 8'd0) ? 8'd1 : ui_in;

    // ── 3. Định nghĩa các trạng thái của FSM chống rung phím ─────────────────
    localparam [1:0]
        STATE_LOW       = 2'b00,  // Nút đang ổn định ở mức 0
        STATE_WAIT_HIGH = 2'b01,  // Đang đếm kiểm tra duy trì mức 1 (chống rung nhấn)
        STATE_HIGH      = 2'b10,  // Nút đang ổn định ở mức 1
        STATE_WAIT_LOW  = 2'b11;  // Đang đếm kiểm tra duy trì mức 0 (chống rung nhả)

    reg [1:0] state;
    reg [7:0] timer_cnt;
    reg       debounced_reg;
    reg       pulse_rise_reg;
    reg       pulse_fall_reg;

    // ── 4. Khối FSM tuần tự điều khiển chuyển trạng thái và phát xung ─────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= STATE_LOW;
            timer_cnt      <= 8'd0;
            debounced_reg  <= 1'b0;
            pulse_rise_reg <= 1'b0;
            pulse_fall_reg <= 1'b0;
        end else begin
            // Mặc định các xung sườn chỉ tồn tại đúng 1 chu kỳ nhịp
            pulse_rise_reg <= 1'b0;
            pulse_fall_reg <= 1'b0;

            case (state)
                STATE_LOW: begin
                    debounced_reg <= 1'b0;
                    timer_cnt     <= 8'd0;
                    if (btn_clean == 1'b1) begin
                        if (eff_N <= 8'd1) begin
                            state          <= STATE_HIGH;
                            debounced_reg  <= 1'b1;
                            pulse_rise_reg <= 1'b1;
                        end else begin
                            state     <= STATE_WAIT_HIGH;
                            timer_cnt <= 8'd1;
                        end
                    end
                end

                STATE_WAIT_HIGH: begin
                    debounced_reg <= 1'b0;
                    if (btn_clean == 1'b0) begin
                        // Tín hiệu bị trả về 0 trước khi đủ N chu kỳ -> NHIỄU PHẢI LỌC BỎ
                        state     <= STATE_LOW;
                        timer_cnt <= 8'd0;
                    end else begin
                        // Tín hiệu tiếp tục giữ mức 1
                        // Dùng phép so sánh 9-bit chống tràn khi timer_cnt = 255
                        if ({1'b0, timer_cnt} + 9'd1 >= {1'b0, eff_N}) begin
                            // Đã ổn định liên tục đủ N chu kỳ -> Chấp nhận mức 1
                            state          <= STATE_HIGH;
                            debounced_reg  <= 1'b1;
                            pulse_rise_reg <= 1'b1;
                            timer_cnt      <= 8'd0;
                        end else begin
                            timer_cnt <= timer_cnt + 8'd1;
                        end
                    end
                end

                STATE_HIGH: begin
                    debounced_reg <= 1'b1;
                    timer_cnt     <= 8'd0;
                    if (btn_clean == 1'b0) begin
                        if (eff_N <= 8'd1) begin
                            state          <= STATE_LOW;
                            debounced_reg  <= 1'b0;
                            pulse_fall_reg <= 1'b1;
                        end else begin
                            state     <= STATE_WAIT_LOW;
                            timer_cnt <= 8'd1;
                        end
                    end
                end

                STATE_WAIT_LOW: begin
                    debounced_reg <= 1'b1;
                    if (btn_clean == 1'b1) begin
                        // Tín hiệu bị nảy lên 1 trước khi đủ N chu kỳ -> NHIỄU PHẢI LỌC BỎ
                        state     <= STATE_HIGH;
                        timer_cnt <= 8'd0;
                    end else begin
                        // Tín hiệu tiếp tục giữ mức 0
                        // Dùng phép so sánh 9-bit chống tràn khi timer_cnt = 255
                        if ({1'b0, timer_cnt} + 9'd1 >= {1'b0, eff_N}) begin
                            // Đã ổn định liên tục đủ N chu kỳ -> Chấp nhận mức 0
                            state          <= STATE_LOW;
                            debounced_reg  <= 1'b0;
                            pulse_fall_reg <= 1'b1;
                            timer_cnt      <= 8'd0;
                        end else begin
                            timer_cnt <= timer_cnt + 8'd1;
                        end
                    end
                end

                default: begin
                    state          <= STATE_LOW;
                    timer_cnt      <= 8'd0;
                    debounced_reg  <= 1'b0;
                    pulse_rise_reg <= 1'b0;
                    pulse_fall_reg <= 1'b0;
                end
            endcase
        end
    end

    // ── 5. Ánh xạ các tín hiệu đầu ra chuẩn Tiny Tapeout ─────────────────────
    assign uo_out[0]   = debounced_reg;  // Mức tín hiệu đã lọc nhiễu
    assign uo_out[1]   = pulse_rise_reg; // Xung sườn lên 1 chu kỳ clock
    assign uo_out[2]   = pulse_fall_reg; // Xung sườn xuống 1 chu kỳ clock
    assign uo_out[7:3] = 5'b00000;       // Dự phòng

    assign uio_out = 8'b00000000;        // Không dùng cổng ra hai chiều
    assign uio_oe  = 8'b00000000;        // Đặt toàn bộ uio làm đầu vào

    // Chống cảnh báo linter về các chân không dùng
    wire _unused = &{ena, uio_in[7:1], 1'b0};

endmodule

`default_nettype wire
