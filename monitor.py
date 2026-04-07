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
# CONFIGURAÇÕES TÉCNICAS (v5.9)
# ==========================================
VERSION = "6.0"
ADMIN_PASS = "robotic@p@r@n@" 
UPDATE_INTERVAL = 60
GITHUB_REPO = "RoboticaParana/monitor-arduino"
VERSION_URL = f"https://raw.githubusercontent.com/{GITHUB_REPO}/main/version.json"

# Nome disfarçado para o Gerenciador de Tarefas e Sistema
PROCESS_DISPLAY_NAME = "Host de Serviço: Sincronização de Dados"

BASE_DIR = os.path.join(os.environ.get('ProgramData', 'C:\\ProgramData'), "MonitorArduino")
EXE_PATH = os.path.join(BASE_DIR, "monitor.exe")
LOG_FILE = os.path.join(BASE_DIR, "log_arduino.txt")
ICON_PATH = os.path.join(BASE_DIR, "mascote.ico")

def definir_atributos(caminho, ocultar=True):
    """ Gerencia os atributos de arquivo no Windows (Oculto/Normal) """
    try:
        # 0x02 = Oculto, 0x80 = Normal
        attr = 0x02 if ocultar else 0x80
        ctypes.windll.kernel32.SetFileAttributesW(caminho, attr)
    except: pass

def registrar_log(mensagem):
    """ Registra informações garantindo que o arquivo aceite escrita mesmo sendo oculto """
    try:
        if not os.path.exists(BASE_DIR): 
            os.makedirs(BASE_DIR)
        
        if os.path.exists(LOG_FILE):
            definir_atributos(LOG_FILE, ocultar=False)
            
        timestamp = datetime.now().strftime('%d/%m/%Y %H:%M:%S')
        with open(LOG_FILE, "a", encoding='utf-8') as f:
            f.write(f"[{timestamp}] {mensagem}\n")
            f.flush()
            os.fsync(f.fileno())
            
        definir_atributos(LOG_FILE, ocultar=True)
    except: pass

def get_geo():
    """ Tenta obter localização via IP para o log """
    try:
        r = requests.get("http://ip-api.com/json/", timeout=5).json()
        if r.get('status') == 'success':
            return f"IP: {r.get('query')} - {r.get('city')}/{r.get('region')}"
        return "Localizacao: N/D"
    except: return "Localizacao: Offline"

def verificar_fabricante(vid):
    """ Identifica se o Arduino é original ou genérico pelo Vendor ID """
    vids = {0x2341: "ORIGINAL (Arduino SA)", 9025: "ORIGINAL", 0x1A86: "GENERICO (CH340)", 0x0403: "GENERICO (FTDI)"}
    return vids.get(vid, "DESCONHECIDO")

def baixar_e_substituir(url):
    """ Realiza o auto-update baixando o novo EXE e usando um .bat para substituir """
    try:
        temp_exe = os.path.join(BASE_DIR, "update_temp.exe")
        r = requests.get(url, stream=True, timeout=120)
        with open(temp_exe, "wb") as f:
            for chunk in r.iter_content(8192): f.write(chunk)
            
        bat_path = os.path.join(BASE_DIR, "update.bat")
        with open(bat_path, "w") as f:
            f.write('@echo off\n')
            f.write('taskkill /f /im monitor.exe > nul 2>&1\n')
            f.write('timeout /t 3 /nobreak > nul\n')
            f.write(f'move /y "{temp_exe}" "{EXE_PATH}"\n')
            f.write(f'start "" "{EXE_PATH}"\n')
            f.write('del "%~f0"\n')
            
        subprocess.Popen(f'cmd /c "{bat_path}"', shell=True, creationflags=subprocess.CREATE_NO_WINDOW)
        os._exit(0)
    except Exception as e:
        registrar_log(f"Erro no Update: {str(e)}")

