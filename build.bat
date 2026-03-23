@echo off
title BUILD AUTO + GITHUB
color 0A

cd /d %~dp0

REM ================================
REM CONFIG
REM ================================
set PYTHON=C:\Python314\python.exe
set VERSAO=2.10
set REPO=RoboticaParana/monitor-arduino

echo ================================
echo ATUALIZANDO VERSAO %VERSAO%
echo ================================

REM ================================
REM ATUALIZAR monitor.py
REM ================================
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"%VERSAO%\"' | Set-Content monitor.py"

REM ================================
REM GARANTIR version.json
REM ================================
if not exist version.json (
    echo Criando version.json...
    (
    echo {
    echo   "version": "%VERSAO%",
    echo   "url": "https://github.com/%REPO%/releases/download/v%VERSAO%/monitor.exe"
    echo }
    ) > version.json
) else (
    powershell -Command "(Get-Content version.json) -replace '\"version\": \".*\"', '\"version\": \"%VERSAO%\"' | Set-Content version.json"
    powershell -Command "(Get-Content version.json) -replace 'releases/download/v.*/monitor.exe', 'releases/download/v%VERSAO%/monitor.exe' | Set-Content version.json"
)

REM ================================
REM LIMPAR BUILD
REM ================================
rmdir /s /q build 2>nul
rmdir /s /q dist 2>nul
del *.spec 2>nul

REM ================================
REM BUILD EXE
REM ================================
echo.
echo GERANDO EXE...

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
    echo ERRO NO BUILD
    pause
    exit
)

REM ================================
REM GIT COMMIT + PUSH
REM ================================
echo.
echo ================================
echo ENVIANDO PARA GITHUB
echo ================================

git add .
git commit -m "Versao %VERSAO%"
git push

REM ================================
REM CRIAR RELEASE
REM ================================
echo.
echo ================================
echo CRIANDO RELEASE
echo ================================

gh release delete v%VERSAO% -y 2>nul

gh release create v%VERSAO% dist/monitor.exe ^
--title "v%VERSAO%" ^
--notes "Release automatica"

REM ================================
REM BACKUP GOOGLE DRIVE
REM ================================
echo.
echo BACKUP GOOGLE DRIVE...

robocopy "C:\Users\Cleiton\Documents\teste3" "G:\Meu Drive\__00002\teste3" /MIR

REM ================================
REM FINAL
REM ================================
echo.
echo ================================
echo BUILD + GITHUB COMPLETO!
echo ================================

pause