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
echo Godot 4.5.1 was not found. Install it or drag its console EXE onto this BAT.
echo The source project is not a standalone Windows game.
pause
exit /b 1
:run
"%GODOT%" --path "%ROOT%" res://labs/Level0ContinuityLab.tscn
if errorlevel 1 (
  echo The lab failed to launch. Check the Godot console errors.
  pause
  exit /b 1
)
endlocal
