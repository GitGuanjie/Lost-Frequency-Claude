# Run from the source root: .\RUN_DEV1_QA_WINDOWS.ps1 -GodotExe "C:\Godot\Godot_v4.5.1-stable_win64_console.exe" -Story
# Does not bypass Windows execution policy. Invoke explicitly from an authorized shell.
param(
  [string]$GodotExe = "godot",
  [switch]$Story
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
python tools\preflight_dev.py
if ($LASTEXITCODE -ne 0) { throw "Static source preflight failed" }
python -m unittest discover -s tests\static -v
if ($LASTEXITCODE -ne 0) { throw "Offline integrity tests failed" }
$arguments = @('tools\run_dev1_qa.py', '--godot', $GodotExe)
if ($Story) { $arguments += '--story' }
python @arguments
if ($LASTEXITCODE -ne 0) { throw "Godot QA failed; see reports\qa\v150_dev1\batch_summary.json" }
Write-Host 'Engine QA passed; human visual/performance acceptance still required.'
