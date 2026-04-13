@echo off
title BUILDER B1N0 v7.2
color 0B
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

:: BUSCA DO INNO SETUP
set INNO=""
for %%G in (
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" 
    "%LocalAppData%\Programs\Inno Setup 6\ISCC.exe"
    "C:\Program Files\Inno Setup 6\ISCC.exe"
) do (if exist %%G set INNO=%%G)

set VERSAO=7.2

echo [1/3] Sincronizando GitHub v!VERSAO!...
echo {"version": "!VERSAO!", "url": "https://github.com/RoboticaParana/monitor-arduino/releases/download/v!VERSAO!/monitor.exe"} > version.json
git add .
git commit -m "Nova Versao Baseada na Estabilidade (v!VERSAO!)" >nul 2>&1
git push origin main --force

echo [2/3] Compilando EXE...
rmdir /s /q build dist 2>nul
python -m PyInstaller --onedir --noconsole --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py
copy /y "dist\monitor\monitor.exe" "dist\monitor.exe" >nul

echo [3/3] Criando Instalador e Release...
if not exist "Output" mkdir "Output"
if %INNO% == "" (
    echo [ERRO] Inno Setup nao encontrado!
) else (
    %INNO% setup.iss /Q
)

:: Comando de release sem flags incompativeis
gh release create v!VERSAO! "./dist/monitor.exe" "./Output/Instalador_AgenteB1n0_v!VERSAO!.exe" --title "v!VERSAO!" --notes "Nova build v!VERSAO! (Base v5.1)" --latest

echo.
echo ======================================================
echo PROCESSO v!VERSAO! FINALIZADO!
echo ======================================================
pause