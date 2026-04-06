@echo off
title GERADOR DO AGENTE MESTRE - MONITOR ARDUINO
color 0B
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

REM ================================
REM CONFIGURAÇÃO
REM ================================
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
echo ===== ATUALIZANDO ARQUIVOS =====
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"!VERSAO!\"' | Set-Content monitor.py"
powershell -Command "(Get-Content monitor.py) -replace 'UPDATE_INTERVAL = .*', 'UPDATE_INTERVAL = !INTERVALO!' | Set-Content monitor.py"

echo { "version": "!VERSAO!", "url": "https://github.com/!REPO!/releases/download/v!VERSAO!/monitor.exe" }>version.json

powershell -Command "(Get-Content setup.iss) -replace 'AppVersion=.*', 'AppVersion=!VERSAO!' | Set-Content setup.iss"
powershell -Command "(Get-Content setup.iss) -replace 'OutputBaseFilename=.*', 'OutputBaseFilename=Instalador_Monitor_v!VERSAO!' | Set-Content setup.iss"

REM ================================
REM GIT SYNC
REM ================================
echo ===== SINCRONIZANDO GIT =====
git rebase --abort >nul 2>&1
git branch -M main >nul 2>&1
git add .
git commit -m "Build v!VERSAO!" >nul 2>&1
:: Força o alinhamento com o GitHub
git push origin main --force

REM ================================
REM COMPILAÇÃO
REM ================================
echo ===== GERANDO EXE E INSTALADOR =====
rmdir /s /q build dist 2>nul
if not exist Output mkdir Output

%PYTHON% -m PyInstaller --onefile --noconsole --uac-admin --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py

if exist %INNO% (
    %INNO% setup.iss
)

REM ================================
REM RELEASES GITHUB (AQUI ESTÁ O SEGREDO)
REM ================================
echo ===== ENVIANDO RELEASES =====
:: 1. Tenta deletar se já existir para não dar erro
gh release delete v!VERSAO! -y 2>nul
:: 2. Tenta deletar a tag local e remota para limpar o caminho
git tag -d v!VERSAO! >nul 2>&1
git push origin :refs/tags/v!VERSAO! >nul 2>&1

:: 3. Cria a nova release anexando os dois arquivos
echo Criando release v!VERSAO! no GitHub...
gh release create v!VERSAO! ^
"./dist/monitor.exe" ^
"./Output/Instalador_Monitor_v!VERSAO!.exe" ^
--title "v!VERSAO!" ^
--notes "Agente Mestre v!VERSAO!"

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERRO] Nao foi possivel criar a Release. 
    echo Verifique se voce instalou o 'gh cli' e rodou 'gh auth login'.
)

echo ===== BACKUP =====
if exist "!DESTINO_DRIVE!" (
    robocopy "%cd%" "!DESTINO_DRIVE!" /E /XD build dist __pycache__ .git >nul
)

echo ========================================
echo PROCESSO FINALIZADO v!VERSAO!
echo ========================================
pause