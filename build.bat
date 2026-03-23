@echo off
title BUILD + GITHUB AUTO FINAL
color 0A

cd /d %~dp0

set PYTHON=C:\Python314\python.exe
set VERSAO=2.10
set REPO=RoboticaParana/monitor-arduino

echo Atualizando versao %VERSAO%...

powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"%VERSAO%\"' | Set-Content monitor.py"

if not exist version.json (
(
echo {
echo   "version": "%VERSAO%",
echo   "url": "https://github.com/%REPO%/releases/download/v%VERSAO%/monitor.exe"
echo }
) > version.json
)

powershell -Command "(Get-Content version.json) -replace '\"version\": \".*\"', '\"version\": \"%VERSAO%\"' | Set-Content version.json"
powershell -Command "(Get-Content version.json) -replace 'releases/download/v.*/monitor.exe', 'releases/download/v%VERSAO%/monitor.exe' | Set-Content version.json"

echo Salvando version.json...
powershell -Command "Get-Content version.json | Set-Content version.json"

rmdir /s /q build 2>nul
rmdir /s /q dist 2>nul
del *.spec 2>nul

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
    echo ERRO BUILD
    pause
    exit
)

echo Commitando...
git add .

git diff --cached --quiet
if %errorlevel%==0 (
    git commit --allow-empty -m "Versao %VERSAO%"
) else (
    git commit -m "Versao %VERSAO%"
)

git push

echo Criando release...

gh release delete v%VERSAO% -y 2>nul

gh release create v%VERSAO% dist/monitor.exe ^
--title "v%VERSAO%" ^
--notes "Release automatica"

echo BACKUP...
robocopy "C:\Users\Cleiton\Documents\teste3" "G:\Meu Drive\__00002\teste3" /MIR

echo FINALIZADO!
pause