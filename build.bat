@echo off
title GERADOR AGENTE B1N0 v6.3
color 0B
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

set PYTHON=python
set INNO="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

set /p VERSAO=Digite a VERSAO (ex: 6.3): 
if "!VERSAO!"=="" exit

echo [1/4] Sincronizando Arquivos e version.json...
echo {"version": "!VERSAO!", "url": "https://github.com/RoboticaParana/monitor-arduino/releases/download/v!VERSAO!/monitor.exe"} > version.json

:: Atualiza versões nos scripts
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"!VERSAO!\"' | Set-Content monitor.py"
powershell -Command "(Get-Content setup.iss) -replace 'AppVersion=.*', 'AppVersion=!VERSAO!' | Set-Content setup.iss"
powershell -Command "(Get-Content setup.iss) -replace 'OutputBaseFilename=.*', 'OutputBaseFilename=Instalador_B1n0_v!VERSAO!' | Set-Content setup.iss"

:: Forçar sincronização total com o GitHub Main
git add .
git commit -m "Preparando v!VERSAO!" >nul 2>&1
git push origin main --force

echo [2/4] Compilando Binario...
rmdir /s /q build dist 2>nul
%PYTHON% -m PyInstaller --onedir --noconsole --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py
copy /y "dist\monitor\monitor.exe" "dist\monitor.exe" >nul

echo [3/4] Gerando Instalador...
if exist %INNO% (%INNO% setup.iss /Q)

echo [4/4] Publicando Release v!VERSAO! (Force Mode)...
:: Deleta tags locais e remotas para evitar o erro 'Tag already exists'
git tag -d v!VERSAO! >nul 2>&1
git push origin :refs/tags/v!VERSAO! >nul 2>&1

:: Cria o release e força o status de 'Latest'
:: Adicionamos o --clobber para sobrescrever arquivos se eles já existirem
gh release create v!VERSAO! "./dist/monitor.exe" "./Output/Instalador_B1n0_v!VERSAO!.exe" --title "v!VERSAO!" --notes "Release v!VERSAO! oficial" --latest --yes --clobber

echo ======================================================
echo PROCESSO CONCLUÍDO.
echo Verifique em: https://github.com/RoboticaParana/monitor-arduino/releases
echo ======================================================
pause