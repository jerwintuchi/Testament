@echo off
REM Testament — start the server and the client from Windows, with no WSL terminal.
REM
REM Run from cmd, or make a desktop shortcut to it:
REM     \\wsl.localhost\Ubuntu-24.04\home\jerwin\projects\Testament\tools\playtest.bat
REM
REM The server runs inside WSL (that is where the repo and node_modules live); the client
REM is Windows-side Godot. Closing the server window stops the server.
REM
REM Does NOT use the script's own folder as a working directory: cmd cannot cd into a UNC
REM path, so every path below is absolute.

setlocal
set DISTRO=Ubuntu-24.04
set REPO=/home/jerwin/projects/Testament
set GODOT=D:\Godot_v4.7-stable_win64.exe
set CLIENT=\\wsl.localhost\Ubuntu-24.04\home\jerwin\projects\Testament\client

echo Starting the Testament server in WSL...
start "Testament server" wsl.exe -d %DISTRO% --cd %REPO% -- bash tools/playtest.sh

REM Ask WSL for its current address. It is reassigned on every WSL restart, which is the
REM usual reason the client reports "server offline" with a perfectly good command.
for /f "usebackq tokens=1" %%i in (`wsl.exe -d %DISTRO% -- hostname -I`) do set WSLIP=%%i

echo Waiting for the server to bind...
timeout /t 4 /nobreak >nul

if not exist "%GODOT%" (
  echo.
  echo   Godot not found at %GODOT%
  echo   Edit GODOT in this file, or launch the client yourself:
  echo     "%GODOT%" --path "%CLIENT%" -- --server=ws://%WSLIP%:3001
  echo.
  pause
  exit /b 1
)

echo Launching the client against ws://%WSLIP%:3001
start "" "%GODOT%" --path "%CLIENT%" -- --server=ws://%WSLIP%:3001
endlocal
