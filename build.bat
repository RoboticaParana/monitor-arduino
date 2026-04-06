@echo off
title GERADOR AGENTE MESTRE v3.9 - ESTAVEL
color 0B
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

REM ================================
REM 1. CONFIGURAÇÃO
REM ================================
set PYTHON=python
set INNO="C:\Users\Cleiton\AppData\Local\Programs\Inno Setup 6\ISCC.exe"
set REPO=RoboticaParana/monitor-arduino

echo ========================================
echo      GERADOR DE VERSAO AGENTE MESTRE
echo ========================================

set /p VERSAO=Digite a NOVA VERSAO (ex: 3.9): 
if "!VERSAO!"=="" exit

echo.
echo ===== 2. ATUALIZANDO SCRIPTS =====
:: Atualiza versão no Python
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"!VERSAO!\"' | Set-Content monitor.py"

:: Gera o JSON de versão
echo { "version": "!VERSAO!", "url": "https://github.com/!REPO!/releases/download/v!VERSAO!/monitor.exe" }>version.json

:: Atualiza o setup.iss
powershell -Command "(Get-Content setup.iss) -replace 'AppVersion=.*', 'AppVersion=!VERSAO!' | Set-Content setup.iss"
powershell -Command "(Get-Content setup.iss) -replace 'OutputBaseFilename=.*', 'OutputBaseFilename=Instalador_Monitor_v!VERSAO!' | Set-Content setup.iss"

echo ===== 3. COMPILANDO (MODO PASTA COM DEPENDENCIAS) =====
:: Limpa pastas antigas
rmdir /s /q build dist 2>nul
if not exist Output mkdir Output

:: Compilação com Hidden Imports para garantir que o ícone e a serial funcionem
%PYTHON% -m PyInstaller --onedir --noconsole --uac-admin --clean ^
--icon=mascote.ico --add-data "mascote.ico;." ^
--hidden-import=pyserial --hidden-import=pystray --hidden-import=PIL --hidden-import=requests ^
monitor.py

if not exist dist\monitor\monitor.exe (
    echo [ERRO] Falha na compilacao do PyInstaller!
    pause
    exit
)

:: Copia o executável principal para a raiz da dist (necessário para o update automático funcionar)
copy /y "dist\monitor\monitor.exe" "dist\monitor.exe" >nul

echo ===== 4. GERANDO INSTALADOR (Inno Setup) =====
if exist %INNO% (
    %INNO% setup.iss
) else (
    echo [ERRO] Caminho do Inno Setup incorreto!
)

echo ===== 5. SINCRONIZANDO GITHUB =====
git add .
git commit -m "Release v!VERSAO!" >nul 2>&1
git push origin main --force

:: Limpa tags antigas para evitar conflitos na Release
git tag -d v!VERSAO! >nul 2>&1
git push origin :refs/tags/v!VERSAO! >nul 2>&1
gh release delete v!VERSAO! -y >nul 2>&1

echo Enviando arquivos para o GitHub...
:: Define o caminho do instalador de forma segura para o comando GH
set "INSTALADOR=./Output/Instalador_Monitor_v!VERSAO!.exe"

:: Cria a Release no GitHub (Tudo em uma única linha para evitar erro de ^)
gh release create v!VERSAO! "./dist/monitor.exe" "%INSTALADOR%" --title "v!VERSAO!" --notes "Versão Estável com Ícone de Bandeja e Log Serial" --latest

if %ERRORLEVEL% equ 0 (
    echo.
    echo ========================================
    echo SUCESSO! Versao !VERSAO! publicada.
    echo ========================================
) else (
    echo.
    echo [ERRO] Falha ao criar release no GitHub.
)

pause