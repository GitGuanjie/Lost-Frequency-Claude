# Test EVERY F3 level in its own fresh Godot 4.5.x headless process.
# One failed/hung level does not prevent testing the remaining levels.
# Requires Windows PowerShell 5.1+ and Godot 4.5.x (no Python required).
param(
    [Parameter(Mandatory=$true)][string]$GodotExe,
    [int]$TimeoutSeconds = 120,
    [string]$Only = ""
)
$ErrorActionPreference = 'Stop'
$Project = $PSScriptRoot
$GodotExe = (Resolve-Path -LiteralPath $GodotExe).Path
$OutputDir = Join-Path $Project 'reports\qa\dev24_entry_100'
$LogDir = Join-Path $OutputDir 'logs'
$LevelDir = Join-Path $OutputDir 'levels'
# The probe writes its result to the entry-audit directory (see
# tests/LevelEntryProbe.gd: REPORT_DIR). This script used to look for it in
# its own `levels` directory, so EVERY level was reported as "No probe result"
# even when the probe had passed - the regression harness reported a failure
# that was really a wrong path.
$AuditDir = Join-Path $Project 'reports\qa\entry_audit\levels'
New-Item -ItemType Directory -Force -Path $LogDir, $LevelDir, $AuditDir | Out-Null
$roster = (Get-Content -Raw -Encoding UTF8 (Join-Path $Project 'data\canon\levels.json') | ConvertFrom-Json).levels
$expected = @($roster | ForEach-Object { $_.stable_id })
if ($expected.Count -ne 100 -or (@($expected | Select-Object -Unique)).Count -ne 100) {
    throw "Unexpected level roster: $($expected.Count) entries. Stopping."
}
if ($Only.Trim() -ne '') {
    $chosen = @($Only.Split(',') | ForEach-Object { $_.Trim().ToUpperInvariant() } | Where-Object { $_ -ne '' })
    foreach ($sid in $chosen) { if ($expected -notcontains $sid) { throw "Unknown --Only level: $sid" } }
} else { $chosen = $expected }

Write-Host "Importing Godot project resources before entry checks..."
$importLog = Join-Path $LogDir 'import.stdout.log'
$importErr = Join-Path $LogDir 'import.stderr.log'
$importProc = Start-Process -FilePath $GodotExe -ArgumentList @('--headless','--editor','--path',"`"$Project`"",'--import') -PassThru -RedirectStandardOutput $importLog -RedirectStandardError $importErr
# Touching .Handle caches the native handle. Without it the Process object
# releases the handle on exit and ExitCode reads as EMPTY, so a successful
# import looks like a failure.
$null = $importProc.Handle
if (-not $importProc.WaitForExit(600000)) {
    Stop-Process -Id $importProc.Id -Force -ErrorAction SilentlyContinue
    throw "Godot asset import exceeded 600 seconds; see $importLog"
}
# Start-Process -PassThru does not populate ExitCode until the process object
# is waited on WITHOUT a timeout. Without this call the exit code of a
# perfectly successful import reads as EMPTY, and "$null -ne 0" is true, so
# the script threw on its own success.
$importProc.WaitForExit()
if ($importProc.ExitCode -ne 0) { throw "Godot asset import failed: exit $($importProc.ExitCode). See $importErr" }

$results = New-Object System.Collections.Generic.List[object]
$index = 0
foreach ($sid in $chosen) {
    $index++
    $log = Join-Path $LogDir ($sid + '.stdout.log')
    $err = Join-Path $LogDir ($sid + '.stderr.log')
    # The probe writes here; the copy in the run's own directory is only an
    # artefact of this run.
    $auditJson = Join-Path $AuditDir ($sid + '.json')
    $json = Join-Path $LevelDir ($sid + '.json')
    Remove-Item -LiteralPath $auditJson -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $json -Force -ErrorAction SilentlyContinue
    $status = 'FAIL'
    $reason = ''
    $exitCode = -1
    $started = Get-Date
    try {
        # --fixed-fps 60 is REQUIRED for a reproducible audit. Without it the
        # frame count before the probe measures the level is not deterministic,
        # and a streamed level has built a different amount of geometry at the
        # moment the metrics are taken: the same L026 measured 675768 / 691180
        # / 698036 triangles in three runs. With the fixed step the number is
        # stable, which is what every other gate in this project does too.
        $p = Start-Process -FilePath $GodotExe -ArgumentList @('--headless','--fixed-fps','60','--path',"`"$Project`"",'res://tests/LevelEntryProbe.tscn','--','--qa',"--level=$sid") -PassThru -RedirectStandardOutput $log -RedirectStandardError $err
        # Cache the handle so the exit code is readable after the process ends.
        $null = $p.Handle
        if (-not $p.WaitForExit($TimeoutSeconds * 1000)) {
            Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
            $reason = "Timeout (${TimeoutSeconds}s): likely hang or very slow build"
        } else {
            # Same as above: the exit code is only populated after a plain
            # WaitForExit().
            $p.WaitForExit()
            $exitCode = $p.ExitCode
            if (Test-Path -LiteralPath $auditJson) {
                $record = Get-Content -Raw -Encoding UTF8 $auditJson | ConvertFrom-Json
                $reason = [string]$record.reason
                if ($exitCode -eq 0 -and $record.status -eq 'PASS') { $status = 'PASS' }
                elseif ($exitCode -ne 0 -and $reason -eq '') { $reason = "Godot exited with code $exitCode" }
                # Keep a copy of the probe report with this run's artefacts.
                try { [System.IO.File]::Copy($auditJson, $json, $true) } catch { }
            } else { $reason = "No probe result (Godot exit code $exitCode); inspect per-level logs" }
        }
    } catch { $reason = "Process launch failed: $_" }
    $elapsed = [math]::Round(((Get-Date) - $started).TotalSeconds, 1)
    $results.Add([PSCustomObject]@{ Level = $sid; Status = $status; Seconds = $elapsed; ExitCode = $exitCode; Reason = $reason })
    $mark = if ($status -eq 'PASS') { '[PASS]' } else { '[FAIL]' }
    Write-Host "[$index/$($chosen.Count)] $mark $sid $reason"
    # Save partial results after EACH level, including if a later level hangs.
    $results | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $OutputDir 'summary.csv')
}
$passed = @($results | Where-Object { $_.Status -eq 'PASS' }).Count
$failed = $results.Count - $passed
$summary = [ordered]@{
    Tested = $results.Count; Passed = $passed; Failed = $failed
    All100Passed = ($chosen.Count -eq 100 -and $failed -eq 0)
    Engine = $GodotExe; Date = (Get-Date).ToUniversalTime().ToString('o')
    # ToArray(), not @($results): the array subexpression operator throws
    # "Argument types do not match" on a List[object] in Windows PowerShell
    # 5.1, and the summary was silently lost.
    Results = $results.ToArray()
}
$summary | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $OutputDir 'summary.json')
Write-Host "RESULT: $passed/$($chosen.Count) entered successfully; $failed failures. Report: $OutputDir\summary.csv"
if ($failed -gt 0) { exit 1 }
exit 0
