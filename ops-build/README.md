# OpenSees Windows 构建脚本

本目录是这台机器上验证过的 OpenSees（Tcl 解释器 + OpenSeesPy）构建脚本。
目标：MSVC 2022 + Intel oneAPI 2026.2（`ifx` / 静态 MKL）+ Python 3.12（rustserver 内置解释器）+ Conan 2 + Ninja。

OpenSeesPy 链接哪个 Python 由 `PYTHON_DIR` 决定；Conan / Ninja 只从 `TOOLS_DIR` 里取，
所以编译用的解释器和构建工具可以分开（内置运行时不装 conan）。

## 前置条件

| 组件 | 版本（已验证） | 说明 |
|---|---|---|
| Visual Studio 2022 | 17.9 / MSVC 14.39 | 需“使用 C++ 的桌面开发”工作负载 |
| Intel oneAPI Toolkit | 2026.2 | 需勾选 **Fortran Compiler**（`ifx`）和 **oneAPI Math Kernel Library** |
| Python（链接目标） | 3.12.3（rustserver 内置） | `PYTHON_DIR`，需带 `include\Python.h` 与 `libs\python312.lib` |
| Conan | 2.34 | 装 `TOOLS_DIR` 即可，`pip install "conan>=2,<3"` |
| Ninja | 1.13 | 同上，`pip install ninja` |
| CMake | ≥ 3.20（用 3.31 验证） | |

## 快速开始

```bat
cd /d <repo>\ops-build
make.bat
```

依次执行：`00-profile` → `01-conan` → `02-configure` → `03-build` → `04-postbuild` → `05-install-python`。
最后一步会把 `opensees.pyd` 自动装进 `PYTHON_DIR` 的 `openseespy`（哈希相同就跳过，
所以重复跑 `make.bat` 是幂等的）。

只改了 C++ 源码后重新编译：

```bat
ops-build\03-build.bat
ops-build\04-postbuild.bat
ops-build\05-install-python.bat
```

## 各脚本作用

| 脚本 | 作用 |
|---|---|
| `env.bat` | 加载 `vcvars64.bat` + oneAPI `setvars.bat`，把 `TOOLS_DIR\Scripts` 与 `PYTHON_DIR\Scripts` 加入 PATH。**所有脚本都先调用它** |
| `00-profile.bat` | `conan profile detect --force`（一次性，可重复执行） |
| `01-conan.bat` | `conan install`：拉取/编译 `tcl/8.6.11`、`hdf5/1.14.6`、`zlib/1.3.1`、`eigen/3.4.0` |
| `02-configure.bat` | CMake 配置（Ninja、`ifx`、静态 MKL、Python 3.12） |
| `03-build.bat` | 编译 `OpenSees` 与 `OpenSeesPy` 两个目标 |
| `04-postbuild.bat` | 改名 `opensees.pyd`、拷贝 `libiomp5md.dll`、调用 `tcl-runtime.ps1` 拷贝 Tcl 运行时库 |
| `05-install-python.bat` | 把产物装进目标解释器的 `openseespy`（默认 `PYTHON_DIR\Lib\site-packages\openseespywin`），装完跑一次 import 自检 |
| `make.bat` | 以上全部串起来 |
| `tcl-runtime.ps1` | 从 Conan 包定位 `tcl8.6` 并复制到 `build\lib\tcl8.6`（供 04 调用） |

## 需要按机器修改的地方

`env.bat` 顶部四个变量：

```bat
set "VSDIR=D:\software\Microsoft Visual Studio\2022\Community"
set "ONEAPI=C:\Program Files (x86)\Intel\oneAPI"

rem 链接目标：产物装进这个解释器的 openseespy
set "PYTHON_DIR=D:\workspace\rustGIS\section_properties_caclutor\rustserver\third_party\python"

rem 只提供 conan / ninja，不参与链接
set "TOOLS_DIR=D:\workspace\py311_ailab"
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
OpenSees.exe ..\..\ops-build\smoke\tcl_cantilever.tcl

set PYTHONPATH=<repo>\build\Release
"%PYTHON_DIR%\python.exe" ..\..\ops-build\smoke\py_cantilever.py
```

## 自动装进目标 Python 的 openseespy（`05-install-python.bat`）

内置解释器的 `openseespy` 是 pip 包，原生模块只有 `openseespywin\opensees.pyd`
（`openseespy\opensees\__init__.py` 里 `from openseespywin.opensees import *`），
所以换二进制只要覆盖这一个文件，不用动 pip 包结构。`make.bat` 最后一步会自己做，
也可以单独跑：

```bat
ops-build\05-install-python.bat
```

行为：

| 情况 | 结果 |
|---|---|
| 目标目录不存在（该解释器没装 openseespy） | 打印 `SKIP` 并 `exit 0`；设 `OPS_INSTALL_STRICT=1` 则改为 `exit 1` |
| 产物与目标哈希相同 | 只打印 `already up to date`，不复制（幂等） |
| 哈希不同 / 目标缺失 | 覆盖 `opensees.pyd` 与 `libiomp5md.dll` |
| 覆盖后 `import openseespy.opensees` 失败 | `exit 1`（通常是 `PYTHON_DIR` 与 pyd 的 ABI 不匹配） |

可覆盖的变量：

```bat
rem 默认 %PYTHON_DIR%\Lib\site-packages\openseespywin
set "OPSPY_DIR=D:\some\env\Lib\site-packages\openseespywin"

rem 目标没装 openseespy 时把 SKIP 变成硬失败
set "OPS_INSTALL_STRICT=1"
```

