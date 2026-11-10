<#
  LOST FREQUENCY - Infinite Backrooms v5 : per-gate verification runner.

  Runs every verification gate and records EVERY gate result, including the
  gates that fail.  The upstream RUN_V5_QA_WINDOWS.bat stops at the first
  failure, which hides the shape of a broken baseline; this runner reports
  the whole table and writes a machine-readable JSON summary.

  Usage:
    powershell -ExecutionPolicy Bypass -File tools/run_v5_gates.ps1 `
        -Engine "C:\Godot\Godot_v4.5.1-stable_win64_console.exe" `
        -Python "C:\Python\python.exe" `
        -OutDir "reports/infinite_world"

  Exit code 0 only when every gate passed.
#>
param(
  [string]$Engine = 'E:\cherry mimo ccnot\backrooms\_dl\godot451\Godot_v4.5.1-stable_win64_console.exe',
  [string]$Python = 'E:\pythonF\python.exe',
  [string]$OutDir = 'reports/infinite_world',
  [int]$TimeoutSec = 1800,
  [switch]$SkipImport
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$LogDir = Join-Path $Root $OutDir
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

if (-not (Test-Path $Engine)) { throw "Godot executable not found: $Engine" }

$results = @()
function Invoke-Gate {
  param([string]$Name, [string[]]$GodotArgs, [string]$LogName, [string]$WorkDir)

  $log = Join-Path $LogDir $LogName
  $sw = [Diagnostics.Stopwatch]::StartNew()
  Push-Location $(if ($WorkDir) { $WorkDir } else { $Root })
  # Godot writes warnings to stderr. Under ErrorActionPreference=Stop the
  # PowerShell host turns that native stderr into a terminating error, which
  # would abort the whole gate table on the first harmless warning.
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    & $Engine @GodotArgs 2>&1 | Out-File -FilePath $log -Encoding utf8
    $code = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $prev
    Pop-Location
  }
  $secs = [Math]::Round($sw.Elapsed.TotalSeconds, 1)
  $status = if ($code -eq 0) { 'PASS' } else { 'FAIL' }
  $script:results += [pscustomobject]@{
    gate = $Name; status = $status; exit_code = $code; seconds = $secs; log = $LogName
  }
  # Write-Host, not Write-Output: the call sites pipe this function into
  # Out-Null, which would discard a Write-Output status line as well.
  Write-Host ("[{0,-4}] {1,-34} exit={2} {3}s" -f $status, $Name, $code, $secs)
  return $code
}

Write-Output "project : $Root"
Write-Output "engine  : $Engine"
Write-Output ""

if (-not $SkipImport) {
  $code = Invoke-Gate -Name '01_asset_import' -GodotArgs @('--headless', '--path', $Root, '--import') -LogName 'gate01_import.log'
}

Invoke-Gate -Name '02_compile_all'        -GodotArgs @('--headless', '--path', $Root, 'res://tests/CompileAll.tscn') -LogName 'gate02_compile.log' | Out-Null
Invoke-Gate -Name '03_continuity_topology' -GodotArgs @('--headless', '--path', $Root, '--script', 'res://tests/ContinuityTopologyTest.gd') -LogName 'gate03_topology.log' | Out-Null
Invoke-Gate -Name '04_continuity_macro'    -GodotArgs @('--headless', '--path', $Root, '--script', 'res://tests/ContinuityMacroStructureTest.gd') -LogName 'gate04_macro.log' | Out-Null
Invoke-Gate -Name '05_continuity_super'    -GodotArgs @('--headless', '--path', $Root, '--script', 'res://tests/ContinuitySuperDistrictTest.gd') -LogName 'gate05_super.log' | Out-Null
Invoke-Gate -Name '06_continuity_plan'     -GodotArgs @('--headless', '--path', $Root, '--script', 'res://tests/ContinuityRegionalPlanTest.gd') -LogName 'gate06_plan.log' | Out-Null
Invoke-Gate -Name '07_physical_walk'       -GodotArgs @('--headless', '--path', $Root, '--fixed-fps', '60', 'res://tests/ContinuityPhysicalWalkTest.tscn') -LogName 'gate07_walk.log' | Out-Null
Invoke-Gate -Name '09_canon_transition'    -GodotArgs @('--headless', '--path', $Root, '--fixed-fps', '60', 'res://tests/ContinuityCanonTransitionTest.tscn') -LogName 'gate09_canon.log' | Out-Null
Invoke-Gate -Name '10_performance_probe'   -GodotArgs @('--headless', '--path', $Root, '--fixed-fps', '60', 'res://tests/ContinuityPerformanceProbe.tscn') -LogName 'gate10_performance.log' | Out-Null

# 08: the offline Python contracts
$pyLog = Join-Path $LogDir 'gate08_python.log'
$sw = [Diagnostics.Stopwatch]::StartNew()
Push-Location $Root
$prev = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
  $env:PYTHONUTF8 = '1'
  & $Python -m unittest discover -s (Join-Path $Root 'tests') -p 'test_worldlab*static.py' -q 2>&1 |
    Out-File -FilePath $pyLog -Encoding utf8
  $code = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $prev
  Pop-Location
}
$status = if ($code -eq 0) { 'PASS' } else { 'FAIL' }
$results += [pscustomobject]@{
  gate = '08_python_contracts'; status = $status; exit_code = $code
  seconds = [Math]::Round($sw.Elapsed.TotalSeconds, 1); log = 'gate08_python.log'
}
Write-Host ("[{0,-4}] {1,-34} exit={2} {3}s" -f $status, '08_python_contracts', $code, [Math]::Round($sw.Elapsed.TotalSeconds, 1))

$failed = @($results | Where-Object { $_.status -ne 'PASS' })
$summary = [pscustomobject]@{
  engine = $Engine
  python = $Python
  project = $Root
  gates = $results
  total = $results.Count
  passed = @($results | Where-Object { $_.status -eq 'PASS' }).Count
  failed = $failed.Count
}
$summary | ConvertTo-Json -Depth 5 | Out-File -FilePath (Join-Path $LogDir 'v5_gate_summary.json') -Encoding utf8

Write-Output ""
Write-Output ("passed {0}/{1}" -f $summary.passed, $summary.total)
if ($failed.Count -gt 0) {
  Write-Output "FAILED GATES:"
  $failed | ForEach-Object { Write-Output ("  {0} exit={1} ({2})" -f $_.gate, $_.exit_code, $_.log) }
  exit 1
}
Write-Output "ALL GATES PASSED"
exit 0
