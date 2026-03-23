import sys
import ctypes
import os

# ===============================
# EVITAR MULTIPLAS INSTANCIAS
# ===============================
mutex_name = "Global\\MonitorArduinoMutex"
mutex = ctypes.windll.kernel32.CreateMutexW(None, False, mutex_name)

if ctypes.windll.kernel32.GetLastError() == 183:
    sys.exit(0)

# ===============================
# IMPORTS
# ===============================
import threading
import time
import socket
import requests
import serial.tools.list_ports
from datetime import datetime
from tkinter import Tk, messagebox
from pystray import Icon, MenuItem, Menu
from PIL import Image

# ===============================
# RESOURCE PATH
# ===============================
def resource_path(relative_path):
    try:
        base_path = sys._MEIPASS
    except:
        base_path = os.path.abspath(".")
    return os.path.join(base_path, relative_path)

# ===============================
# CONFIG
# ===============================
VERSION = "2.10"
UPDATE_URL = "https://raw.githubusercontent.com/RoboticaParana/monitor-arduino/main/version.json"

PASTA = r"C:\ProgramData\RoboticsMonitor"
os.makedirs(PASTA, exist_ok=True)

LOG = os.path.join(PASTA, "upload_log.txt")
open(LOG, "a").close()

# ===============================
# IP + GEO
# ===============================
def get_ip():
    try:
        return socket.gethostbyname(socket.gethostname())
    except:
        return "IP"

def get_geo():
    try:
        r = requests.get("http://ip-api.com/json/", timeout=3)
        d = r.json()
        return f"{d.get('city')}/{d.get('country')}"
    except:
        return "N/A"

# ===============================
# CHIP
# ===============================
def identificar_chip(vid):
    if vid == 6790:
        return "CH340"
    elif vid == 9025:
        return "Arduino LLC"
    elif vid == 10755:
        return "Arduino SA"
    elif vid == 4292:
        return "CP210x"
    else:
        return "Desconhecido"

# ===============================
# DETECTAR PLACAS
# ===============================
def get_arduinos():
    placas = {}
    for p in serial.tools.list_ports.comports():
        placas[p.device] = {
            "nome": p.description,
            "vid": p.vid,
            "pid": p.pid,
            "serial": p.serial_number
        }
    return placas

# ===============================
# LOG
# ===============================
def registrar(msg):
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(msg + "\n")

# ===============================
# POPUP
# ===============================
def popup(titulo, msg, confirm=False):
    root = Tk()
    root.withdraw()

    if confirm:
        res = messagebox.askyesno(titulo, msg)
        root.destroy()
        return res
    else:
        messagebox.showinfo(titulo, msg)
        root.destroy()

# ===============================
# UPDATE
# ===============================
def verificar_update():
    try:
        r = requests.get(UPDATE_URL, timeout=10)
        data = r.json()

        nova = data.get("version")
        url = data.get("url")

        if nova != VERSION:
            if popup("Atualização disponível", f"Nova versão {nova}\nAtual: {VERSION}\nAtualizar?", True):
                baixar_update(url)
        else:
            popup("Monitor Arduino", f"Você já está na versão mais recente ({VERSION})")

    except Exception as e:
        popup("Erro", f"Falha ao verificar atualização\n{e}")

def baixar_update(url):
    try:
        novo = os.path.join(PASTA, "monitor_new.exe")

        r = requests.get(url, stream=True)

        with open(novo, "wb") as f:
            for chunk in r.iter_content(1024):
                f.write(chunk)

        iniciar_updater(novo)

    except Exception as e:
        popup("Erro", f"Erro ao baixar atualização\n{e}")

def iniciar_updater(novo):
    atual = sys.executable
    pasta = os.path.dirname(atual)
    updater = os.path.join(PASTA, "updater.bat")

    with open(updater, "w") as f:
        f.write(f"""
@echo off
timeout /t 5 >nul
taskkill /f /im monitor.exe
timeout /t 5 >nul
cd /d "{pasta}"
ren monitor.exe monitor_old.exe
move /Y "{novo}" monitor.exe
timeout /t 3 >nul
start "" monitor.exe
timeout /t 2 >nul
del monitor_old.exe
del "%~f0"
""")

    os.startfile(updater)
    os._exit(0)

# ===============================
# MONITOR ARDUINO
# ===============================
def monitor():
    anterior = get_arduinos()

    while True:
        atual = get_arduinos()

        for porta, dados in atual.items():
            if porta not in anterior:
                agora = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
                chip = identificar_chip(dados["vid"])
                ip = get_ip()
                geo = get_geo()

                registrar(
                    f"CONECTOU - {agora} - PORTA:{porta} - NOME:{dados['nome']} "
                    f"- VID:{dados['vid']} - PID:{dados['pid']} "
                    f"- SERIAL:{dados['serial']} - CHIP:{chip} "
                    f"- IP:{ip} - LOC:{geo}"
                )

        for porta in anterior:
            if porta not in atual:
                time.sleep(1)
                novo = get_arduinos()
                if porta in novo:
                    dados = novo[porta]
                    agora = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
                    chip = identificar_chip(dados["vid"])

                    registrar(
                        f"UPLOAD - {agora} - PORTA:{porta} - NOME:{dados['nome']} - CHIP:{chip}"
                    )

        anterior = atual
        time.sleep(0.5)

# ===============================
# LOOP UPDATE
# ===============================
def loop_update():
    time.sleep(5)
    verificar_update()

    while True:
        time.sleep(1800)
        verificar_update()

# ===============================
# TRAY
# ===============================
def sair(icon, item):
    icon.stop()
    os._exit(0)

def tray():
    try:
        img = Image.open(resource_path("mascote.ico"))
    except:
        img = Image.new("RGB", (64, 64), (0, 200, 0))

    menu = Menu(
        MenuItem("Verificar atualização", lambda icon, item: verificar_update()),
        MenuItem("Sair", sair)
    )

    icon = Icon(
        "MonitorArduino",
        img,
        f"Monitor Arduino v{VERSION}",
        menu
    )

    icon.run()

# ===============================
# START
# ===============================
threading.Thread(target=monitor, daemon=True).start()
threading.Thread(target=loop_update, daemon=True).start()

tray()
