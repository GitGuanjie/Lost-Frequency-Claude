param([Parameter(Mandatory=$true)][string]$GodotExe)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Test-Path -LiteralPath $GodotExe)) { throw "Godot executable not found: $GodotExe" }
python .\tools\run_dev24_qa.py --godot $GodotExe
if ($LASTEXITCODE -ne 0) { throw 'DEV24 native Godot QA failed. See reports/qa/v150_dev24/summary.json' }
Write-Host 'DEV24 engine tests passed; player-controlled traversal and Windows FPS remain separate.'
