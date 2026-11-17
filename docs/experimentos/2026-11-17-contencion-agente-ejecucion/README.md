# Contención de un agente que ejecuta comandos

**Qué probé:** si un agente al que se le da shell puede quedar encerrado en un contenedor con la red cerrada, el disco de solo lectura y las credenciales fuera de su alcance, y qué se rompe al intentarlo.

**Qué salió:** las 19 comprobaciones se comportan como se espera en este equipo. El agente arranca con `uid=1000`, sin capacidades, sin resolución externa y sin ruta a Internet; la única salida es un proxy con lista, y la credencial la pone el proxy desde un fichero con permisos 600 que solo monta él. El tope de memoria mata el proceso con código 137 y el motor lo marca como `OOMKilled`. Con tope de 32 procesos, el shell abortó en el intento 31.

**Qué no está medido:** el escape por fallo del kernel, porque el núcleo sigue siendo el del host; el comportamiento con el agente real dentro y no solo con comandos equivalentes; el perfil seccomp ajustado; y el coste con una imagen de trabajo en vez de una mínima.

> **Estado:** Validado el uso del mecanismo en este equipo el 2026-11-17.
> **Evidencia:** [resultados de la pasada](resultados/01-bateria.txt) y el resto de `resultados/00` a `resultados/09`, con [el guion de la prueba](pruebas.sh). Se ejecutó y se observó; no hay reproducibilidad declarada en otro equipo. No valida el aislamiento frente a un fallo del kernel ni sustituye a la prueba de permisos del agente real.

Con el agente ejecutando órdenes en la misma máquina donde viven los repositorios, un error de criterio del modelo o una instrucción escondida en un archivo tienen el mismo alcance que si los escribiera yo. Encerrarlo no lo hace más listo: reduce lo que puede tocar cuando se equivoca. Es la diferencia entre un taller con las herramientas guardadas y uno con la puerta abierta a la calle.

## 1. Metadatos

| Campo | Valor |
|---|---|
| **Fecha** | 2026-11-17 |
| **Tipo** | Ejecución de mecanismo de aislamiento, sin modelo |
| **Imagen del agente** | `contencion-agente:local`, `sha256:2a26a4c2…c71b`, sobre `alpine:3.20` con `curl` |
| **Motor** | Docker 29.1.3, driver `overlayfs`, cgroup v2 |
| **Entorno** | Ubuntu 26.04.1 LTS, Linux 7.0.0-42-generic, 20 núcleos, 30 GB de RAM |
| **Artefactos** | `resultados/00` a `resultados/09`, de la pasada publicada |
| **Estado** | Validado el uso |

## 2. Diseño del encierro

| Control | Cómo se aplica |
|---|---|
| Usuario | `--user 1000:1000`, sin `sudo` ni privilegios |
| Capacidades | `--cap-drop ALL` y `--security-opt no-new-privileges` |
| Sistema de archivos | `--read-only`, `/tmp` en `tmpfs` de 64 MB sin ejecución |
| Repositorio | La raíz del repositorio montada de solo lectura en `/repo`; nada más del host |
| Red | Red interna sin puerta de salida; solo se llega al proxy |
| Salida | Proxy propio con lista de `host:puerto` y registro de cada petición |
| Credencial | Fichero con permisos 600 montado únicamente en el proxy; se añade como `Authorization` al reenviar |
| Recursos | `--memory`, `--pids-limit` y `--cpus` |
| Socket de Docker | No se monta: el agente no puede crear contenedores |
| Batería | Se pasa por la entrada estándar con `sh -s`; no se monta ningún guion |

La cadena es la misma que se usaría con el agente real: cambiar el comando de entrada por el del agente y dejar el resto igual. La credencial no se pasa como variable de entorno a propósito: una variable de contenedor queda visible en `docker inspect` y en el entorno del proceso. Va en un fichero con permisos 600 que solo monta el proxy.

## 3. Qué se ejecutó

```bash
cd docs/experimentos/2026-11-17-contencion-agente-ejecucion
./lanzar.sh
```

