param([Parameter(Mandatory=$true)][string]$GodotExe, [switch]$Release)
$ErrorActionPreference="Stop"
Set-Location $PSScriptRoot
$godotPath=(Resolve-Path $GodotExe).Path
& "$PSScriptRoot/RUN_DEV7_QA_WINDOWS.ps1" -GodotExe $godotPath -Story
if ($LASTEXITCODE -ne 0) { throw "Godot validation failed" }
if ($Release) {
  python tools/production_gate_dev7.py --release
  if ($LASTEXITCODE -ne 0) { throw "Missing all-level Windows/manual evidence; refusing stable release" }
}
New-Item -ItemType Directory -Force -Path builds | Out-Null
& $godotPath --headless --path . --export-release "Windows Desktop" "builds/LostFrequency_dev7.exe"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path builds/LostFrequency_dev7.exe)) { throw "Official export failed" }
Write-Host "Native candidate built. Windows launch, GPU and human gameplay still need separate verification."
