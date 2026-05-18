@echo off
title BUILDER B1N0
color 0B
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d %~dp0

:: BUSCA DO INNO SETUP
set "INNO="
for %%G in ("C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "C:\Program Files\Inno Setup 6\ISCC.exe" "%LocalAppData%\Programs\Inno Setup 6\ISCC.exe") do (
    if exist "%%~G" set "INNO=%%~G"
)

echo [0/6] Atualizando versao...
for /f "usebackq delims=" %%V in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bump_version.ps1"`) do set "VERSAO=%%V"
if not defined VERSAO (
    echo ERRO CRITICO: Falha ao atualizar versao.
    pause
    exit /b 1
)
title BUILDER B1N0 v!VERSAO!
echo Nova versao: v!VERSAO!
echo.

echo [1/6] Limpando pastas antigas...
rmdir /s /q build dist 2>nul

echo [2/6] Instalando dependencias necessarias...
pip install requests psutil pystray pillow pyinstaller --upgrade --quiet
if errorlevel 1 (
    echo ERRO CRITICO: Falha ao instalar dependencias.
    pause
    exit /b 1
)

echo [3/6] Compilando Agente (Monitor)...
python -m PyInstaller --clean --onedir --noconsole --icon=mascote.ico --add-data "mascote.ico;." monitor.py
if errorlevel 1 (
    echo ERRO CRITICO: PyInstaller falhou ao compilar monitor.py
    pause
    exit /b 1
)
if not exist "dist\monitor.exe" (
    if not exist "dist\monitor\monitor.exe" (
        echo ERRO CRITICO: Falha ao compilar monitor.py
        pause
        exit /b 1
    )
)

echo [4/6] Compilando Gerenciador (Manager)...
python -m PyInstaller --clean --onedir --noconsole --icon=mascote.ico manager.py
if errorlevel 1 (
    echo ERRO CRITICO: PyInstaller falhou ao compilar manager.py
    pause
    exit /b 1
)
if not exist "dist\manager.exe" (
    if not exist "dist\manager\manager.exe" (
        echo ERRO CRITICO: Falha ao compilar manager.py
        pause
        exit /b 1
    )
)

echo [5/6] Gerando Instalador Final...
if defined INNO (
    "!INNO!" setup.iss
    if errorlevel 1 (
        echo ERRO CRITICO: Falha ao gerar instalador.
        pause
        exit /b 1
    )
) else (
    echo ERRO: Inno Setup nao encontrado!
    pause
    exit /b 1
)

if not "%PUBLICAR_GITHUB%"=="1" (
    echo.
    echo Publicacao no GitHub ignorada. Para publicar, rode:
    echo set PUBLICAR_GITHUB=1
    echo build.bat
    goto fim
)

echo [6/6] Publicando no GitHub...
git add monitor.py manager.py setup.iss version.json build.bat bump_version.ps1 .gitignore
if errorlevel 1 (
    echo ERRO CRITICO: Falha ao preparar arquivos para commit.
    pause
    exit /b 1
)

git commit -m "Build v!VERSAO!"
if errorlevel 1 (
    echo ERRO CRITICO: Falha ao criar commit.
    pause
    exit /b 1
)

git push origin main
if errorlevel 1 (
    echo ERRO CRITICO: Falha ao enviar commit para o GitHub.
    pause
    exit /b 1
)

gh release view "v!VERSAO!" >nul 2>nul
if errorlevel 1 (
    gh release create "v!VERSAO!" "dist\monitor\monitor.exe#monitor.exe" "Output\Instalador_AgenteB1n0_v!VERSAO!.exe#Instalador_AgenteB1n0_v!VERSAO!.exe" --title "v!VERSAO!" --notes "Build v!VERSAO!" --latest
) else (
    gh release upload "v!VERSAO!" "dist\monitor\monitor.exe#monitor.exe" "Output\Instalador_AgenteB1n0_v!VERSAO!.exe#Instalador_AgenteB1n0_v!VERSAO!.exe" --clobber
)
if errorlevel 1 (
    echo ERRO CRITICO: Falha ao criar ou atualizar Release no GitHub.
    pause
    exit /b 1
)

echo.
:fim
echo Build v!VERSAO! finalizado.
if "%PUBLICAR_GITHUB%"=="1" echo Publicado no GitHub Release v!VERSAO!.
pause
