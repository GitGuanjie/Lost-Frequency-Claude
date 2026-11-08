# Strict acceptance for dev28: BOTH 100/100 native F3 entries and nine
# native content/physics/GLB tests. Never report success from static results.
param([Parameter(Mandatory=$true)][string]$GodotExe)
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'RUN_100_LEVEL_ENTRY_QA_WINDOWS.ps1') -GodotExe $GodotExe
if($LASTEXITCODE -ne 0) {throw '100-level native F3 entry test FAILED (see reports/qa/dev24_entry_100/summary.csv)'}
& (Join-Path $PSScriptRoot 'RUN_DEV28_NATIVE_QA_WINDOWS.ps1') -GodotExe $GodotExe
if($LASTEXITCODE -ne 0) {throw 'DEV28 physical/interaction suite FAILED (see reports/qa/dev28_native/summary.csv)'}
Write-Host 'STRICT_NATIVE_ACCEPTANCE: 100 F3 entries plus all DEV28 probes passed.'
