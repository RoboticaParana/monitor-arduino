import os
import time
import requests
import subprocess
import sys
import serial.tools.list_ports
from datetime import datetime
import threading
from PIL import Image, ImageDraw # pip install pillow
import pystray # pip install pystray

# ==========================================
# CONFIGURAÇÕES
# ==========================================
VERSION = "4.1"
BASE_DIR = os.path.join(os.environ.get('ProgramData', 'C:\\ProgramData'), "MonitorArduino")
LOG_FILE = os.path.join(BASE_DIR, "log_arduino.txt")
ICON_PATH = os.path.join(BASE_DIR, "mascote.ico")

def registrar_log(mensagem):
    try:
        if not os.path.exists(BASE_DIR): os.makedirs(BASE_DIR)
        with open(LOG_FILE, "a", encoding='utf-8') as f:
            f.write(f"[{datetime.now().strftime('%d/%m/%Y %H:%M:%S')}] v{VERSION} - {mensagem}\n")
            f.flush()
            os.fsync(f.fileno())
    except: pass

def monitorar_usb():
    """ Loop de detecção de placas """
    portas_conhecidas = {p.device for p in serial.tools.list_ports.comports()}
    registrar_log("=== MONITORAMENTO DE PORTAS INICIADO ===")
    
    while True:
        try:
            portas_atuais = serial.tools.list_ports.comports()
            dispositivos_agora = {p.device for p in portas_atuais}

            # Placa Conectada
            for porta in (dispositivos_agora - portas_conhecidas):
                p = next(it for it in portas_atuais if it.device == porta)
                msg = f"CONECTADO: {p.device} | ID: {p.hwid} | {p.description}"
                registrar_log(msg)

            # Placa Removida
            for porta in (portas_conhecidas - dispositivos_agora):
                registrar_log(f"DESCONECTADO: {porta}")

            portas_conhecidas = dispositivos_agora
            time.sleep(3)
        except Exception as e:
            registrar_log(f"Erro no loop USB: {e}")
            time.sleep(5)

def criar_icone():
    """ Cria o ícone na bandeja do sistema """
    try:
        # Tenta carregar seu mascote.ico, se falhar cria um quadrado azul
        if os.path.exists(ICON_PATH):
            image = Image.open(ICON_PATH)
        else:
            image = Image.new('RGB', (64, 64), color=(0, 100, 255))
        
        menu = pystray.Menu(pystray.MenuItem(f"Agente Mestre v{VERSION}", lambda: None))
        icon = pystray.Icon("Monitor", image, "Monitor Arduino", menu)
        icon.run()
    except Exception as e:
        registrar_log(f"Erro ao criar ícone: {e}")

if __name__ == "__main__":
    registrar_log("=== AGENTE INICIADO ===")
    
    # Inicia o monitoramento USB em uma thread separada (para não travar o ícone)
    thread_usb = threading.Thread(target=monitorar_usb, daemon=True)
    thread_usb.start()

    # Inicia o ícone (isso mantém o programa vivo e visível)
    criar_icone()
