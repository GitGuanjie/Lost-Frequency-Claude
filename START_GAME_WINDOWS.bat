@echo off
REM LOST FREQUENCY - run from source with Godot 4.5.x on PATH (or set GODOT=path\to\Godot.exe)
if "%GODOT%"=="" set GODOT=godot
"%GODOT%" --path "%~dp0"
