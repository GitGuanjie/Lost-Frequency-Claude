param([Parameter(Mandatory=$true)][string]$GodotExe, [switch]$Release)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$godotPath = (Resolve-Path $GodotExe).Path
python -m unittest discover -s tests/static -v
if ($LASTEXITCODE -ne 0) { throw "Static tests failed" }
python tools/world_audit.py --fail-on-issues
if ($LASTEXITCODE -ne 0) { throw "World integrity audit failed" }
python tools/run_dev6_qa.py --godot $godotPath
if ($LASTEXITCODE -ne 0) { throw "Godot QA failed; refusing release build" }
if ($Release) {
    python tools/production_gate.py --release
    if ($LASTEXITCODE -ne 0) { throw "Manual Windows evidence incomplete; refusing stable release" }
}
New-Item -ItemType Directory -Force -Path "builds" | Out-Null
& $godotPath --headless --path . --export-release "Windows Desktop" "builds/LostFrequency_dev6.exe"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path "builds/LostFrequency_dev6.exe")) { throw "Native Godot export failed" }
Write-Host "Native Windows candidate exported. Manual launch and GPU checks are STILL REQUIRED before stable release." 
