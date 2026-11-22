@echo off
rem Build the two serial targets. OpenSeesPy is EXCLUDE_FROM_ALL upstream,
rem so it must be requested explicitly.
call "%~dp0env.bat" || exit /b 1

cd /d "%~dp0.." || exit /b 1

echo === building target OpenSees ===
cmake --build build\Release --target OpenSees --parallel 8
if errorlevel 1 (
  echo === OpenSees BUILD FAILED ===
  exit /b 1
)
echo === OpenSees OK ===

echo === building target OpenSeesPy ===
cmake --build build\Release --target OpenSeesPy --parallel 8
if errorlevel 1 (
  echo === OpenSeesPy BUILD FAILED ===
  exit /b 1
)
echo === OpenSeesPy OK ===
