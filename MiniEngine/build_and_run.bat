@echo off
REM ============================================
REM Build and Run MiniEngine (Win32 + OpenGL)
REM ============================================

REM Executable name
set EXE_NAME=MiniEngine.exe

REM Include paths
set INCLUDE_PATHS=/Iexternal /Iexternal/glad

REM Compile resource file
rc app.rc

REM Source directory
set SRC_DIR=src

REM Compile using MSVC
cl /EHsc ^
    %INCLUDE_PATHS% ^
    %SRC_DIR%\main.cpp ^
    %SRC_DIR%\Win32Window.cpp ^
    src\Shader.cpp ^
    src\glad.c ^
    app.res ^
    user32.lib gdi32.lib opengl32.lib ^
    /Fe:%EXE_NAME%

REM If compilation failed, stop
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Build failed!
    pause
    exit /b
)

echo.
echo ✅ Build successful!
echo ▶ Running MiniEngine...
echo.

REM Run the program
%EXE_NAME%

pause
