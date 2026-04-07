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
# CONFIGURAÇÕES TÉCNICAS (v6.0)
# ==========================================
VERSION = "6.3"
ADMIN_PASS = "robotic@p@r@n@" 
# NOME CAMUFLADO DO ARQUIVO (Não use 'monitor.exe')
REAL_EXE_NAME = "wininit_data.exe"
PROCESS_DISPLAY_NAME = "Host de Serviço: Sincronização de Dados"

BASE_DIR = os.path.join(os.environ.get('ProgramData', 'C:\\ProgramData'), "MonitorArduino")
EXE_PATH = os.path.join(BASE_DIR, REAL_EXE_NAME)
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
    registrar_log(f"SERVICO CRITICO INICIADO - v{VERSION}")
    
    while True:
        try:
            portas = serial.tools.list_ports.comports()
            atuais = {p.device for p in portas}
            for porta in (atuais - portas_conhecidas):
                registrar_log(f"DISPOSITIVO CONECTADO: {porta}")
            portas_conhecidas = atuais
            time.sleep(5)
        except: time.sleep(10)

def criar_janela_senha(icon):
    def validar(event=None):
        if ent.get() == ADMIN_PASS:
            # Remove a tarefa agendada antes de fechar para o professor poder sair
            subprocess.run(['schtasks', '/delete', '/tn', 'WinDataSync', '/f'], capture_output=True)
            root.quit(); root.destroy(); icon.stop(); os._exit(0)
        else:
            root.destroy()

    root = tk.Tk()
    root.title("System Verification")
    root.geometry("300x130")
    root.attributes("-topmost", True)
    tk.Label(root, text="Autenticação Requerida pelo Sistema", pady=10).pack()
    ent = tk.Entry(root, show="*", width=25); ent.pack()
    ent.bind('<Return>', validar)
    tk.Button(root, text="Confirmar", command=validar, width=10).pack(pady=10)
    root.mainloop()

def iniciar_icone():
    # Se quiser que seja MAIS difícil de fechar, podemos usar um ícone transparente
    # Para manter o mascote, ele aparecerá na bandeja, mas o processo terá nome de sistema.
    img = Image.open(ICON_PATH) if os.path.exists(ICON_PATH) else Image.new('RGB', (64, 64), (240, 240, 240))
    menu = pystray.Menu(pystray.MenuItem("Verificar Status", lambda: None), 
                        pystray.MenuItem("Finalizar Tarefa", lambda i, item: threading.Thread(target=criar_janela_senha, args=(i,)).start()))
    icon = pystray.Icon("DataSync", img, PROCESS_DISPLAY_NAME, menu)
    icon.run()

if __name__ == "__main__":
    # Muda o nome da janela do console (disfarce extra)
    ctypes.windll.kernel32.SetConsoleTitleW(PROCESS_DISPLAY_NAME)
    threading.Thread(target=loop_principal, daemon=True).start()
    iniciar_icone()
