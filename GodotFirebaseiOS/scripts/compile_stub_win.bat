@echo off
REM Compiles stub.c into a valid Windows DLL using MSVC
REM Usage: compile_stub_win.bat

set LOGFILE=%~dp0compile_log.txt

echo Initializing MSVC... > "%LOGFILE%"
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" x64 >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo ERROR: Failed to initialize MSVC environment. >> "%LOGFILE%"
    exit /b 1
)

set STUB_SRC=%~dp0stub.c
set DEST=%~dp0..\..\demo\addons\GodotFirebaseiOS\stubs\stub.dll

echo Compiling %STUB_SRC% ... >> "%LOGFILE%"
echo DEST=%DEST% >> "%LOGFILE%"
cl /LD /Fe:"%DEST%" "%STUB_SRC%" >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo ERROR: Compilation failed. >> "%LOGFILE%"
    exit /b 1
)

REM Clean up intermediate files left by cl.exe
del "%~dp0stub.obj" 2>nul
del "%~dp0..\..\demo\addons\GodotFirebaseiOS\stubs\stub.lib" 2>nul
del "%~dp0..\..\demo\addons\GodotFirebaseiOS\stubs\stub.exp" 2>nul

echo SUCCESS: stub.dll compiled at %DEST% >> "%LOGFILE%"
