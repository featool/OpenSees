# Copy the Tcl script library from the Conan package into build\lib\tcl8.6,
# which is where the embedded Tcl looks for init.tcl relative to OpenSees.exe.
$ErrorActionPreference = 'Stop'

$data = 'build\Release\generators\TCL-release-x86_64-data.cmake'
if (-not (Test-Path $data)) {
    Write-Host '[postbuild] WARNING: TCL data cmake not found, skip Tcl library copy'
    exit 0
}

$line = (Select-String -Path $data -Pattern 'tcl_PACKAGE_FOLDER_RELEASE').Line
$pkg  = $line.Split([char]34)[1]
$src  = Join-Path $pkg 'lib\tcl8.6'

if (-not (Test-Path (Join-Path $src 'init.tcl'))) {
    Write-Host "[postbuild] WARNING: tcl8.6 not found under $pkg"
    exit 1
}

New-Item -ItemType Directory -Force 'build\lib\tcl8.6' | Out-Null
Copy-Item (Join-Path $src '*') 'build\lib\tcl8.6\' -Recurse -Force
Write-Host "[postbuild] tcl8.6 copied from $pkg"
