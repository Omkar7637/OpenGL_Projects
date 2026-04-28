@echo off
setlocal EnableDelayedExpansion

REM Build script for Model_Loading (Win32 + OpenGL + GLEW)
REM Layout: src\  include\  res\  assets\
REM Sources: split modules + OGL_Common.h

pushd "%~dp0"

set "RES=res\OGL.rc"
set "OUT=OGL.exe"
set "RES_OBJ=OGL.res"

set "SOURCES=src\OGL_Main.c src\OGL_Globals.c src\OGL_Window.c src\OGL_GLInit.c src\OGL_Model.c src\OGL_Render.c src\OGL_Cleanup.c src\rubik_gltf.c src\math_bridge.cpp"

if not exist "%RES%" (
    echo [ERROR] Resource file not found: %RES%
    popd
    exit /b 1
)

where cl >nul 2>nul
if errorlevel 1 (
    echo [ERROR] cl.exe not found.
    echo Open "Developer Command Prompt for VS" and run this script again.
    popd
    exit /b 1
)

where rc >nul 2>nul
if errorlevel 1 (
    echo [ERROR] rc.exe not found.
    popd
    exit /b 1
)

REM ---------------------------------------------------------------------------
REM GLEW include + x64 import library
REM ---------------------------------------------------------------------------
set "GLEW_INC="
set "GLEW_LIBDIR="
set "GLEW_HOME="

if not "%GLEW_ROOT%"=="" (
    set "GLEW_HOME=%GLEW_ROOT%"
)

if "!GLEW_HOME!"=="" (
    set "TRY=C:\glew-2.3.1"
    if exist "!TRY!\include\GL\glew.h" if exist "!TRY!\lib\Release\x64\glew32.lib" set "GLEW_HOME=!TRY!"
)
if "!GLEW_HOME!"=="" (
    set "TRY=C:\glew-2.3.0"
    if exist "!TRY!\include\GL\glew.h" if exist "!TRY!\lib\Release\x64\glew32.lib" set "GLEW_HOME=!TRY!"
)
if "!GLEW_HOME!"=="" (
    set "TRY=%~dp0..\..\..\glew-2.3.1"
    if exist "!TRY!\include\GL\glew.h" if exist "!TRY!\lib\Release\x64\glew32.lib" set "GLEW_HOME=!TRY!"
)
if "!GLEW_HOME!"=="" (
    set "TRY=%~dp0..\..\..\glew-2.3.0"
    if exist "!TRY!\include\GL\glew.h" if exist "!TRY!\lib\Release\x64\glew32.lib" set "GLEW_HOME=!TRY!"
)

if not "!GLEW_HOME!"=="" (
    set "GLEW_INC=!GLEW_HOME!\include"
    set "GLEW_LIBDIR=!GLEW_HOME!\lib\Release\x64"
)

if not exist "!GLEW_INC!\GL\glew.h" (
    echo [ERROR] GLEW headers not found ^(!GLEW_INC!\GL\glew.h^).
    echo set GLEW_ROOT=C:\glew-2.3.1
    popd
    exit /b 1
)

if not exist "!GLEW_LIBDIR!\glew32.lib" (
    echo [ERROR] GLEW x64 library not found: !GLEW_LIBDIR!\glew32.lib
    popd
    exit /b 1
)

echo Using GLEW_HOME=!GLEW_HOME!

echo [1/3] Cleaning old outputs...
del /q "%OUT%" "%RES_OBJ%" *.obj *.ilk *.pdb 2>nul

echo [2/3] Compiling resources...
rc /nologo /fo "%RES_OBJ%" /I "include" "%RES%"
if errorlevel 1 (
    echo [ERROR] Resource compilation failed.
    popd
    exit /b 1
)

echo [3/3] Compiling and linking...
cl /nologo /EHsc /MD /std:c++17 /O2 ^
 /I "include" /I "!GLEW_INC!" ^
 %SOURCES% "%RES_OBJ%" ^
 /link /OUT:"%OUT%" /LIBPATH:"!GLEW_LIBDIR!" glew32.lib opengl32.lib user32.lib gdi32.lib kernel32.lib
if errorlevel 1 (
    echo [ERROR] Build failed.
    popd
    exit /b 1
)

if exist "!GLEW_HOME!\bin\Release\x64\glew32.dll" (
    copy /y "!GLEW_HOME!\bin\Release\x64\glew32.dll" "." >nul
    echo Copied glew32.dll next to %OUT%
)

echo [OK] Build succeeded: %OUT%
popd
endlocal
exit /b 0
