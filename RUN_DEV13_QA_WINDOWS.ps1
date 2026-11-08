# Dev13 native Godot 4.5.1 validation; fail closed.
param(
 [Parameter(Mandatory=$true)][string]$GodotExe,
 [switch]$Story,
 [switch]$Full
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Test-Path -LiteralPath $GodotExe)) { throw "Godot executable not found: $GodotExe" }
$argsList = @('tools/run_dev13_qa.py','--godot',$GodotExe)
if ($Story) { $argsList += '--story' }
if ($Full) { $argsList += '--full' }
& python @argsList
if ($LASTEXITCODE -ne 0) { throw 'Dev13 Godot QA failed. Do not mark Windows build verified.' }
Write-Host 'Godot headless QA complete. Manual Windows gameplay/GPU validation still required.'
