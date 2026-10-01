@echo off
setlocal
set VSLANG=1033
set "ROOT=%~dp0"
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
  echo Install Visual Studio Build Tools with Desktop development with C++.
  exit /b 1
)
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSINSTALL=%%i"
if not defined VSINSTALL exit /b 1
call "%VSINSTALL%\Common7\Tools\VsDevCmd.bat" -arch=x64 -host_arch=x64
if errorlevel 1 exit /b 1
where make.exe >nul 2>&1
if errorlevel 1 set "PATH=%PATH%;C:\msys64\usr\bin"
for %%i in (git.exe cmake.exe nasm.exe make.exe) do (
  where %%i >nul 2>&1
  if errorlevel 1 (
    echo Missing %%i. See README.md prerequisites.
    exit /b 1
  )
)
for /f "delims=" %%i in ('where git.exe') do if not defined GIT_EXE set "GIT_EXE=%%i"
for %%i in ("%GIT_EXE%") do set "GIT_BIN_DIR=%%~dpi"
set "BASH=%GIT_BIN_DIR%..\bin\bash.exe"
if not exist "%BASH%" (
  echo Git for Windows bash.exe was not found. Put Git for Windows cmd directory first in PATH.
  exit /b 1
)
"%BASH%" --noprofile --norc "%ROOT%integration\build-windows.sh"
exit /b %ERRORLEVEL%
