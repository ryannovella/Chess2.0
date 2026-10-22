# setup_engines.ps1
# Unduh dan pasang Stockfish 18 dan Maia-3 Checkpoint untuk Chess 2.0
$ErrorActionPreference = "Stop"

$EngineDir = Join-Path $PSScriptRoot "engine"
if (-not (Test-Path $EngineDir)) {
    New-Item -ItemType Directory -Path $EngineDir | Out-Null
}

# 1. Stockfish 18
$StockfishExe = Join-Path $EngineDir "stockfish.exe"
if (Test-Path $StockfishExe) {
    Write-Host "[OK] stockfish.exe sudah terpasang." -ForegroundColor Green
} else {
    Write-Host "Mengunduh Stockfish binary..." -ForegroundColor Cyan
    $ZipUrl = "https://github.com/official-stockfish/Stockfish/releases/download/sf_18/stockfish-windows-x86-64-avx2.zip"
    $ZipPath = Join-Path $env:TEMP "stockfish_temp.zip"
    $ExtractPath = Join-Path $env:TEMP "stockfish_extract"

    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath
    if (Test-Path $ExtractPath) { Remove-Item -Recurse -Force $ExtractPath }
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

    $FoundExe = Get-ChildItem -Path $ExtractPath -Filter "*.exe" -Recurse | Select-Object -First 1
    if ($FoundExe) {
        Copy-Item -Path $FoundExe.FullName -Destination $StockfishExe -Force
        Write-Host "[OK] Berhasil memasang stockfish.exe" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Binary Stockfish tidak ditemukan dalam arsip!" -ForegroundColor Red
    }
    Remove-Item -Force $ZipPath -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $ExtractPath -ErrorAction SilentlyContinue
}

# 2. Maia-3 5M Model Checkpoint
$MaiaModel = Join-Path $EngineDir "maia3-5m.pt"
if (Test-Path $MaiaModel) {
    Write-Host "[OK] maia3-5m.pt sudah terpasang." -ForegroundColor Green
} else {
    Write-Host "Mengunduh Maia-3 5M checkpoint (Hugging Face)..." -ForegroundColor Cyan
    $ModelUrl = "https://huggingface.co/UofTCSSLab/Maia3-5M/resolve/main/maia3-5m.pt"
    Invoke-WebRequest -Uri $ModelUrl -OutFile $MaiaModel
    Write-Host "[OK] Berhasil mengunduh maia3-5m.pt" -ForegroundColor Green
}

# 3. Maia Launcher C# compilation (if needed)
$MaiaExe = Join-Path $EngineDir "maia3.exe"
$MaiaCs = Join-Path $EngineDir "MaiaLauncher.cs"
if (-not (Test-Path $MaiaExe) -and (Test-Path $MaiaCs)) {
    Write-Host "Mengompilasi MaiaLauncher.cs..." -ForegroundColor Cyan
    $CscPath = Join-Path $env:SystemRoot "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
    if (Test-Path $CscPath) {
        & $CscPath /target:winexe /out:"$MaiaExe" "$MaiaCs"
        Write-Host "[OK] Berhasil mengompilasi maia3.exe" -ForegroundColor Green
    }
}

Write-Host "`nSetup engine selesai! Game siap dimainkan." -ForegroundColor Green
