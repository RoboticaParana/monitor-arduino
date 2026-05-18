import os, time, requests, subprocess, sys, json

# Em build --onefile, __file__ pode apontar para a pasta temporaria do PyInstaller.
BASE_DIR = os.path.dirname(sys.executable) if getattr(sys, "frozen", False) else os.path.dirname(os.path.realpath(__file__))
MONITOR_EXE = os.path.join(BASE_DIR, "monitor.exe")
VERSION_LOCAL_FILE = os.path.join(BASE_DIR, "version.local")
LOG_FILE = os.path.join(BASE_DIR, "agente_b1n0_manager.log")
URL_VERSION_JSON = "https://raw.githubusercontent.com/RoboticaParana/monitor-arduino/main/version.json"
MONITOR_VERSION_EMBUTIDA = "7.4.13"

def registrar_log(mensagem):
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"{time.strftime('%d/%m/%Y %H:%M:%S')} - {mensagem}\n")
    except Exception:
        pass

def verificar_e_atualizar():
    try:
        v_local = MONITOR_VERSION_EMBUTIDA
        if os.path.exists(VERSION_LOCAL_FILE):
            with open(VERSION_LOCAL_FILE, "r") as f:
                v_local = f.read().strip()
        else:
            with open(VERSION_LOCAL_FILE, "w") as f:
                f.write(v_local)

        res = requests.get(URL_VERSION_JSON, timeout=20)
        if res.status_code == 200:
            data = json.loads(res.content.decode("utf-8-sig"))
            if data["version"] != v_local:
                registrar_log(f"Atualizacao encontrada: local={v_local} remoto={data['version']}")
                r = requests.get(data["url"], timeout=30)
                if r.status_code != 200 or len(r.content) < 1024:
                    registrar_log(f"Download invalido: HTTP {r.status_code}, bytes={len(r.content)}")
                    return

                temp = MONITOR_EXE + ".download"
                with open(temp, "wb") as f:
                    f.write(r.content)

                subprocess.run("taskkill /f /im monitor.exe", shell=True, capture_output=True)
                time.sleep(2)

                backup = MONITOR_EXE + ".bak"
                if os.path.exists(MONITOR_EXE):
                    try:
                        os.replace(MONITOR_EXE, backup)
                    except Exception as e:
                        registrar_log(f"Falha ao criar backup: {e}")

                os.replace(temp, MONITOR_EXE)
                with open(VERSION_LOCAL_FILE, "w") as f:
                    f.write(data["version"])
                subprocess.Popen([MONITOR_EXE], cwd=BASE_DIR, shell=False)
                registrar_log("Atualizacao aplicada e monitor reiniciado")
    except Exception as e:
        registrar_log(f"Falha ao atualizar: {e}")

if __name__ == "__main__":
    time.sleep(5)

    while True:
        try:
            check = subprocess.run('tasklist /FI "IMAGENAME eq monitor.exe"', capture_output=True, text=True, shell=True)
            if "monitor.exe" not in check.stdout and os.path.exists(MONITOR_EXE):
                subprocess.Popen([MONITOR_EXE], cwd=BASE_DIR, shell=False)
                registrar_log("Monitor iniciado")
        except Exception as e:
            registrar_log(f"Falha ao verificar/iniciar monitor: {e}")

        verificar_e_atualizar()
        time.sleep(60)
