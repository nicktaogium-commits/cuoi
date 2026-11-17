@echo off
chcp 65001 >nul
cd /d "%~dp0"
if not exist dist\CroakSquad.jar call BUILD.bat
rem VPS moi: chay RUN_SERVER.bat --nogui 80 (public 48440 -> internal 80).
java -Dfile.encoding=UTF-8 -cp dist\CroakSquad.jar croaksquad.server.ServerMain %*
pause