El script construye la imagen, crea dos redes (una interna sin salida y otra con ella), levanta un servicio de destino y el proxy, ejecuta la batería dentro del contenedor y recoge los resultados en `resultados/`. Cada pasada borra los `.txt` anteriores y deja solo su propia salida. Al terminar, o si algo falla, borra lo que creó por etiqueta.

Salida literal, recortada en el centro con `…`:

```text
CHECK capacidades-y-seccomp        … observado=CapEff=0000000000000000 NoNewPrivs=1 Seccomp=2 veredicto=ok
CHECK salida-por-ip                … observado=curl: (7) Failed to connect to 1.1.1.1 port 443 after 0 ms: Could not connect to server veredicto=ok
CHECK proxy-host-permitido         … observado=codigo=200 {"ruta": "/", "cabeceras": {"Accept-Encoding": "identity", "User-Agent": "curl/8.14.1", "Accept": "*/*", "Host": "eco:9000", "Authorization": "Bearer token-de-prueba-no-es-un-secreto"}} veredicto=ok
CHECK proxy-connect-denegado       … observado=curl: (56) CONNECT tunnel failed, response 403 veredicto=ok
FIN DE LA BATERIA fallos=0
```

Artefactos generados:

- `resultados/00-preparacion.txt` — imagen, identificador y arranque del proxy.
- `resultados/01-bateria.txt` — las 19 comprobaciones con lo observado en cada una.
- `resultados/02-memoria.txt` — 200 MB pedidos con tope de 128 MB: código 137 y `oom-killed=true`.
- `resultados/03-persistencia.txt` — la huella escrita desaparece al volver a entrar.
- `resultados/04-procesos.txt` — 200 peticiones, 31 intentos, tope 32, código 2.
- `resultados/05-pausa.txt` — el estado en memoria sobrevive a pausar y reanudar.
- `resultados/06-arranque.txt` — cinco arranques, entre 355 y 368 ms.
- `resultados/07-limites.txt` — configuración efectiva que aplica el motor.
- `resultados/08-proxy.txt` — registro del proxy: 200 al permitido, 403 al resto.
- `resultados/09-token.txt` — el fichero de la credencial montado a propósito en un contenedor: legible con `uid=1000` y denegado con `uid=1500`.

El token que aparece en los artefactos es ficticio (`token-de-prueba-no-es-un-secreto`) y está ahí a propósito: demuestra qué llega al destino.

## 4. Resultados

| Comprobación | Observado |
|---|---|
| Usuario sin root | `uid=1000` |
| Capacidades y seccomp | `CapEff=0`, `NoNewPrivs=1`, `Seccomp=2` |
| Lectura de `/etc/shadow` | `Permission denied` |
| Escritura en la raíz | `Read-only file system` |
| Escritura en `/tmp` | Permitida |
| Montajes del host | Ninguno bajo `/home`; además `/tmp`, `/repo` y lo que Docker pone por defecto (`/proc`, `/sys`, `/dev`, `/etc/hosts`…) |
| Repositorio | Visible en `/repo` con opciones `ro,relatime` |
| Escritura en el repositorio | `Read-only file system` |
| Variable del host exportada | Ausente dentro |
| Variable pasada con `-e` | Visible dentro (testigo) |
| Credencial en el entorno | Ausente (comprobación de regresión) |
| Fichero de la credencial, mismo uid | Legible (código 0) |
| Fichero de la credencial, otro uid | `Permission denied` (código 1) |
| Socket de Docker | No existe |
| Procesos visibles | 5 líneas, PID 1 es el shell |
| Salida directa por nombre | Sin resolución |
| Resolución DNS externa | Sin respuesta |
| Salida directa por IP | No conecta a `1.1.1.1:443` |
| Proxy a host permitido | 200 y `Authorization` inyectada, visible en el destino |
| Proxy a host no permitido | 403 |
| Túnel `CONNECT` no permitido | 403 |
| Memoria, 200 MB con tope 128 MB | Código 137, `OOMKilled` |
| Procesos, tope 32 | Abortó en el intento 31 |
| Persistencia tras salir | El archivo ya no existe |
| Pausa y reanudación | El contenido en memoria sigue ahí |
| Arranque | 355–368 ms, imagen ya presente |

## 5. Hallazgos y límites

