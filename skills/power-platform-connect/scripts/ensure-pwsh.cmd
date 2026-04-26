@echo off
rem ensure-pwsh.cmd — thin Windows launcher
rem Invokes Windows PowerShell 5.1 to bootstrap PowerShell 7, then delegates to check-pac.ps1.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0ensure-pwsh.ps1" %*
exit /b %ERRORLEVEL%
