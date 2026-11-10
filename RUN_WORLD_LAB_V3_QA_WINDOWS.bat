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
    echo Godot 4.5.1 executable not found.
    echo Usage: RUN_WORLD_LAB_V3_QA_WINDOWS.bat "C:\path\to\Godot_v4.5.1-stable_win64_console.exe"
    exit /b 2
)
echo Project: "%ROOT%"
echo Engine:  "%ENGINE%"
"%ENGINE%" --headless --path "%ROOT%" --import
if errorlevel 1 goto :fail
"%ENGINE%" --headless --path "%ROOT%" res://tests/CompileAll.tscn
if errorlevel 1 goto :fail
"%ENGINE%" --headless --path "%ROOT%" --script res://tests/ContinuityTopologyTest.gd
if errorlevel 1 goto :fail
"%ENGINE%" --headless --path "%ROOT%" --script res://tests/ContinuityMacroStructureTest.gd
if errorlevel 1 goto :fail
echo.
echo Static Godot checks passed. Launching lab for manual physical traversal.
echo This does NOT certify Windows export, GPU performance or player QA.
"%ENGINE%" --path "%ROOT%" res://labs/Level0ContinuityLab.tscn
exit /b %errorlevel%
:fail
echo.
echo FAILED. Preserve the console output and do not promote the build.
exit /b 1
