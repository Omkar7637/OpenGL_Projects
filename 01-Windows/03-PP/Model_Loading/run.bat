@echo off
setlocal

REM Build then run OGL.exe (use Developer Command Prompt for VS)

cd /d "%~dp0"

call build.bat
if errorlevel 1 (
    echo [ERROR] Build failed; not starting executable.
    exit /b 1
)

if not exist "OGL.exe" (
    echo [ERROR] OGL.exe not found after build.
    exit /b 1
)

echo [OK] Starting OGL.exe ...
start "" "OGL.exe"

endlocal
exit /b 0
