param([Parameter(Mandatory=$true)][string]$GodotExe)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Test-Path -LiteralPath $GodotExe)) { throw "Godot executable not found: $GodotExe" }
python .\tools\run_dev23_qa.py --godot $GodotExe
if ($LASTEXITCODE -ne 0) { throw 'DEV23 Godot native QA FAILED. Open reports/qa/v150_dev23/summary.json' }
Write-Host 'DEV23 native QA passed. Human traversal and Windows GPU FPS acceptance still required.'
