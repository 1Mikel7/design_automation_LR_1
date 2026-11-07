@echo off
cd /d "%~dp0"
if not exist build mkdir build
iverilog -g2012 -o build\sim.vvp ..\rtl\apb_slave.sv ..\tb\apb_master.sv ..\tb\top.sv
if errorlevel 1 exit /b 1
vvp build\sim.vvp %*