@echo off
title BUILD AUTO + GITHUB FINAL
color 0A

REM ================================
REM IR PARA PASTA DO SCRIPT
REM ================================
cd /d %~dp0

REM ================================
REM CONFIG
REM ================================
set PYTHON=C:\Python314\python.exe
set VERSAO=2.11
set REPO=RoboticaParana/monitor-arduino

echo.
echo ================================
echo ATUALIZANDO PARA VERSAO %VERSAO%
echo ================================

REM ================================
REM ATUALIZAR monitor.py
REM ================================
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"%VERSAO%\"' | Set-Content monitor.py"

REM ================================
REM ATUALIZAR version.json (SEM ERRO)
REM ================================
echo Atualizando version.json...

(
echo {
echo   "version": "%VERSAO%",
echo   "url": "https://github.com/%REPO%/releases/download/v%VERSAO%/monitor.exe"
echo }
) > version_temp.json

move /Y version_temp.json version.json >nul

REM ================================
REM LIMPAR BUILDS
REM ================================
echo.
echo ================================
echo LIMPANDO BUILDS...
echo ================================

rmdir /s /q build 2>nul
rmdir /s /q dist 2>nul
del *.spec 2>nul

REM ================================
REM BUILD EXE
REM ================================
echo.
echo ================================
echo GERANDO EXE...
echo ================================

%PYTHON% -m PyInstaller --onefile --noconsole --clean ^
--icon=mascote.ico ^
--add-data "mascote.ico;." ^
--hidden-import=serial ^
--hidden-import=serial.tools ^
--hidden-import=serial.tools.list_ports ^
--hidden-import=pystray ^
--hidden-import=PIL ^
--hidden-import=tkinter ^
monitor.py

if not exist dist\monitor.exe (
    echo.
    echo ERRO: monitor.exe NAO FOI GERADO!
    pause
    exit
)

REM ================================
REM COMMIT + PUSH GITHUB
REM ================================
echo.
echo ================================
echo ENVIANDO PARA GITHUB...
echo ================================

git add .

git diff --cached --quiet
if %errorlevel%==0 (
    echo Nenhuma alteracao detectada, forçando commit...
    git commit --allow-empty -m "Versao %VERSAO%"
) else (
    git commit -m "Versao %VERSAO%"
)

git push

REM ================================
REM CRIAR RELEASE
REM ================================
echo.
echo ================================
echo CRIANDO RELEASE...
echo ================================

gh release delete v%VERSAO% -y 2>nul

gh release create v%VERSAO% dist/monitor.exe ^
--title "v%VERSAO%" ^
--notes "Release automatica"

REM ================================
REM BACKUP GOOGLE DRIVE
REM ================================
echo.
echo ================================
echo BACKUP GOOGLE DRIVE...
echo ================================

robocopy "C:\Users\Cleiton\Documents\teste3" "G:\Meu Drive\__00002\teste3" /MIR /R:2 /W:2

REM ================================
REM FINAL
REM ================================
echo.
echo ================================
echo BUILD COMPLETO FINALIZADO!
echo ================================

pause