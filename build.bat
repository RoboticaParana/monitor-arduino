@echo off
title BUILDER AGENTE B1N0 v6.4
color 0B
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

set /p VERSAO=Digite a VERSAO (6.4): 
if "!VERSAO!"=="" set VERSAO=6.4

echo [1/4] Atualizando version.json e scripts...
echo {"version": "!VERSAO!", "url": "https://github.com/RoboticaParana/monitor-arduino/releases/download/v!VERSAO!/monitor.exe"} > version.json

powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"!VERSAO!\"' | Set-Content monitor.py"
powershell -Command "(Get-Content setup.iss) -replace 'AppVersion=.*', 'AppVersion=!VERSAO!' | Set-Content setup.iss"
powershell -Command "(Get-Content setup.iss) -replace 'OutputBaseFilename=.*', 'OutputBaseFilename=Instalador_AgenteB1n0_v!VERSAO!' | Set-Content setup.iss"

echo [2/4] Enviando para o GitHub...
git add .
git commit -m "Build v!VERSAO! - Nome e Idioma corrigidos" >nul 2>&1
git push origin main --force

echo [3/4] Compilando Binario...
rmdir /s /q build dist 2>nul
python -m PyInstaller --onedir --noconsole --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py
copy /y "dist\monitor\monitor.exe" "dist\monitor.exe" >nul

echo [4/4] Gerando Instalador e Release...
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" setup.iss /Q
gh release create v!VERSAO! "./dist/monitor.exe" "./Output/Instalador_AgenteB1n0_v!VERSAO!.exe" --title "v!VERSAO!" --latest --yes --clobber

pause