# Experimental export gated by *fresh* dev22 AND inherited dev21 QA.
# A Windows EXE alone never proves that all structures are actually walkable.
param([Parameter(Mandatory=$true)][string]$GodotExe)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Test-Path -LiteralPath $GodotExe)) { throw "Godot executable not found: $GodotExe" }
python tools/run_dev22_qa.py --godot $GodotExe
if ($LASTEXITCODE -ne 0) { throw 'DEV22 native QA failed: export denied.' }
$summaryPath = Join-Path $PSScriptRoot 'reports/qa/v150_dev22/batch_summary.json'
if (-not (Test-Path $summaryPath)) { throw 'Missing fresh DEV22 native QA evidence' }
$summary = Get-Content -Raw $summaryPath | ConvertFrom-Json
if ($summary.version -ne '1.5.0-dev22' -or $summary.status -ne 'PASS' -or -not $summary.engine_certified) {
 throw 'DEV22 evidence is stale or incomplete'
}
$dest = Join-Path $PSScriptRoot 'export/windows/LostFrequency_v1.5.0-dev22_EXPERIMENTAL.exe'
New-Item -ItemType Directory -Force (Split-Path -Parent $dest) | Out-Null
& $GodotExe --headless --path $PSScriptRoot --export-debug 'Windows Desktop' $dest
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $dest) -or (Get-Item $dest).Length -lt 1000000) {
 throw 'Fresh Windows export was not created'
}
Write-Host "Experimental Windows export: $dest"
Write-Host 'Manual route traversal, rendering and performance review are still REQUIRED.'
