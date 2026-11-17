"""Proxy de salida con lista de hosts permitidos y cabecera inyectada.

El agente no ve la credencial: la pone el proxy al reenviar la petición.
Variables de entorno:
  PERMITIDOS        lista separada por comas de host:puerto autorizados
  TOKEN_FICHERO     ruta a un fichero con el valor; se lee una vez al arrancar
"""

import http.client
import os
import select
import socket
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit

PERMITIDOS = {h.strip() for h in os.environ.get("PERMITIDOS", "").split(",") if h.strip()}

if os.environ.get("TOKEN_FICHERO"):
    with open(os.environ["TOKEN_FICHERO"], encoding="utf-8") as fichero:
        TOKEN = fichero.read().strip()
else:
    TOKEN = ""


def autorizado(hostpuerto: str) -> bool:
    return hostpuerto in PERMITIDOS


def separar(hostpuerto: str) -> tuple[str, int]:
    host, _, puerto = hostpuerto.rpartition(":")
    if not host:
        return hostpuerto, 80
    return host, int(puerto)


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, formato, *args):  # silencia el log por defecto
        pass

    def apuntar(self, metodo, hostpuerto, estado):
        print(f"PROXY {metodo} {hostpuerto} {estado}", flush=True)

    def do_CONNECT(self):
        hostpuerto = self.path
        if not autorizado(hostpuerto):
            self.apuntar("CONNECT", hostpuerto, 403)
            self.send_error(403, "host no permitido")
            return
        host, puerto = separar(hostpuerto)
        try:
            destino = socket.create_connection((host, puerto), timeout=10)
        except OSError as error:
            self.apuntar("CONNECT", hostpuerto, 502)
            self.send_error(502, str(error))
            return
        self.send_response(200, "Connection Established")
        self.end_headers()
        self.apuntar("CONNECT", hostpuerto, 200)
        self._tunel(destino)

    def _tunel(self, destino):
        origen = self.connection
        sockets = [origen, destino]
        try:
            while True:
                listos, _, _ = select.select(sockets, [], [], 30)
                if not listos:
                    return
                for s in listos:
                    datos = s.recv(65536)
                    if not datos:
                        return
                    (destino if s is origen else origen).sendall(datos)
        finally:
            destino.close()

    def do_GET(self):
        partes = urlsplit(self.path)
        hostpuerto = partes.netloc
        if not hostpuerto:
            self.apuntar("GET", self.path, 400)
            self.send_error(400, "se espera una URL absoluta")
            return
        if not autorizado(hostpuerto):
            self.apuntar("GET", hostpuerto, 403)
            self.send_error(403, "host no permitido")
            return
        host, puerto = separar(hostpuerto)
        cabeceras = {
            k: v
            for k, v in self.headers.items()
            if k.lower() not in ("proxy-connection", "connection", "authorization", "host")
        }
        cabeceras["Host"] = hostpuerto
        if TOKEN:
            cabeceras["Authorization"] = f"Bearer {TOKEN}"
        try:
            conexion = http.client.HTTPConnection(host, puerto, timeout=10)
            conexion.request("GET", partes.path or "/", headers=cabeceras)
            respuesta = conexion.getresponse()
            cuerpo = respuesta.read()
        except OSError as error:
            self.apuntar("GET", hostpuerto, 502)
            self.send_error(502, str(error))
            return
        self.send_response(respuesta.status)
        self.send_header("Content-Type", respuesta.getheader("Content-Type", "application/json"))
        self.send_header("Content-Length", str(len(cuerpo)))
        self.end_headers()
        self.wfile.write(cuerpo)
        self.apuntar("GET", hostpuerto, respuesta.status)


def main():
    puerto = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    print(f"PROXY escuchando en {puerto}; permitidos: {sorted(PERMITIDOS)}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", puerto), Handler).serve_forever()


if __name__ == "__main__":
    main()
