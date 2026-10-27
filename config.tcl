# ─────────────────────────────────────────────────────────────────────────────
#  config.tcl — Cấu hình OpenLane cho đề tài F06
# ─────────────────────────────────────────────────────────────────────────────
set ::env(DESIGN_NAME) "tt_um_eee703128_24101349"
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]

set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "10.0"

set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 160 100"
set ::env(FP_CORE_UTIL) 30
set ::env(PL_TARGET_DENSITY) 0.40

set ::env(SYNTH_STRATEGY) "AREA 0"
set ::env(ROUTING_CORES) 2
