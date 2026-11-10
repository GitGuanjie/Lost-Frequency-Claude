@echo off
setlocal enableextensions
set "ROOT=%~dp0"
rem %~dp0 ends with a backslash, which would escape the closing quote
rem of the --path argument and break every command below.
set "ROOT=%ROOT:~0,-1%"
set "ENGINE=%~1"
if not defined ENGINE (
    for %%G in (godot.console.exe Godot_v4.5.1-stable_win64_console.exe godot.exe godot4.exe) do (
        if not defined ENGINE for %%P in (%%~$PATH:G) do if not "%%~P"=="" set "ENGINE=%%~P"
    )
)
if not defined ENGINE (
    echo Godot 4.5.1 not found. Pass the console EXE as argument.
    echo Example: RUN_WORLD_LAB_V4_QA_WINDOWS.bat "C:\path	o\Godot_v4.5.1-stable_win64_console.exe"
    exit /b 2
)
"%ENGINE%" --headless --path "%ROOT%" --import
if errorlevel 1 goto :fail
"%ENGINE%" --headless --path "%ROOT%" res://tests/CompileAll.tscn
if errorlevel 1 goto :fail
"%ENGINE%" --headless --path "%ROOT%" --script res://tests/ContinuityTopologyTest.gd
if errorlevel 1 goto :fail
"%ENGINE%" --headless --path "%ROOT%" --script res://tests/ContinuityMacroStructureTest.gd
if errorlevel 1 goto :fail
"%ENGINE%" --headless --path "%ROOT%" --script res://tests/ContinuitySuperDistrictTest.gd
if errorlevel 1 goto :fail
python -m unittest discover -s "%ROOT%tests" -p "test_worldlab*static.py" -q
if errorlevel 1 goto :fail
if "%~2"=="--qa-only" exit /b 0
echo Topology tests passed; now run manual movement, collision, visuals and saves.
"%ENGINE%" --path "%ROOT%" res://labs/Level0ContinuityLab.tscn
exit /b %errorlevel%
:fail
echo FAIL - preserve the error output. This build is not certified.
exit /b 1
