@echo off
chcp 65001 >nul
echo Mo firewall TCP 80 cho Croak Squad V24...
netsh advfirewall firewall add rule name="CroakSquad V24 TCP 80" dir=in action=allow protocol=TCP localport=80 profile=any
pause
