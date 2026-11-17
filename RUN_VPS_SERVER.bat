@echo off
chcp 65001 >nul
cd /d "%~dp0"
if not exist dist\CroakSquad.jar call BUILD.bat
if not exist dist\CroakSquad.jar exit /b 1
echo Croak Squad V24 - VPS server
echo Public endpoint: 103.249.117.201:48440
echo NAT: public TCP 48440 -^> internal TCP 80
echo.
echo Checking internal TCP port 80...
netstat -ano | findstr /R /C:":80 .*LISTENING"
netstat -ano | findstr /R /C:":80 .*LISTENING" >nul
if not errorlevel 1 (
  echo.
  echo WARNING: A process is already LISTENING on TCP port 80.
  echo Identify the PID above with: tasklist /FI "PID eq NUMBER"
  echo Do not stop an unknown Windows/IIS service.
  choice /C YN /M "Try starting Croak Squad on port 80 anyway"
  if errorlevel 2 exit /b 2
)
echo.
echo Starting Croak Squad Server V24 on TCP 80...
java -Dfile.encoding=UTF-8 -cp dist\CroakSquad.jar croaksquad.server.ServerMain --nogui 80
pause
