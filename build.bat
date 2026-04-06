@echo off
title GERADOR AGENTE MESTRE - MONITOR ARDUINO
color 0B
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

REM ================================
REM 1. CONFIGURAÇÃO DE CAMINHOS
REM ================================
:: Usando 'python' direto pois seu sistema reconheceu assim no log anterior
set PYTHON=python
:: Caminho do Inno Setup no seu usuário Cleiton
set INNO="C:\Users\Cleiton\AppData\Local\Programs\Inno Setup 6\ISCC.exe"
set REPO=RoboticaParana/monitor-arduino

echo ========================================
echo      GERADOR DE VERSAO AGENTE MESTRE
echo ========================================

REM ================================
REM 2. ENTRADA DE DADOS
REM ================================
set /p VERSAO=Digite a NOVA VERSAO (ex: 3.0): 
if "!VERSAO!"=="" (
    echo [ERRO] Versao vazia. Saindo...
    pause
    exit
)

set /p INTERVALO=Intervalo de checagem (segundos) [60]: 
if "!INTERVALO!"=="" set INTERVALO=60

echo.
echo ===== 3. ATUALIZANDO SCRIPTS (Python e Inno) =====
:: Atualiza a versão e intervalo no código-fonte
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"!VERSAO!\"' | Set-Content monitor.py"
powershell -Command "(Get-Content monitor.py) -replace 'UPDATE_INTERVAL = .*', 'UPDATE_INTERVAL = !INTERVALO!' | Set-Content monitor.py"

:: Gera o arquivo JSON que os agentes usam para saber se precisam atualizar
echo { "version": "!VERSAO!", "url": "https://github.com/!REPO!/releases/download/v!VERSAO!/monitor.exe" }>version.json

:: Atualiza os campos de versão no script do Instalador (Inno Setup)
powershell -Command "(Get-Content setup.iss) -replace 'AppVersion=.*', 'AppVersion=!VERSAO!' | Set-Content setup.iss"
powershell -Command "(Get-Content setup.iss) -replace 'OutputBaseFilename=.*', 'OutputBaseFilename=Instalador_Monitor_v!VERSAO!' | Set-Content setup.iss"

echo ===== 4. SINCRONIZANDO GIT (Branch Main) =====
git branch -M main >nul 2>&1
git add .
git commit -m "Preparando v!VERSAO!" >nul 2>&1
:: Força o envio do código para o GitHub
git push origin main --force

echo ===== 5. COMPILANDO EXE (PyInstaller) =====
:: Limpa pastas de builds antigos
rmdir /s /q build dist 2>nul
if not exist Output mkdir Output

%PYTHON% -m PyInstaller --onefile --noconsole --uac-admin --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py

if not exist dist\monitor.exe (
    echo [ERRO] O PyInstaller falhou em gerar o monitor.exe!
    pause
    exit
)

echo ===== 6. GERANDO INSTALADOR (Inno Setup) =====
if exist %INNO% (
    %INNO% setup.iss
) else (
    echo [AVISO] Inno Setup nao encontrado em %INNO%. Pulando instalador...
)

echo ===== 7. CRIANDO RELEASE NO GITHUB (Barra Lateral) =====
:: Limpa tags antigas locais e remotas para evitar conflito
git tag -d v!VERSAO! >nul 2>&1
git push origin :refs/tags/v!VERSAO! >nul 2>&1
gh release delete v!VERSAO! -y >nul 2>&1

echo Enviando arquivos e atualizando barra lateral para v!VERSAO!...
:: O COMANDO ABAIXO DEVE FICAR EM UMA LINHA SO PARA EVITAR O ERRO DO "^"
gh release create v!VERSAO! "./dist/monitor.exe" "./Output/Instalador_Monitor_v!VERSAO!.exe" --title "v!VERSAO!" --notes "Agente Mestre v!VERSAO! - Instalacao Unica" --latest

if %ERRORLEVEL% equ 0 (
    echo.
    echo ===================================================
    echo [SUCESSO] Versao !VERSAO! agora e a OFICIAL!
    echo Verifique em: https://github.com/!REPO!/releases
    echo ===================================================
) else (
    echo.
    echo [ERRO] A Release nao foi criada no GitHub.
    echo Verifique se o 'gh auth login' foi feito corretamente.
)

echo.
echo Pressione qualquer tecla para encerrar...
pause >nul