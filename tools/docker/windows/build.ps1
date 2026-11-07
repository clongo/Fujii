# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

param(
    [string]$SourceDir = 'C:\src',
    [string]$BuildDir = 'C:\src\build\docker-windows',
    [ValidateSet('Release', 'RelWithDebInfo', 'Debug')]
    [string]$BuildType = 'Release',
    [ValidateRange(1, 1024)]
    [int]$Jobs = 12,
    [switch]$BuildTests,
    [switch]$Tests
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Test-Path -LiteralPath (Join-Path $SourceDir 'CMakeLists.txt') -PathType Leaf)) {
    throw "No CMakeLists.txt in $SourceDir. Mount the repository at C:\src or pass -SourceDir."
}
if (-not $env:QT_ROOT_DIR) {
    throw 'QT_ROOT_DIR must point to the installed Qt MSVC x64 kit.'
}

$testOption = if ($Tests -or $BuildTests) { 'ON' } else { 'OFF' }
& cmake -S $SourceDir -B $BuildDir -G Ninja `
    "-DCMAKE_BUILD_TYPE=$BuildType" `
    -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl `
    "-DCMAKE_PREFIX_PATH=$env:QT_ROOT_DIR" `
    "-DBUILD_TESTING=$testOption" "-DYUZU_TESTS=$testOption" `
    -DENABLE_QT=ON -DYUZU_CMD=ON `
    -DYUZU_ROOM=OFF -DYUZU_ROOM_STANDALONE=OFF `
    -DYUZU_USE_BUNDLED_QT=OFF -DYUZU_USE_BUNDLED_SDL3=ON `
    -DENABLE_UPDATE_CHECKER=ON -DUSE_DISCORD_PRESENCE=OFF
if ($LASTEXITCODE -ne 0) {
    throw "CMake configuration failed with exit code $LASTEXITCODE"
}

& cmake --build $BuildDir --parallel $Jobs
if ($LASTEXITCODE -ne 0) {
    throw "Build failed with exit code $LASTEXITCODE"
}

if ($Tests) {
    if (-not (Test-Path -LiteralPath "$env:SystemRoot\System32\wlanapi.dll")) {
        throw 'The core tests need wlanapi.dll, which Server Core does not provide. Use -BuildTests and run the compiled test executables on desktop Windows (see docs\Build.md).'
    }
    & ctest --test-dir $BuildDir --output-on-failure --no-tests=error
    if ($LASTEXITCODE -ne 0) {
        throw "Tests failed with exit code $LASTEXITCODE"
    }
}

Write-Host "Build complete. Binaries and runtime dependencies: $BuildDir\bin"
