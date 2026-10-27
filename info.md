## Thiết kế này làm gì

Mạch thực hiện chức năng lọc nhiễu cơ học (debounce filter) cho nút bấm sử dụng máy trạng thái hữu hạn (FSM) kết hợp bộ đếm thời gian có tham số N cấu hình được lúc chạy (runtime configurable). Khi người dùng nhấn hoặc nhả nút bấm cơ khí, tiếp điểm cơ học bị rung nảy sinh ra chuỗi xung nhiễu ngắn ngẫu nhiên. Mạch chỉ chấp nhận xác nhận chuyển đổi mức tín hiệu logic khi nút bấm duy trì mức mới ổn định liên tục tối thiểu N chu kỳ xung nhịp. Thiết kế xuất ra tín hiệu mức đã lọc sạch nhiễu cùng với hai xung phát hiện sườn (xung sườn lên và xung sườn xuống) có độ rộng chuẩn đúng một chu kỳ xung nhịp.

## Cách hoạt động

Mạch bao gồm ba khối chức năng chính được kết nối tuần tự:
1. **Khối đồng bộ hóa đầu vào (Input Synchronizer):** Sử dụng hai tầng D-Flip-Flop để đồng bộ hóa tín hiệu bất đồng bộ từ chân nút thô (`uio_in[0]`), giúp khử bỏ hoàn toàn nguy cơ siêu ổn định (metastability) trước khi đưa vào lõi logic.
2. **Bộ đếm chu kỳ ổn định:** Bộ đếm 8-bit đếm thời gian tín hiệu nút bấm duy trì mức mới liên tục. Nếu trong quá trình đếm tín hiệu bị rung nảy đổi mức trở lại, bộ đếm lập tức bị reset về 0 để loại bỏ hoàn toàn các xung nhiễu ngắn hơn N chu kỳ.
3. **Máy trạng thái hữu hạn (FSM) 4 trạng thái:**
   - `STATE_LOW (2'b00)`: Nút bấm đang ổn định ở mức 0, đầu ra mức lọc `uo_out[0] = 0`. Khi phát hiện nút thô lên 1, FSM chuyển sang `STATE_WAIT_HIGH`.
   - `STATE_WAIT_HIGH (2'b01)`: Đang đếm thời gian ổn định mức 1. Nếu nút thô rớt về 0 trước N chu kỳ, FSM quay về `STATE_LOW` và xóa bộ đếm. Nếu ổn định đủ N chu kỳ, FSM chuyển sang `STATE_HIGH`, cập nhật mức lọc lên 1 và kích hoạt xung sườn lên `uo_out[1] = 1`.
   - `STATE_HIGH (2'b10)`: Nút bấm đang ổn định ở mức 1, đầu ra mức lọc `uo_out[0] = 1`. Khi phát hiện nút thô về 0, FSM chuyển sang `STATE_WAIT_LOW`.
   - `STATE_WAIT_LOW (2'b11)`: Đang đếm thời gian ổn định mức 0 khi nhả nút. Nếu nút thô nảy lại lên 1 trước N chu kỳ, FSM quay về `STATE_HIGH` và xóa bộ đếm. Nếu ổn định đủ N chu kỳ, FSM chuyển sang `STATE_LOW`, cập nhật mức lọc về 0 và kích hoạt xung sườn xuống `uo_out[2] = 1`.

## Cách kiểm thử

Hệ thống kiểm thử tự động (self-checking testbench) được xây dựng trong `test/tb.v` bao gồm đầy đủ các ca kiểm tra:
1. **Trạng thái khởi tạo sau reset:** Đảm bảo toàn bộ đầu ra và bộ đếm khởi tạo về 0 an toàn.
2. **Nhiễu ngắn hơn N chu kỳ:** Bơm các xung gai đơn chu kỳ và đa chu kỳ (1 nhịp, 2 nhịp với N=4); kiểm tra mạch lọc bỏ hoàn toàn, mức đầu ra không đổi.
3. **Nhấn phím ổn định liên tục >= N chu kỳ:** Kiểm tra mức lọc chuyển lên 1 và xung sườn lên `uo_out[1]` kích hoạt đúng 1 chu kỳ nhịp duy nhất.
4. **Nhiễu rớt khi đang giữ phím:** Bơm xung rớt về 0 ngắn hơn N chu kỳ; kiểm tra mạch giữ nguyên mức 1.
5. **Nhả phím ổn định liên tục >= N chu kỳ:** Kiểm tra mức lọc chuyển về 0 và xung sườn xuống `uo_out[2]` kích hoạt đúng 1 chu kỳ nhịp duy nhất.
6. **Kiểm tra ranh giới biên (N-1 và N chu kỳ):** Thử nghiệm với N=5 chu kỳ. Xung kéo dài 4 chu kỳ (N-1) bị lọc bỏ hoàn toàn; xung kéo dài đúng 5 chu kỳ (N) được chấp nhận thành công.
7. **Các ca kiểm thử tự nghĩ thêm:**
   - Thay đổi tham số thời gian N lúc đang chạy (Runtime reconfiguration) từ N=4 lên N=8 để kiểm tra tính thích ứng động.
   - Mô phỏng chuỗi xung rung nảy cơ khí ngẫu nhiên nhiều lần trước khi ổn định (Mechanical Bouncing).
   - Kích hoạt tín hiệu Reset bất đồng bộ giữa chừng khi bộ đếm đang đếm dở để kiểm tra tính an toàn chuyển trạng thái.

## Ánh xạ chân

| Chân | Tín hiệu | Ý nghĩa |
|---|---|---|
| `ui_in[7:0]` | `N[7:0]` | Tham số thời gian: số chu kỳ xung nhịp yêu cầu ổn định liên tục |
| `uo_out[0]` | `debounced` | Mức tín hiệu nút bấm đã lọc sạch nhiễu cơ học |
| `uo_out[1]` | `pulse_rise` | Xung tích cực 1 chu kỳ tại sườn lên của mức lọc (0 -> 1) |
| `uo_out[2]` | `pulse_fall` | Xung tích cực 1 chu kỳ tại sườn xuống của mức lọc (1 -> 0) |
| `uo_out[7:3]`| Cố định `5'b0` | Dự phòng, gán mức logic 0 |
| `uio_in[0]` | `btn_raw` | Tín hiệu nút bấm thô bất đồng bộ từ bên ngoài đưa vào |
| `uio_in[7:1]`| Không dùng | Không kết nối chức năng |
| `uio_out[7:0]`| `8'b00000000` | Cổng hai chiều cấu hình hướng ra bằng 0 |
| `uio_oe[7:0]` | `8'b00000000` | Điều khiển hướng chân uio làm đầu vào |

## Giới hạn

- Thiết kế giả định tần số xung nhịp hệ thống đủ nhanh so với thời gian rung cơ khí của nút bấm thực tế. Trong ứng dụng thực tế với nút bấm cơ khí (rung vài ms) và clock hệ thống 50-100 MHz, tham số N cần được mở rộng hoặc phối hợp với mạch chia tần trước khi đưa vào FSM.
- Thiết kế không khẳng định mạch đã được kiểm chứng trên silicon vật lý hay chế tạo thực tế, mà đây là kết quả mô phỏng số mức RTL và tổng hợp logic trong khuôn khổ học phần giáo dục EEE703128.
