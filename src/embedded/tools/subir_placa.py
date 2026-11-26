#!/usr/bin/env python3
"""Sube a una placa NodeMCU-ESP32 los .lua que necesita, siguiendo require/dofile desde app/init.lua.

Pasos: respalda la placa en respaldos/<mac>-<fecha>/, frena la app (renombra init.lua y reinicia),
sube credentials.lua y lo ejecuta (pines en estado seguro), sube el resto verificando cada archivo
con una suma de control, deja init.lua para el final y reinicia. config.json y los archivos que
no son del firmware no se tocan. Los archivos que ya están iguales en la placa no se vuelven a subir.

Uso:
  tools/subir_placa.py --lista                 # solo muestra los archivos que se suben
  tools/subir_placa.py                         # /dev/ttyUSB0
  tools/subir_placa.py --puerto /dev/ttyUSB1 --sin-respaldo

Requiere pyserial (apt install python3-serial o pip install pyserial).
"""
import argparse
import re
import sys
import time
from datetime import datetime
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent  # src/embedded
DIRS = [BASE / "app", BASE / "libs"]
ENTRADA = "init.lua"
PRIMERO = "credentials.lua"
PATRON = re.compile(r"""\b(require|dofile)\s*\(?\s*["']([\w.]+)["']""")


# ---------------------------------------------------------------- archivos

def buscar(nombre):
    archivo = nombre if nombre.endswith(".lua") else nombre + ".lua"
    for d in DIRS:
        if (d / archivo).is_file():
            return d / archivo
    return None


def dependencias():
    pendientes, vistos, faltantes = [ENTRADA], {}, set()
    while pendientes:
        nombre = pendientes.pop()
        ruta = buscar(nombre)
        if ruta is None:
            faltantes.add(nombre)
            continue
        if ruta.name in vistos:
            continue
        vistos[ruta.name] = ruta
        for linea in ruta.read_text(encoding="utf-8").splitlines():
            codigo = linea.split("--", 1)[0]  # ignora comentarios
            pendientes += [m.group(2) for m in PATRON.finditer(codigo)]
    return vistos, faltantes


def suma(datos):
    s = 0
    for b in datos:
        s = (s * 31 + b) % 2147483647
    return len(datos), s


# ---------------------------------------------------------------- placa

class Placa:
    """REPL de NodeMCU por serie. Comandos cortos para no disparar el watchdog."""

    def __init__(self, puerto):
        import serial
        self.p = serial.Serial(puerto, 115200, timeout=0.05)
        self.p.dtr = False
        self.p.rts = False

    def leer(self, t):
        fin, buf = time.time() + t, b""
        while time.time() < fin:
            buf += self.p.read(4096)
        return buf.decode("latin-1")

    def cmd(self, linea, timeout=10.0):
        self.p.reset_input_buffer()
        self.p.write(linea.encode("latin-1") + b"\r\n")
        buf, fin = b"", time.time() + timeout
        while time.time() < fin:
            buf += self.p.read(4096)
            if buf.endswith(b"> ") and b"\n" in buf:
                break
        out = buf.decode("latin-1")
        out = out.split("\n", 1)[1] if "\n" in out else ""
        return out.rsplit("> ", 1)[0].strip("\r\n")

    def sincronizar(self, intentos=5):
        for _ in range(intentos):
            self.p.write(b"\r\n")
            self.leer(0.5)
            if "SYNC2" in self.cmd('print("SYNC"..1+1)', timeout=3):
                return
        raise RuntimeError("la placa no responde en el REPL")

    def reiniciar(self, espera=6):
        self.p.write(b"\r\nnode.restart()\r\n")
        return self.leer(espera)

    def existe(self, nombre):
        return "SI" in self.cmd(f'print(file.exists("{nombre}") and "SI" or "NO")')

    def archivos(self):
        r = self.cmd("for k,v in pairs(file.list()) do print('F:'..k..'='..v) end")
        return {a: int(b) for a, b in re.findall(r"^F:(\S+)=(\d+)\s*$", r, re.M)}

    def suma(self, nombre, paso=1024):
        self.cmd("__s,__n=0,0")
        off = 0
        while True:
            r = self.cmd(
                f'do local f=io.open("{nombre}","rb") f:seek("set",{off}) local d=f:read({paso}) f:close() '
                'if d then __n=__n+#d for i=1,#d do __s=(__s*31+d:byte(i))%2147483647 end print("L="..#d) '
                'else print("L=0") end end')
            m = re.search(r"L=(\d+)", r)
            if not m:
                raise RuntimeError(f"suma de {nombre}: {r[-200:]}")
            if m.group(1) == "0":
                break
            off += paso
        m = re.search(r"CK=(\d+):(\d+)", self.cmd('print("CK="..__n..":"..__s)'))
        return int(m.group(1)), int(m.group(2))

    def bajar(self, nombre, paso=384):
        out = b""
        while True:
            r = self.cmd(
                f'do local f=io.open("{nombre}","rb") f:seek("set",{len(out)}) local d=f:read({paso}) f:close() '
                'if d then local t={} for j=1,#d do t[j]=string.format("%02x",d:byte(j)) end '
                'print("H:"..table.concat(t)) else print("H:") end end')
            m = re.search(r"^H:([0-9a-f]*)\s*$", r, re.M)
            if not m:
                raise RuntimeError(f"lectura de {nombre}: {r[-200:]}")
            if not m.group(1):
                return out
            out += bytes.fromhex(m.group(1))

    def subir(self, nombre, datos):
        tmp = nombre + ".tmp"
        if "OK" not in self.cmd(f'__f=io.open("{tmp}","wb") print(__f and "OK" or "ERR")'):
            raise RuntimeError(f"no se pudo abrir {tmp}")
        for i in range(0, len(datos), 48):
            esc = "".join(chr(b) if 32 <= b < 127 and chr(b) not in '"\\' else f"\\{b:03d}"
                          for b in datos[i:i + 48])
            r = self.cmd(f'__f:write("{esc}")')
            if "rror" in r:
                raise RuntimeError(f"escribiendo {nombre}: {r}")
        self.cmd("__f:close() __f=nil")
        self.cmd(f'file.remove("{nombre}") file.rename("{tmp}","{nombre}")')
        if self.suma(nombre) != suma(datos):
            raise RuntimeError(f"{nombre}: la suma de control no coincide")


