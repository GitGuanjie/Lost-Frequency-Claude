# Native Godot 4.5.1 targeted QA. Nothing is marked validated without a fresh report.
param(
 [Parameter(Mandatory=$true)][string]$GodotExe,
 [switch]$Story,
 [switch]$Full
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Test-Path -LiteralPath $GodotExe)) { throw "Godot executable not found: $GodotExe" }
$argsList = @('tools/run_dev11_qa.py','--godot',$GodotExe)
if ($Story) { $argsList += '--story' }
if ($Full) { $argsList += '--full' }
& python @argsList
if ($LASTEXITCODE -ne 0) { throw 'dev11 Godot QA failed; do not distribute as verified.' }
Write-Host 'Godot headless QA complete. Manual Windows gameplay/GPU test remains required.'
