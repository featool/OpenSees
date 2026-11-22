@echo off
rem ============================================================
rem  OpenSees Windows build environment
rem  Toolchain: MSVC 2022 + Intel oneAPI 2026.2 (ifx/MKL)
rem             + Python (PYTHON_DIR) + Conan 2 + Ninja (TOOLS_DIR)
rem
rem  >>> Edit the four paths below if your installs differ <<<
rem ============================================================

rem Guard: this script is called by every step script. Without this,
rem oneAPI's setvars.bat keeps prepending directories to PATH and the
rem command line eventually exceeds the cmd.exe 8191-char limit.
if defined OPS_ENV_READY exit /b 0

set "VSDIR=D:\software\Microsoft Visual Studio\2022\Community"
set "ONEAPI=C:\Program Files (x86)\Intel\oneAPI"

rem Target interpreter: OpenSeesPy is compiled and linked against THIS python
rem (include\Python.h + libs\python3XX.lib). Here it is the interpreter that
rem rustserver ships (rustserver\third_party\python, CPython 3.12), so the
rem produced opensees.pyd can be dropped straight into its openseespy package.
set "PYTHON_DIR=D:\workspace\rustGIS\section_properties_caclutor\rustserver\third_party\python"

rem Build tooling only (conan + ninja). It does not have to be the interpreter
rem above: keeping it separate avoids installing conan/ninja into the runtime
rem that gets shipped with rustserver.
set "TOOLS_DIR=D:\workspace\py311_ailab"

rem forward-slash variants for cmake -D arguments
set "ONEAPIFWD=%ONEAPI:\=/%"
set "PYFWD=%PYTHON_DIR:\=/%"

call "%VSDIR%\VC\Auxiliary\Build\vcvars64.bat" >nul
if errorlevel 1 (
  echo [env] ERROR: vcvars64.bat failed - check VSDIR "%VSDIR%"
  exit /b 1
)

call "%ONEAPI%\setvars.bat" intel64 mod >nul
if errorlevel 1 (
  echo [env] ERROR: oneAPI setvars.bat failed - check ONEAPI "%ONEAPI%"
  exit /b 1
)

set "PATH=%TOOLS_DIR%\Scripts;%PYTHON_DIR%\Scripts;%PATH%"
set "OPS_ENV_READY=1"