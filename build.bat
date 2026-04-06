@echo off
title GERADOR DO AGENTE MESTRE - MONITOR ARDUINO
color 0B
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

REM ================================
REM CONFIGURAÇÃO
REM ================================
:: Tenta usar o comando 'python' global do sistema
set PYTHON=python
set INNO="C:\Users\Cleiton\AppData\Local\Programs\Inno Setup 6\ISCC.exe"
set REPO=RoboticaParana/monitor-arduino
set DESTINO_DRIVE=G:\Meu Drive\__00002\teste3

REM ================================
REM PEGAR VERSÃO ATUAL
REM ================================
set VERSAO_ATUAL=0.0.0
if exist version.json (
    for /f "tokens=2 delims=:," %%a in ('findstr "version" version.json') do (
        set VERSAO_ATUAL=%%a
    )
)
set VERSAO_ATUAL=!VERSAO_ATUAL:"=!
set VERSAO_ATUAL=!VERSAO_ATUAL: =!

echo ========================================
echo VERSAO ATUAL: !VERSAO_ATUAL!
echo ========================================

set /p VERSAO=Digite a NOVA VERSAO: 
if "!VERSAO!"=="" exit
set /p INTERVALO=Intervalo (segundos) [60]: 
if "!INTERVALO!"=="" set INTERVALO=60

echo.
echo ===== INICIANDO COMPILAÇÃO v!VERSAO! =====

REM ATUALIZAR SCRIPTS
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"!VERSAO!\"' | Set-Content monitor.py"
powershell -Command "(Get-Content monitor.py) -replace 'UPDATE_INTERVAL = .*', 'UPDATE_INTERVAL = !INTERVALO!' | Set-Content monitor.py"

echo { "version": "!VERSAO!", "url": "https://github.com/!REPO!/releases/download/v!VERSAO!/monitor.exe" }>version.json

powershell -Command "(Get-Content setup.iss) -replace 'AppVersion=.*', 'AppVersion=!VERSAO!' | Set-Content setup.iss"
powershell -Command "(Get-Content setup.iss) -replace 'OutputBaseFilename=.*', 'OutputBaseFilename=Instalador_Monitor_v!VERSAO!' | Set-Content setup.iss"

REM ================================
REM CORREÇÃO DO GIT
REM ================================
if not exist .git (
    echo Inicializando repositório Git...
    git init
    git remote add origin https://github.com/!REPO!.git
)

echo ===== SINCRONIZANDO =====
git add .
git commit -m "Preparando v!VERSAO!" >nul 2>&1
:: O pull só funciona se já houver algo no GitHub, se der erro aqui ele ignora e segue
git pull origin main --rebase >nul 2>&1

echo Limpando pastas...
rmdir /s /q build dist 2>nul
if not exist Output mkdir Output

REM ================================
REM BUILD EXE
REM ================================
echo ===== GERANDO EXE (Agente) =====
%PYTHON% -m PyInstaller --onefile --noconsole --uac-admin --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py

if not exist dist\monitor.exe (
    echo [ERRO] O PyInstaller falhou! Tentando comando alternativo...
    py -m PyInstaller --onefile --noconsole --uac-admin --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py
)

if not exist dist\monitor.exe (
    echo [ERRO CRITICO] Python ou PyInstaller nao encontrados.
    pause
    exit
)

REM ================================
REM INSTALADOR E GITHUB
REM ================================
if exist %INNO% (
    echo ===== GERANDO INSTALADOR =====
    %INNO% setup.iss
)

echo ===== ENVIANDO PARA GITHUB =====
git add .
git commit -m "Release v!VERSAO!"
git push origin main

echo ===== CRIANDO RELEASE =====
gh release create v!VERSAO! dist\monitor.exe Output\Instalador_Monitor_v!VERSAO!.exe --title "v!VERSAO!" --notes "Agente Mestre"

echo Sucesso!
pause