import ctypes
import os
import sys
import time
import threading
import requests
import subprocess
import pystray
import shutil
import random
from PIL import Image
from pystray import MenuItem as item

# Configurações automáticas (O build.bat altera estas linhas)
VERSION = "3.5"
UPDATE_INTERVAL = 30
URL_JSON = "https://raw.githubusercontent.com/RoboticaParana/monitor-arduino/main/version.json"

# Pasta global para permitir atualização sem senha de admin após a 1ª vez
BASE_DIR = r"C:\ProgramData\MonitorArduino"
EXE_PATH = os.path.join(BASE_DIR, "monitor.exe")
ICO_PATH = os.path.join(BASE_DIR, "mascote.ico")

def baixar_e_substituir(url):
    try:
        if not os.path.exists(BASE_DIR): os.makedirs(BASE_DIR)
        temp_exe = os.path.join(BASE_DIR, "update_temp.exe")
        
        # Download da nova versão
        r = requests.get(url, stream=True, timeout=60)
        r.raise_for_status()
        with open(temp_exe, "wb") as f:
            for chunk in r.iter_content(8192): f.write(chunk)
        
        # Verifica se o arquivo baixado é válido (mínimo 1MB)
        if os.path.getsize(temp_exe) < 1000000: return

        # BAT para matar o processo, esperar a limpeza de DLLs e substituir
        bat_path = os.path.join(BASE_DIR, "update.bat")
        with open(bat_path, "w") as f:
            f.write(f'@echo off\n')
            f.write(f'title ATUALIZANDO MONITOR AGENTE...\n')
            f.write(f'taskkill /f /im monitor.exe > nul 2>&1\n')
            # Espera 5 segundos para o Windows liberar as DLLs do Python da memória
            f.write(f'timeout /t 5 /nobreak > nul\n') 
            f.write(f'move /y "{temp_exe}" "{EXE_PATH}"\n')
            f.write(f'start "" "{EXE_PATH}"\n')
            f.write(f'del "%~f0"\n')
        
        # Executa o BAT e fecha o programa atual
        subprocess.Popen([bat_path], shell=True)
        os._exit(0)
    except Exception as e:
        pass

def loop_update():
    while True:
        try:
            # Cache buster para evitar pegar versão antiga do cache do GitHub
            r = requests.get(f"{URL_JSON}?c={random.randint(1,99999)}", timeout=15)
            dados = r.json()
            if dados["version"] != VERSION:
                baixar_e_substituir(dados["url"])
        except:
            pass
        time.sleep(UPDATE_INTERVAL)

def criar_icone():
    try: 
        img = Image.open(ICO_PATH)
    except: 
        img = Image.new("RGB", (64, 64), (0, 128, 0))

    icon = pystray.Icon("Monitor", img, f"Monitor v{VERSION}", 
                        menu=(item(f"Versão {VERSION}", lambda: None, enabled=False),
                              item("Sair", lambda icon, item: (icon.stop(), os._exit(0)))))
    
    threading.Thread(target=loop_update, daemon=True).start()
    icon.run()

if __name__ == "__main__":
    criar_icone()
