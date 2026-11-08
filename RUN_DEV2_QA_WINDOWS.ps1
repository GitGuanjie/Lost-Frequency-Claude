# Run from an authorised PowerShell session, inside the source root.
# Example: .\RUN_DEV2_QA_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64_console.exe"
param(
  [string]$GodotExe = 'godot',
  [string[]]$Level = @(),
  [switch]$Story
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
python -m unittest discover -s tests\static -v
if ($LASTEXITCODE -ne 0) { throw 'Offline source integrity checks failed' }
python tools\world_audit.py
if ($LASTEXITCODE -ne 0) { throw 'World audit failed' }
$arguments = @('tools\run_dev2_qa.py','--godot',$GodotExe)
foreach ($sid in $Level) { $arguments += @('--level',$sid) }
if ($Story) { $arguments += '--story' }
python @arguments
if ($LASTEXITCODE -ne 0) { throw 'Godot QA failed; read reports\qa\v150_dev2\batch_summary.json' }
Write-Host 'Headless engine checks complete. GPU captures and human play are still required.'
