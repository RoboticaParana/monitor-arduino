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

# Configurações automáticas
VERSION = "3.0"
UPDATE_INTERVAL = 60
URL_JSON = "https://raw.githubusercontent.com/RoboticaParana/monitor-arduino/main/version.json"

# Pasta global para permitir atualização sem senha de admin após a 1ª vez
BASE_DIR = r"C:\ProgramData\MonitorArduino"
EXE_PATH = os.path.join(BASE_DIR, "monitor.exe")
ICO_PATH = os.path.join(BASE_DIR, "mascote.ico")

def baixar_e_substituir(url):
    try:
        if not os.path.exists(BASE_DIR): os.makedirs(BASE_DIR)
        temp_exe = os.path.join(BASE_DIR, "update_temp.exe")
        
        r = requests.get(url, stream=True, timeout=60)
        r.raise_for_status()
        with open(temp_exe, "wb") as f:
            for chunk in r.iter_content(8192): f.write(chunk)
        
        if os.path.getsize(temp_exe) < 100000: return

        # BAT para matar o processo, substituir o arquivo e reiniciar
        bat_path = os.path.join(BASE_DIR, "update.bat")
        with open(bat_path, "w") as f:
            f.write(f'@echo off\n')
            f.write(f'timeout /t 2 /nobreak > nul\n')
            f.write(f'taskkill /f /im monitor.exe > nul\n')
            f.write(f'move /y "{temp_exe}" "{EXE_PATH}"\n')
            f.write(f'start "" "{EXE_PATH}"\n')
            f.write(f'del "%~f0"\n')
        
        subprocess.Popen([bat_path], shell=True)
        os._exit(0)
    except: pass

def loop_update():
    while True:
        try:
            # Cache buster para o GitHub
            r = requests.get(f"{URL_JSON}?c={random.randint(1,999)}", timeout=10)
            if r.json()["version"] != VERSION:
                baixar_e_substituir(r.json()["url"])
        except: pass
        time.sleep(UPDATE_INTERVAL)

def criar_icone():
    try: img = Image.open(ICO_PATH)
    except: img = Image.new("RGB", (64, 64), (0, 128, 0))

    icon = pystray.Icon("Monitor", img, f"Monitor v{VERSION}", 
                        menu=(item(f"Versão {VERSION}", lambda: None, enabled=False),
                              item("Sair", lambda icon, item: (icon.stop(), os._exit(0)))))
    
    threading.Thread(target=loop_update, daemon=True).start()
    icon.run()

if __name__ == "__main__":
    criar_icone()
