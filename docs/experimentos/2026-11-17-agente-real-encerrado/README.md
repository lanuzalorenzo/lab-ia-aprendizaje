# El agente real dentro de la política de contención

**Qué probé:** si el agente que uso a diario arranca dentro del contenedor encerrado, qué necesita para funcionar y qué envía antes de tocar un solo archivo del repositorio.

**Qué salió:** arranca y completa una vuelta entera dentro del encierro: recibe la orden, pide leer un archivo y responde. En la primera pasada envía dos peticiones de 2.133 y 24.518 bytes sin leer nada; cuando el modelo pide el archivo, la tercera, de 24.796 bytes, lleva el contenido: el marcador del fixture aparece dentro del cuerpo. Sin salida de red no llega a nada: pide `models.opencode.ai`, no resuelve y se queda hasta el tope de tiempo.

**Qué no está medido:** el comportamiento con un proveedor real de modelos, el modo interactivo completo y el coste de una tarea larga.

> **Estado:** Validado el uso (2026-11-17), con los artefactos de [`resultados/`](resultados/). Se ejecutó el agente real en el encierro y se observó qué envía; no hay llamada a ningún proveedor externo ni medición de coste.

Antes de encerrar al agente conviene saber qué necesita. Si al cerrar la red deja de arrancar, el encierro no es una política: es una pared. Y si al abrirla mínimamente manda veinticuatro kilobytes de instrucciones antes de leer nada, eso también es parte de la frontera de datos, aunque no sea un archivo del repositorio.

## 1. Metadatos

| Campo | Valor |
|---|---|
| **Fecha** | 2026-11-17 |
| **Tipo** | Ejecución del agente real contra un modelo falso local |
| **Agente** | `opencode v2.2.6`, binario de 258.824.368 bytes montado en solo lectura |
| **Imagen** | `debian:12-slim` con `ca-certificates`; imagen `agente-real:local` `sha256:879f911f…f7bdc` |
| **Destino** | Extremo local compatible con OpenAI que registra lo que recibe |
| **Entorno** | Ubuntu 26.04.1 LTS, Linux 7.0.0-42-generic, Docker 29.1.3 |
| **Artefactos** | `resultados/00` a `resultados/05` |
| **Estado** | Validado el uso |

## 2. La política aplicada

| Control | Valor |
|---|---|
| Usuario y capacidades | `--user 1000:1000`, `--cap-drop ALL`, `no-new-privileges` |
| Raíz | De solo lectura |
| Repositorio | `/repo` en `ro`, con un fixture y un marcador |
| Hogar del agente | `tmpfs` en `/home/agente`, escribible |
| Temporal | `tmpfs` en `/tmp` con `exec` (ver H-2) |
| Red | Interna sin salida; solo el proxy |
| Destinos permitidos | `eco:9000`, `opencode.ai:443`, `models.opencode.ai:443`, `registry.npmjs.org:443` |
| Recursos | 1 GB de memoria, 1 CPU, 256 procesos |

El binario se monta, no se copia: la imagen no lo contiene y el agente se actualiza en el host.

## 3. Qué se ejecutó

```bash
cd docs/experimentos/2026-11-17-agente-real-encerrado
./lanzar.sh
```

Tres fases sobre la misma política: sin red, con el temporal sin ejecución y con proxy más destino local. El fixture se crea en el directorio temporal de la pasada, y al terminar se borran contenedores, redes y el crudo de las peticiones.

Salida literal, recortada:

```text
imagen=sha256:879f911f8dc4f9252f987be35853c67ec1523c715dce6b51850cbb44113f7bdc
agente=opencode v2.2.6
== Fase 1: sin red ==
codigo-salida=124
message="Failed to fetch models.dev" cause="Cause([Fail(HttpClientError: Transport error (GET https://models.opencode.ai/experimental/v2.0/api.json?type=chat,decision,image) (cause: TypeError: getaddrinfo EAI_AGAIN models.opencode.ai))])" http.span=1346 role=server
== Fase 2: temporal sin ejecución ==
codigo-salida=1
Failed to initialize OpenTUI render library: Failed to open library \
== Fase 3 ==
ECO #1 POST /v1/chat/completions ECO cuerpo=2133B modelo=eco roles=system,user herramientas=0 marcador=no
ECO #2 POST /v1/chat/completions ECO cuerpo=24518B modelo=eco roles=system,user herramientas=13 marcador=no
ECO #3 POST /v1/chat/completions ECO cuerpo=24796B modelo=eco roles=system,user,assistant,tool herramientas=13 marcador=si
```

