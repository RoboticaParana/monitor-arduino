
import os, time, requests, socket, uuid, psutil, threading, json, sys
from datetime import datetime
from PIL import Image
import pystray
import tkinter as tk

VERSION = "7.4.10"
ADMIN_PASS = "robotic@p@r@n@" 
URL_PLANILHA = "https://script.google.com/macros/s/AKfycbxDiys_7p3BFqwuq-GJ-pe_Fn0q6cIiVCBkXwKTp2Ft5Mqkud6nFeMCdR3DYsbu49XB/exec" # COLE AQUI A MESMA URL DA EXTENSÃƒO


# Em build --onefile, __file__ pode apontar para uma pasta temporaria do PyInstaller.
BASE_DIR = os.path.dirname(sys.executable) if getattr(sys, "frozen", False) else os.path.dirname(os.path.realpath(__file__))
ICON_PATH = os.path.join(BASE_DIR, "mascote.ico")
LOG_FILE = os.path.join(BASE_DIR, "agente_b1n0.log")
UPLOAD_PROCESSOS = {
    "arduino-cli.exe": "Arduino IDE",
    "avrdude.exe": "Arduino/AVR",
    "esptool.exe": "ESP",
    "esptool.py": "ESP",
    "bossac.exe": "Arduino/SAMD",
    "dfu-util.exe": "DFU",
    "openocd.exe": "OpenOCD",
    "mbuild.exe": "mBlock",
}
UPLOAD_ASSINATURAS_CMD = {
    "arduino-cli": "Arduino IDE",
    "avrdude": "Arduino/AVR",
    "esptool": "ESP",
    "bossac": "Arduino/SAMD",
    "dfu-util": "DFU",
    "openocd": "OpenOCD",
    "mblock": "mBlock",
}
APP_PROCESSOS = {
    "arduino.exe": "Arduino IDE",
    "arduino-ide.exe": "Arduino IDE",
    "mBlock.exe": "mBlock Software",
}
UPLOAD_PROCESSOS_LOWER = {k.lower(): v for k, v in UPLOAD_PROCESSOS.items()}
APP_PROCESSOS_LOWER = {k.lower(): v for k, v in APP_PROCESSOS.items()}

def registrar_log(mensagem):
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"[{datetime.now().strftime('%d/%m/%Y %H:%M:%S')}] {mensagem}\n")
    except Exception:
        pass

def localizar_icone():
    candidatos = [
        os.path.join(BASE_DIR, "mascote.ico"),
        os.path.join(getattr(sys, "_MEIPASS", BASE_DIR), "mascote.ico"),
        os.path.join(os.path.dirname(os.path.realpath(__file__)), "mascote.ico"),
    ]
    for caminho in candidatos:
        if os.path.exists(caminho):
            return caminho
    return None

def obter_id_unico():
    id_hash = hex(uuid.getnode()).upper()[2:8]
    return f"WIN-{id_hash}"

def obter_ip_local():
    try:
        return socket.gethostbyname(socket.gethostname())
    except Exception:
        return "N/D"

def enviar_para_planilha(evento, plataforma, detalhe=""):
    dados = {
        "id": int(time.time() * 1000),
        "data": datetime.now().strftime('%d/%m/%Y %H:%M:%S'),
        "evento": f"{evento} de um dispositivo Windows ({plataforma})",
        "placa": "Detectada via Software",
        "serial": obter_id_unico(),
        "ip_publico": "Buscando...",
        "ip_local": obter_ip_local(),
        "detalhe": detalhe,
        "versao_agente": VERSION
    }
    try:
        response = requests.post(URL_PLANILHA, data=json.dumps(dados), headers={'Content-Type':'application/json'}, timeout=15)
        registrar_log(f"ENVIO {evento} | {plataforma} | HTTP {response.status_code} | {detalhe}")
    except Exception as e:
        registrar_log(f"FALHA ENVIO {evento} | {plataforma} | {e}")

def descrever_contexto_app():
    try:
        ativos = []
        for proc in psutil.process_iter(['name']):
            nome = (proc.info.get('name') or "").lower()
            if nome in APP_PROCESSOS_LOWER:
                ativos.append(APP_PROCESSOS_LOWER[nome])
        return ", ".join(sorted(set(ativos))) if ativos else "Aplicativo nao identificado"
    except Exception:
        return "Aplicativo nao identificado"

def identificar_upload(nome, cmdline):
    nome_lower = (nome or "").lower()
    cmd_lower = " ".join(cmdline or []).lower()
    if nome_lower in UPLOAD_PROCESSOS_LOWER:
        return UPLOAD_PROCESSOS_LOWER[nome_lower]
    for assinatura, plataforma in UPLOAD_ASSINATURAS_CMD.items():
        if assinatura in cmd_lower:
            return plataforma
    return None

def loop_principal():
    ultimo_envio = {}
    registrar_log(f"AGENTE B1N0 INICIADO - v{VERSION}")
    while True:
        try:
            for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
                nome = proc.info.get('name') or ""
                cmdline = proc.info.get('cmdline') or []
                plataforma_upload = identificar_upload(nome, cmdline)
                if plataforma_upload:
                    agora = time.time()
                    chave = f"{nome.lower()}:{proc.info.get('pid')}"
                    if chave not in ultimo_envio or (agora - ultimo_envio[chave] > 30):
                        cmd_texto = " ".join(cmdline)
                        detalhe = f"processo={nome}; app={descrever_contexto_app()}; cmd={cmd_texto[:400]}"
                        enviar_para_planilha("UPLOAD", plataforma_upload, detalhe)
                        ultimo_envio[chave] = agora
            time.sleep(10)
        except Exception as e:
            registrar_log(f"ERRO LOOP: {e}")
            time.sleep(15)

def criar_janela_senha(icon):
    def validar(event=None):
        if ent.get() == ADMIN_PASS:
            icon.stop(); os._exit(0)
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
    try:
        caminho_icone = localizar_icone()
        img = Image.open(caminho_icone) if caminho_icone else Image.new('RGBA', (64, 64), (0, 74, 128, 255))
        img = img.convert("RGBA").resize((64, 64))
    except Exception as e:
        registrar_log(f"FALHA ICONE: {e}")
        img = Image.new('RGBA', (64, 64), (0, 74, 128, 255))
        
    menu = pystray.Menu(pystray.MenuItem(f"v{VERSION}", lambda: None), pystray.MenuItem("Sair", lambda i, item: threading.Thread(target=criar_janela_senha, args=(i,)).start()))
    icon = pystray.Icon("AgenteB1n0", img, "Agente B1n0", menu)
    icon.run()

if __name__ == "__main__":
    threading.Thread(target=loop_principal, daemon=True).start()
    iniciar_icone()
