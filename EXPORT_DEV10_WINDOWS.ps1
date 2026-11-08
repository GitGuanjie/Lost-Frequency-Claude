# Native Windows Godot 4.5.1 import, asset smoke, targeted 24-level QA and debug export.
# This refuses to export when the batch verification fails. Manual GPU review remains mandatory.
param(
 [Parameter(Mandatory=$true)][string]$GodotExe,
 [switch]$Story
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Test-Path -LiteralPath $GodotExe)) { throw "Godot executable not found: $GodotExe" }
$py = @('tools/run_dev10_qa.py','--godot',$GodotExe)
if ($Story) { $py += '--story' }
& python @py
if ($LASTEXITCODE -ne 0) { throw "Godot QA failed. See reports/qa/v150_dev10/batch_summary.json" }
$summaryPath = Join-Path $PSScriptRoot 'reports/qa/v150_dev10/batch_summary.json'
if (-not (Test-Path $summaryPath)) { throw 'Missing fresh QA summary' }
$summary = Get-Content -Raw $summaryPath | ConvertFrom-Json
if ($summary.version -ne '1.5.0-dev10' -or $summary.status -ne 'PASS') { throw 'Wrong/stale QA evidence' }
$dest = Join-Path $PSScriptRoot 'export/windows/LostFrequency_v1.5.0-dev10_EXPERIMENTAL.exe'
New-Item -ItemType Directory -Force (Split-Path -Parent $dest) | Out-Null
if (Test-Path $dest) { Remove-Item $dest -Force }
& $GodotExe --headless --path $PSScriptRoot --export-debug 'Windows Desktop' $dest
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $dest) -or (Get-Item $dest).Length -lt 1000000) {
 throw 'Native Godot Windows export did not produce a new valid-sized EXE.'
}
Write-Host "EXPERIMENTAL Windows export created: $dest"
Write-Host 'Not a stable release: manual Windows launch, screenshots, FPS, collision/exit and save/load evidence still required.'