## 4. Resultados

| Pregunta | Observado |
|---|---|
| ¿Arranca en el encierro? | Sí: `opencode v2.2.6` con raíz de solo lectura y sin privilegios |
| ¿Completa una vuelta? | Sí: orden, lectura de un archivo y respuesta |
| ¿Necesita un temporal ejecutable? | En modo interactivo sí; en `run` no |
| ¿Funciona sin red? | No: no resuelve `models.opencode.ai` y se queda hasta el tope de 40 s |
| ¿Qué pide antes de trabajar? | El catálogo de modelos en `models.opencode.ai` |
| ¿Cuánto envía antes de leer un archivo? | Dos peticiones: 2.133 B y 24.518 B |
| ¿Qué lleva ese cuerpo? | Prompt de sistema, entorno, 13 esquemas de herramientas y el mensaje del usuario |
| ¿Sale el contenido del repositorio? | Sí, en la tercera petición (24.796 B): el marcador aparece tras la lectura |
| ¿Se puede inyectar la credencial desde el proxy? | No con TLS: el proxy solo túnela, no abre el contenido |

## 5. Hallazgos y límites

- **H-1:** el encierro no impide trabajar. La raíz de solo lectura, el usuario sin privilegios y el repositorio en `ro` no estorban; el agente necesita un hogar escribible y un temporal.
- **H-2:** el modo interactivo extrae una biblioteca a `/tmp` y la mapea; con el temporal en `noexec` no arranca. Es una concesión real de la política: o se permite ejecutar ahí o se usa el modo sin interfaz.
- **H-3:** sin red, el agente no falla limpiamente. Se queda esperando hasta agotar el tiempo, después de un intento que no llega a dar error visible al usuario.
- **H-4:** antes de leer nada del repositorio, la petición ya pesa 24,5 kB y contiene su prompt de sistema y trece esquemas de herramientas. Eso también cruza la frontera y casi nunca se cuenta.
- **H-5:** cuando el modelo pide un archivo, su contenido viaja en la petición siguiente: 24.796 B con el marcador dentro. El repositorio en `ro` protege la escritura, no la lectura; lo que se lee, sale.
- **H-6:** con TLS por túnel, el proxy decide a dónde se conecta, no qué se envía. La credencial que no entra en el sandbox no puede inyectarse en una llamada cifrada sin interceptar el certificado; haría falta un intermediario propio o un servicio local que firme la llamada.
- **H-7:** el crudo de las peticiones no se publica porque contiene el prompt de sistema del agente. El artefacto guarda el recuento, el tamaño y la presencia del marcador, no el texto.

## 6. Qué no demuestra

- No usa un proveedor real: no hay clave ni llamada a un servicio externo de modelos.
- No cubre el modo interactivo completo, solo su arranque.
- No mide el coste en tokens ni el tiempo de una tarea larga.
- No compara con el agente corriendo fuera del contenedor.
- El proxy no conserva el streaming de la respuesta: la lee entera antes de reenviarla. No afecta a lo medido, pero cambia el comportamiento frente a un túnel.
- Si el cliente manda el cuerpo sin `Content-Length`, el proxy lo descarta sin avisar.

## 7. Cómo reproducir

```bash
cd docs/experimentos/2026-11-17-agente-real-encerrado
./lanzar.sh
```

Requisitos: Docker, el binario del agente en `~/.opencode/bin/opencode` (o `BINARIO_AGENTE`) y acceso a la red para construir la imagen. El fixture y el marcador `marcador-señuelo-7f3a` se generan en cada pasada y no se versionan.

## 8. Relación con la hoja de ruta

Esto alimenta el experimento de frontera de datos de [`hoja-de-ruta-seguridad-asistentes.md`](../../referencia/hoja-de-ruta-seguridad-asistentes.md): dice qué destinos pide el agente, qué manda antes de leer nada y qué manda cuando lee un archivo del repositorio.
