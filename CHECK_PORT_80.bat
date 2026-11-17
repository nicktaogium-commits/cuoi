@echo off
chcp 65001 >nul
echo ===== KIEM TRA TCP PORT 80 TREN VPS =====
netstat -ano | findstr ":80"
echo.
echo Neu co dong LISTENING tai :80, cong dang duoc mot tien trinh su dung.
echo Nhin PID o cot cuoi, sau do chay: tasklist /FI "PID eq SO_PID"
echo Khong tat tien trinh neu chua biet no la gi.
pause