- **H-1 (instrumento):** las pasadas anteriores a esta tenían defectos propios: el proxy arrancaba sobre una imagen sin `python3`, la prueba de procesos mataba el shell y el directorio de resultados acumulaba ficheros de numeraciones viejas. Se corrigieron; la carpeta `resultados/` contiene solo la pasada publicada y el script la vacía al empezar.
- **H-2 (instrumento):** cuando el proxy rechaza un `CONNECT`, `curl` devuelve 56 y no rellena `%{http_code}`, que queda a cero. La comprobación se hace sobre el mensaje y sobre el registro del proxy, no sobre ese código.
- **H-3:** Docker no propaga una variable del host si no se pasa con `-e`, y el testigo de la misma pasada lo confirma: la exportada en el host no aparece dentro y la pasada con `-e` sí. Una variable de contenedor, en cambio, queda en `docker inspect`: por eso la credencial va en un fichero montado.
- **H-4 (alcance):** el mecanismo contiene, no juzga. Una instrucción inyectada desde el repositorio puede hacer que el agente ejecute algo equivocado dentro del contenedor con total normalidad. Eso se controla con permisos y revisión, no con esto.
- **H-5 (credencial):** el agente no puede leer el token, pero sí puede usarlo contra el host permitido. Es una capacidad delegada, no una identidad propia; si el proxy permite un servicio con efectos, el agente puede invocarlo.
- **H-6 (límite real):** el núcleo es el del host. Un fallo del kernel que permita escapar del contenedor no queda cubierto. Una microVM lo cambiaría; aquí no se probó, aunque el equipo expone `/dev/kvm`.
- **H-7 (imagen):** la imagen usada tiene shell y `curl`. Un agente real trae más herramientas, más superficie y más consumo; no se midió con esa carga.
- **H-8 (tópicos):** el tope de procesos no avisa: el shell muere con `can't fork` y las peticiones restantes ni se intentan. Un agente real puede quedarse a medias sin mensaje claro.
- **H-9 (identidad):** los permisos de fichero no separan nada si el uid coincide. En este equipo el usuario del host es 1000 y el contenedor corre como 1000, así que un fichero 600 montado dentro se lee sin más; con `uid=1500` la lectura se deniega. Por eso la credencial no se monta en el sandbox: se queda en el proxy. Montarla «por comodidad» habría dejado el token al alcance del agente.

## 6. Qué no demuestra

- No demuestra que el agente real se comporte igual dentro: no se ejecutó el cliente del agente, solo comandos equivalentes.
- No hay perfil seccomp propio ni *user namespace remapping*: se usa lo que aplica Docker por defecto.
- No hay microVM, ni *checkpoint* a disco, ni puerta de entrada: la pausa conserva memoria, no permite guardar y reanudar en otra máquina.
- No hay inspección de TLS: la lista del proxy se aplica al nombre del destino, no al contenido de la conexión.
- No mide el coste de tener el agente trabajando, solo el arranque del contenedor.
- No cubre el escape por fallo del kernel ni la inyección de instrucciones dentro del propio contenedor.

## 7. Cómo reproducir

```bash
cd docs/experimentos/2026-11-17-contencion-agente-ejecucion
./lanzar.sh
```

Requisitos: Docker con el usuario en el grupo `docker` y acceso a la red para construir la imagen y descargar la de Python. Se ejecuta dentro del clon del repositorio, porque monta su raíz en `/repo`. Los contenedores y las redes llevan el PID de la pasada en el nombre y una segunda etiqueta `pasada`, así que el `trap` borra solo lo suyo. Para lanzar dos pasadas a la vez, pásale una carpeta de resultados distinta a cada una. Si el script se corta de golpe, esto deja el equipo como estaba:

```bash
docker rm -f $(docker ps -aq --filter label=experimento=contencion-agente)
docker network rm $(docker network ls -q --filter label=experimento=contencion-agente)
```

## 8. Relación con la hoja de ruta

Esto mide el mecanismo, no el alcance del agente: no hay modelo en la batería. El experimento de permisos de [`hoja-de-ruta-seguridad-asistentes.md`](../../referencia/hoja-de-ruta-seguridad-asistentes.md) sigue pendiente y necesita el entorno con modelo reproducible; lo medido aquí es la política que ese experimento aplicará después.
