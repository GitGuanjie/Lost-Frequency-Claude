param([Parameter(Mandatory=$true)][string]$GodotExe, [switch]$Story)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$godotPath = (Resolve-Path $GodotExe -ErrorAction Stop).Path
python -m unittest discover -s tests/static -v
if ($LASTEXITCODE -ne 0) { throw "Static regression failed" }
python tools/world_audit.py --fail-on-issues
if ($LASTEXITCODE -ne 0) { throw "World graph audit failed" }
$argsList = @("tools/run_dev8_qa.py", "--godot", $godotPath)
if ($Story) { $argsList += "--story" }
python @argsList
if ($LASTEXITCODE -ne 0) { throw "Godot QA failed (see reports/qa/v150_dev8); do not publish" }
Write-Host "Headless Godot QA completed. Windows GPU/manual playtest STILL REQUIRED."
