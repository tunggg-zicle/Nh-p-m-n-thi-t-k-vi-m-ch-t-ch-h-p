# ─────────────────────────────────────────────────────────────────────────────
#  run_synth.ps1 — Chay tong hop logic Yosys cho F06 truc tiep tu PowerShell
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  DE TAI F06: TONG HOP LOGIC BANG YOSYS (SYNTHESIS)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

$wslCmd = "cd /mnt/d/tung24101349/BO_CAI_DAT_SINH_VIEN/f06_fsm_debounce && sed -i 's/\r$//' synth/run_synth.sh && bash synth/run_synth.sh"
wsl -d Ubuntu-24.04 -e bash -c $wslCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[THANH CONG] Tong hop logic va doi chieu tai nguyen phan cung thanh cong!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[THAT BAI] Co loi trong qua trinh tong hop." -ForegroundColor Red
}
