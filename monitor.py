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

# ==========================================
# CONFIGURAÇÕES TÉCNICAS
# ==========================================
VERSION = "4.7"
ADMIN_PASS = "1234" 
UPDATE_INTERVAL = 60
GITHUB_REPO = "RoboticaParana/monitor-arduino"
VERSION_URL = f"https://raw.githubusercontent.com/{GITHUB_REPO}/main/version.json"

BASE_DIR = os.path.join(os.environ.get('ProgramData', 'C:\\ProgramData'), "MonitorArduino")
EXE_PATH = os.path.join(BASE_DIR, "monitor.exe")
LOG_FILE = os.path.join(BASE_DIR, "log_arduino.txt")
ICON_PATH = os.path.join(BASE_DIR, "mascote.ico")

def registrar_log(mensagem):
    try:
        if not os.path.exists(BASE_DIR): os.makedirs(BASE_DIR)
        with open(LOG_FILE, "a", encoding='utf-8') as f:
            f.write(f"[{datetime.now().strftime('%d/%m/%Y %H:%M:%S')}] {mensagem}\n")
            f.flush()
            os.fsync(f.fileno())
    except: pass

def get_geo():
    try:
        r = requests.get("http://ip-api.com/json/", timeout=5).json()
        return f"Local: {r.get('city')}/{r.get('regionName')} - IP: {r.get('query')}" if r.get('status') == 'success' else "Localizacao: N/D"
    except: return "Localizacao: Offline"

def verificar_fabricante(vid):
    vids = {0x2341: "ORIGINAL (Arduino SA)", 9025: "ORIGINAL (Arduino SA)", 0x1A86: "GENERICO (CH340)", 0x0403: "GENERICO (FTDI)"}
    return vids.get(vid, "DESCONHECIDO")

def baixar_e_substituir(url):
    try:
        temp_exe = os.path.join(BASE_DIR, "update_temp.exe")
        r = requests.get(url, stream=True, timeout=120)
        with open(temp_exe, "wb") as f:
            for chunk in r.iter_content(8192): f.write(chunk)
        bat_path = os.path.join(BASE_DIR, "update.bat")
        with open(bat_path, "w") as f:
            f.write('@echo off\ntaskkill /f /im monitor.exe > nul 2>&1\ntimeout /t 5 /nobreak > nul\n:try_move\n')
            f.write(f'move /y "{temp_exe}" "{EXE_PATH}"\nif errorlevel 1 (timeout /t 2 > nul & goto try_move)\n')
            f.write(f'start "" "{EXE_PATH}"\ndel "%%~f0"\n')
        subprocess.Popen(f'cmd /c "{bat_path}"', shell=True, creationflags=subprocess.CREATE_NEW_CONSOLE)
        os._exit(0)
    except: pass

def verificar_atualizacao():
    try:
        headers = {'User-Agent': 'Mozilla/5.0', 'Cache-Control': 'no-cache'}
        res = requests.get(f"{VERSION_URL}?t={int(time.time())}", headers=headers, timeout=15)
        if res.status_code == 200:
            data = res.json()
            if str(data.get("version")).strip() != VERSION: baixar_e_substituir(data.get("url"))
    except: pass

def loop_principal():
    portas_conhecidas = {p.device for p in serial.tools.list_ports.comports()}
    geo_info = get_geo()
    ult_check = 0
    while True:
        try:
            portas = serial.tools.list_ports.comports()
            atuais = {p.device for p in portas}
            for porta in (atuais - portas_conhecidas):
                p = next(it for it in portas if it.device == porta)
                vid = p.vid if p.vid else 0
                log_msg = f"CONEXAO: {p.description} | Porta: {p.device} | VID: {vid:04x} | PID: {p.pid:04x} | SN: {p.serial_number} | Fab: {verificar_fabricante(vid)} | {geo_info}"
                registrar_log(log_msg)
            portas_conhecidas = atuais
            if time.time() - ult_check > UPDATE_INTERVAL:
                verificar_atualizacao()
                ult_check = time.time()
            time.sleep(3)
        except: time.sleep(10)

def criar_janela_senha(icon):
    """ Função executada em Thread separada para garantir o foco do teclado """
    def validar(event=None): # Aceita o 'Enter' do teclado também
        if ent.get() == ADMIN_PASS:
            root.quit()
            root.destroy()
            icon.stop()
            os._exit(0)
        else:
            registrar_log("Tentativa de fechamento: Senha incorreta.")
            root.destroy()

    root = tk.Tk()
    root.title("Segurança do Agente")
    root.geometry("300x130")
    root.resizable(False, False)
    root.attributes("-topmost", True)
    
    # Centralizar janela
    screen_width = root.winfo_screenwidth()
    screen_height = root.winfo_screenheight()
    x = (screen_width // 2) - (300 // 2)
    y = (screen_height // 2) - (130 // 2)
    root.geometry(f"300x130+{x}+{y}")

    tk.Label(root, text="Digite a senha de administrador:", pady=10).pack()
    ent = tk.Entry(root, show="*", width=20)
    ent.pack()
    ent.bind('<Return>', validar) # Atalho para a tecla Enter
    
    btn_frame = tk.Frame(root, pady=10)
    btn_frame.pack()
    tk.Button(btn_frame, text="Confirmar", command=validar, width=10).pack(side=tk.LEFT, padx=5)
    tk.Button(btn_frame, text="Cancelar", command=root.destroy, width=10).pack(side=tk.LEFT, padx=5)

    # Forçar foco absoluto
    ent.focus_set()
    root.after(200, lambda: root.focus_force())
    root.mainloop()

def acao_fechar(icon, item):
    """ Chama a janela em uma nova Thread para não travar o ícone """
    threading.Thread(target=criar_janela_senha, args=(icon,), daemon=True).start()

def iniciar_icone():
    try:
        img = Image.open(ICON_PATH) if os.path.exists(ICON_PATH) else Image.new('RGB', (64, 64), (0, 120, 215))
        menu = pystray.Menu(
            pystray.MenuItem(f"Agente v{VERSION}", lambda: None), 
            pystray.MenuItem("Fechar Monitor", acao_fechar)
        )
        icon = pystray.Icon("MonitorArduino", img, f"Agente Mestre v{VERSION}", menu)
        icon.run()
    except:
        while True: time.sleep(100)

if __name__ == "__main__":
    # Thread do monitor de USB e Updates
    threading.Thread(target=loop_principal, daemon=True).start()
    # Thread Principal rodando o Ícone da Bandeja
    iniciar_icone()
