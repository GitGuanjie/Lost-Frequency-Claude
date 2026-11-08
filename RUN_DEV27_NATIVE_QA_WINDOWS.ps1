# Native Godot 4.5.1 import/F3/physics/interaction verification. Run on Windows.
param([Parameter(Mandatory=$true)][string]$GodotExe,[int]$TimeoutSeconds=150)
$ErrorActionPreference='Stop'
$Root=$PSScriptRoot
$GodotExe=(Resolve-Path -LiteralPath $GodotExe).Path
$Dir=Join-Path $Root 'reports\qa\dev27_native'
$Logs=Join-Path $Dir 'logs'
$Levels=Join-Path $Dir 'levels'
New-Item -ItemType Directory -Force -Path $Logs,$Levels | Out-Null
$p=Start-Process -FilePath $GodotExe -ArgumentList @('--headless','--editor','--path',"`"$Root`"",'--import') -PassThru -RedirectStandardOutput (Join-Path $Logs 'import.log') -RedirectStandardError (Join-Path $Logs 'import.err')
if(-not $p.WaitForExit(600000)) {Stop-Process -Id $p.Id -Force; throw 'Godot import timed out'}
if($p.ExitCode -ne 0) {throw 'Godot native import failed; inspect logs/import.err'}
$items=@()
foreach($sid in @('L016','L024','L029','L077','L140','L737','L899','L998')) {
 $report=Join-Path $Levels "$sid.json"
 Remove-Item -LiteralPath $report -ErrorAction SilentlyContinue
 $status='FAIL';$reason='no native report';$code=-1
 try {
  $p=Start-Process -FilePath $GodotExe -ArgumentList @('--headless','--path',"`"$Root`"",'res://tests/Dev27FieldSectorsProbe.tscn','--','--qa',"--level=$sid") -PassThru -RedirectStandardOutput (Join-Path $Logs "$sid.log") -RedirectStandardError (Join-Path $Logs "$sid.err")
  if(-not $p.WaitForExit($TimeoutSeconds*1000)) {Stop-Process -Id $p.Id -Force; $reason='timeout'}
  else {$code=$p.ExitCode; if(Test-Path $report) {$o=Get-Content -Raw -Encoding UTF8 $report | ConvertFrom-Json;$reason=$o.note;if($code -eq 0 -and $o.status -eq 'PASS'){$status='PASS'}}}
 } catch {$reason="engine error: $_"}
 $items += [PSCustomObject]@{Level=$sid;Status=$status;ExitCode=$code;Reason=$reason}
 $items | Export-Csv (Join-Path $Dir 'summary.csv') -NoTypeInformation -Encoding UTF8
 Write-Host "$sid $status $reason"
}
if(@($items | Where-Object {$_.Status -ne 'PASS'}).Count -gt 0){exit 1}
Write-Host 'All 8 dev27 native checks passed.'
