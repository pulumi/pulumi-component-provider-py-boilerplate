@echo off
setlocal
set SCRIPT_DIR=%~dp0
%SCRIPT_DIR%\venv\Scripts\python.exe %SCRIPT_DIR%\run-provider.py %*
