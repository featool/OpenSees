@echo off
rem ============================================================
rem  One-click build: profile -> conan -> configure -> build -> postbuild
rem  Usage:  make.bat
rem  Incremental rebuild after editing C++ sources: run 03-build.bat
rem  (optionally 04-postbuild.bat) instead of this script.
rem ============================================================
setlocal
set "HERE=%~dp0"

call "%HERE%00-profile.bat"
if errorlevel 1 exit /b 1
call "%HERE%01-conan.bat"
if errorlevel 1 exit /b 1
call "%HERE%02-configure.bat"
if errorlevel 1 exit /b 1
call "%HERE%03-build.bat"
if errorlevel 1 exit /b 1
call "%HERE%04-postbuild.bat"
if errorlevel 1 exit /b 1

echo.
echo ============================================
echo  BUILD COMPLETE
echo  artifacts : %HERE%..\build\Release\
echo ============================================