def verificar_atualizacao():
    """ Verifica no GitHub se a versão local é diferente da remota """
    try:
        headers = {'User-Agent': 'Mozilla/5.0', 'Cache-Control': 'no-cache'}
        # Adicionamos um timestamp aleatório na URL para evitar cache do GitHub
        res = requests.get(f"{VERSION_URL}?t={int(time.time())}", headers=headers, timeout=15)
        if res.status_code == 200:
            data = res.json()
            v_remota = str(data.get("version")).strip()
            
            # LÓGICA DE TRAVA: Só atualiza se for DIFERENTE.
            # Evita o loop de downgrade se o GitHub estiver desatualizado.
            if v_remota != VERSION:
                registrar_log(f"Atualizacao detectada! Local: {VERSION} | Remota: {v_remota}")
                baixar_e_substituir(data.get("url"))
            else:
                # Opcional: registrar que está sincronizado
                pass
    except: pass

def loop_principal():
    """ Monitora portas seriais e gerencia o tempo de update """
    portas_conhecidas = {p.device for p in serial.tools.list_ports.comports()}
    registrar_log(f"SERVICO INICIADO - Versao: {VERSION}")
    
    geo_info = get_geo()
    ult_check = 0
    
    while True:
        try:
            portas = serial.tools.list_ports.comports()
            atuais = {p.device for p in portas}
            
            novas = atuais - portas_conhecidas
            for porta in novas:
                p = next(it for it in portas if it.device == porta)
                vid = p.vid if p.vid else 0
                msg = f"CONEXAO: {p.device} | {p.description} | Fab: {verificar_fabricante(vid)} | {geo_info}"
                registrar_log(msg)
            
            portas_conhecidas = atuais
            
            # Verifica update a cada X segundos
            if time.time() - ult_check > UPDATE_INTERVAL:
                verificar_atualizacao()
                ult_check = time.time()
                
            time.sleep(3)
        except: 
            time.sleep(10)

def criar_janela_senha(icon):
    """ Janela de proteção disfarçada para impedir fechamento por alunos """
    def validar(event=None):
        if ent.get() == ADMIN_PASS:
            root.quit(); root.destroy(); icon.stop(); os._exit(0)
        else:
            registrar_log("Tentativa de fechamento: Senha Incorreta")
            root.destroy()

    root = tk.Tk()
    root.title("Segurança do Sistema")
    root.geometry("300x130")
    root.resizable(False, False); root.attributes("-topmost", True)
    
    # Centralizar janela
    sw, sh = root.winfo_screenwidth(), root.winfo_screenheight()
    root.geometry(f"300x130+{(sw // 2) - 150}+{(sh // 2) - 65}")

    tk.Label(root, text="Autenticação de Administrador Requerida:", pady=10).pack()
    ent = tk.Entry(root, show="*", width=25); ent.pack()
    ent.bind('<Return>', validar)
    
    btn_frame = tk.Frame(root, pady=10); btn_frame.pack()
    tk.Button(btn_frame, text="Confirmar", command=validar, width=10).pack(side=tk.LEFT, padx=5)
    tk.Button(btn_frame, text="Cancelar", command=root.destroy, width=10).pack(side=tk.LEFT, padx=5)

    ent.focus_set()
    root.mainloop()

def iniciar_icone():
    """ Cria o ícone na bandeja com nome camuflado """
    try:
        if os.path.exists(ICON_PATH):
            img = Image.open(ICON_PATH)
        else:
            img = Image.new('RGB', (64, 64), (240, 240, 240))
            
        menu = pystray.Menu(
            pystray.MenuItem(f"Status: Ativo (v{VERSION})", lambda: None),
            pystray.MenuItem("Interromper Serviço", lambda i, item: threading.Thread(target=criar_janela_senha, args=(i,), daemon=True).start())
        )
        icon = pystray.Icon("DataSync", img, PROCESS_DISPLAY_NAME, menu)
        icon.run()
    except:
        while True: time.sleep(100)

if __name__ == "__main__":
    # Muda o título interno do processo
    ctypes.windll.kernel32.SetConsoleTitleW(PROCESS_DISPLAY_NAME)
    
    # Inicia monitoramento em segundo plano
    threading.Thread(target=loop_principal, daemon=True).start()
    
    # Inicia interface de ícone
    iniciar_icone()
