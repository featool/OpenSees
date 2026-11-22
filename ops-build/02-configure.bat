@echo off
rem Configure the build tree (Ninja + MSVC + ifx + static MKL).
rem Notes:
rem  * MPI is disabled on purpose: CMakeLists.txt creates OpenSeesMP with
rem    add_dependencies(OpenSeesMP mumps) while the mumps target does not
rem    exist, which breaks generation. We only build serial OpenSees/OpenSeesPy.
rem  * Python3_EXECUTABLE is pinned so the sparsePython solver does not pick
rem    up a different Python (e.g. conda 3.13) than the one OpenSeesPy links.
call "%~dp0env.bat" || exit /b 1

cd /d "%~dp0.." || exit /b 1

set "CMAKE_POLICY_VERSION_MINIMUM=3.5"

echo === cmake configure (repo: %CD%) ===
cmake -S . -B build\Release -G Ninja ^
  -DCMAKE_TOOLCHAIN_FILE="%CD%/build/Release/generators/conan_toolchain.cmake" ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_Fortran_COMPILER="%ONEAPIFWD%/compiler/latest/bin/ifx.exe" ^
  -DPython_EXECUTABLE="%PYFWD%/python.exe" ^
  -DPython3_EXECUTABLE="%PYFWD%/python.exe" ^
  -DPython3_ROOT_DIR="%PYFWD%" ^
  -DPython3_FIND_REGISTRY=NEVER ^
  -DCMAKE_DISABLE_FIND_PACKAGE_MPI=TRUE ^
  -DBLA_STATIC=ON -DMKL_LINK=static -DMKL_INTERFACE_FULL=intel_lp64 ^
  -DCMAKE_NINJA_FORCE_RESPONSE_FILE=ON ^
  -DCMAKE_C_USE_RESPONSE_FILE_FOR_OBJECTS=ON ^
  -DCMAKE_CXX_USE_RESPONSE_FILE_FOR_OBJECTS=ON ^
  -DCMAKE_INSTALL_PREFIX="%CD%/../OpenSees-install"

if errorlevel 1 (
  echo === CMAKE CONFIGURE FAILED ===
  exit /b 1
)
echo === cmake configure OK ===
