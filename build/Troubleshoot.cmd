@echo off
title Tool Filter - Troubleshoot
cd /d "%~dp0"
echo ============================================
echo  Tool Filter - che do kiem tra loi
echo  Cua so nay hien thong bao loi cua PowerShell
echo ============================================
echo.
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0resources\Tool-Filter.ps1"
echo.
echo Ma thoat: %ERRORLEVEL%
pause
