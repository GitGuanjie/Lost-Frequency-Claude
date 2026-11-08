# Run in PowerShell from the extracted v1.5.0-dev5 source root.
param(
  [string]$GodotExe = 'godot',
  [string[]]$Level = @(),
  [switch]$Story
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
python -m unittest discover -s tests\static -v
if ($LASTEXITCODE -ne 0) { throw 'Static integrity gates failed' }
python tools\world_audit.py --fail-on-issues
if ($LASTEXITCODE -ne 0) { throw 'Manifest and arrival audit failed' }
$cmd = @('tools\run_dev5_qa.py','--godot',$GodotExe)
foreach ($sid in $Level) { $cmd += @('--level',$sid) }
if ($Story) { $cmd += '--story' }
python @cmd
if ($LASTEXITCODE -ne 0) { throw 'Godot import/QA failed. Inspect reports\qa\v150_dev5\batch_summary.json' }
Write-Host 'Headless engine QA complete; Windows GPU/performance and human play are separate gates.'
