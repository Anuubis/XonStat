@echo off
set curdir=%cd%
cd /d "%~dp0"
set psql="c:\program files (x86)\postgresql\9.4\bin\psql.exe"
set pgpassword=xonstat

cd ..\sql
%psql% -U xonstat -w xonstatdb <update_player_region.sql
%psql% -U xonstat -w xonstatdb <update_ranks.sql

cd "%curdir%""