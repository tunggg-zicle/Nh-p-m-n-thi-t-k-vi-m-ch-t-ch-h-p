# ─────────────────────────────────────────────────────────────────────────────
#  run_sim.ps1 — Chay mo phong F06 truc tiep tu Windows PowerShell
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  DE TAI F06: CHAY MO PHONG VA KIEM CHUNG TU DONG (SIMULATION)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

$wslCmd = "cd /mnt/d/tung24101349/BO_CAI_DAT_SINH_VIEN/f06_fsm_debounce && sed -i 's/\r$//' sim/run_sim.sh && bash sim/run_sim.sh"
wsl -d Ubuntu-24.04 -e bash -c $wslCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[THANH CONG] Toan bo ca kiem thu mo phong de tai F06 da DAT (ALL TESTS PASSED)!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[THAT BAI] Co loi trong qua trinh mo phong." -ForegroundColor Red
}
