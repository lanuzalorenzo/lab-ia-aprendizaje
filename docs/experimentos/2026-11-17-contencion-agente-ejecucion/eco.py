"""Servicio de destino que devuelve las cabeceras que recibe.

Sirve para comprobar qué llega al otro lado: si la credencial la pone el
proxy, aquí aparece y dentro del contenedor del agente no.
"""

import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, formato, *args):
        pass

    def do_GET(self):
        cuerpo = json.dumps(
            {"ruta": self.path, "cabeceras": dict(self.headers.items())},
            ensure_ascii=False,
        ).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(cuerpo)))
        self.end_headers()
        self.wfile.write(cuerpo)


if __name__ == "__main__":
    puerto = int(sys.argv[1]) if len(sys.argv) > 1 else 9000
    ThreadingHTTPServer(("0.0.0.0", puerto), Handler).serve_forever()