# ---------------------------------------------------------------- principal

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--puerto", default="/dev/ttyUSB0")
    ap.add_argument("--lista", action="store_true", help="solo listar los archivos a subir")
    ap.add_argument("--sin-respaldo", action="store_true")
    args = ap.parse_args()

    locales, faltantes = dependencias()
    if faltantes:
        print("No encontrados (¿módulos del firmware?):", ", ".join(sorted(faltantes)), file=sys.stderr)
    for nombre, ruta in sorted(locales.items()):
        print(f"  {ruta.relative_to(BASE)}")
    if args.lista:
        return

    pl = Placa(args.puerto)
    pl.sincronizar()
    mac = re.sub(r"[^0-9a-f]", "", pl.cmd("print(wifi.sta.getmac())").lower())[-12:] or "sinmac"
    print(f"Placa {mac} en {args.puerto}")

    # 1. frenar la app para tener la consola quieta
    if pl.existe(ENTRADA):
        pl.cmd(f'file.remove("init_off.lua") file.rename("{ENTRADA}","init_off.lua")')
        pl.reiniciar()
        pl.sincronizar()
    en_placa = pl.archivos()

    # 2. respaldo
    if not args.sin_respaldo:
        dest = BASE / "respaldos" / f"{mac}-{datetime.now():%Y%m%d-%H%M%S}"
        dest.mkdir(parents=True)
        for nombre in sorted(en_placa):
            datos = pl.bajar(nombre)
            if suma(datos) != pl.suma(nombre):
                raise RuntimeError(f"respaldo de {nombre} inconsistente")
            (dest / nombre).write_bytes(datos)
        print(f"Respaldo: {dest.relative_to(BASE)} ({len(en_placa)} archivos)")

    # 3. credentials primero (pines seguros), init.lua al final
    orden = [PRIMERO] + sorted(n for n in locales if n not in (PRIMERO, ENTRADA)) + [ENTRADA]
    for nombre in orden:
        datos = locales[nombre].read_bytes()
        destino = "init_off.lua" if nombre == ENTRADA else nombre
        if destino in en_placa and pl.suma(destino) == suma(datos):
            print(f"  =  {nombre}")
        else:
            pl.subir(nombre, datos)
            print(f"  ok {nombre}")
        if nombre == PRIMERO:
            pl.cmd(f'dofile("{PRIMERO}")')
        if nombre == ENTRADA and not pl.existe(ENTRADA):
            pl.cmd(f'file.rename("init_off.lua","{ENTRADA}")')
    pl.cmd('file.remove("init_off.lua")')
    if not pl.existe(ENTRADA):
        raise RuntimeError("init.lua no quedó en la placa")

    # 4. reiniciar y revisar el arranque
    log = pl.reiniciar(espera=20)
    errores = [l for l in log.splitlines() if re.search(r"lua error|stack traceback|panic|cannot open", l, re.I)]
    print("Arranque:", "OK" if not errores else "con errores")
    for l in errores:
        print("  ", l.strip())
    sys.exit(1 if errores else 0)


if __name__ == "__main__":
    main()
