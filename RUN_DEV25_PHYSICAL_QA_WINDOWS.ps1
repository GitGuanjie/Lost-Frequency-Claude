# Native physics/interaction tests for DEV25. Requires Godot 4.5.1 Standard.
# Runs six themed levels separately; failure of one will not mask the others.
param(
    [Parameter(Mandatory=$true)][string]$GodotExe,
    [int]$TimeoutSeconds = 150
)
$ErrorActionPreference = 'Stop'
$Project = $PSScriptRoot
$GodotExe = (Resolve-Path -LiteralPath $GodotExe).Path
$Report = Join-Path $Project 'reports\qa\dev25_physical'
$Logs = Join-Path $Report 'logs'
$Levels = Join-Path $Report 'levels'
New-Item -ItemType Directory -Force -Path $Logs,$Levels | Out-Null
$importLog = Join-Path $Logs 'import.log'
$importErr = Join-Path $Logs 'import.err'
Write-Host 'Importing Godot project with native 4.5.1 engine...'
$p = Start-Process -FilePath $GodotExe -ArgumentList @('--headless','--editor','--path',"`"$Project`"",'--import') -PassThru -RedirectStandardOutput $importLog -RedirectStandardError $importErr
if (-not $p.WaitForExit(600000)) { Stop-Process -Id $p.Id -Force; throw 'Godot import timed out' }
if ($p.ExitCode -ne 0) { throw "Godot import failed ($($p.ExitCode)); read $importErr" }
$records = @()
foreach ($sid in @('L041','L048','L100','L140','L149','L201')) {
    $out = Join-Path $Logs "$sid.log"
    $err = Join-Path $Logs "$sid.err"
    $file = Join-Path $Levels "$sid.json"
    Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
    $status = 'FAIL'
    $reason = 'no report'
    $exitCode = -1
    try {
        $p = Start-Process -FilePath $GodotExe -ArgumentList @('--headless','--path',"`"$Project`"",'res://tests/Dev25PhysicalProbe.tscn','--','--qa',"--level=$sid") -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
        if (-not $p.WaitForExit($TimeoutSeconds * 1000)) { Stop-Process -Id $p.Id -Force; $reason = 'timeout' }
        else {
            $exitCode = $p.ExitCode
            if (Test-Path -LiteralPath $file) {
                $result = Get-Content -Raw -Encoding UTF8 $file | ConvertFrom-Json
                $reason = [string]$result.reason
                if ($result.status -eq 'PASS' -and $exitCode -eq 0) { $status = 'PASS' }
            }
        }
    } catch { $reason = "unable to start Godot: $_" }
    $records += [PSCustomObject]@{Level=$sid;Status=$status;ExitCode=$exitCode;Reason=$reason}
    Write-Host "$sid : $status : $reason"
    $records | Export-Csv -Path (Join-Path $Report 'summary.csv') -NoTypeInformation -Encoding UTF8
}
if (@($records | Where-Object { $_.Status -ne 'PASS' }).Count -gt 0) { exit 1 }
Write-Host 'All six DEV25 native physics/interaction checks passed.'
