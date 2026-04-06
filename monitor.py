import os
import time
import json
import requests
import subprocess
import sys
import serial.tools.list_ports
from datetime import datetime
import threading
from PIL import Image
import pystray

# ==========================================
# CONFIGURAÇÕES TÉCNICAS (O build.bat altera isso)
# ==========================================
VERSION = "4.2"
UPDATE_INTERVAL = 60
GITHUB_REPO = "RoboticaParana/monitor-arduino"
# Usamos a URL RAW para garantir que o Python leia o JSON puro
VERSION_URL = f"https://raw.githubusercontent.com/{GITHUB_REPO}/main/version.json"

# Caminhos de Sistema (ProgramData é o local mais estável para permissões)
BASE_DIR = os.path.join(os.environ.get('ProgramData', 'C:\\ProgramData'), "MonitorArduino")
EXE_PATH = os.path.join(BASE_DIR, "monitor.exe")
LOG_FILE = os.path.join(BASE_DIR, "log_arduino.txt")
ICON_PATH = os.path.join(BASE_DIR, "mascote.ico")

def registrar_log(mensagem):
    """ Grava eventos com flush imediato para o HD """
    try:
        if not os.path.exists(BASE_DIR):
            os.makedirs(BASE_DIR)
        
        timestamp = datetime.now().strftime('%d/%m/%Y %H:%M:%S')
        with open(LOG_FILE, "a", encoding='utf-8') as f:
            f.write(f"[{timestamp}] v{VERSION} - {mensagem}\n")
            f.flush()
            os.fsync(f.fileno())
    except:
        pass

def baixar_e_substituir(url):
    """ Faz o download da nova versão e executa o script de troca """
    try:
        temp_exe = os.path.join(BASE_DIR, "update_temp.exe")
        registrar_log(f"Baixando atualização: {url}")
        
        # Download do novo executável
        r = requests.get(url, stream=True, timeout=120)
        r.raise_for_status()
        with open(temp_exe, "wb") as f:
            for chunk in r.iter_content(8192):
                f.write(chunk)
        
        # Criação do script BAT de substituição (Reforçado)
        bat_path = os.path.join(BASE_DIR, "update.bat")
        with open(bat_path, "w") as f:
            f.write('@echo off\n')
            f.write('title ATUALIZANDO MONITOR AGENTE...\n')
            f.write('taskkill /f /im monitor.exe > nul 2>&1\n')
            f.write('timeout /t 5 /nobreak > nul\n')
            f.write(':try_move\n')
            f.write(f'move /y "{temp_exe}" "{EXE_PATH}"\n')
            f.write('if errorlevel 1 (timeout /t 2 > nul & goto try_move)\n')
            f.write(f'start "" "{EXE_PATH}"\n')
            f.write('del "%~f0"\n')
        
        registrar_log("Fechando para aplicar atualização via BAT...")
        # Lança o BAT de forma independente e encerra o Python
        subprocess.Popen(f'cmd /c "{bat_path}"', shell=True, creationflags=subprocess.CREATE_NEW_CONSOLE)
        os._exit(0)
    except Exception as e:
        registrar_log(f"ERRO NO UPDATE: {e}")

def verificar_atualizacao():
    """ Checa se a versão no GitHub é diferente da local """
    try:
        # Headers para evitar cache do GitHub e bloqueios
        headers = {
            'User-Agent': 'Mozilla/5.0',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache'
        }
        # Adicionamos um parâmetro aleatório na URL para forçar o GitHub a ignorar o cache
        timestamp_url = f"{VERSION_URL}?t={int(time.time())}"
        
        response = requests.get(timestamp_url, headers=headers, timeout=15)
        if response.status_code == 200:
            data = response.json()
            nova_v = str(data.get("version")).strip()
            
            if nova_v != VERSION:
                registrar_log(f"Upgrade disponível: {VERSION} -> {nova_v}")
                baixar_e_substituir(data.get("url"))
    except Exception as e:
        pass # Erros de rede não devem travar o monitoramento USB

def loop_monitoramento():
    """ Thread secundária: Monitora USB e Atualizações """
    portas_conhecidas = {p.device for p in serial.tools.list_ports.comports()}
    registrar_log("=== MONITORAMENTO USB INICIADO ===")
    
    ultimo_check_update = 0

    while True:
        try:
            portas_atuais = serial.tools.list_ports.comports()
            dispositivos_agora = {p.device for p in portas_atuais}

            # Detectar Conexão
            for porta in (dispositivos_agora - portas_conhecidas):
                p = next(it for it in portas_atuais if it.device == porta)
                registrar_log(f"PLACA CONECTADA: {p.device} | {p.description}")

            # Detectar Desconexão
            for porta in (portas_conhecidas - dispositivos_agora):
                registrar_log(f"PLACA DESCONECTADA: {porta}")

            portas_conhecidas = dispositivos_agora

            # Verificar atualização a cada INTERVALO definido
            if time.time() - ultimo_check_update > UPDATE_INTERVAL:
                verificar_atualizacao()
                ultimo_check_update = time.time()

            time.sleep(3) # Checa portas USB a cada 3 segundos
        except Exception as e:
            registrar_log(f"Erro no loop principal: {e}")
            time.sleep(10)

def setup_icone():
    """ Thread principal: Mantém o ícone na bandeja """
    try:
        if os.path.exists(ICON_PATH):
            image = Image.open(ICON_PATH)
        else:
            # Caso o ícone suma, cria um fallback visual
            image = Image.new('RGB', (64, 64), color=(0, 120, 215))
        
        menu = pystray.Menu(
            pystray.MenuItem(f"Monitor v{VERSION}", lambda: None),
            pystray.MenuItem("Sair (Admin)", lambda icon, item: os._exit(0))
        )
        
        icon = pystray.Icon("MonitorArduino", image, f"Agente Mestre v{VERSION}", menu)
        icon.run()
    except Exception as e:
        registrar_log(f"Erro no ícone da bandeja: {e}")
        # Se o ícone falhar, mantemos o programa vivo com um loop infinito
        while True: time.sleep(100)

if __name__ == "__main__":
    registrar_log("=== AGENTE MESTRE INICIADO ===")
    
    # 1. Inicia o monitoramento de USB e Updates em Background
    t = threading.Thread(target=loop_monitoramento, daemon=True)
    t.start()

    # 2. Inicia o ícone da bandeja (bloqueia a thread principal para manter o EXE rodando)
    setup_icone()
