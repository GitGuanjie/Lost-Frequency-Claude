# Debug export only when fresh DEV24 Godot import+physics+GLB+E QA succeeds.
param([Parameter(Mandatory=$true)][string]$GodotExe)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Test-Path -LiteralPath $GodotExe)) { throw "Godot executable not found: $GodotExe" }
python tools/run_dev24_qa.py --godot $GodotExe
if ($LASTEXITCODE -ne 0) { throw 'DEV24 native QA failed: Windows export denied.' }
$summaryPath = Join-Path $PSScriptRoot 'reports/qa/v150_dev24/summary.json'
if (-not (Test-Path $summaryPath)) { throw 'DEV24 native QA report missing' }
$summary = Get-Content -Raw $summaryPath | ConvertFrom-Json
if ($summary.version -ne '1.5.0-dev24' -or $summary.status -ne 'PASS' -or -not $summary.engine_certified) {
 throw 'DEV24 native QA incomplete or stale'
}
$dest = Join-Path $PSScriptRoot 'export/windows/LostFrequency_v1.5.0-dev24_EXPERIMENTAL.exe'
New-Item -ItemType Directory -Force (Split-Path -Parent $dest) | Out-Null
& $GodotExe --headless --path $PSScriptRoot --export-debug 'Windows Desktop' $dest
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $dest) -or (Get-Item $dest).Length -lt 1000000) {
 throw 'Windows debug export did not complete'
}
Write-Host "Experimental Windows build: $dest"
Write-Host 'Manual walkable route review + gameplay testing are required before any release claim.'
