@echo off
REM LOST FREQUENCY - engine-executed QA (writes reports\qa\latest_results.json)
if "%GODOT%"=="" set GODOT=godot
cd /d "%~dp0"
"%GODOT%" --headless --path . --import
"%GODOT%" --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa %*
echo QA exit code: %ERRORLEVEL%
pause
