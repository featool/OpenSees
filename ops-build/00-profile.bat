@echo off
rem Detect the Conan profile (one time only, but harmless to re-run)
call "%~dp0env.bat" || exit /b 1

conan profile detect --force
if errorlevel 1 exit /b 1

echo.
echo ---------- default profile ----------
conan profile show