第一次替换前会把 pip 原始二进制存成 `opensees.pyd.orig`（只存一次，之后的覆盖不会
再动它）。回滚：

```bat
copy /y "...\openseespywin\opensees.pyd.orig" "...\openseespywin\opensees.pyd"
```

`opensees.pyd` 的模块名是 `opensees`，与 pip 包里的文件名一致，所以路径不用改；
`libiomp5md.dll` 必须和被替换的 pyd 放在同一目录（MKL 是静态链进去的，
但 Intel OpenMP 仍是 DLL）。

## 三个刻意的处理（不是笔误）

1. **不启用 MPI**（`-DCMAKE_DISABLE_FIND_PACKAGE_MPI=TRUE`）
   上游 `CMakeLists.txt` 在找到 MPI 时会创建 `OpenSeesMP`，并执行
   `add_dependencies(OpenSeesMP mumps)`；但 `mumps` 目标只在定义了
   `MUMPS_DIR` 时才存在（且 ExternalProject 已被注释），导致
   `cmake` 生成阶段直接报错。串行目标不需要 MPI。
   需要并行版时，先编译 MUMPS，再传 `-DMUMPS_DIR=...` 并去掉该开关。

2. **锚定 Python 版本：`PYTHON_DIR` + `Python3_ROOT_DIR` + `Python3_FIND_REGISTRY=NEVER`**
   `SRC/system_of_eqn/*/sparsePython` 会 `find_package(Python3 COMPONENTS Development)`。
   conan 的 toolchain 把 `CMAKE_FIND_PACKAGE_PREFER_CONFIG` 设为 ON，此时
   **只给 `Python3_EXECUTABLE` 是不够的**：Development 组件仍会从注册表挑到别的
   Python（本机是 `D:\software\miniconda3` 的 3.13），结果是 `OpenSeesPy.dll`
   同时链上目标版本的 `python3XX.lib` 和 `python313.lib`，`SparsePython*` 还按 3.13
   的头文件编译 —— 能链接通过，运行时两个 CPython 运行时混用。
   `Python3_ROOT_DIR`（或 `Python3_LIBRARY`/`Python3_INCLUDE_DIR`）才是有效的锚点。
   验证方法：`cmake` 输出里的 `Found Python3:` 必须指向 `%PYTHON_DIR%`，
   且 `build\Release\build.ninja` 里搜不到别的 `python3XX.lib`。

3. **`04-postbuild.bat` 拷贝 Tcl 库**
   配置日志会打印 `-- Using System TCL`，但 `TCL_INCLUDE_PATH` 为空，
   `init.tcl` 不会被拷到运行时目录，`OpenSees.exe` 会报
   `Can't find a usable init.tcl`。脚本从 Conan 包目录补拷到
   `build\lib\tcl8.6`（Tcl 按 `exe目录/../lib/tcl8.6` 查找）。

4. **`env.bat` 的幂等保护**
   每个步骤脚本都会 call env.bat。oneAPI 的 setvars.bat 每次都会往 PATH
   追加一组目录；5 次调用后命令行会超过 cmd.exe 的 8191 字符上限，报
   `The input line is too long.`。因此 `env.bat` 用 `OPS_ENV_READY`
   做了保护，重复调用直接返回。

## 未包含

`OpenSeesMP` / `OpenSeesSP` 未编译（需要 MUMPS + Intel MPI + ScaLAPACK）。

## 验证记录（2026-11-22，本机）

六个阶段全部通过（`00` → `05` 均 exit 0），最后一次是针对内置 Python 3.12.3 的构建：

| 阶段 | 结果 |
|---|---|
| `00-profile` | conan 2.34 探测到 `msvc 193 / cppstd 14`，profile 写入 `C:\Users\lixin\.conan2` |
| `01-conan` | tcl 8.6.11 / hdf5 1.14.6 / zlib 1.3.1 / eigen 3.4.0 全部命中本地缓存（`Cache`，无下载、无源码编译） |
| `02-configure` | 14.4 s；MKL 2026.2 被 `FindBLAS/FindLAPACK` 找到（不再走 `OTHER/LAPACK`），`Found Python3:` 命中 `PYTHON_DIR` |
| `03-build` | 约 10 分钟（`--parallel 8`，20 逻辑核）；0 error，9 条 `LNK4006` 重复符号（umfpack / elmt05 等 vendored 代码，无害） |
| `04-postbuild` | `opensees.pyd` + `libiomp5md.dll` + `build\lib\tcl8.6`（`init.tcl` 与 encoding/tzdata 等子目录）就位 |
| `05-install-python` | 装进 `PYTHON_DIR\Lib\site-packages\openseespywin`，import 自检输出 `openseespy 3.8.0` |

产物：`build\Release\OpenSees.exe` 40.2 MB、`OpenSeesPy.dll` 39.0 MB（→ `opensees.pyd`），
整个 `build\` 约 0.52 GB。`ops.version()` = `3.8.0`；`opensees.pyd` 的导入表里只有
`python312.dll` 与 `libiomp5md.dll`（MKL 静态链入，所以没有 `mkl_rt.dll` 依赖）。

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
"%PYTHON_DIR%\python.exe" ..\..\ops-build\smoke\py_cantilever.py
```

装进内置解释器之后（见上文「自动装进目标 Python 的 openseespy」），
同一模型改用 `import openseespy.opensees as ops` 跑，挠度仍是 1.149425e-07（相对误差 2.3e-16）。
