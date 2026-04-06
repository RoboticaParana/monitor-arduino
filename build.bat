@echo off
title GERADOR AGENTE MESTRE v3.5 - ESTAVEL
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

set /p VERSAO=Digite a NOVA VERSAO (ex: 3.5): 
if "!VERSAO!"=="" exit

echo.
echo ===== 2. ATUALIZANDO SCRIPTS =====
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"!VERSAO!\"' | Set-Content monitor.py"
echo { "version": "!VERSAO!", "url": "https://github.com/!REPO!/releases/download/v!VERSAO!/monitor.exe" }>version.json

:: Atualiza o setup.iss com a versão correta antes de compilar
powershell -Command "(Get-Content setup.iss) -replace 'AppVersion=.*', 'AppVersion=!VERSAO!' | Set-Content setup.iss"
powershell -Command "(Get-Content setup.iss) -replace 'OutputBaseFilename=.*', 'OutputBaseFilename=Instalador_Monitor_v!VERSAO!' | Set-Content setup.iss"

echo ===== 3. COMPILANDO (MODO PASTA) =====
rmdir /s /q build dist 2>nul
if not exist Output mkdir Output

:: Compila no modo pasta para evitar erro de DLL
%PYTHON% -m PyInstaller --onedir --noconsole --uac-admin --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py

if not exist dist\monitor\monitor.exe (
    echo [ERRO] Falha na compilacao do PyInstaller!
    pause
    exit
)

:: Copia o executável principal para a raiz da dist para facilitar o upload
copy /y "dist\monitor\monitor.exe" "dist\monitor.exe" >nul

echo ===== 4. GERANDO INSTALADOR =====
if exist %INNO% (
    %INNO% setup.iss
)

echo ===== 5. SINCRONIZANDO GITHUB =====
git add .
git commit -m "Release v!VERSAO!" >nul 2>&1
git push origin main --force

:: Limpa tags antigas para garantir a nova release
git tag -d v!VERSAO! >nul 2>&1
git push origin :refs/tags/v!VERSAO! >nul 2>&1
gh release delete v!VERSAO! -y >nul 2>&1

echo Enviando arquivos para o GitHub...
:: Busca o nome exato do instalador que foi criado na pasta Output
for %%f in (Output\Instalador_Monitor_v!VERSAO!.exe) do set INSTALADOR=%%f

:: CRIA A RELEASE (Tudo em uma linha só)
gh release create v!VERSAO! "./dist/monitor.exe" "!INSTALADOR!" --title "v!VERSAO!" --notes "Versão Estável 3.14 (Modo Pasta)" --latest

if %ERRORLEVEL% equ 0 (
    echo.
    echo ========================================
    echo SUCESSO! Versao !VERSAO! publicada.
    echo ========================================
) else (
    echo.
    echo [ERRO] A Release falhou. Verifique se o arquivo !INSTALADOR! existe.
)

pause