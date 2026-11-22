# Simulacro de continuidad: cliente sin red contra pesos en disco

Esto es la caja de fusibles del laboratorio: si un día falta el proveedor remoto, lo que esté en disco es lo único que queda. El simulacro comprueba si un cliente sin Internet llega a un modelo ya descargado y termina una tarea, y de paso mira qué falta cuando el inventario se hace de verdad. Se ejecutó sobre una red Docker interna; el servidor del montaje original no estaba disponible y eso se cuenta, no se tapa.

**Qué probé:** si un cliente sin salida a Internet puede usar un modelo cuyos pesos ya están en disco, y qué queda de verdad en disco el día que se necesita.

**Qué salió:** un servidor y un cliente en una red sin salida a Internet, con `qwen2.5:3b` respondiendo por la API local: dos tareas en 25 segundos y OpenCode arrancando contra él y completando una tarea en 124. El `sha256` del blob de pesos coincide con el nombre del fichero, y la copia de los pesos restaurada en un volumen limpio devuelve el mismo digest de blob y responde. Antes de eso, el paso que la guía pone primero falló: el servidor del montaje no estaba en la red y en el cliente no había pesos. Lo único irrecuperable sin red era justo lo que faltaba.

**Qué no está medido:** el inventario del servidor original, la velocidad con GPU y la copia fuera de la máquina; la restauración se probó en el mismo equipo.

> **Estado:** Validado (2026-11-22). Ejecutado sobre un montaje reproducido —servidor y cliente en una red interna sin salida a Internet—, con la salida en [`salida-simulacro.txt`](salida-simulacro.txt): corte, inventario, dos tareas, cliente y restauración de los pesos. No valida el servidor del montaje original, que no era alcanzable; ese inventario queda como ítem aparte y fuera de este artefacto.

---

## 1. Metadatos

| Campo | Valor |
|-------|-------|
| **Fecha** | 2026-11-22 |
| **Tipo** | Ejecución con modelo |
| **Modelo(s)** | `qwen2.5:3b`; manifiesto `357c53fb659c5076de1d65ccb0b397446227b71a42be9d1603d46168015c9e4b`; blob `5ee4f07cdb9beadbbb293e85803c569b01bd37ed059d2715faa7bb405f31caa6` |
| **Script/Versión** | [`scripts/simulacro/continuidad-local.sh`](../../../scripts/simulacro/continuidad-local.sh); sin commit fijado en la ejecución: el guion entra en el commit de esta rama |
| **Entorno** | i7-12700H (20 hilos), 30 GiB de RAM, RTX 3050 Laptop de 4096 MiB (no usada: el contenedor corre en CPU), Ubuntu 26.04.1, kernel 7.0.0-42, Docker 29.1.3, `ollama/ollama:0.12.10` |
| **Estado** | Validado |

## 2. Qué se ha ejecutado

El simulacro tiene tres partes y la primera no salió como estaba previsto, que es justo el dato que la guía pedía fijar antes que ningún otro.

```bash
# 1. Qué queda del montaje anterior, desde el equipo cliente
getent hosts ollama.lab.local   # sin resultado
command -v ollama               # sin binario
ls /usr/share/ollama            # no existe
```

El servidor del montaje no está en la red desde la que se hizo el simulacro —un hotspot aislado de la red del laboratorio— y en el cliente no hay runtime ni pesos. El inventario del servidor no se pudo hacer: eso queda pendiente y no se da por bueno.

La segunda parte monta un sustituto medible: una red Docker interna, sin puerta de enlace hacia Internet, con el servidor a un lado y el cliente al otro. La red del equipo no se toca.

```bash
./scripts/simulacro/continuidad-local.sh preparar    # imagen y pesos, con red
./scripts/simulacro/continuidad-local.sh simulacro   # servidor, corte, inventario, tareas y cliente
./scripts/simulacro/continuidad-local.sh restaurar   # copia de pesos, restauración y prueba
```

Salida completa: [`salida-simulacro.txt`](salida-simulacro.txt). Es la salida del guion sin los códigos de color y de cursor que emite el terminal; no se ha cambiado ninguna cifra.

Artefactos generados:

- `salida-simulacro.txt` — salida del guion, sin secuencias de control.
- Volumen `ollama-simulacro` — pesos del servidor; `ollama-restaurado` — la copia restaurada.
- `/tmp/opencode/simulacro/ollama-models-2026-11-22.tar.gz` — copia de los pesos en el mismo equipo, no fuera de él.

## 3. Qué mide y qué no

| Pregunta | Estado |
|----------|--------|
| ¿Se puede inferir sin salida a Internet si los pesos están en disco? | Validado: la red interna no tiene puerta de enlace y la API respondió |
| ¿El cliente completa una tarea real sin red? | Validado: OpenCode 2.3.2 arranca y la completa, con imprecisiones en la respuesta (H-4) |
| ¿Se puede restaurar una copia de los pesos y volver a inferir? | Validado en el mismo equipo: volumen limpio, mismo digest de blob, respuesta en 2 s |
| ¿Qué conserva el servidor del montaje original? | Fuera de este artefacto: no era alcanzable; queda como ítem aparte |
| ¿Qué velocidad da con GPU? | No medido: el contenedor corre en CPU |

## 4. Resultados

