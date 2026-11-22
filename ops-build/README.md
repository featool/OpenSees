# OpenSees Windows 构建脚本

本目录是这台机器上验证过的 OpenSees（Tcl 解释器 + OpenSeesPy）构建脚本。
目标：MSVC 2022 + Intel oneAPI 2026.2（`ifx` / 静态 MKL）+ Python 3.11 + Conan 2 + Ninja。

## 前置条件

| 组件 | 版本（已验证） | 说明 |
|---|---|---|
| Visual Studio 2022 | 17.9 / MSVC 14.39 | 需“使用 C++ 的桌面开发”工作负载 |
| Intel oneAPI Toolkit | 2026.2 | 需勾选 **Fortran Compiler**（`ifx`）和 **oneAPI Math Kernel Library** |
| Python | 3.11.x（64 位） | 需带 `include\Python.h` 与 `libs\python311.lib` |
| Conan | 2.34 | `pip install "conan>=2,<3"` |
| Ninja | 1.13 | `pip install ninja` |
| CMake | ≥ 3.20（用 3.31 验证） | |

## 快速开始

```bat
cd /d <repo>\ops-build
make.bat
```

依次执行：`00-profile` → `01-conan` → `02-configure` → `03-build` → `04-postbuild`。

只改了 C++ 源码后重新编译：

```bat
ops-build\03-build.bat
ops-build\04-postbuild.bat
```

## 各脚本作用

| 脚本 | 作用 |
|---|---|
| `env.bat` | 加载 `vcvars64.bat` + oneAPI `setvars.bat`，把 Python 的 `Scripts` 加入 PATH。**所有脚本都先调用它** |
| `00-profile.bat` | `conan profile detect --force`（一次性，可重复执行） |
| `01-conan.bat` | `conan install`：拉取/编译 `tcl/8.6.11`、`hdf5/1.14.6`、`zlib/1.3.1`、`eigen/3.4.0` |
| `02-configure.bat` | CMake 配置（Ninja、`ifx`、静态 MKL、Python 3.11） |
| `03-build.bat` | 编译 `OpenSees` 与 `OpenSeesPy` 两个目标 |
| `04-postbuild.bat` | 改名 `opensees.pyd`、拷贝 `libiomp5md.dll`、调用 `tcl-runtime.ps1` 拷贝 Tcl 运行时库 |
| `make.bat` | 以上全部串起来 |
| `tcl-runtime.ps1` | 从 Conan 包定位 	cl8.6 并复制到 uild\lib\tcl8.6（供 04 调用） |

## 需要按机器修改的地方

`env.bat` 顶部三个变量：

```bat
set "VSDIR=D:\software\Microsoft Visual Studio\2022\Community"
set "ONEAPI=C:\Program Files (x86)\Intel\oneAPI"
set "PYTHON_DIR=D:\workspace\py311_ailab"
```

## 产物

构建完成后位于 `build\Release\`：

| 文件 | 说明 |
|---|---|
| `OpenSees.exe` | Tcl 版可执行文件 |
| `opensees.pyd` | Python 模块（由 `OpenSeesPy.dll` 改名） |
| `libiomp5md.dll` | Intel OpenMP 运行库，Python 导入必需 |
| `build\lib\tcl8.6\` | Tcl 脚本库，`OpenSees.exe` 运行时需要 |

验证：

```bat
cd /d <repo>\build\Release
OpenSees.exe t.tcl

