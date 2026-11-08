param([Parameter(Mandatory=$true)][string]$GodotExe, [switch]$Release)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$godotPath = (Resolve-Path $GodotExe -ErrorAction Stop).Path
& "$PSScriptRoot/RUN_DEV8_QA_WINDOWS.ps1" -GodotExe $godotPath -Story
if (-not $?) { throw "Godot QA did not succeed" }
if ($Release) {
    python tools/production_gate_dev8.py --release
    if ($LASTEXITCODE -ne 0) { throw "100-level release evidence missing" }
}
New-Item -ItemType Directory -Force -Path builds | Out-Null
& $godotPath --headless --path . --export-release "Windows Desktop" "builds/LostFrequency_dev8.exe"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path builds/LostFrequency_dev8.exe)) { throw "Native export failed" }
Write-Host "Native Godot candidate exported. Windows boot/GPU/manual gameplay still require separate verification."
