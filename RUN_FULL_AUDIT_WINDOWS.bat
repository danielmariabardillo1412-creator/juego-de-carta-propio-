@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" if not "%PROJECT_DIR:~-2,1%"==":" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "LOG_DIR=%PROJECT_DIR%\diagnostic_logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "STATUS_LOG=%LOG_DIR%\full_audit_status_latest.txt"

set "GODOT_EXE=%~1"
if "%GODOT_EXE%"=="" set "GODOT_EXE=godot"

set /a TOTAL_FAILURES=0
>"%STATUS_LOG%" echo UNIVERSAL CARD ENGINE FULL AUDIT
>>"%STATUS_LOG%" echo Project: %PROJECT_DIR%
>>"%STATUS_LOG%" echo Godot command: %GODOT_EXE%
>>"%STATUS_LOG%" echo Started: %DATE% %TIME%

call :RUN_INTEGRITY
call :RUN_STATIC_AUDIT
call :RUN_TEST diagnostic res://tests/diagnostics/run_engine_diagnostics.gd
call :RUN_TEST uce_01 res://tests/run_uce_01_smoke.gd
call :RUN_TEST uce_02 res://tests/run_uce_02_cards.gd
call :RUN_TEST uce_03 res://tests/run_uce_03_random_deal.gd
call :RUN_TEST uce_f01 res://tests/run_uce_f01_foundations.gd
call :RUN_TEST uce_f02 res://tests/run_uce_f02_cards_hardening.gd
call :RUN_TEST uce_f03 res://tests/run_uce_f03_session_flow.gd
call :RUN_TEST uce_f04 res://tests/run_uce_f04_persistence_sync.gd
call :RUN_TEST uce_f05 res://tests/run_uce_f05_interfaces_ai.gd
call :RUN_TEST complete res://tests/full/run_complete_engine_experiment.gd
call :RUN_MAIN main_scene

echo.
>>"%STATUS_LOG%" echo Finished: %DATE% %TIME%
if !TOTAL_FAILURES! EQU 0 (
    echo FULL AUDIT PASS
    >>"%STATUS_LOG%" echo FINAL=PASS
    exit /b 0
)

echo FULL AUDIT FAIL: !TOTAL_FAILURES! command(s) failed.
>>"%STATUS_LOG%" echo FINAL=FAIL
>>"%STATUS_LOG%" echo Failure count: !TOTAL_FAILURES!
exit /b 1

:RUN_INTEGRITY
set "TEST_LOG=%LOG_DIR%\package_integrity_console_latest.log"
echo Running package_integrity...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_DIR%\tools\verify_manifest.ps1" -ProjectRoot "%PROJECT_DIR%" >"%TEST_LOG%" 2>&1
set "TEST_EXIT=!ERRORLEVEL!"
echo package_integrity exit=!TEST_EXIT!
>>"%STATUS_LOG%" echo package_integrity=!TEST_EXIT!
if not !TEST_EXIT! EQU 0 set /a TOTAL_FAILURES+=1
exit /b 0

:RUN_STATIC_AUDIT
set "TEST_LOG=%LOG_DIR%\static_audit_latest.log"
echo Running static_audit...
where py >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    py -3 "%PROJECT_DIR%\tools\static_audit.py" >"%TEST_LOG%" 2>&1
) else (
    where python >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        python "%PROJECT_DIR%\tools\static_audit.py" >"%TEST_LOG%" 2>&1
    ) else (
        >"%TEST_LOG%" echo SKIP: Python was not found. Packaged STATIC_AUDIT.json remains available.
        set "TEST_EXIT=0"
        echo static_audit skipped: Python unavailable
        >>"%STATUS_LOG%" echo static_audit=SKIP_PYTHON_UNAVAILABLE
        exit /b 0
    )
)
set "TEST_EXIT=!ERRORLEVEL!"
echo static_audit exit=!TEST_EXIT!
>>"%STATUS_LOG%" echo static_audit=!TEST_EXIT!
if not !TEST_EXIT! EQU 0 set /a TOTAL_FAILURES+=1
exit /b 0

:RUN_TEST
set "TEST_NAME=%~1"
set "SCRIPT_PATH=%~2"
set "TEST_LOG=%LOG_DIR%\%TEST_NAME%_latest.log"
echo Running %TEST_NAME%...
"%GODOT_EXE%" --headless --path "%PROJECT_DIR%" --script "%SCRIPT_PATH%" >"%TEST_LOG%" 2>&1
set "TEST_EXIT=!ERRORLEVEL!"
echo %TEST_NAME% exit=!TEST_EXIT!
>>"%STATUS_LOG%" echo %TEST_NAME%=!TEST_EXIT!
if not !TEST_EXIT! EQU 0 set /a TOTAL_FAILURES+=1
exit /b 0

:RUN_MAIN
set "TEST_NAME=%~1"
set "TEST_LOG=%LOG_DIR%\%TEST_NAME%_latest.log"
echo Running %TEST_NAME%...
"%GODOT_EXE%" --headless --path "%PROJECT_DIR%" >"%TEST_LOG%" 2>&1
set "TEST_EXIT=!ERRORLEVEL!"
echo %TEST_NAME% exit=!TEST_EXIT!
>>"%STATUS_LOG%" echo %TEST_NAME%=!TEST_EXIT!
if not !TEST_EXIT! EQU 0 set /a TOTAL_FAILURES+=1
exit /b 0
