@echo off
cd /d "%~dp0"
if not exist dist\CroakSquad.jar call BUILD.bat
java -Dfile.encoding=UTF-8 -jar dist\CroakSquad.jar
pause
