// ─────────────────────────────────────────────────────────────────────────────
//  EEE703128 — Nhập môn Thiết kế Vi mạch Tích hợp
//  Module đối chiếu cho Đề tài F06: FSM chống rung phím với N tối đa 15 (4-bit)
//  Mã sinh viên: 24101349
//
//  MỤC ĐÍCH:
//    - So sánh tài nguyên phần cứng (diện tích ô chuẩn, số flip-flop) với phiên bản
//      N tối đa 255 (8-bit) theo đúng yêu cầu phân tích Mục 8 của đề bài.
//    - Bộ đếm chỉ cần 4 bit (timer_cnt[3:0]), tham số N nhận qua ui_in[3:0].
// ─────────────────────────────────────────────────────────────────────────────
`default_nettype none

module debounce_n15 (
    input  wire [7:0] ui_in,    // ui_in[3:0] = N (tối đa 15), ui_in[7:4] không dùng
    output wire [7:0] uo_out,   // [0]=debounced, [1]=pulse_rise, [2]=pulse_fall
    input  wire [7:0] uio_in,   // uio_in[0] = nút thô
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ── 1. Hai tầng Flip-Flop đồng bộ hóa đầu vào ───────────────────────────
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

    // ── 2. Tham số thời gian N 4-bit (tối đa 15) ────────────────────────────
    wire [3:0] N = ui_in[3:0];
    wire [3:0] eff_N = (N == 4'd0) ? 4'd1 : N;

    // ── 3. Định nghĩa các trạng thái FSM ─────────────────────────────────────
    localparam [1:0]
        STATE_LOW       = 2'b00,
        STATE_WAIT_HIGH = 2'b01,
        STATE_HIGH      = 2'b10,
        STATE_WAIT_LOW  = 2'b11;

    reg [1:0] state;
    reg [3:0] timer_cnt; // Bộ đếm 4-bit (thay vì 8-bit)
    reg       debounced_reg;
    reg       pulse_rise_reg;
    reg       pulse_fall_reg;

    // ── 4. Khối FSM tuần tự ──────────────────────────────────────────────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= STATE_LOW;
            timer_cnt      <= 4'd0;
            debounced_reg  <= 1'b0;
            pulse_rise_reg <= 1'b0;
            pulse_fall_reg <= 1'b0;
        end else begin
            pulse_rise_reg <= 1'b0;
            pulse_fall_reg <= 1'b0;

            case (state)
                STATE_LOW: begin
                    debounced_reg <= 1'b0;
                    timer_cnt     <= 4'd0;
                    if (btn_clean == 1'b1) begin
                        if (eff_N <= 4'd1) begin
                            state          <= STATE_HIGH;
                            debounced_reg  <= 1'b1;
                            pulse_rise_reg <= 1'b1;
                        end else begin
                            state     <= STATE_WAIT_HIGH;
                            timer_cnt <= 4'd1;
                        end
                    end
                end

                STATE_WAIT_HIGH: begin
                    debounced_reg <= 1'b0;
                    if (btn_clean == 1'b0) begin
                        state     <= STATE_LOW;
                        timer_cnt <= 4'd0;
                    end else begin
                        if ({1'b0, timer_cnt} + 5'd1 >= {1'b0, eff_N}) begin
                            state          <= STATE_HIGH;
                            debounced_reg  <= 1'b1;
                            pulse_rise_reg <= 1'b1;
                            timer_cnt      <= 4'd0;
                        end else begin
                            timer_cnt <= timer_cnt + 4'd1;
                        end
                    end
                end

                STATE_HIGH: begin
                    debounced_reg <= 1'b1;
                    timer_cnt     <= 4'd0;
                    if (btn_clean == 1'b0) begin
                        if (eff_N <= 4'd1) begin
                            state          <= STATE_LOW;
                            debounced_reg  <= 1'b0;
                            pulse_fall_reg <= 1'b1;
                        end else begin
                            state     <= STATE_WAIT_LOW;
                            timer_cnt <= 4'd1;
                        end
                    end
                end

                STATE_WAIT_LOW: begin
                    debounced_reg <= 1'b1;
                    if (btn_clean == 1'b1) begin
                        state     <= STATE_HIGH;
                        timer_cnt <= 4'd0;
                    end else begin
                        if ({1'b0, timer_cnt} + 5'd1 >= {1'b0, eff_N}) begin
                            state          <= STATE_LOW;
                            debounced_reg  <= 1'b0;
                            pulse_fall_reg <= 1'b1;
                            timer_cnt      <= 4'd0;
                        end else begin
                            timer_cnt <= timer_cnt + 4'd1;
                        end
                    end
                end

                default: begin
                    state          <= STATE_LOW;
                    timer_cnt      <= 4'd0;
                    debounced_reg  <= 1'b0;
                    pulse_rise_reg <= 1'b0;
                    pulse_fall_reg <= 1'b0;
                end
            endcase
        end
    end

    assign uo_out[0]   = debounced_reg;
    assign uo_out[1]   = pulse_rise_reg;
    assign uo_out[2]   = pulse_fall_reg;
    assign uo_out[7:3] = 5'b00000;

    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

    wire _unused = &{ena, ui_in[7:4], uio_in[7:1], 1'b0};

endmodule

`default_nettype wire
