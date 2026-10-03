@echo off
setlocal
cd /d "%~dp0"
where godot >nul 2>&1
if errorlevel 1 (
  echo Godot 4.7 or newer is required on PATH. Tested with 4.7.2. Engine not bundled.
  pause
  exit /b 1
)
echo Preparing Hanoi - After Dark...
godot --headless --path "%~dp0godot" --editor --import
if errorlevel 1 exit /b 1
godot --path "%~dp0godot" %*
exit /b %errorlevel%
