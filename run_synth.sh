#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  run_synth.sh — Chạy tổng hợp Yosys cho F06 (8-bit vs 4-bit)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p synth/reports synth/netlist

echo "=========================================================="
echo "  [1/2] Tổng hợp thiết kế chính F06: N tối đa 255 (8-bit)"
echo "=========================================================="
yosys -s synth/f06_synth.ys | tee synth/reports/f06_yosys.log

echo ""
echo "=========================================================="
echo "  [2/2] Tổng hợp thiết kế đối chiếu: N tối đa 15 (4-bit)"
echo "=========================================================="
yosys -s synth/n15_synth.ys | tee synth/reports/n15_yosys.log

echo ""
echo "=========================================================="
echo "  BẢNG SO SÁNH TÀI NGUYÊN (PHỤC VỤ MỤC 8 BÁO CÁO)"
echo "=========================================================="

LOG_8B=synth/reports/f06_yosys.log
LOG_4B=synth/reports/n15_yosys.log

CELLS_8B=$(awk '/^=== /{n=0} /Number of cells/{n=$NF} END{print n+0}' "$LOG_8B")
FF_8B=$(awk '/^=== /{s=0} /DFF/{s+=$NF} END{print s+0}' "$LOG_8B")

CELLS_4B=$(awk '/^=== /{n=0} /Number of cells/{n=$NF} END{print n+0}' "$LOG_4B")
FF_4B=$(awk '/^=== /{s=0} /DFF/{s+=$NF} END{print s+0}' "$LOG_4B")

DELTA_CELLS=$((CELLS_8B - CELLS_4B))
DELTA_FF=$((FF_8B - FF_4B))

printf "%-32s | %14s | %14s | %10s\n" "Chỉ số phần cứng" "N<=255 (8-bit)" "N<=15 (4-bit)" "Chênh lệch"
printf "%-32s-+-%14s-+-%14s-+-%10s\n" "--------------------------------" "--------------" "--------------" "----------"
printf "%-32s | %14d | %14d | %+10d\n" "Tổng số ô chuẩn (cells)" "$CELLS_8B" "$CELLS_4B" "$DELTA_CELLS"
printf "%-32s | %14d | %14d | %+10d\n" "Số phần tử nhớ (flip-flops)" "$FF_8B" "$FF_4B" "$DELTA_FF"
echo "=========================================================="
echo "Đã ghi nhận số liệu định lượng chính xác để trả lời Mục 8 của Báo cáo."
