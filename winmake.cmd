@echo off
setlocal
REM Simple wrapper to run PowerShell script with same args
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0winmake.ps1" %*
endlocal
