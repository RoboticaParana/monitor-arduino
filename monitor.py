import os
import time
import json
import requests
import subprocess
import sys
import serial.tools.list_ports
from datetime import datetime

# ==========================================
# CONFIGURAÇÕES TÉCNICAS
# ==========================================
VERSION = "3.8"  # O build.bat altera isso automaticamente
UPDATE_INTERVAL = 60
GITHUB_REPO = "RoboticaParana/monitor-arduino"
VERSION_URL = f"https://raw.githubusercontent.com/{GITHUB_REPO}/main/version.json"

# Caminhos de Sistema
BASE_DIR = os.path.join(os.environ.get('ProgramData', 'C:\\ProgramData'), "MonitorArduino")
EXE_PATH = os.path.join(BASE_DIR, "monitor.exe")
LOG_FILE = os.path.join(BASE_DIR, "log_arduino.txt")

def registrar_log(mensagem):
    """ Grava eventos no arquivo de log com flush forçado para o HD """
    try:
        if not os.path.exists(BASE_DIR):
            os.makedirs(BASE_DIR)
        
        timestamp = datetime.now().strftime('%d/%m/%Y %H:%M:%S')
        with open(LOG_FILE, "a", encoding='utf-8') as f:
            f.write(f"[{timestamp}] v{VERSION} - {mensagem}\n")
            f.flush()  # Garante a gravação imediata
            os.fsync(f.fileno()) # Força o sistema operacional a salvar
    except Exception as e:
        print(f"Erro ao gravar log: {e}")

def verificar_atualizacao():
    """ Checa se existe nova versão no GitHub """
    try:
        response = requests.get(VERSION_URL, timeout=10)
        data = response.json()
        nova_versao = data.get("version")
        
        if nova_versao and nova_versao != VERSION:
            registrar_log(f"Nova versão detectada: {nova_versao}. Iniciando update...")
            baixar_e_substituir(data.get("url"))
    except Exception as e:
        pass # Silencioso para não atrapalhar o log do Arduino

def baixar_e_substituir(url):
    """ Baixa o novo executável e roda o script de troca """
    try:
        temp_exe = os.path.join(BASE_DIR, "update_temp.exe")
        r = requests.get(url, stream=True, timeout=60)
        with open(temp_exe, "wb") as f:
            for chunk in r.iter_content(8192):
                f.write(chunk)
        
        bat_path = os.path.join(BASE_DIR, "update.bat")
        with open(bat_path, "w") as f:
            f.write(f'@echo off\n')
            f.write(f'taskkill /f /im monitor.exe > nul 2>&1\n')
            f.write(f'timeout /t 3 /nobreak > nul\n')
            f.write(f'move /y "{temp_exe}" "{EXE_PATH}"\n')
            f.write(f'start "" "{EXE_PATH}"\n')
            f.write(f'del "%~f0"\n')
        
        subprocess.Popen([bat_path], shell=True)
        sys.exit(0)
    except Exception as e:
        registrar_log(f"Falha no download da atualização: {e}")

def monitorar_portas():
    """ Verifica se há novas placas conectadas """
    portas_conhecidas = set()
    
    # Primeira leitura para ignorar o que já estava plugado ao ligar
    for p in serial.tools.list_ports.comports():
        portas_conhecidas.add(p.device)

    registrar_log("=== MONITORAMENTO INICIADO ===")

    while True:
        try:
            portas_atuais = serial.tools.list_ports.comports()
            dispositivos_agora = {p.device for p in portas_atuais}

            # Detectar novos dispositivos
            novos = dispositivos_agora - portas_conhecidas
            for porta in novos:
                # Busca detalhes da porta nova
                detalhes = next(p for p in portas_atuais if p.device == porta)
                info = (f"PLACA CONECTADA: {detalhes.device} | "
                        f"Hardware: {detalhes.hwid} | "
                        f"Desc: {detalhes.description}")
                registrar_log(info)

            # Detectar dispositivos removidos
            removidos = portas_conhecidas - dispositivos_agora
            for porta in removidos:
                registrar_log(f"PLACA DESCONECTADA: {porta}")

            portas_conhecidas = dispositivos_agora
            
            # Checar atualização a cada ciclo (definido pelo intervalo)
            verificar_atualizacao()
            
            time.sleep(5) # Verifica portas a cada 5 segundos
        except Exception as e:
            registrar_log(f"Erro no loop de monitoramento: {e}")
            time.sleep(10)

if __name__ == "__main__":
    # Espera um pouco ao iniciar para o Windows carregar drivers USB
    time.sleep(2)
    monitorar_portas()
