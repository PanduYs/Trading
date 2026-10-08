# Setup tradingview-mcp di Windows.
# Jalankan dari PowerShell:  powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1
param([string]$InstallDir = "$env:USERPROFILE\tradingview-mcp")
$ErrorActionPreference = 'Stop'

foreach ($cmd in 'git', 'node', 'npm') {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Error "$cmd belum terpasang. Install Git (git-scm.com) dan Node.js 18+ (nodejs.org), lalu jalankan ulang."
    }
}
$nodeMajor = [int]((node --version).TrimStart('v').Split('.')[0])
if ($nodeMajor -lt 18) { Write-Error "Node.js 18+ dibutuhkan (terpasang: $(node --version))." }

Write-Host "==> Clone / update tradingview-mcp ke $InstallDir"
if (Test-Path "$InstallDir\.git") { git -C $InstallDir pull --ff-only }
else { git clone https://github.com/tradesdontlie/tradingview-mcp.git $InstallDir }

Write-Host "==> npm install"
Push-Location $InstallDir
npm install
Pop-Location

$serverJs = Join-Path $InstallDir 'src\server.js'

Write-Host "==> Daftarkan ke Claude Code"
if (Get-Command claude -ErrorAction SilentlyContinue) {
    try { claude mcp remove tradingview -s user 2>$null | Out-Null } catch { }
    claude mcp add tradingview -s user -- node $serverJs
} else {
    Write-Host "   Claude Code CLI tidak ditemukan, lewati."
}

Write-Host "==> Daftarkan ke Claude Desktop"
node (Join-Path $PSScriptRoot 'register-mcp.mjs') $InstallDir

Write-Host ""
Write-Host "Selesai. Langkah berikut:"
Write-Host "  1. Jalankan TradingView mode debug:  $InstallDir\scripts\launch_tv_debug.bat"
Write-Host "     (skrip ini menutup TradingView yang sedang terbuka dulu)"
Write-Host "  2. Restart Claude Code / Claude Desktop"
Write-Host "  3. Ketik ke Claude: Use tv_health_check to verify TradingView is connected"
