@echo off
title Tool Filter - O C
cd /d "%~dp0"
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Tool-Filter.ps1"
if errorlevel 1 (
  echo.
  echo Tool gap loi. Xem huong dan trong README.md
  pause
)
