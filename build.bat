@echo off
title GERADOR AGENTE B1N0 v6.2
color 0B
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

set PYTHON=python
set INNO="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if not exist %INNO% set INNO="C:\Users\%USERNAME%\AppData\Local\Programs\Inno Setup 6\ISCC.exe"

set /p VERSAO=Digite a VERSAO (ex: 6.2): 
if "!VERSAO!"=="" exit

echo [1/4] Sincronizando Arquivos e Tags...
:: Atualiza os arquivos locais
echo {"version": "!VERSAO!", "url": "https://github.com/RoboticaParana/monitor-arduino/releases/download/v!VERSAO!/monitor.exe"} > version.json
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"!VERSAO!\"' | Set-Content monitor.py"
powershell -Command "(Get-Content setup.iss) -replace 'AppVersion=.*', 'AppVersion=!VERSAO!' | Set-Content setup.iss"
powershell -Command "(Get-Content setup.iss) -replace 'OutputBaseFilename=.*', 'OutputBaseFilename=Instalador_B1n0_v!VERSAO!' | Set-Content setup.iss"

:: Limpa tags antigas para evitar conflito no release
git tag -d v!VERSAO! >nul 2>&1
git push --delete origin v!VERSAO! >nul 2>&1

:: Envia arquivos para o Main
git add .
git commit -m "Release v!VERSAO!" >nul 2>&1
git push origin main

echo [2/4] Compilando EXE...
rmdir /s /q build dist 2>nul
%PYTHON% -m PyInstaller --onedir --noconsole --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py
copy /y "dist\monitor\monitor.exe" "dist\monitor.exe" >nul

echo [3/4] Gerando Instalador...
if exist %INNO% (%INNO% setup.iss /Q)

echo [4/4] Publicando Release v!VERSAO!...
:: O comando agora força a criação da tag e do release como 'Latest'
gh release create v!VERSAO! "./dist/monitor.exe" "./Output/Instalador_B1n0_v!VERSAO!.exe" --title "v!VERSAO!" --notes "Versão v!VERSAO! com correções de persistência" --latest --yes

echo ======================================================
echo VERIFIQUE AGORA: https://github.com/RoboticaParana/monitor-arduino/releases
echo ======================================================
pause