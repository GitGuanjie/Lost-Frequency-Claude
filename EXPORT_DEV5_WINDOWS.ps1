# Native Godot 4.5.1 Windows release builder. Requires export templates.
param([string]$GodotExe = 'godot', [switch]$SkipQA)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not $SkipQA) {
  & "$PSScriptRoot\RUN_DEV5_QA_WINDOWS.ps1" -GodotExe $GodotExe -Story
  if ($LASTEXITCODE -ne 0) { throw 'QA failed. Native export aborted.' }
}
& $GodotExe --headless --path "$PSScriptRoot" --import
if ($LASTEXITCODE -ne 0) { throw 'Godot source import failed' }
$target = Join-Path $PSScriptRoot 'export\windows\LostFrequency.exe'
New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
if (Test-Path $target) { Remove-Item $target }
& $GodotExe --headless --path "$PSScriptRoot" --export-release 'Windows Desktop' "$target"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $target)) { throw 'Godot native Windows export failed; check export template installation' }
if ((Get-Item $target).Length -lt 10000000) { throw 'Exported EXE is implausibly small' }
Get-FileHash $target -Algorithm SHA256
Write-Host 'Native Windows build created. Run smoke tests on a real Windows desktop before distributing as verified.'
