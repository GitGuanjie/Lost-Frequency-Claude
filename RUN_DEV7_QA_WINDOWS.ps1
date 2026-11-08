param([Parameter(Mandatory=$true)][string]$GodotExe, [switch]$Story)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$godotPath=(Resolve-Path $GodotExe).Path
python -m unittest discover -s tests/static -v
if ($LASTEXITCODE -ne 0) { throw "Static tests failed" }
python tools/world_audit.py --fail-on-issues
if ($LASTEXITCODE -ne 0) { throw "World audit failed" }
$qa=@("tools/run_dev7_qa.py","--godot",$godotPath)
if ($Story) { $qa+="--story" }
python @qa
if ($LASTEXITCODE -ne 0) { throw "Godot QA failed; do not publish" }
Write-Host "Headless QA passed for selected stages; GPU and Windows playtest STILL REQUIRED."
