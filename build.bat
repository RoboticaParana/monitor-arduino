@echo off
title BUILD + GITHUB AUTO
color 0A

cd /d %~dp0

REM ================================
REM CONFIG
REM ================================
set PYTHON=C:\Python314\python.exe
set VERSAO=2.9
set REPO=RoboticaParana/monitor-arduino
set TOKEN=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

echo Atualizando versao para %VERSAO%...

REM ================================
REM ATUALIZAR PY
REM ================================
powershell -Command "(Get-Content monitor.py) -replace 'VERSION = \".*\"', 'VERSION = \"%VERSAO%\"' | Set-Content monitor.py"

REM ================================
REM ATUALIZAR JSON
REM ================================
powershell -Command "(Get-Content version.json) -replace '\"version\": \".*\"', '\"version\": \"%VERSAO%\"' | Set-Content version.json"
powershell -Command "(Get-Content version.json) -replace 'releases/download/v.*/monitor.exe', 'releases/download/v%VERSAO%/monitor.exe' | Set-Content version.json"

REM ================================
REM LIMPAR
REM ================================
rmdir /s /q build 2>nul
rmdir /s /q dist 2>nul
del *.spec 2>nul

REM ================================
REM BUILD
REM ================================
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

echo.
echo ================================
echo COMMIT GITHUB
echo ================================

git add .
git commit -m "Versao %VERSAO%"
git push

echo.
echo ================================
echo CRIANDO RELEASE
echo ================================

curl -X POST ^
-H "Authorization: token %TOKEN%" ^
-H "Accept: application/vnd.github.v3+json" ^
https://api.github.com/repos/%REPO%/releases ^
-d "{\"tag_name\":\"v%VERSAO%\",\"name\":\"v%VERSAO%\",\"body\":\"Release automatica\",\"draft\":false,\"prerelease\":false}" > release.json

REM ================================
REM PEGAR URL DE UPLOAD
REM ================================
for /f "tokens=2 delims=:," %%a in ('findstr upload_url release.json') do set URL=%%a

set URL=%URL:"=%
set URL=%URL:{?name,label}=%

echo Upload URL: %URL%

echo.
echo ================================
echo ENVIANDO EXE
echo ================================

curl -X POST ^
-H "Authorization: token %TOKEN%" ^
-H "Content-Type: application/octet-stream" ^
--data-binary @dist/monitor.exe ^
"%URL%?name=monitor.exe"

echo.
echo ================================
echo BUILD + RELEASE COMPLETO!
echo ================================

pause