@echo off
title GERADOR DO AGENTE MESTRE - MONITOR ARDUINO
color 0B

:: Garante que o terminal entenda acentos (Robótica)
chcp 65001 >nul

setlocal EnableDelayedExpansion
cd /d %~dp0

REM ================================
REM CONFIGURAÇÃO
REM ================================
:: Usando o comando python que funcionou no seu log
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
echo VERSAO ATUAL NO PROJETO: !VERSAO_ATUAL!
echo ========================================

REM ================================
REM ENTRADA DE DADOS
REM ================================
set /p VERSAO=Digite a NOVA VERSAO (ex: 3.0): 
if "!VERSAO!"=="" (echo Versao invalida! & pause & exit)

set /p INTERVALO=Intervalo de checagem em segundos [60]: 
if "!INTERVALO!"=="" set INTERVALO=60

echo.
echo ===== INICIANDO COMPILAÇÃO v!VERSAO! =====

REM ================================
REM ATUALIZAR SCRIPTS (PowerShell)
REM ================================
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"!VERSAO!\"' | Set-Content monitor.py"
powershell -Command "(Get-Content monitor.py) -replace 'UPDATE_INTERVAL = .*', 'UPDATE_INTERVAL = !INTERVALO!' | Set-Content monitor.py"

:: Gera o version.json (O link aponta para o monitor.exe direto)
echo {>version.json
echo   "version": "!VERSAO!",>>version.json
echo   "url": "https://github.com/!REPO!/releases/download/v!VERSAO!/monitor.exe">>version.json
echo }>>version.json

:: Atualiza o script do instalador Inno Setup
powershell -Command "(Get-Content setup.iss) -replace 'AppVersion=.*', 'AppVersion=!VERSAO!' | Set-Content setup.iss"
powershell -Command "(Get-Content setup.iss) -replace 'OutputBaseFilename=.*', 'OutputBaseFilename=Instalador_Monitor_v!VERSAO!' | Set-Content setup.iss"

REM ================================
REM LIMPEZA E SYNC GIT (Anti-Erro)
REM ================================
echo ===== SINCRONIZANDO REPOSITÓRIO =====
:: Cancela qualquer rebase travado de antes
git rebase --abort >nul 2>&1
:: Garante que a branch se chama main
git branch -M main >nul 2>&1

git add .
git commit -m "Preparando Release v!VERSAO!" >nul 2>&1
:: O pull tenta baixar novidades, se falhar ele ignora e segue
git pull origin main --rebase >nul 2>&1

echo Limpando builds antigos...
rmdir /s /q build 2>nul
rmdir /s /q dist 2>nul
if not exist Output mkdir Output

REM ================================
REM BUILD DO EXECUTÁVEL (PyInstaller)
REM ================================
echo ===== GERANDO EXE (Agente) =====
%PYTHON% -m PyInstaller --onefile --noconsole --uac-admin --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py

if not exist dist\monitor.exe (
    echo [ERRO] O PyInstaller falhou!
    pause
    exit
)

REM ================================
REM GERAR INSTALADOR (Inno Setup)
REM ================================
echo ===== GERANDO INSTALADOR MESTRE =====
if exist %INNO% (
    %INNO% setup.iss
) else (
    echo [ERRO] Inno Setup nao encontrado em %INNO%
    pause
    exit
)

REM ================================
REM GITHUB RELEASE (Anti-Erro)
REM ================================
echo ===== PUBLICANDO NO GITHUB =====
git add .
git commit -m "Release Final v!VERSAO!" >nul 2>&1
:: Envia forçado para garantir que a main do PC e do GitHub sejam iguais
git push origin main --force

echo ===== CRIANDO RELEASE =====
where gh >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo Verificando e deletando release antiga v!VERSAO! se existir...
    gh release delete v!VERSAO! -y 2>nul
    timeout /t 2 > nul
    
    echo Criando nova release v!VERSAO!...
    gh release create v!VERSAO! ^
    dist\monitor.exe ^
    Output\Instalador_Monitor_v!VERSAO!.exe ^
    --title "v!VERSAO!" --notes "Agente Mestre - Instalação única. Intervalo: !INTERVALO!s"
) else (
    echo [AVISO] GitHub CLI (gh) nao encontrado. Release nao criada automaticamente.
)

REM ================================
REM BACKUP DRIVE
REM ================================
if exist "!DESTINO_DRIVE!" (
    echo ===== REALIZANDO BACKUP NO DRIVE =====
    robocopy "%cd%" "!DESTINO_DRIVE!" /E /XD build dist __pycache__ .git >nul
)

echo.
echo ========================================
echo BUILD v!VERSAO! FINALIZADO COM SUCESSO!
echo ========================================
pause