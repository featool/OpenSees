@echo off
rem ============================================================
rem  Install the freshly built opensees.pyd into the target
rem  interpreter's openseespy package (drop-in replacement).
rem
rem  Target : %OPSPY_DIR%, default
rem           %PYTHON_DIR%\Lib\site-packages\openseespywin
rem  Skip   : when that directory does not exist (no pip openseespy
rem           in this interpreter). Set OPS_INSTALL_STRICT=1 to turn
rem           that skip into an error.
rem
rem  The pip-original binary is kept once as opensees.pyd.orig, so
rem  re-running this script is a no-op while the hashes already match.
rem  Flat label flow on purpose: "exit /b" nested in a parenthesised
rem  block does not reliably propagate the exit code here.
rem ============================================================
call "%~dp0env.bat" || exit /b 1

cd /d "%~dp0.." || exit /b 1

set "BUILD=build\Release"
if not exist "%BUILD%\opensees.pyd" goto :no_build

if not defined OPSPY_DIR set "OPSPY_DIR=%PYTHON_DIR%\Lib\site-packages\openseespywin"
if not exist "%OPSPY_DIR%" goto :no_target

rem --- keep the pip original exactly once, so this stays re-runnable
if exist "%OPSPY_DIR%\opensees.pyd.orig" goto :have_backup
echo [install-py] saving pip original as opensees.pyd.orig
copy /y "%OPSPY_DIR%\opensees.pyd" "%OPSPY_DIR%\opensees.pyd.orig" >nul
if errorlevel 1 exit /b 1
:have_backup

fc /b "%BUILD%\opensees.pyd" "%OPSPY_DIR%\opensees.pyd" >nul 2>&1
if errorlevel 1 goto :copy_pyd
echo [install-py] opensees.pyd already up to date
goto :dll
:copy_pyd
echo [install-py] copying opensees.pyd to %OPSPY_DIR%
copy /y "%BUILD%\opensees.pyd" "%OPSPY_DIR%\opensees.pyd" >nul
if errorlevel 1 exit /b 1
:dll

fc /b "%BUILD%\libiomp5md.dll" "%OPSPY_DIR%\libiomp5md.dll" >nul 2>&1
if errorlevel 1 goto :copy_dll
echo [install-py] libiomp5md.dll already up to date
goto :verify
:copy_dll
echo [install-py] copying libiomp5md.dll
copy /y "%BUILD%\libiomp5md.dll" "%OPSPY_DIR%\libiomp5md.dll" >nul
if errorlevel 1 exit /b 1

:verify
echo [install-py] verifying import
"%PYTHON_DIR%\python.exe" -c "import openseespy.opensees as ops; print(\"[install-py] openseespy\", ops.version())"
if errorlevel 1 goto :import_failed
echo.
echo === INSTALL-PY OK ===
exit /b 0

:no_build
echo [install-py] ERROR: %BUILD%\opensees.pyd not found - run 03-build.bat and 04-postbuild.bat first
exit /b 1

:no_target
echo [install-py] SKIP: %OPSPY_DIR% not found, no openseespy in this interpreter.
echo [install-py]       "%PYTHON_DIR%\python.exe" -m pip install openseespy
echo [install-py]       or point OPSPY_DIR at the openseespywin directory.
if "%OPS_INSTALL_STRICT%"=="1" goto :strict_fail
exit /b 0

:strict_fail
echo [install-py] ERROR: OPS_INSTALL_STRICT=1, refusing to skip
exit /b 1

:import_failed
echo [install-py] ERROR: import failed - does %PYTHON_DIR% match the interpreter this pyd was built for?
exit /b 1
