@echo off

:: Run as administrator ::

SET MODULEDIR=IMM-Module

echo "Installing modules from %~dp0%MODULEDIR%"
xcopy "%~dp0%MODULEDIR%" "%WINDIR%\System32\WindowsPowerShell\v1.0\Modules\%MODULEDIR%" /y /s /i /d
pause
