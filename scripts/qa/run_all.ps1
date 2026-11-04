# Engine-executed QA (Windows). Usage: .\scripts\qa\run_all.ps1 [--levels=L000,L005]
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\..")
$godot = if ($env:GODOT) { $env:GODOT } else { "godot" }
& $godot --headless --path . --import
& $godot --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa @args
exit $LASTEXITCODE
