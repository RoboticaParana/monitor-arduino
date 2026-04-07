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
import ctypes

# ==========================================
# CONFIGURAÇÕES TÉCNICAS (v5.1)
# ==========================================
VERSION = "5.1"
ADMIN_PASS = "robotic@p@r@n@" 

BASE_DIR = os.path.join(os.environ.get('ProgramData', 'C:\\ProgramData'), "MonitorArduino")
EXE_PATH = os.path.join(BASE_DIR, "monitor.exe")
LOG_FILE = os.path.join(BASE_DIR, "log_arduino.txt")
ICON_PATH = os.path.join(BASE_DIR, "mascote.ico")

def registrar_log(mensagem):
    try:
        if not os.path.exists(BASE_DIR): os.makedirs(BASE_DIR)
        timestamp = datetime.now().strftime('%d/%m/%Y %H:%M:%S')
        with open(LOG_FILE, "a", encoding='utf-8') as f:
            f.write(f"[{timestamp}] {mensagem}\n")
    except: pass

def loop_principal():
    portas_conhecidas = {p.device for p in serial.tools.list_ports.comports()}
    registrar_log(f"AGENTE B1N0 INICIADO - v{VERSION}")
    
    while True:
        try:
            portas = serial.tools.list_ports.comports()
            atuais = {p.device for p in portas}
            for porta in (atuais - portas_conhecidas):
                registrar_log(f"ARDUINO CONECTADO: {porta}")
            portas_conhecidas = atuais
            time.sleep(5)
        except: time.sleep(10)

def criar_janela_senha(icon):
    def validar(event=None):
        if ent.get() == ADMIN_PASS:
            root.quit(); root.destroy(); icon.stop(); os._exit(0)
        else:
            root.destroy()

    root = tk.Tk()
    root.title("Agente B1n0")
    root.geometry("300x130")
    root.attributes("-topmost", True)
    tk.Label(root, text="Senha de Administrador:", pady=10).pack()
    ent = tk.Entry(root, show="*", width=25); ent.pack()
    ent.bind('<Return>', validar)
    tk.Button(root, text="Sair", command=validar, width=10).pack(pady=10)
    root.mainloop()

def iniciar_icone():
    img = Image.open(ICON_PATH) if os.path.exists(ICON_PATH) else Image.new('RGB', (64, 64), (200, 200, 200))
    menu = pystray.Menu(
        pystray.MenuItem(f"Agente B1n0 v{VERSION}", lambda: None), 
        pystray.MenuItem("Encerrar", lambda i, item: threading.Thread(target=criar_janela_senha, args=(i,)).start())
    )
    icon = pystray.Icon("AgenteB1n0", img, "Agente B1n0", menu)
    icon.run()

if __name__ == "__main__":
    ctypes.windll.kernel32.SetConsoleTitleW("Agente B1n0")
    threading.Thread(target=loop_principal, daemon=True).start()
    iniciar_icone()