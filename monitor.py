import os
import time
import json
import requests
import subprocess
import sys
import serial.tools.list_ports
from datetime import datetime

# ==========================================
# CONFIGURAÇÕES
# ==========================================
VERSION = "3.9" 
UPDATE_INTERVAL = 60
GITHUB_REPO = "RoboticaParana/monitor-arduino"
VERSION_URL = f"https://raw.githubusercontent.com/{GITHUB_REPO}/main/version.json"

BASE_DIR = os.path.join(os.environ.get('ProgramData', 'C:\\ProgramData'), "MonitorArduino")
EXE_PATH = os.path.join(BASE_DIR, "monitor.exe")
LOG_FILE = os.path.join(BASE_DIR, "log_arduino.txt")

def registrar_log(mensagem):
    try:
        if not os.path.exists(BASE_DIR): os.makedirs(BASE_DIR)
        timestamp = datetime.now().strftime('%d/%m/%Y %H:%M:%S')
        with open(LOG_FILE, "a", encoding='utf-8') as f:
            f.write(f"[{timestamp}] v{VERSION} - {mensagem}\n")
            f.flush()
            os.fsync(f.fileno())
    except: pass

def baixar_e_substituir(url):
    """ Baixa a nova versão e força a reinicialização """
    try:
        temp_exe = os.path.join(BASE_DIR, "update_temp.exe")
        registrar_log(f"Baixando atualização de: {url}")
        
        r = requests.get(url, stream=True, timeout=60)
        with open(temp_exe, "wb") as f:
            for chunk in r.iter_content(8192): f.write(chunk)
        
        bat_path = os.path.join(BASE_DIR, "update.bat")
        
        # SCRIPT BAT REFORÇADO
        with open(bat_path, "w") as f:
            f.write('@echo off\n')
            f.write('title ATUALIZANDO MONITOR...\n')
            # 1. Mata o processo atual (forçado)
            f.write('taskkill /f /im monitor.exe > nul 2>&1\n')
            # 2. Espera o Windows liberar os arquivos da memória
            f.write('timeout /t 5 /nobreak > nul\n')
            # 3. Tenta mover o arquivo. Se falhar (arquivo preso), tenta de novo em loop
            f.write(':try_move\n')
            f.write(f'move /y "{temp_exe}" "{EXE_PATH}"\n')
            f.write('if errorlevel 1 (timeout /t 2 > nul & goto try_move)\n')
            # 4. INICIALIZAÇÃO GARANTIDA: Usa o comando START e verifica se abriu
            f.write(f'start "" "{EXE_PATH}"\n')
            # 5. Se auto-deleta
            f.write('del "%~f0"\n')
        
        registrar_log("Script de atualização gerado. Reiniciando...")
        # Inicia o BAT de forma independente
        subprocess.Popen(f'cmd /c "{bat_path}"', shell=True, creationflags=subprocess.CREATE_NEW_CONSOLE)
        os._exit(0)
    except Exception as e:
        registrar_log(f"Erro no processo de update: {e}")

def verificar_atualizacao():
    try:
        response = requests.get(VERSION_URL, timeout=10)
        data = response.json()
        if data.get("version") != VERSION:
            baixar_e_substituir(data.get("url"))
    except: pass

def monitorar_portas():
    portas_conhecidas = {p.device for p in serial.tools.list_ports.comports()}
    registrar_log("=== MONITORAMENTO v" + VERSION + " INICIADO ===")

    while True:
        try:
            portas_atuais = serial.tools.list_ports.comports()
            dispositivos_agora = {p.device for p in portas_atuais}

            for porta in (dispositivos_agora - portas_conhecidas):
                detalhes = next(p for p in portas_atuais if p.device == porta)
                registrar_log(f"CONECTADO: {detalhes.device} | {detalhes.description}")

            for porta in (portas_conhecidas - dispositivos_agora):
                registrar_log(f"DESCONECTADO: {porta}")

            portas_conhecidas = dispositivos_agora
            verificar_atualizacao()
            time.sleep(5)
        except Exception as e:
            time.sleep(10)

if __name__ == "__main__":
    monitorar_portas()
