#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  run_sim.sh — Chạy mô phỏng cho F06: FSM chống rung phím có tham số thời gian
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p sim/waveforms sim/build

echo "=========================================================="
echo "  [1/2] Biên dịch và chạy mô phỏng chính: tb.v"
echo "=========================================================="
iverilog -g2012 -DVCD_FILE=\"sim/waveforms/f06_debounce.vcd\" -o sim/build/tb_f06 src/project.v test/tb.v
vvp sim/build/tb_f06

echo ""
echo "=========================================================="
echo "  [2/2] Chạy mô phỏng đối chiếu (Mục 8): tb_compare_n.v"
echo "=========================================================="
iverilog -g2012 -DVCD_FILE=\"sim/waveforms/compare_n.vcd\" -o sim/build/tb_compare src/project.v src/debounce_n15.v test/tb_compare_n.v
vvp sim/build/tb_compare

echo ""
echo "Hoàn thành mô phỏng. File dạng sóng được tạo tại:"
echo "  - sim/waveforms/f06_debounce.vcd"
echo "  - sim/waveforms/compare_n.vcd"
