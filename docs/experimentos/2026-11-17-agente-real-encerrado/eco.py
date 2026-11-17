"""Destino local compatible con OpenAI que apunta lo que el agente le envía.

No publica el cuerpo: lo guarda en crudo en el directorio de registro y
escribe una línea con el resumen (modelo, roles, herramientas, tamaño y si
aparece el marcador). En modo `herramienta`, la primera respuesta pide leer
un archivo del repositorio para provocar una segunda petición con su
contenido.

Variables de entorno:
  MARCADOR   cadena que se busca en cada cuerpo
  REGISTRO   directorio donde se guarda el cuerpo en crudo
  MODO       `texto` (por defecto) o `herramienta`
"""

import json
import os
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MARCADOR = os.environ.get("MARCADOR", "marcador-señuelo-7f3a")
REGISTRO = os.environ.get("REGISTRO", "/registro")
MODO = os.environ.get("MODO", "texto")
RUTA = os.environ.get("RUTA", "/repo/datos.txt")

contador = {"n": 0}
candado = threading.Lock()


def resumen(cuerpo: bytes) -> str:
    texto = cuerpo.decode("utf-8", "replace")
    datos = {}
    try:
        datos = json.loads(texto)
    except json.JSONDecodeError:
        pass
    roles = [m.get("role", "?") for m in datos.get("messages", [])] if datos else []
    herramientas = len(datos.get("tools", [])) if datos else 0
    return (
        f"ECO cuerpo={len(texto)}B modelo={datos.get('model', '-')} "
        f"roles={','.join(roles) or '-'} herramientas={herramientas} "
        f"marcador={'si' if MARCADOR in texto else 'no'}"
    )


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, formato, *args):
        pass

    def _responder(self):
        largo = int(self.headers.get("Content-Length", "0") or 0)
        cuerpo = self.rfile.read(largo) if largo else b""
        with candado:
            if self.command == "POST":
                contador["n"] += 1
            numero = contador["n"]
        with open(os.path.join(REGISTRO, f"crudo-{numero}.json"), "wb") as fichero:
            fichero.write(cuerpo)
        print(f"ECO #{numero} {self.command} {self.path} {resumen(cuerpo)}", flush=True)

        if self.command != "POST":
            respuesta = {
                "object": "list",
                "data": [{"id": "eco", "object": "model", "owned_by": "local"}],
            }
            datos = json.dumps(respuesta).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(datos)))
            self.end_headers()
            self.wfile.write(datos)
            return

        pide_stream = b'"stream": true' in cuerpo.replace(b'"stream":true', b'"stream": true')
        try:
            datos_peticion = json.loads(cuerpo.decode("utf-8", "replace"))
        except json.JSONDecodeError:
            datos_peticion = {}
        hay_herramientas = bool(datos_peticion.get("tools"))
        ya_leyo = any(m.get("role") == "tool" for m in datos_peticion.get("messages", []))
        if MODO == "herramienta" and hay_herramientas and not ya_leyo:
            delta = {
                "role": "assistant",
                "tool_calls": [
                    {
                        "index": 0,
                        "id": "llamada-1",
                        "type": "function",
                        "function": {
                            "name": "read",
                            "arguments": json.dumps({"path": RUTA}),
                        },
                    }
                ],
            }
            fin = "tool_calls"
        else:
            delta = {"role": "assistant", "content": "listo"}
            fin = "stop"

        if not pide_stream:
            datos = json.dumps(
                {
                    "id": "eco-1",
                    "object": "chat.completion",
                    "created": 0,
                    "model": "eco",
                    "choices": [{"index": 0, "message": delta, "finish_reason": fin}],
                    "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2},
                }
            ).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(datos)))
            self.end_headers()
            self.wfile.write(datos)
            return

        trozos = [
            {
                "id": "eco-1",
                "object": "chat.completion.chunk",
                "created": 0,
                "model": "eco",
                "choices": [{"index": 0, "delta": delta, "finish_reason": None}],
            },
            {
                "id": "eco-1",
                "object": "chat.completion.chunk",
                "created": 0,
                "model": "eco",
                "choices": [{"index": 0, "delta": {}, "finish_reason": fin}],
            },
        ]
        cuerpo_sse = "".join(f"data: {json.dumps(t)}\n\n" for t in trozos) + "data: [DONE]\n\n"
        datos = cuerpo_sse.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Content-Length", str(len(datos)))
        self.end_headers()
        self.wfile.write(datos)

    do_GET = _responder
    do_POST = _responder


if __name__ == "__main__":
    puerto = int(sys.argv[1]) if len(sys.argv) > 1 else 9000
    os.makedirs(REGISTRO, exist_ok=True)
    ThreadingHTTPServer(("0.0.0.0", puerto), Handler).serve_forever()
