@echo off
REM ===========================================================================
REM  LOST FREQUENCY - Infinite Backrooms v5 : native verification suite
REM
REM  Usage:  RUN_V5_QA_WINDOWS.bat "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
REM
REM  Runs, in order:
REM    1. asset import
REM    2. CompileAll            - every GDScript in the project compiles
REM    3. ContinuityTopologyTest     - coordinate / face / stair invariants
REM    4. ContinuityMacroStructureTest - 4x4 macro hall invariants
REM    5. ContinuitySuperDistrictTest  - 8x8 superdistrict invariants
REM    6. ContinuityRegionalPlanTest   - the v5 multiscale plan invariants
REM    7. ContinuityPhysicalWalkTest   - a real body walks the generated world
REM    8. the offline Python contracts
REM
REM  Every step is a gate: the first failure stops the run.
REM ===========================================================================
setlocal enableextensions
set "ROOT=%~dp0"
rem %~dp0 ends with a backslash, which would escape the closing quote
rem of the --path argument and break every command below.
set "ROOT=%ROOT:~0,-1%"
set "ENGINE=%~1"
set "PYTHONUTF8=1"

if not defined ENGINE (
    for %%G in (godot.console.exe Godot_v4.7.2-stable_win64_console.exe Godot_v4.7.1-stable_win64_console.exe Godot_v4.5.1-stable_win64_console.exe godot.exe godot4.exe) do (
        if not defined ENGINE for %%P in (%%~$PATH:G) do if not "%%~P"=="" set "ENGINE=%%~P"
    )
)
if not defined ENGINE (
    echo Godot console executable not found.
    echo Usage: RUN_V5_QA_WINDOWS.bat "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
    exit /b 2
)

echo Project: "%ROOT%"
echo Engine:  "%ENGINE%"
echo.

echo == 1/8 asset import ==
"%ENGINE%" --headless --path "%ROOT%" --import
if errorlevel 1 goto :fail

echo == 2/8 CompileAll ==
"%ENGINE%" --headless --path "%ROOT%" res://tests/CompileAll.tscn
if errorlevel 1 goto :fail

echo == 3/8 ContinuityTopologyTest ==
"%ENGINE%" --headless --path "%ROOT%" --script res://tests/ContinuityTopologyTest.gd
if errorlevel 1 goto :fail

echo == 4/8 ContinuityMacroStructureTest ==
"%ENGINE%" --headless --path "%ROOT%" --script res://tests/ContinuityMacroStructureTest.gd
if errorlevel 1 goto :fail

echo == 5/8 ContinuitySuperDistrictTest ==
"%ENGINE%" --headless --path "%ROOT%" --script res://tests/ContinuitySuperDistrictTest.gd
if errorlevel 1 goto :fail

echo == 6/8 ContinuityRegionalPlanTest ==
"%ENGINE%" --headless --path "%ROOT%" --script res://tests/ContinuityRegionalPlanTest.gd
if errorlevel 1 goto :fail

echo == 7/8 ContinuityPhysicalWalkTest (real physics) ==
"%ENGINE%" --headless --path "%ROOT%" --fixed-fps 60 res://tests/ContinuityPhysicalWalkTest.tscn
if errorlevel 1 goto :fail

echo == 8/8 offline Python contracts ==
python -m unittest discover -s "%ROOT%\tests" -p "test_worldlab*static.py" -q
if errorlevel 1 goto :fail

echo.
echo ============================================================
echo  ALL NATIVE CHECKS PASSED
echo  The world compiles, the plan is self-consistent, a real
echo  body walks it, and the offline contracts hold.
echo  A Windows export still has to be produced and run on a
echo  real Windows system before it may be called a release.
echo ============================================================
exit /b 0

:fail
echo.
echo FAILED - preserve the console output above. This build is not certified.
exit /b 1
