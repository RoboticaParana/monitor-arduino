@echo off
title GERADOR AGENTE B1N0 v5.0
color 0B
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

set PYTHON=python
set INNO="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
set REPO=RoboticaParana/monitor-arduino

if not exist %INNO% set INNO="C:\Users\%USERNAME%\AppData\Local\Programs\Inno Setup 6\ISCC.exe"

set /p VERSAO=Digite a NOVA VERSAO (ex: 5.0): 
if "!VERSAO!"=="" exit

echo ===== 1. ATUALIZANDO ARQUIVOS =====
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"!VERSAO!\"' | Set-Content monitor.py"
echo { "version": "!VERSAO!", "url": "https://github.com/!REPO!/releases/download/v!VERSAO!/monitor.exe" }>version.json
powershell -Command "(Get-Content setup.iss) -replace 'AppVersion=.*', 'AppVersion=!VERSAO!' | Set-Content setup.iss"
powershell -Command "(Get-Content setup.iss) -replace 'OutputBaseFilename=.*', 'OutputBaseFilename=Instalador_B1n0_v!VERSAO!' | Set-Content setup.iss"

echo ===== 2. COMPILANDO =====
rmdir /s /q build dist 2>nul
%PYTHON% -m PyInstaller --onedir --noconsole --clean ^
--icon=mascote.ico --add-data "mascote.ico;." ^
--hidden-import=pyserial --hidden-import=pystray --hidden-import=PIL --hidden-import=requests --hidden-import=tkinter ^
monitor.py

if not exist dist\monitor\monitor.exe (
    echo [ERRO] Falha na compilacao!
    pause
    exit
)
copy /y "dist\monitor\monitor.exe" "dist\monitor.exe" >nul

echo ===== 3. GERANDO INSTALADOR (v5.0) =====
if exist %INNO% (
    %INNO% setup.iss
) else (
    echo [ERRO] Inno Setup nao encontrado.
)

echo ===== 4. GITHUB RELEASE =====
git add .
git commit -m "Release v!VERSAO!" >nul 2>&1
git push origin main --force
git tag -d v!VERSAO! >nul 2>&1
git push origin :refs/tags/v!VERSAO! >nul 2>&1
gh release delete v!VERSAO! -y >nul 2>&1

echo Enviando para o GitHub...
gh release create v!VERSAO! "./dist/monitor.exe" "./Output/Instalador_B1n0_v!VERSAO!.exe" --title "v!VERSAO!" --notes "Agente B1n0 v5.0 - Fix Log Update" --latest

echo PROCESSO v!VERSAO! FINALIZADO.
pause