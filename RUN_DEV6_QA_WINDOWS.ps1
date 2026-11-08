param(
    [Parameter(Mandatory=$true)][string]$GodotExe,
    [switch]$Story
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$godotPath = (Resolve-Path $GodotExe).Path
python -m unittest discover -s tests/static -v
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python tools/world_audit.py --fail-on-issues
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$argsQA = @("tools/run_dev6_qa.py", "--godot", $godotPath)
if ($Story) { $argsQA += "--story" }
python @argsQA
exit $LASTEXITCODE
