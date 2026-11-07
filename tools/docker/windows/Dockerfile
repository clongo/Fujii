# escape=`
# SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

FROM mcr.microsoft.com/windows/servercore:ltsc2025

SHELL ["C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

ENV QT_ROOT_DIR="C:\Qt\6.8.3\msvc2022_64" `
    VULKAN_SDK="C:\VulkanSDK\1.4.341.1" `
    Path="C:\Python;C:\Python\Scripts;C:\Git\cmd;C:\Git\usr\bin;C:\Qt\6.8.3\msvc2022_64\bin;C:\VulkanSDK\1.4.341.1\Bin;C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0"

COPY install.ps1 build.ps1 entrypoint.cmd C:\builder\
RUN & C:\builder\install.ps1

WORKDIR C:\src
ENTRYPOINT ["C:\\Windows\\System32\\cmd.exe", "/S", "/C", "C:\\builder\\entrypoint.cmd"]
