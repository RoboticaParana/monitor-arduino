@echo off
title GERADOR AGENTE B1N0 v6.1
color 0B
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

:: --- CONFIGURAÇÃO DE AMBIENTE ---
set PYTHON=python
set INNO="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if not exist %INNO% set INNO="C:\Users\%USERNAME%\AppData\Local\Programs\Inno Setup 6\ISCC.exe"

:: --- ENTRADA DE DADOS ---
set /p VERSAO=Digite apenas o numero da VERSAO (ex: 6.1): 
if "!VERSAO!"=="" exit

echo [1/4] Sincronizando GitHub (Modo Silencioso)...
:: Garante que o Git não peça nome/email se não estiver configurado
git config user.email "bot@roboticaparana.com.br"
git config user.name "B1n0 Builder"

:: Atualiza os arquivos com a nova versão
echo {"version": "!VERSAO!", "url": "https://github.com/RoboticaParana/monitor-arduino/releases/download/v!VERSAO!/monitor.exe"} > version.json
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"!VERSAO!\"' | Set-Content monitor.py"
powershell -Command "(Get-Content setup.iss) -replace 'AppVersion=.*', 'AppVersion=!VERSAO!' | Set-Content setup.iss"
powershell -Command "(Get-Content setup.iss) -replace 'OutputBaseFilename=.*', 'OutputBaseFilename=Instalador_B1n0_v!VERSAO!' | Set-Content setup.iss"

:: Envia para o GitHub antes de compilar
git add .
git commit -m "Automated build v!VERSAO!" >nul 2>&1
git push origin main -f >nul 2>&1

echo [2/4] Compilando Binario (PyInstaller)...
rmdir /s /q build dist 2>nul
%PYTHON% -m PyInstaller --onedir --noconsole --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py
copy /y "dist\monitor\monitor.exe" "dist\monitor.exe" >nul

echo [3/4] Gerando Instalador (Inno Setup)...
if exist %INNO% (%INNO% setup.iss /Q)

echo [4/4] Criando Release no GitHub...
:: O parametro -y ou --yes evita perguntas do tipo "deseja continuar?"
gh release create v!VERSAO! "./dist/monitor.exe" "./Output/Instalador_B1n0_v!VERSAO!.exe" --title "v!VERSAO!" --notes "Build v!VERSAO! - Protecao Anti-Fechamento" --latest --yes

echo ======================================================
echo FINALIZADO COM SUCESSO! VERSAO !VERSAO! NO AR.
echo ======================================================
pause