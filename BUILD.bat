@echo off
rem Biên dịch KHÔNG cần NetBeans (cần JDK 8 trở lên có lệnh javac)
cd /d "%~dp0"
if exist out rmdir /s /q out
mkdir out
dir /s /b src\*.java > sources.txt
javac -encoding UTF-8 -source 8 -target 8 -d out @sources.txt
if errorlevel 1 (echo Bien dich that bai & del sources.txt & pause & exit /b 1)
del sources.txt
xcopy /E /I /Y /Q src\assets out\assets >nul
if not exist dist mkdir dist
jar cfm dist\CroakSquad.jar manifest.mf -C out .
echo Xong! File: dist\CroakSquad.jar
pause
