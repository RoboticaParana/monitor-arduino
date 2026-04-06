@echo off
title GERADOR AGENTE MESTRE v3.0
color 0B
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

set PYTHON=python
set INNO="C:\Users\Cleiton\AppData\Local\Programs\Inno Setup 6\ISCC.exe"
set REPO=RoboticaParana/monitor-arduino

set /p VERSAO=Digite a NOVA VERSAO (ex: 3.0): 
if "!VERSAO!"=="" exit

echo.
echo ===== 1. ATUALIZANDO ARQUIVOS =====
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"!VERSAO!\"' | Set-Content monitor.py"
echo { "version": "!VERSAO!", "url": "https://github.com/!REPO!/releases/download/v!VERSAO!/monitor.exe" }>version.json
powershell -Command "(Get-Content setup.iss) -replace 'AppVersion=.*', 'AppVersion=!VERSAO!' | Set-Content setup.iss"
powershell -Command "(Get-Content setup.iss) -replace 'OutputBaseFilename=.*', 'OutputBaseFilename=Instalador_Monitor_v!VERSAO!' | Set-Content setup.iss"

echo ===== 2. SINCRONIZANDO GIT (FORÇADO) =====
git branch -M main >nul 2>&1
git add .
git commit -m "Release v!VERSAO!" >nul 2>&1
git push origin main --force

echo ===== 3. COMPILANDO EXE E INSTALADOR =====
rmdir /s /q build dist 2>nul
%PYTHON% -m PyInstaller --onefile --noconsole --uac-admin --clean --icon=mascote.ico --add-data "mascote.ico;." monitor.py
if exist %INNO% (%INNO% setup.iss)

echo ===== 4. CRIANDO RELEASE NO GITHUB =====
:: Tenta deletar a tag local e remota para limpar o caminho antes de criar
git tag -d v!VERSAO! >nul 2>&1
git push origin :refs/tags/v!VERSAO! >nul 2>&1
gh release delete v!VERSAO! -y >nul 2>&1

:: Comando principal de criação
echo Enviando arquivos para o GitHub...
gh release create v!VERSAO! ^
"./dist/monitor.exe" ^
"./Output/Instalador_Monitor_v!VERSAO!.exe" ^
--title "v!VERSAO!" ^
--notes "Agente Mestre v!VERSAO!"

if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCESSO] Versao !VERSAO! enviada!
) else (
    echo.
    echo [ERRO] Falha ao criar release. Verifique a mensagem acima.
)

echo.
echo Pressione qualquer tecla para fechar...
pause >nul