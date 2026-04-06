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
import tkinter as tk
from tkinter import simpledialog

# ==========================================
# CONFIGURAÇÕES TÉCNICAS
# ==========================================
VERSION = "4.5"
ADMIN_PASS = "1234"  # Altere para a sua senha
UPDATE_INTERVAL = 60
GITHUB_REPO = "RoboticaParana/monitor-arduino"
VERSION_URL = f"https://raw.githubusercontent.com/{GITHUB_REPO}/main/version.json"

BASE_DIR = os.path.join(os.environ.get('ProgramData', 'C:\\ProgramData'), "MonitorArduino")
EXE_PATH = os.path.join(BASE_DIR, "monitor.exe")
LOG_FILE = os.path.join(BASE_DIR, "log_arduino.txt")
ICON_PATH = os.path.join(BASE_DIR, "mascote.ico")

def registrar_log(mensagem):
    try:
        if not os.path.exists(BASE_DIR):
            os.makedirs(BASE_DIR)
        timestamp = datetime.now().strftime('%d/%m/%Y %H:%M:%S')
        with open(LOG_FILE, "a", encoding='utf-8') as f:
            f.write(f"[{timestamp}] {mensagem}\n")
            f.flush()
            os.fsync(f.fileno())
    except:
        pass

def get_geo():
    try:
        r = requests.get("http://ip-api.com/json/", timeout=5).json()
        if r.get('status') == 'success':
            return f"Local: {r.get('city')}/{r.get('regionName')} - IP: {r.get('query')}"
        return "Localizacao: Nao identificada"
    except:
        return "Localizacao: Offline"

def verificar_fabricante(vid):
    if vid == 0x2341 or vid == 9025: return "ORIGINAL (Arduino SA)"
    if vid == 0x1A86: return "GENERICO (CH340/CH341)"
    if vid == 0x0403: return "GENERICO (FTDI)"
    return "DESCONHECIDO"

def baixar_e_substituir(url):
    try:
        temp_exe = os.path.join(BASE_DIR, "update_temp.exe")
        r = requests.get(url, stream=True, timeout=120)
        with open(temp_exe, "wb") as f:
            for chunk in r.iter_content(8192):
                f.write(chunk)
        
        bat_path = os.path.join(BASE_DIR, "update.bat")
        with open(bat_path, "w") as f:
            f.write('@echo off\n')
            f.write('taskkill /f /im monitor.exe > nul 2>&1\n')
            f.write('timeout /t 5 /nobreak > nul\n')
            f.write(':try_move\n')
            f.write(f'move /y "{temp_exe}" "{EXE_PATH}"\n')
            f.write('if errorlevel 1 (timeout /t 2 > nul & goto try_move)\n')
            f.write(f'start "" "{EXE_PATH}"\n')
            f.write('del "%~f0"\n')
        
        subprocess.Popen(f'cmd /c "{bat_path}"', shell=True, creationflags=subprocess.CREATE_NEW_CONSOLE)
        os._exit(0)
    except:
        pass

def verificar_atualizacao():
    try:
        headers = {'User-Agent': 'Mozilla/5.0', 'Cache-Control': 'no-cache'}
        t_url = f"{VERSION_URL}?t={int(time.time())}"
        res = requests.get(t_url, headers=headers, timeout=15)
        if res.status_code == 200:
            data = res.json()
            if str(data.get("version")).strip() != VERSION:
                baixar_e_substituir(data.get("url"))
    except:
        pass

def loop_principal():
    portas_conhecidas = {p.device for p in serial.tools.list_ports.comports()}
    geo_info = get_geo()
    ultimo_check = 0
    
    while True:
        try:
            portas_atuais = serial.tools.list_ports.comports()
            dispositivos_agora = {p.device for p in portas_atuais}

            novas = dispositivos_agora - portas_conhecidas
            for porta in novas:
                p = next(it for it in portas_atuais if it.device == porta)
                vid = p.vid if p.vid else 0
                pid = p.pid if p.pid else 0
                sn = p.serial_number if p.serial_number else "SEM_SERIAL"
                fabricante = verificar_fabricante(vid)
                
                log_msg = (f"CONEXAO: {p.description} | Porta: {p.device} | "
                           f"VID: {vid:04x} | PID: {pid:04x} | SN: {sn} | "
                           f"Fabricante: {fabricante} | {geo_info}")
                registrar_log(log_msg)

            portas_conhecidas = dispositivos_agora

            if time.time() - ultimo_check > UPDATE_INTERVAL:
                verificar_atualizacao()
                ultimo_check = time.time()
            
            time.sleep(3)
        except:
            time.sleep(10)

def solicitar_senha_para_sair(icon, item):
    """ Janela de senha com FOCO FORÇADO """
    root = tk.Tk()
    root.withdraw() 
    root.attributes("-topmost", True) # Garante que fique na frente de tudo
    
    # Pequeno delay para garantir que o Windows processe a janela antes do foco
    root.after(100, lambda: root.focus_force()) 
    
    senha = simpledialog.askstring("Segurança", "Digite a senha de Administrador:", show="*", parent=root)
    
    if senha is not None: # Se não clicou em Cancelar
        if senha == ADMIN_PASS:
            icon.stop()
            root.destroy()
            os._exit(0)
        else:
            registrar_log("Tentativa de fechamento com senha incorreta.")
    
    root.destroy() # Fecha a instância do Tkinter ao terminar ou cancelar

def iniciar_icone():
    try:
        if os.path.exists(ICON_PATH):
            img = Image.open(ICON_PATH)
        else:
            img = Image.new('RGB', (64, 64), (0, 120, 215))
        
        menu = pystray.Menu(
            pystray.MenuItem(f"Agente v{VERSION}", lambda: None),
            pystray.MenuItem("Fechar Monitor", solicitar_senha_para_sair)
        )
        icon = pystray.Icon("MonitorArduino", img, f"Agente Mestre v{VERSION}", menu)
        icon.run()
    except:
        while True: time.sleep(100)

if __name__ == "__main__":
    t = threading.Thread(target=loop_principal, daemon=True)
    t.start()
    iniciar_icone()
