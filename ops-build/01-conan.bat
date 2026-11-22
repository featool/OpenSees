@echo off
rem Fetch / build the third-party dependencies declared in conanfile.py:
rem   tcl/8.6.11, hdf5/1.14.6, zlib/1.3.1, eigen/3.4.0
rem First run may build tcl/hdf5 from source (10-30 min); later runs hit the cache.
call "%~dp0env.bat" || exit /b 1

cd /d "%~dp0.." || exit /b 1

echo === conan install (repo: %CD%) ===
conan install . -s build_type=Release -s arch=x86_64 -s compiler.runtime=static --build=missing -c tools.cmake.cmaketoolchain:generator=Ninja
if errorlevel 1 (
  echo === CONAN INSTALL FAILED ===
  exit /b 1
)

echo.
echo === conan install OK ===
if exist "build\Release\generators\conan_toolchain.cmake" (
  echo toolchain: build\Release\generators\conan_toolchain.cmake
) else (
  echo WARNING: conan_toolchain.cmake not found
  exit /b 1
)
