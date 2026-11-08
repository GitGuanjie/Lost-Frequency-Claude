# Native Godot 4.5.1 Windows development export with fail-closed QA.
# Not an endorsement of an untested binary; manual Windows GPU test is required.
param(
 [Parameter(Mandatory=$true)][string]$GodotExe,
 [switch]$Story,
 [switch]$Full
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Test-Path -LiteralPath $GodotExe)) { throw "Godot executable not found: $GodotExe" }
$py = @('tools/run_dev17_qa.py','--godot',$GodotExe)
if ($Story) { $py += '--story' }
if ($Full) { $py += '--full' }
& python @py
if ($LASTEXITCODE -ne 0) { throw 'Dev17 Godot QA failed: no Windows export permitted.' }
$summaryPath = Join-Path $PSScriptRoot 'reports/qa/v150_dev17/batch_summary.json'
if (-not (Test-Path $summaryPath)) { throw 'Missing fresh engine QA summary' }
$summary = Get-Content -Raw $summaryPath | ConvertFrom-Json
if ($summary.version -ne '1.5.0-dev17' -or $summary.status -ne 'PASS') {
 throw 'Wrong, stale or failing Godot QA evidence'
}
$dest = Join-Path $PSScriptRoot 'export/windows/LostFrequency_v1.5.0-dev17_EXPERIMENTAL.exe'
New-Item -ItemType Directory -Force (Split-Path -Parent $dest) | Out-Null
if (Test-Path $dest) { Remove-Item $dest -Force }
& $GodotExe --headless --path $PSScriptRoot --export-debug 'Windows Desktop' $dest
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $dest) -or (Get-Item $dest).Length -lt 1000000) {
 throw 'Godot did not export a new Windows EXE'
}
Write-Host "Experimental Windows export: $dest"
Write-Host 'STILL REQUIRES launch/physics/nav/FPS/visual review on actual Windows hardware.'
