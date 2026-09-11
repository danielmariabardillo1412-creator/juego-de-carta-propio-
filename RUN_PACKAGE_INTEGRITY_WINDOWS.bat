@echo off
setlocal EnableExtensions
set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" if not "%PROJECT_DIR:~-2,1%"==":" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "LOG_DIR=%PROJECT_DIR%\diagnostic_logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_DIR%\tools\verify_manifest.ps1" -ProjectRoot "%PROJECT_DIR%" >"%LOG_DIR%\package_integrity_console_latest.log" 2>&1
set "EXIT_CODE=%ERRORLEVEL%"
echo Package integrity exit code: %EXIT_CODE%
exit /b %EXIT_CODE%
