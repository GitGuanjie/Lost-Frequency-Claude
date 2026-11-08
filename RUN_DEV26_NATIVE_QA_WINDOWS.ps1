# DEV26 engine acceptance, NOT static-only. Godot 4.5.1 Standard required.
param([Parameter(Mandatory=$true)][string]$GodotExe, [int]$TimeoutSeconds = 150)
$ErrorActionPreference = 'Stop'
$Project = $PSScriptRoot
$GodotExe = (Resolve-Path -LiteralPath $GodotExe).Path
$Output = Join-Path $Project 'reports\qa\dev26_native'
$Logs = Join-Path $Output 'logs'
$Levels = Join-Path $Output 'levels'
New-Item -ItemType Directory -Force -Path $Logs,$Levels | Out-Null
$importOut = Join-Path $Logs 'import.log'
$importErr = Join-Path $Logs 'import.err'
$p = Start-Process -FilePath $GodotExe -ArgumentList @('--headless','--editor','--path',"`"$Project`"",'--import') -PassThru -RedirectStandardOutput $importOut -RedirectStandardError $importErr
if (-not $p.WaitForExit(600000)) { Stop-Process -Id $p.Id -Force; throw 'Godot import timed out' }
if ($p.ExitCode -ne 0) { throw "Godot import failed; inspect $importErr" }
$records = @()
foreach ($sid in @('L052','L053','L058','L060','L079','L083','L090','L096','L101','L114','L160','L197','L071')) {
    $out = Join-Path $Logs "$sid.log"
    $err = Join-Path $Logs "$sid.err"
    $report = Join-Path $Levels "$sid.json"
    Remove-Item -LiteralPath $report -Force -ErrorAction SilentlyContinue
    $status = 'FAIL'
    $reason = 'no native report produced'
    $exitCode = -1
    try {
        $p = Start-Process -FilePath $GodotExe -ArgumentList @('--headless','--path',"`"$Project`"",'res://tests/Dev26ExperienceProbe.tscn','--','--qa',"--level=$sid") -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
        if (-not $p.WaitForExit($TimeoutSeconds * 1000)) { Stop-Process -Id $p.Id -Force; $reason = 'timeout' }
        else {
            $exitCode = $p.ExitCode
            if (Test-Path -LiteralPath $report) {
                $result = Get-Content -Raw -Encoding UTF8 $report | ConvertFrom-Json
                $reason = [string]$result.reason
                if ($result.status -eq 'PASS' -and $exitCode -eq 0) { $status = 'PASS' }
            }
        }
    } catch { $reason = "Godot could not execute: $_" }
    $records += [PSCustomObject]@{Level=$sid;Status=$status;ExitCode=$exitCode;Reason=$reason}
    $records | Export-Csv -Path (Join-Path $Output 'summary.csv') -NoTypeInformation -Encoding UTF8
    Write-Host "$sid : $status : $reason"
}
if (@($records | Where-Object {$_.Status -ne 'PASS'}).Count -gt 0) { exit 1 }
Write-Host 'All 13 DEV26 native experience tests passed.'
