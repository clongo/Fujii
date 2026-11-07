# Building Eglantine

> [!WARNING]
> This guide is intended for developers ONLY. If you are not a developer or packager, you are unlikely to receive support.

This is a full-fledged guide to build Eglantine on all supported platforms.

If you already have a development environment set up:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -G Ninja
cmake --build build
```

On Linux, macOS, and MinGW/MSYS2, make sure to read the [dependencies guide](Deps.md). On Android, read its [dedicated page](build/Android.md).

## Dependencies

First, you must [install some dependencies](Deps.md).

## Clone

Next, you will want to clone Eglantine via the terminal:

```sh
git clone https://github.com/Djihads80/Eglantine.git
cd Eglantine
```

Or use Qt Creator (Create Project -> Import Project -> Git Clone).

## Android

Android has a completely different build process than other platforms. See its [dedicated page](build/Android.md).

## Initial Configuration

If the configure phase fails, see the `Troubleshooting` section below. Usually, as long as you followed the dependencies guide, the defaults *should* successfully configure and build.

### Option A: Qt Creator

This is the recommended GUI method for Linux, macOS, and Windows.

<details>
<summary>Click to Open</summary>

> [!WARNING]
> On MSYS2, to use Qt Creator you are recommended to *also* install Qt from the online installer, ensuring to select the "MinGW" version.

Open the CMakeLists.txt file in your cloned directory via File -> Open File or Project (Ctrl+O), if you didn't clone Eglantine via the project import tool.

Select your desired "kit" (usually, the default is okay). RelWithDebInfo or Release is recommended:

![Qt Creator kits](img/creator-1.png)

Hit "Configure Project", then wait for CMake to finish configuring (may take a while on Windows).

</details>

### Option B: Command Line

<details>
<summary>Click to Open</summary>

> [!WARNING]
>For all systems:
>
>- *CMake* **MUST** be in your PATH (and also *ninja*, if you are using it as `<GENERATOR>`)
>- You *MUST* be in the cloned *Eglantine* directory
>
>On Windows:
>
> - It's recommended to install **[Ninja](https://ninja-build.org/)**
> - You must load **Visual C++ development environment**, this can be done by running our convenience script:
>   - `tools/windows/load-msvc-env.ps1` (for PowerShell 5+)
>   - `tools/windows/load-msvc-env.sh` (for MSYS2, Git Bash, etc)

Available `<GENERATOR>`:

- MSYS2: `MSYS Makefiles`
- MSVC: `Ninja` (preferred) or `Visual Studio 17 2022`
- macOS: `Ninja` (preferred) or `Xcode`
- Others: `Ninja` (preferred) or `UNIX Makefiles`

Available `<BUILD_TYPE>`:

- `Release` (default)
- `RelWithDebInfo` (debug symbols--compiled executable will be large)
- `Debug` (if you are using a debugger and annoyed with stuff getting optimized out)

Caveat for Debug Builds:

- If you're building with CCache, you will need to add the environment variable `CL` with the `/FS` flag ([Reference](https://learn.microsoft.com/pt-br/cpp/build/reference/fs-force-synchronous-pdb-writes?view=msvc-170))

Also see the root CMakeLists.txt for more build options. Usually the default will provide the best experience, however.

```sh
cmake -S . -B build -G "<GENERATOR>" -DCMAKE_BUILD_TYPE=<BUILD_TYPE> -DYUZU_TESTS=OFF
```

If you are on Windows and prefer to use Clang:

```sh
cmake -S . -B build -G "<GENERATOR>" -DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl
```

</details>

### Option C: [CLion](https://www.jetbrains.com/clion/)

<details>
<summary>Click to Open</summary>

- Clone the Repository:

<img src="https://user-images.githubusercontent.com/42481638/216899046-0d41d7d6-8e4d-4ed2-9587-b57088af5214.png" width="500">
<img src="https://user-images.githubusercontent.com/42481638/216899061-b2ea274a-e88c-40ae-bf0b-4450b46e9fea.png" width="500">
<img src="https://user-images.githubusercontent.com/42481638/216899076-0e5988c4-d431-4284-a5ff-9ecff973db76.png" width="500">

---

### Building & Setup

- Once Cloned, You will be taken to a prompt like the image below:

<img src="https://user-images.githubusercontent.com/42481638/216899092-3fe4cec6-a540-44e3-9e1e-3de9c2fffc2f.png" width="500">

- Set the settings to the image below:
- Change `Build type: Release`
- Change `Name: Release`
- Change `Toolchain Visual Studio`
- Change `Generator: Let CMake decide`
- Change `Build directory: build`

<img src="https://user-images.githubusercontent.com/42481638/216899164-6cee8482-3d59-428f-b1bc-e6dc793c9b20.png" width="500">

- Click OK; now CLion will build a directory and index your code to allow for IntelliSense. Please be patient.
- Once this process has been completed (No loading bar bottom right), you can now build Eglantine
- In the top right, click on the drop-down menu, select all configurations, then select Eglantine

<img src="https://user-images.githubusercontent.com/42481638/216899226-975048e9-bc6d-4ec1-bc2d-bd8a1e15ed04.png" height="500" >

- Now run by clicking the play button or pressing Shift+F10, and Eglantine will auto-launch once built.

<img src="https://user-images.githubusercontent.com/42481638/216899275-d514ec6a-e563-470e-81e2-3e04f0429b68.png" width="500">
</details>

#### Option D: Visual Studio with clang-cl

<details>
1. Install `"x64 Native Tools Command Prompt"` for VS from the installer and also install `cmake-gui`.
2. Open `"x64 Native Tools Command Prompt"` and type `cmake-gui`.
3. Click configure choose ninja generator > specify native compilers.
4. Put `"C:/Program Files/Microsoft Visual Studio/18/Community/VC/Tools/Llvm/x64/bin/clang-cl.exe"` as your C/C++ compiler path.
5. Open `Visual studio > Open project` or Solution > Change to search for the CMake project file (`CMakeList.txt`) file on the cloned directory, and then build.
</details>

## Troubleshooting

If your initial configure failed:

- *Carefully* re-read the [dependencies guide](Deps.md)
- Clear the CPM cache (`.cache/cpm`) and CMake cache (`<build directory>/CMakeCache.txt`)
- Evaluate the error and find any related settings
- See the [CPM docs](CPMUtil.md) to see if you may need to forcefully bundle any packages

Otherwise, feel free to ask for help in Stoat or Discord.

## Caveats

Many platforms have quirks, bugs, and other fun stuff that may cause issues when building OR running. See the [Caveats page](Caveats.md) before continuing.

## Building & Running

### On Qt Creator

Simply hit Ctrl+B, or the "hammer" icon in the bottom left. To run, hit the "play" icon, or Ctrl+R.

### On Command Line

If you are using the `UNIX Makefiles` or `Visual Studio 17 2022` as `<GENERATOR>`, you should also add `--parallel` for faster build times.

```sh
cmake --build build
```

Your compiled executable will be in:

- `build/bin/eglantine.exe` for Windows,
- `build/bin/Eglantine.app/Contents/MacOS/eglantine` for macOS,
- and `build/bin/eglantine` for others.

## Scripts

Take a look at our [CI scripts](https://github.com/Eglantine-CI/Workflow). You can use `.ci/common/configure.sh` on any POSIX-compliant shell, but you are heavily encouraged to instead write your own based. It's not really that hard, provided you can read CMake.

## Windows x86_64 builds with Docker

The [Windows build image](../tools/docker/windows/Dockerfile) builds native Windows
x86_64 binaries using MSVC and Ninja. It includes Visual Studio 2022 Build Tools
and the Windows SDK, Python 3.12.10, Git 2.49.0, CMake 3.31.10, Ninja 1.13.0,
Qt 6.8.3 with Qt Charts, and Vulkan SDK 1.4.341.1. Other dependencies are downloaded
by the repository's existing CPM configuration.
The image explicitly preserves Windows system directories in PATH because the
base image does not expose its default PATH through Docker image metadata.

Requirements:

- A Windows x86_64 host supporting Windows Server 2025 containers (for example
  Windows 11 24H2 or later Pro/Enterprise with Hyper-V, or Windows Server 2025).
- Docker configured for **Windows containers**, not Linux containers. In Docker
  Desktop, select **Switch to Windows containers**.
- Internet access during image creation and the first source build.
- Ample disk space for the large Windows/toolchain image and build output.
  Allow at least 8 GB of container memory; the 12-job example below uses 16 GB.
  Reduce the CPU allocation, memory allocation, and build parallelism on smaller hosts.

From the repository root, run these commands in PowerShell:

```powershell
docker build --isolation=hyperv --memory=8g -t lichii-build-windows .\tools\docker\windows
docker run --rm --isolation=hyperv --cpus=12 --memory=16g `
    --mount "type=bind,source=$($PWD.Path),target=C:\src" `
    lichii-build-windows
