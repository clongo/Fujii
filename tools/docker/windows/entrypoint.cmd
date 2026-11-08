@echo off
rem SPDX-FileCopyrightText: Copyright 2026 Eden Emulator Project
rem SPDX-License-Identifier: GPL-3.0-or-later

call C:\BuildTools\VC\Auxiliary\Build\vcvars64.bat
if errorlevel 1 exit /b %errorlevel%

C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\builder\build.ps1 %*
exit /b %errorlevel%
