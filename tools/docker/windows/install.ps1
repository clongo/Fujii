# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

function Install-Tool {
    param(
        [string]$Uri,
        [string]$FileName,
        [string[]]$Arguments,
        [int[]]$SuccessCodes = @(0)
    )

    $destination = Join-Path $env:TEMP $FileName
    Invoke-WebRequest -UseBasicParsing -Uri $Uri -OutFile $destination
    $process = Start-Process -FilePath $destination -ArgumentList $Arguments -Wait -PassThru
    if ($process.ExitCode -notin $SuccessCodes) {
        throw "$FileName failed with exit code $($process.ExitCode)"
    }
    Remove-Item -LiteralPath $destination
}

Install-Tool -Uri 'https://aka.ms/vs/17/release/vs_buildtools.exe' `
    -FileName 'vs_buildtools.exe' -SuccessCodes @(0, 3010) -Arguments @(
        '--quiet', '--wait', '--norestart', '--nocache',
        '--installPath', 'C:\BuildTools',
        '--add', 'Microsoft.VisualStudio.Workload.VCTools',
        '--add', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
        '--add', 'Microsoft.VisualStudio.Component.Windows11SDK.22621'
    )

Install-Tool -Uri 'https://www.python.org/ftp/python/3.12.10/python-3.12.10-amd64.exe' `
    -FileName 'python.exe' -Arguments @(
        '/quiet', 'InstallAllUsers=1', 'TargetDir=C:\Python',
        'Include_launcher=0', 'Include_test=0', 'Include_pip=1', 'PrependPath=0'
    )

Install-Tool -Uri 'https://github.com/git-for-windows/git/releases/download/v2.49.0.windows.1/Git-2.49.0-64-bit.exe' `
    -FileName 'git-installer.exe' -Arguments @(
        '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-', '/DIR=C:\Git'
    )

& python -m pip install --no-cache-dir cmake==3.31.10 ninja==1.13.0 aqtinstall==3.3.0
if ($LASTEXITCODE -ne 0) {
    throw "Installing Python build tools failed with exit code $LASTEXITCODE"
}

& python -m aqt install-qt windows desktop 6.8.3 win64_msvc2022_64 -O C:\Qt -m qtcharts
if ($LASTEXITCODE -ne 0) {
    throw "Installing Qt failed with exit code $LASTEXITCODE"
}

Install-Tool -Uri 'https://sdk.lunarg.com/sdk/download/1.4.341.1/windows/vulkansdk-windows-X64-1.4.341.1.exe' `
    -FileName 'vulkan-sdk.exe' -Arguments @(
        '--root', $env:VULKAN_SDK,
        '--accept-licenses', '--default-answer', '--confirm-command', 'install'
    )

foreach ($file in @(
    'C:\BuildTools\VC\Auxiliary\Build\vcvars64.bat',
    'C:\Python\python.exe',
    'C:\Python\Scripts\cmake.exe',
    'C:\Python\Scripts\ninja.exe',
    'C:\Git\cmd\git.exe',
    "$env:QT_ROOT_DIR\bin\windeployqt.exe",
    "$env:VULKAN_SDK\Include\vulkan\vulkan.h"
)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "Required build tool is missing after installation: $file"
    }
}

& $env:ComSpec /d /s /c 'call C:\BuildTools\VC\Auxiliary\Build\vcvars64.bat && where cl && cmake --version && ninja --version && python --version && git --version'
if ($LASTEXITCODE -ne 0) {
    throw "Build tool smoke check failed with exit code $LASTEXITCODE"
}