| Medida | Valor |
|---|---|
| Runtime | Ollama 0.12.10; imagen `ollama/ollama@sha256:e8c3d1f6ad16323bc40dc63eff0701d4fc32113f75a86b54b3e836eef8290de6` |
| Red del simulacro | `lab-drill`, bridge interna: sin puerta de enlace hacia Internet |
| Interfaces del servidor | `eth0` y `lo` |
| Salida a Internet | ninguna: la resolución de `example.com` agota 5 s |
| API local | `http://ollama-servidor:11434/api/tags` responde con el modelo cargado |
| Modelo | `qwen2.5:3b`, Q4_K_M, 3.1B, 1.929.912.432 bytes |
| Blob de pesos | `5ee4f07c…`, 1.929.903.008 bytes, `sha256` verificado contra el nombre del fichero: coincide |
| Almacén | 1,8 GiB |
| T1: explicar `tar -czf` | 8 s; respuesta correcta |
| T2: leer `run_agent.sh` | 17 s; resumen correcto en esta pasada |
| Cliente: OpenCode 2.3.2 (242 MB) contra la API local, sin red | arranca y completa una tarea real en 124 s; la respuesta inventa código que no está en el script |
| Copia de los pesos | `ollama-models-2026-11-22.tar.gz`, 1,8 GB, `sha256 4baefd1d…` |
| Restauración en volumen limpio | mismo digest de blob `5ee4f07c…`; una inferencia en 2 s |
| Manifiesto frente al registrado el 22/10 | `357c53fb659c` en los dos: la etiqueta sigue apuntando a los mismos pesos |

## 5. Inventario

| Elemento | Ruta | Tamaño real | Digest o versión | Fecha |
|---|---|---|---|---|
| Runtime de Ollama | imagen `ollama/ollama:0.12.10` | 5,68 GB | `0.12.10`; `sha256:e8c3d1f6…` | 2026-11-22 |
| Modelo operativo (`qwen2.5-coder:7b`) | no descargado | 0 | — | — |
| Modelo de reserva (`qwen2.5:3b`) | volumen `ollama-simulacro` | 1,93 GB | `5ee4f07cdb9b…` | 2026-11-22 |
| Cliente de prueba | imagen `curlimages/curl:8.11.1` | 32,3 MB | `8.11.1` | 2026-11-22 |
| Cliente de trabajo | OpenCode 2.3.2, binario montado en el contenedor | 242 MB | `2.3.2` | 2026-11-22 |
| Copia local de los pesos | `/tmp/opencode/simulacro/ollama-models-2026-11-22.tar.gz` | 1,8 GB | `4baefd1d…` | 2026-11-22 |
| Copia fuera de la máquina | — | ninguna | — | — |

La imagen de Ollama pesa 5,68 GB, pero no es comparable con la estimación de 1–2 GB de la guía: la imagen trae la base y las librerías CUDA y ROCm. Un runtime instalado en el sistema no se midió aquí, porque esta máquina no tiene instalación de Ollama. Y el modelo operativo, el que de verdad hace falta, no está descargado en ningún sitio.

## 6. Hallazgos / Limitaciones

- **H-1**: el punto único de fallo que la guía describe es real y estaba abierto. Desde este equipo no se llega al servidor y no hay pesos en local: sin red, hoy no había IA de reserva. Lo que no se descargó, no se recupera el día del corte.
- **H-2**: `ollama.lab.local` no resuelve fuera de la red del laboratorio. Un nombre de esa red no sirve como plan de continuidad si el equipo sale de ella.
- **H-3**: el corte por `nftables` de la guía aísla el equipo entero y, en una sesión como esta, corta también el canal de trabajo. Se sustituyó por una red Docker interna, sin puerta de enlace: el corte es real, el cliente está dentro y el host no se toca. No basta con que el cliente no salga: si el servidor conserva la salida, la prueba mide otra cosa.
- **H-4**: la misma tarea no da siempre lo mismo. En la primera pasada el modelo dijo que `run_agent.sh` arranca el servicio —falso—; en las dos siguientes acertó el resumen, y por el cliente añadió código que no existe en el script. Completa la tarea y se equivoca; sirve para trabajar, no para dar por bueno lo que dice.
- **H-5**: el cliente que uso a diario, OpenCode 2.3.2, arranca sin Internet y completa una tarea contra la API local. La guía lo daba por no comprobado desde el principio. Los 124 s incluyen el arranque del cliente: no se separó ese tiempo del de la inferencia.
- **H-6**: restaurar los pesos no restaura el runtime. La copia que se probó lleva solo el almacén de modelos; el runtime se recupera con la imagen por digest o con una copia del binario que aquí no se hizo.

## 7. Qué no demuestra

- No valida el servidor del montaje: no era alcanzable y su inventario es otro ítem.
- No mide velocidad ni calidad frente al proveedor remoto; solo que la inferencia ocurre sin red y que una tarea se completa.
- No prueba el perfil de Continue del paso 4: el cliente probado fue OpenCode.
- No prueba que la copia sobreviva a la pérdida del equipo: se restauró en el mismo disco, no desde un medio externo.
- No mide la GPU: el contenedor corre en CPU.

## 8. Siguiente paso

Inventariar el servidor del montaje cuando vuelva a la red del laboratorio: `ollama list`, `FROM` del manifiesto y `du -sh` de los modelos. Lo probado aquí es el corte, el inventario de un montaje reproducido, las tareas, el cliente y la restauración en el mismo equipo; quedan fuera el servidor original, la copia externa, la GPU y el perfil de Continue.
