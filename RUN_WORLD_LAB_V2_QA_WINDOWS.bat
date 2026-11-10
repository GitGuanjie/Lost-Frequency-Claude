@echo off
setlocal
set "ROOT=%~dp0"
rem %~dp0 ends with a backslash, which would escape the closing quote
rem of the --path argument and break every command below.
set "ROOT=%ROOT:~0,-1%"
set "GODOT=%~1"
if not "%GODOT%"=="" goto run
if exist "%ROOT%Godot_v4.5.1-stable_win64_console.exe" set "GODOT=%ROOT%Godot_v4.5.1-stable_win64_console.exe"
if not "%GODOT%"=="" goto run
for %%G in (godot.exe Godot_v4.5.1-stable_win64_console.exe godot4.exe) do (
  if "%GODOT%"=="" (
    where %%G >nul 2>&1
    if not errorlevel 1 set "GODOT=%%G"
  )
)
if not "%GODOT%"=="" goto run
echo Godot 4.5.1 Console executable not found. Pass its full path as first argument.
pause
exit /b 1
:run
echo Checking Godot resource import...
"%GODOT%" --headless --path "%ROOT%" --import || goto failed
echo Checking all scripts...
"%GODOT%" --headless --path "%ROOT%" res://tests/CompileAll.tscn || goto failed
echo Checking 3D continuum contract...
"%GODOT%" --headless --path "%ROOT%" --script res://tests/ContinuityTopologyTest.gd || goto failed
echo PASS for engine import and tests. Physics walk and FPS still need interactive QA.
pause
exit /b 0
:failed
echo FAILED: inspect the console output; do not treat the source as a validated release.
pause
exit /b 1