```

In VS Code, press **Ctrl+Shift+B** or select **Tasks: Run Build Task** to run
the default **Build Windows (Docker)** task from
[tasks.json](../.vscode/tasks.json). This task allocates 20 CPUs and 20 GB of
memory and uses 20 compiler jobs. It requires the `lichii-build-windows` image
to have been built already; adjust the task's resource limits for smaller hosts.

The image contains only build tools, not a copy of the source. The source mount
must be writable: build output is saved to `build\docker-windows`, and CPM downloads
are cached in `.cache\cpm` in the checkout. Both persist after the container exits.
Keep this build directory separate from any host or Linux CMake build directory.
Hyper-V containers default to only two virtual CPUs. Set `--cpus` explicitly:
`-Jobs` controls compiler parallelism but does not allocate CPUs to the container.

The GUI executable is `build\docker-windows\bin\lichii.exe`; the command-line
executable is `build\docker-windows\bin\yuzu-cmd.exe`. The existing CMake
post-build steps copy runtime DLLs and Qt plugins alongside them. Run the binaries
on the Windows host, not inside the build container; keep the entire `bin` folder
together. The host needs the x64 Visual C++ Redistributable for Visual Studio 2022
and appropriate graphics drivers.

For a build with debug symbols, fewer parallel jobs, and unit tests:

```powershell
docker run --rm --isolation=hyperv --cpus=4 --memory=8g `
    --mount "type=bind,source=$($PWD.Path),target=C:\src" `
    lichii-build-windows -BuildType RelWithDebInfo -Jobs 4 -BuildTests
