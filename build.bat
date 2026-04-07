@echo off
title BUILDER AGENTE B1N0 v6.8
color 0A
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

:: --- BUSCA DINÂMICA DO INNO SETUP ---
set INNO=""
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" set INNO="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist "C:\Users\%USERNAME%\AppData\Local\Programs\Inno Setup 6\ISCC.exe" set INNO="C:\Users\%USERNAME%\AppData\Local\Programs\Inno Setup 6\ISCC.exe"

set /p VERSAO=Digite a VERSAO (6.8): 
if "!VERSAO!"=="" set VERSAO=6.8

echo [1/3] Sincronizando GitHub...
echo {"version": "!VERSAO!", "url": "https://github.com/RoboticaParana/monitor-arduino/releases/download/v!VERSAO!/monitor.exe"} > version.json
git add .
git commit -m "Update to v!VERSAO!" >nul 2>&1
git push origin main --force

echo [2/3] Compilando EXE...
rmdir /s /q build dist 2>nul
python -m PyInstaller --onedir --noconsole --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py
copy /y "dist\monitor\monitor.exe" "dist\monitor.exe" >nul

echo [3/3] Criando Instalador e Release...
:: Tenta rodar o Inno Setup se encontrado
if %INNO% == "" (
    echo [AVISO] Inno Setup nao encontrado. Pulando geracao do instalador.
) else (
    %INNO% setup.iss /Q
)

:: REMOVIDO --clobber para compatibilidade com sua versao do gh
:: Se o release ja existir, o comando abaixo pode avisar, mas seguira em frente
gh release create v!VERSAO! "./dist/monitor.exe" "./Output/Instalador_AgenteB1n0_v!VERSAO!.exe" --title "v!VERSAO!" --notes "Release v!VERSAO!" --latest

echo.
echo ======================================================
echo PROCESSO FINALIZADO!
echo ======================================================
pause