# Native Godot export on Windows. Unlike the experimental ZIP, this uses
# installed Godot 4.5.1 export templates and compiles/imports the real project.
param(
  [string]$GodotExe = 'godot',
  [switch]$SkipQa
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$destination = Join-Path $PSScriptRoot 'export\windows_dev3_native'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Write-Host '[1/4] Source integrity checks'
python -m unittest discover -s tests\static -p 'test_*.py' -v
if ($LASTEXITCODE -ne 0) { throw 'Source checks failed' }
Write-Host '[2/4] Import project using native Godot'
& $GodotExe --headless --path $PSScriptRoot --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed: inspect stderr' }
if (-not $SkipQa) {
  Write-Host '[3/4] Run focused engine QA (will fail closed)'
  python tools\run_dev3_qa.py --godot $GodotExe
  if ($LASTEXITCODE -ne 0) { throw 'Engine QA failed. New levels remain IN_DEVELOPMENT.' }
} else {
  Write-Warning 'QA explicitly skipped: output is only an UNVERIFIED DEVELOPMENT build.'
}
Write-Host '[4/4] Native Windows export with installed templates'
$exe = Join-Path $destination 'LostFrequency.exe'
if (Test-Path $exe) { Remove-Item $exe -Force }
& $GodotExe --headless --path $PSScriptRoot --export-release 'Windows Desktop' $exe
if ($LASTEXITCODE -ne 0) { throw 'Native Windows export failed. Install Godot 4.5.1 export templates.' }
if (-not (Test-Path $exe) -or (Get-Item $exe).Length -lt 10000000) { throw 'Export did not produce a plausible EXE.' }
$readme = Join-Path $destination 'BUILD_STATUS.txt'
if ($SkipQa) {
    'UNVERIFIED development export: source gates and Godot import only. Run full QA before public release.' | Set-Content $readme
} else {
    'Native Windows export: focused headless QA passed; requires GPU and human-play verification before release.' | Set-Content $readme
}
Copy-Item LICENSE.md (Join-Path $destination 'LICENSE.md') -Force
Write-Host "Output: $exe"
