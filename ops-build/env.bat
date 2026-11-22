@echo off
rem ============================================================
rem  OpenSees Windows build environment
rem  Toolchain: MSVC 2022 + Intel oneAPI 2026.2 (ifx/MKL)
rem             + Python 3.11 + Conan 2 + Ninja
rem
rem  >>> Edit the three paths below if your installs differ <<<
rem ============================================================

rem Guard: this script is called by every step script. Without this,
rem oneAPI's setvars.bat keeps prepending directories to PATH and the
rem command line eventually exceeds the cmd.exe 8191-char limit.
if defined OPS_ENV_READY exit /b 0

set "VSDIR=D:\software\Microsoft Visual Studio\2022\Community"
set "ONEAPI=C:\Program Files (x86)\Intel\oneAPI"
set "PYTHON_DIR=D:\workspace\py311_ailab"

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

set "PATH=%PYTHON_DIR%\Scripts;%PATH%"
set "OPS_ENV_READY=1"