URL_PLANILHA = "https://script.google.com/macros/s/AKfycbxDiys_7p3BFqwuq-GJ-pe_Fn0q6cIiVCBkXwKTp2Ft5Mqkud6nFeMCdR3DYsbu49XB/exec" # COLE AQUI A MESMA URL DA EXTENSÃO

import os
import time
import requests
import socket
import uuid
import psutil
import threading
from datetime import datetime
from PIL import Image
import pystray
import tkinter as tk
import ctypes
import json

# ==========================================
# CONFIGURAÇÕES TÉCNICAS (v7.2)
# ==========================================
VERSION = "7.2"
ADMIN_PASS = "robotic@p@r@n@" 


BASE_DIR = os.path.join(os.environ.get('ProgramData', 'C:\\ProgramData'), "AgenteB1n0")
ICON_PATH = os.path.join(BASE_DIR, "mascote.ico")

def obter_id_unico():
    # ID persistente baseado no MAC Address
    id_hash = hex(uuid.getnode()).upper()[2:8]
    return f"WIN-{id_hash}"

def enviar_para_planilha(evento, plataforma):
    dados = {
        "id": int(time.time() * 1000),
        "data": datetime.now().strftime('%d/%m/%Y %H:%M:%S'),
        "evento": f"{evento} de um dispositivo Windows ({plataforma})",
        "placa": "Detectada via Software",
        "serial": obter_id_unico(),
        "ip_publico": "Buscando...",
        "ip_local": "127.0.0.1"
    }
    
    try:
        # Tenta obter IPs rapidamente
        dados["ip_local"] = socket.gethostbyname(socket.gethostname())
        # O Google Apps Script prefere receber os dados como string ou parâmetros
        # Usamos allow_redirects=True porque o Google sempre redireciona o POST
        response = requests.post(
            URL_PLANILHA, 
            data=json.dumps(dados),
            headers={'Content-Type': 'application/json'},
            allow_redirects=True, 
            timeout=15
        )
        print(f"Status do envio: {response.status_code}")
    except Exception as e:
        print(f"Erro ao enviar: {e}")

def loop_principal():
    # Monitoramento de processos
    SOFTWARES = {
        "arduino.exe": "Arduino IDE",
        "arduino-ide.exe": "Arduino IDE", # Versão 2.x do Arduino
        "mBlock.exe": "mBlock Software",
        "javaw.exe": "Arduino IDE/mBlock (Java)" # Algumas versões antigas rodam como javaw
    }
    
    # Dicionário para controlar quando o log foi enviado (evita spam)
    ultimo_envio = {}

    while True:
        try:
            for proc in psutil.process_iter(['name']):
                nome = proc.info['name']
                if nome in SOFTWARES:
                    agora = time.time()
                    # Só envia se passou mais de 60 segundos do último envio do mesmo software
                    if nome not in ultimo_envio or (agora - ultimo_envio[nome] > 60):
                        enviar_para_planilha("UPLOAD", SOFTWARES[nome])
                        ultimo_envio[nome] = agora
            
            time.sleep(10) # Verifica a cada 10 segundos
        except:
            time.sleep(15)

# --- MANTÉM AS FUNÇÕES DE INTERFACE (ÍCONE E SENHA) ---
def criar_janela_senha(icon):
    def validar(event=None):
        if ent.get() == ADMIN_PASS:
            root.quit(); root.destroy(); icon.stop(); os._exit(0)
        else: root.destroy()
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
    img = Image.open(ICON_PATH) if os.path.exists(ICON_PATH) else Image.new('RGB', (64, 64), (0, 74, 128))
    menu = pystray.Menu(
        pystray.MenuItem(f"Agente B1n0 (v{VERSION})", lambda: None), 
        pystray.MenuItem("Encerrar Servico", lambda i, item: threading.Thread(target=criar_janela_senha, args=(i,)).start())
    )
    icon = pystray.Icon("AgenteB1n0", img, "Agente B1n0", menu)
    icon.run()

if __name__ == "__main__":
    # Garante que o processo rode em background sem console se compilado com --noconsole
    threading.Thread(target=loop_principal, daemon=True).start()
    iniciar_icone()