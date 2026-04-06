@echo off
title GERADOR AGENTE MESTRE v3.4 - MODO ESTAVEL
color 0B
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

set PYTHON=python
set INNO="C:\Users\Cleiton\AppData\Local\Programs\Inno Setup 6\ISCC.exe"
set REPO=RoboticaParana/monitor-arduino

set /p VERSAO=Digite a NOVA VERSAO (ex: 3.4): 
if "!VERSAO!"=="" exit

echo ===== 1. ATUALIZANDO SCRIPTS =====
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"!VERSAO!\"' | Set-Content monitor.py"
echo { "version": "!VERSAO!", "url": "https://github.com/!REPO!/releases/download/v!VERSAO!/monitor.exe" }>version.json

echo ===== 2. COMPILANDO (MODO DIRETORIO PARA ESTABILIDADE) =====
rmdir /s /q build dist 2>nul
:: Mudamos para --onedir para evitar o erro de Python DLL
%PYTHON% -m PyInstaller --onedir --noconsole --uac-admin --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py

if not exist dist\monitor\monitor.exe (
    echo [ERRO] Falha na compilacao!
    pause
    exit
)

:: Criamos uma copia do executavel principal fora da pasta para o GitHub ler
copy /y "dist\monitor\monitor.exe" "dist\monitor.exe"

echo ===== 3. GERANDO INSTALADOR =====
if exist %INNO% (%INNO% setup.iss)

echo ===== 4. GITHUB RELEASE =====
git add .
git commit -m "Release v!VERSAO!" >nul 2>&1
git push origin main --force

gh release delete v!VERSAO! -y >nul 2>&1
gh release create v!VERSAO! "./dist/monitor.exe" "./Output/Instalador_Monitor_v!VERSAO!.exe" --title "v!VERSAO!" --notes "Versao Estavel" --latest

pause