@echo off
rem Post-build fixes required to actually RUN the artifacts:
rem  1. OpenSeesPy.dll -> opensees.pyd (Python only imports *.pyd)
rem  2. copy libiomp5md.dll (static MKL/intel_thread needs it at runtime)
rem  3. copy the Tcl script library to build\lib\tcl8.6 (see tcl-runtime.ps1)
call "%~dp0env.bat" || exit /b 1

cd /d "%~dp0.." || exit /b 1

set "BUILD=build\Release"

if not exist "%BUILD%\OpenSeesPy.dll" (
  echo [postbuild] ERROR: OpenSeesPy.dll not found - run 03-build.bat first
  exit /b 1
)

echo [postbuild] OpenSeesPy.dll to opensees.pyd
copy /y "%BUILD%\OpenSeesPy.dll" "%BUILD%\opensees.pyd" >nul
if errorlevel 1 exit /b 1

echo [postbuild] copying libiomp5md.dll
copy /y "%ONEAPI%\compiler\latest\bin\libiomp5md.dll" "%BUILD%\libiomp5md.dll" >nul
if errorlevel 1 exit /b 1

echo [postbuild] ensuring Tcl runtime library
if not exist "build\lib\tcl8.6\init.tcl" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tcl-runtime.ps1"
  if errorlevel 1 exit /b 1
) else (
  echo [postbuild] build\lib\tcl8.6 already present
)

echo.
echo === POSTBUILD OK ===
dir /b "%BUILD%\OpenSees.exe" "%BUILD%\opensees.pyd" "%BUILD%\libiomp5md.dll"
