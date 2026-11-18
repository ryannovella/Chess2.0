# setup_engines.ps1
# Unduh dan pasang Stockfish 18 (wajib) + Maia-3 (opsional) serta import aset Godot untuk Chess 2.0
$ErrorActionPreference = "Stop"

$EngineDir = Join-Path $PSScriptRoot "engine"
if (-not (Test-Path $EngineDir)) {
    New-Item -ItemType Directory -Path $EngineDir | Out-Null
}

function Test-ValidBinary {
    param([string]$Path, [long]$MinBytes = 4096)
    if (-not (Test-Path $Path)) { return $false }
    return (Get-Item $Path).Length -ge $MinBytes
}

# 1. Stockfish 18 (Wajib untuk bot AI, engine arrows, dan Game Review)
$StockfishExe = Join-Path $EngineDir "stockfish.exe"
if (Test-ValidBinary -Path $StockfishExe -MinBytes 1000000) {
    Write-Host "[OK] stockfish.exe sudah terpasang." -ForegroundColor Green
} else {
    $Urls = @(
        "https://github.com/official-stockfish/Stockfish/releases/download/sf_18/stockfish-windows-x86-64-avx2.zip",
        "https://github.com/official-stockfish/Stockfish/releases/download/sf_18/stockfish-windows-x86-64-sse41-popcnt.zip"
    )
    $Installed = $false
    foreach ($ZipUrl in $Urls) {
        try {
            Write-Host "Mengunduh Stockfish 18 dari $ZipUrl ..." -ForegroundColor Cyan
            $ZipPath = Join-Path $env:TEMP "stockfish_temp.zip"
            $ExtractPath = Join-Path $env:TEMP "stockfish_extract"

            Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing
            if (Test-Path $ExtractPath) { Remove-Item -Recurse -Force $ExtractPath }
            Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

            $FoundExe = Get-ChildItem -Path $ExtractPath -Filter "*.exe" -Recurse | Select-Object -First 1
            if ($FoundExe -and $FoundExe.Length -ge 1000000) {
                Copy-Item -Path $FoundExe.FullName -Destination $StockfishExe -Force
                Write-Host "[OK] Berhasil memasang stockfish.exe" -ForegroundColor Green
                $Installed = $true
            }
            Remove-Item -Force $ZipPath -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $ExtractPath -ErrorAction SilentlyContinue
            if ($Installed) { break }
        } catch {
            Write-Host "[WARN] Gagal mengunduh dari $ZipUrl : $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    if (-not $Installed) {
        throw "Gagal memasang stockfish.exe. Periksa koneksi internet Anda."
    }
}

# 2. Maia-3 5M Model Checkpoint (Opsional, untuk bot bergaya manusia)
$MaiaModel = Join-Path $EngineDir "maia3-5m.pt"
if (Test-ValidBinary -Path $MaiaModel -MinBytes 1000000) {
    Write-Host "[OK] maia3-5m.pt sudah terpasang." -ForegroundColor Green
} else {
    try {
        Write-Host "Mengunduh Maia-3 5M checkpoint (Hugging Face)..." -ForegroundColor Cyan
        $ModelUrl = "https://huggingface.co/UofTCSSLab/Maia3-5M/resolve/main/maia3-5m.pt"
        Invoke-WebRequest -Uri $ModelUrl -OutFile $MaiaModel -UseBasicParsing
        Write-Host "[OK] Berhasil mengunduh maia3-5m.pt" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Gagal mengunduh maia3-5m.pt (opsional). Game tetap jalan normal dengan Stockfish 18." -ForegroundColor Yellow
    }
}

# 3. Maia Launcher C# compilation (Opsional)
$MaiaExe = Join-Path $EngineDir "maia3.exe"
$MaiaCs = Join-Path $EngineDir "MaiaLauncher.cs"
if (-not (Test-ValidBinary -Path $MaiaExe) -and (Test-Path $MaiaCs)) {
    $CscPath = Join-Path $env:SystemRoot "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
    if (Test-Path $CscPath) {
        Write-Host "Mengompilasi MaiaLauncher.cs..." -ForegroundColor Cyan
        & $CscPath /target:winexe /out:"$MaiaExe" "$MaiaCs" | Out-Null
        if (Test-ValidBinary -Path $MaiaExe) {
            Write-Host "[OK] Berhasil mengompilasi maia3.exe" -ForegroundColor Green
        }
    } else {
        Write-Host "[INFO] .NET csc.exe tidak ditemukan; melewati kompilasi maia3.exe (Stockfish tetap aktif)." -ForegroundColor DarkGray
    }
}

# 4. Pre-import proyek Godot agar cache .godot/ langsung terbentuk (mencegah error startup)
$GodotCmd = Get-Command godot -ErrorAction SilentlyContinue
if ($GodotCmd) {
    Write-Host "Menjalankan Godot asset import (--import)..." -ForegroundColor Cyan
    & $GodotCmd.Source --headless --path "$PSScriptRoot" --import | Out-Null
    Write-Host "[OK] Cache .godot/ selesai di-import." -ForegroundColor Green
} else {
    Write-Host "[INFO] Buka proyek ini di Godot 4.7 Editor sekali agar folder .godot/ ter-import sebelum Play." -ForegroundColor Yellow
}

Write-Host "`nSetup selesai! Chess 2.0 siap dimainkan." -ForegroundColor Green
