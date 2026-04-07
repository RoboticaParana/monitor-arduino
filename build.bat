@echo off
title BUILDER AGENTE B1N0 v6.7
color 0A
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

set /p VERSAO=Digite a VERSAO (6.7): 
if "!VERSAO!"=="" set VERSAO=6.7

echo [1/3] Sincronizando GitHub...
echo {"version": "!VERSAO!", "url": "https://github.com/RoboticaParana/monitor-arduino/releases/download/v!VERSAO!/monitor.exe"} > version.json
git add .
git commit -m "Update to v!VERSAO! (Transparent Version)"
git push origin main --force

echo [2/3] Compilando EXE...
rmdir /s /q build dist 2>nul
python -m PyInstaller --onedir --noconsole --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py
copy /y "dist\monitor\monitor.exe" "dist\monitor.exe" >nul

echo [3/3] Criando Instalador e Release...
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" setup.iss
gh release create v!VERSAO! "./dist/monitor.exe" "./Output/Instalador_AgenteB1n0_v!VERSAO!.exe" --title "v!VERSAO!" --latest --clobber

echo FEITO!
pause