set PYTHONPATH=<repo>\build\Release
python -c "import opensees as ops; print(ops.version())"
```

## 三个刻意的处理（不是笔误）

1. **不启用 MPI**（`-DCMAKE_DISABLE_FIND_PACKAGE_MPI=TRUE`）
   上游 `CMakeLists.txt` 在找到 MPI 时会创建 `OpenSeesMP`，并执行
   `add_dependencies(OpenSeesMP mumps)`；但 `mumps` 目标只在定义了
   `MUMPS_DIR` 时才存在（且 ExternalProject 已被注释），导致
   `cmake` 生成阶段直接报错。串行目标不需要 MPI。
   需要并行版时，先编译 MUMPS，再传 `-DMUMPS_DIR=...` 并去掉该开关。

2. **固定 Python 3.11：`PYTHON_DIR` + `Python3_ROOT_DIR` + `Python3_FIND_REGISTRY=NEVER`**
   `SRC/system_of_eqn/*/sparsePython` 会 `find_package(Python3 COMPONENTS Development)`。
   conan 的 toolchain 把 `CMAKE_FIND_PACKAGE_PREFER_CONFIG` 设为 ON，此时
   **只给 `Python3_EXECUTABLE` 是不够的**：Development 组件仍会从注册表挑到别的
   Python（本机是 `D:\software\miniconda3` 的 3.13），结果是 `OpenSeesPy.dll`
   同时链上 `python311.lib` 和 `python313.lib`，`SparsePython*` 还按 3.13 的头文件
   编译 —— 能链接通过，运行时两个 CPython 运行时混用。
   `Python3_ROOT_DIR`（或 `Python3_LIBRARY`/`Python3_INCLUDE_DIR`）才是有效的锚点。
   验证方法：`cmake` 输出里的 `Found Python3:` 必须指向 `%PYTHON_DIR%`，
   且 `build\Release\build.ninja` 里搜不到 `python313`。

3. **`04-postbuild.bat` 拷贝 Tcl 库**
   配置日志会打印 `-- Using System TCL`，但 `TCL_INCLUDE_PATH` 为空，
   `init.tcl` 不会被拷到运行时目录，`OpenSees.exe` 会报
   `Can't find a usable init.tcl`。脚本从 Conan 包目录补拷到
   `build\lib\tcl8.6`（Tcl 按 `exe目录/../lib/tcl8.6` 查找）。

## 未包含

`OpenSeesMP` / `OpenSeesSP` 未编译（需要 MUMPS + Intel MPI + ScaLAPACK）。
4. **nv.bat 的幂等保护**
   每个步骤脚本都会 call env.bat。oneAPI 的 setvars.bat 每次都会往
   PATH 追加一组目录；5 次调用后命令行会超过 cmd.exe 的 8191 字符上限，
   报 The input line is too long.。因此 nv.bat 用 OPS_ENV_READY
   做了保护，重复调用直接返回。
## 验证记录（2026-11-22，本机）

`make.bat` 五个阶段全部通过（`00`→`04` 均 exit 0）：

| 阶段 | 结果 |
|---|---|
| `00-profile` | conan 2.34 探测到 `msvc 193 / cppstd 14`，profile 写入 `C:\Users\lixin\.conan2` |
| `01-conan` | tcl 8.6.11 / hdf5 1.14.6 / zlib 1.3.1 / eigen 3.4.0 全部命中本地缓存（`Cache`，无下载、无源码编译） |
| `02-configure` | 14.4 s；MKL 2026.2 被 `FindBLAS/FindLAPACK` 找到（不再走 `OTHER/LAPACK`），Python 3.11.11 命中 |
| `03-build` | 约 10 分钟（`--parallel 8`，20 逻辑核）；0 error，9 条 `LNK4006` 重复符号（umfpack / elmt05 等 vendored 代码，无害） |
| `04-postbuild` | `opensees.pyd` + `libiomp5md.dll` + `build\lib\tcl8.6`（13 个 .tcl，含 `init.tcl`）就位 |

产物：`build\Release\OpenSees.exe` 40.2 MB、`OpenSeesPy.dll` 38.9 MB（→ `opensees.pyd`），
整个 `build\` 约 0.52 GB。版本号 `ops.version()` = `3.8.0`。

数值核对（`smoke\` 下两个文件，悬臂梁，E=29000, I=100, L=1, P=1）：

| 量 | 解析解 | Tcl 版 | Python 版 |
|---|---|---|---|
| 端部挠度 | 1.149425e-07 | 1.149425287356e-07 | 1.149425e-07（相对误差 2.3e-16） |
| 端部转角 | 1.724138e-07 | 1.724137931034e-07 | 1.724138e-07（相对误差 3.1e-16） |

`smoke\` 用法：

```bat
cd /d <repo>\build\Release
OpenSees.exe ..\..\ops-build\smoke\tcl_cantilever.tcl

set PYTHONPATH=<repo>\build\Release
D:\workspace\py311_ailab\python.exe ..\..\ops-build\smoke\py_cantilever.py
```

`opensees.pyd` 的导入表里只有 `python311.dll` 与 `libiomp5md.dll`（MKL 静态链入，
所以没有 `mkl_rt.dll` 依赖）。
