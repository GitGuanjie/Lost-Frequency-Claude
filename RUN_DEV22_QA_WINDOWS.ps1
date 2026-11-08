# DEV22: mandatory Godot 4.5.1 engine smoke, no false successful releases.
param([Parameter(Mandatory=$true)][string]$GodotExe)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Test-Path -LiteralPath $GodotExe)) { throw "Godot executable not found: $GodotExe" }
python tools/run_dev22_qa.py --godot $GodotExe
if ($LASTEXITCODE -ne 0) { throw 'DEV22 engine smoke failed. Do NOT publish as playable.' }
Write-Host 'Godot headless smoke passed; still requires manual player traversal and Windows FPS testing.'
