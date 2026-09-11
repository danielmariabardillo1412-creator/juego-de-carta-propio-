@echo off
setlocal EnableExtensions

set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" if not "%PROJECT_DIR:~-2,1%"==":" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "LOG_DIR=%PROJECT_DIR%\diagnostic_logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

set "GODOT_EXE=%~1"
if "%GODOT_EXE%"=="" set "GODOT_EXE=godot"

set "CONSOLE_LOG=%LOG_DIR%\godot_console_latest.log"
set "STATUS_LOG=%LOG_DIR%\launcher_status_latest.txt"
set "INTEGRITY_LOG=%LOG_DIR%\package_integrity_console_latest.log"

>"%STATUS_LOG%" echo Universal Card Engine diagnostic launcher
>>"%STATUS_LOG%" echo Project: %PROJECT_DIR%
>>"%STATUS_LOG%" echo Godot command: %GODOT_EXE%
>>"%STATUS_LOG%" echo Started: %DATE% %TIME%

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_DIR%\tools\verify_manifest.ps1" -ProjectRoot "%PROJECT_DIR%" >"%INTEGRITY_LOG%" 2>&1
set "INTEGRITY_EXIT=%ERRORLEVEL%"
>>"%STATUS_LOG%" echo Package integrity exit code: %INTEGRITY_EXIT%

"%GODOT_EXE%" --headless --path "%PROJECT_DIR%" --script res://tests/diagnostics/run_engine_diagnostics.gd >"%CONSOLE_LOG%" 2>&1
set "EXIT_CODE=%ERRORLEVEL%"

>>"%STATUS_LOG%" echo Godot diagnostic exit code: %EXIT_CODE%
>>"%STATUS_LOG%" echo Finished: %DATE% %TIME%
>>"%STATUS_LOG%" echo Console log: %CONSOLE_LOG%

if not "%INTEGRITY_EXIT%"=="0" (
    echo WARNING: package integrity failed. See "%INTEGRITY_LOG%".
)
echo Diagnostic finished with exit code %EXIT_CODE%.
echo Console log: "%CONSOLE_LOG%"
echo Structured report: "%LOG_DIR%\uce_diagnostic_latest.json"
echo Human report: "%LOG_DIR%\uce_diagnostic_latest.txt"
exit /b %EXIT_CODE%