```

`-BuildTests` compiles the tests without running them. The Server Core image lacks
`wlanapi.dll`, required by the emulator's networking code and core tests, so run
the compiled test executables on the desktop Windows host:

```powershell
$bin = Join-Path $PWD.Path 'build\docker-windows\bin'
$previousPlatform = $env:QT_QPA_PLATFORM
try {
    $env:QT_QPA_PLATFORM = 'offscreen'
    foreach ($test in @('tests', 'sdl_window_state_tests', 'update_checker_tests',
                       'config_tests', 'compatibility_report_tests')) {
        & (Join-Path $bin "$test.exe")
        if ($LASTEXITCODE -ne 0) { throw "$test failed with exit code $LASTEXITCODE" }
    }
} finally {
    $env:QT_QPA_PLATFORM = $previousPlatform
}
```

`-Tests` both compiles and runs CTest, and fails explicitly if the container lacks
the required Windows runtime. Bundled dependency self-tests are not part of the
emulator's test suite.

Startup regression coverage includes closing the migration dialog without selecting
a button and loading older fork shader caches containing task/mesh records. Keep
the task/mesh serialization fields enabled for the existing fork cache versions;
omitting them without a version change misaligns subsequent records.

The default is `Release`, 12 jobs, and no tests, matching the Windows release
configuration apart from release publishing metadata. The
[build script](../tools/docker/windows/build.ps1) also accepts `-SourceDir` and
`-BuildDir` (paths inside the container). Image creation checks that the required
tools were installed; source configuration, compilation, and optional tests each
stop on failure.

`ltsc2025` requires a compatible Windows host/kernel; Hyper-V isolation avoids
process-isolation kernel mismatches on supported desktop hosts. This image cannot
run on a Linux Docker daemon or Windows Home. The Visual Studio 2022 installer
uses Microsoft's serviced release channel, so rebuilding the image may update
MSVC and SDK servicing components. Review the Microsoft, Qt, and Vulkan SDK
licenses before building or redistributing the image.
