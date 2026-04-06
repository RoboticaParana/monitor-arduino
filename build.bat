@echo off
title GERADOR AGENTE MESTRE - MONITOR ARDUINO
color 0B
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

set PYTHON=python
set INNO="C:\Users\Cleiton\AppData\Local\Programs\Inno Setup 6\ISCC.exe"
set REPO=RoboticaParana/monitor-arduino

echo ========================================
echo      GERADOR DE VERSAO AGENTE MESTRE
echo ========================================

set /p VERSAO=Digite a NOVA VERSAO (ex: 3.2): 
if "!VERSAO!"=="" exit
set /p INTERVALO=Intervalo de checagem (segundos) [60]: 
if "!INTERVALO!"=="" set INTERVALO=60

echo.
echo ===== 1. ATUALIZANDO ARQUIVOS =====
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"!VERSAO!\"' | Set-Content monitor.py"
powershell -Command "(Get-Content monitor.py) -replace 'UPDATE_INTERVAL = .*', 'UPDATE_INTERVAL = !INTERVALO!' | Set-Content monitor.py"

echo { "version": "!VERSAO!", "url": "https://github.com/!REPO!/releases/download/v!VERSAO!/monitor.exe" }>version.json

powershell -Command "(Get-Content setup.iss) -replace 'AppVersion=.*', 'AppVersion=!VERSAO!' | Set-Content setup.iss"
powershell -Command "(Get-Content setup.iss) -replace 'OutputBaseFilename=.*', 'OutputBaseFilename=Instalador_Monitor_v!VERSAO!' | Set-Content setup.iss"

echo ===== 2. SINCRONIZANDO GIT =====
git branch -M main >nul 2>&1
git add .
git commit -m "Build v!VERSAO!" >nul 2>&1
git push origin main --force

echo ===== 3. COMPILANDO EXE (MODO ROBUSTO) =====
rmdir /s /q build dist 2>nul
if not exist Output mkdir Output

:: O parametro --runtime-tmpdir "." ajuda a evitar o erro de DLL ao atualizar
%PYTHON% -m PyInstaller --onefile --noconsole --uac-admin --clean --icon=mascote.ico --add-data "mascote.ico;." --runtime-tmpdir "." monitor.py

if not exist dist\monitor.exe (
    echo [ERRO] Falha no PyInstaller!
    pause
    exit
)

echo ===== 4. GERANDO INSTALADOR =====
if exist %INNO% (%INNO% setup.iss)

echo ===== 5. CRIANDO RELEASE NO GITHUB =====
git tag -d v!VERSAO! >nul 2>&1
git push origin :refs/tags/v!VERSAO! >nul 2>&1
gh release delete v!VERSAO! -y >nul 2>&1

echo Enviando arquivos...
gh release create v!VERSAO! "./dist/monitor.exe" "./Output/Instalador_Monitor_v!VERSAO!.exe" --title "v!VERSAO!" --notes "Agente Mestre v!VERSAO!" --latest

if %ERRORLEVEL% equ 0 (
    echo [SUCESSO] v!VERSAO! publicada!
) else (
    echo [ERRO] Falha na release do GitHub.
)
pause