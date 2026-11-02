# Continuidad de la IA local: qué tener en disco antes de necesitarlo

> **Estado:** Runbook preparado — el montaje local se hizo (bitácora) y la inferencia se ejecutó con artefactos (evidencia), aunque en un entorno efímero; aquí se prepara su continuidad. Ninguna cifra de tamaño medida todavía en este repositorio. El simulacro está `Pendiente`.
>
> **Propósito:** que el laboratorio siga sirviendo si un día no hay proveedor remoto, sin improvisar ese mismo día.

Esto no es un plan para el fin del mundo. Es la caja de fusibles de casa: no se monta porque esperes un apagón, se monta porque cuesta poco y evita buscar una vela a oscuras. Aquí la vela es un modelo que ya está descargado y un cliente que ya sabe hablar con él.

## 0. De dónde parte esto

No se empieza de cero. Montar un agente local con Ollama ya lo hice, con registro y con decisión tomada después. Esta guía no repite ese trabajo: hereda lo que quedó y añade la parte que no se hizo, que es conservarlo para cuando la alternativa no esté.

| Hecho | Estado | Dónde está |
|---|---|---|
| Servidor Ubuntu sin escritorio y Ollama como servicio | Validado el montaje: se hizo en el servidor y consta en la bitácora, sin artefacto congelado. La guía de despliegue sigue en Runbook preparado | [Guía de despliegue](server-deployment-ubuntu-ollama.md), [bitácora, entradas 01–03](../referencia/bitacora-decisiones-aprendizaje.md) |
| Inferencia con `qwen2.5:3b` y entorno registrado | Validado que se ejecutó, con artefactos. Esa ejecución fue efímera —el script instaló y desinstaló—, así que no acredita el servidor. La página está en Parcial por los niveles N2 y N3 pendientes | [Evidencia del 22 de octubre](../evidencias/2026-10-22-robustez-ejecucion-v1/README.md#1-entorno) |
| `qwen2.5-coder:7b` con Continue a 16K | Parcial: probado por el autor, sin artefacto reproducible | [Bitácora, entrada 05](../referencia/bitacora-decisiones-aprendizaje.md#entrada-05-ajuste-de-la-ventana-de-contexto-portfolio-agent-con-continue) |
| Flujo local como opción diaria | Probado y dado por no óptimo: dejó de ser la opción por defecto porque montarlo y ajustar el rendimiento consumía demasiado tiempo y su capacidad no cubría el trabajo diario. El flujo diario pasó a OpenCode con proveedor remoto | [Local frente a cloud, §3–§4](local-vs-cloud.md), [bitácora, entrada 08](../referencia/bitacora-decisiones-aprendizaje.md#entrada-08-trabajo-diario-con-opencode-go-y-local-para-datos-restringidos) |

Dos matices que hacen que esta guía sea útil y no un capricho:

- **El descarte fue de tiempo y capacidad, no una medición.** Así está anotado: experiencia propia. No hay cifras que demuestren que el local era peor, solo que costaba más de lo que aportaba mientras hubiera alternativa.
- **Ese motivo solo se sostiene mientras exista la alternativa.** Con proveedor remoto disponible, el local es más caro en esfuerzo. Sin él, deja de competir con nada. Una decisión correcta en un escenario no tiene por qué serlo en el otro, y no hace falta declarar emergencia para notarlo.

## 1. Qué se rompe y qué no

Un corte de proveedor remoto no rompe la IA local. Rompe tres cosas, y solo una se puede arreglar después:

| Dependencia | Si falta el día del corte | Se arregla antes, no después |
|---|---|---|
| Pesos del modelo | No hay inferencia posible | Sí: están en disco o no están |
| Runtime (Ollama) — el programa que carga el modelo y responde a las peticiones | No hay servidor que cargue el modelo | Sí: la versión se guarda instalada y copiada |
| Cliente y su configuración | El editor arranca, pero no tiene a quién preguntar | Sí: un perfil local ya escrito y probado |
| Hardware | Nada cambia | No aplica |

La conclusión práctica es corta: **lo único irrecuperable sin red es lo que no se descargó**. El resto es configuración y ya está en el repositorio.

Esto ya empezó, y solo hay que recogerlo: el entorno —RTX 3050 Laptop de 4096 MiB, i7-12700H, 31 GB de RAM, Ollama 0.40.8— y el identificador del manifiesto de `qwen2.5:3b` están registrados desde la primera ejecución (§0). Al identificador le falta el `sha256` del blob, que se anota en el §3. Son los datos que costaría más trabajo reconstruir que leer.

## 2. Inventario: qué debe estar en disco

Cifras de orden de magnitud, no medidas en este repositorio. El simulacro (§7) las sustituye por las reales.

| Elemento | Por qué hace falta | Orden de magnitud | Copia |
|---|---|---|---|
| Runtime de Ollama, versión fijada | Sin runtime no se carga ningún peso, aunque esté en disco. Van juntos el binario y sus librerías | 1–2 GB si incluye librerías CUDA; el binario solo, decenas de MB | Servidor + disco externo |
| Pesos del modelo operativo (`qwen2.5-coder:7b`) | Es la pieza que no se puede reconstruir | ~4,7 GB en Q4 | Servidor + disco externo |
| Un modelo pequeño de reserva | Cabe entero en los 4 GB de VRAM (memoria de la tarjeta gráfica); `qwen2.5:3b` ya se ejecutó aquí | ~2 GB | Servidor + disco externo |
| `Modelfile` propio (el fichero con el que Ollama construye un modelo derivado) | Reconstruye el modelo sin volver a descargar la base | Kilobytes | Repositorio |
| Cliente fijado (OpenCode o la extensión de VS Code) | Sin cliente, el modelo existe pero no lo usas | Decenas de MB | Disco externo |
| Perfil local del cliente | Evita que el arranque dependa de una sesión remota | Kilobytes | Equipo cliente + disco externo; no se versiona |
| Conjunto de evaluación de `docs/evidencias/` | Permite comparar el local con lo ya medido, sin red. Reejecutarlo necesita además `scripts/robustez/` y Python | Megabytes | Repositorio |

Dos copias y una fuera de la máquina. Si los pesos solo viven en el servidor, el punto único de fallo sigue existiendo, solo que es más pequeño y más silencioso.

## 3. Fijar qué modelo es, no solo su nombre

Una etiqueta como `qwen2.5-coder:7b` puede apuntar a pesos distintos según cuándo se descargó. Para la continuidad importa el identificador concreto, no el nombre:

```bash
ollama list
ollama show --modelfile qwen2.5-coder:7b | grep '^FROM'
```

`ollama list` muestra un identificador corto del manifiesto; la línea `FROM` del `Modelfile` trae el `sha256` del blob (cada fichero de pesos, guardado con un nombre que sale de su propio hash). Son dos valores distintos y el que se anota en el inventario es el segundo.

El formato ya está registrado una vez: `qwen2.5:3b` consta como `357c53fb659c` en la [ejecución del 22 de octubre](../evidencias/2026-10-22-robustez-ejecucion-v1/entorno.json), que es el identificador del manifiesto, no el `sha256` del blob. Coincide con la fase 1 de la [hoja de ruta de seguridad](../referencia/hoja-de-ruta-seguridad-asistentes.md): fijar el digest es el mismo trabajo que exige la reproducibilidad.

## 4. Dónde están los pesos y cómo se copian

La ruta depende de cómo corra el servicio, así que se pregunta a `systemd` en lugar de suponerla:

```bash
systemctl show ollama -p User -p Environment
sudo du -sh /usr/share/ollama/.ollama/models
```

En la instalación de sistema de Ubuntu la ruta habitual es `/usr/share/ollama/.ollama/models`. La unidad de `config/ollama.service` es una referencia sin verificar y no fija `User` ni `HOME`: si se copiara tal cual, los modelos acabarían bajo el usuario con el que corriera el servicio. Se lee antes de copiar.

Antes de empaquetar, comprueba el espacio: un disco externo lleno deja la copia a medias sin avisar.

```bash
df -h /mnt/externo
sudo du -sh /usr/share/ollama/.ollama/models
```

La copia se hace con el servicio parado, para no capturar un blob a medio escribir. Van los pesos **y** el runtime: restaurar los pesos sin el binario ni la unidad de `systemd` no levanta nada.

```bash
sudo systemctl stop ollama
sudo tar -C /usr/share/ollama/.ollama -czf /mnt/externo/ollama-models-$(date +%F).tar.gz models \
  && sudo tar -czf /mnt/externo/ollama-bin-$(date +%F).tar.gz -C / \
       usr/local/bin/ollama usr/local/lib/ollama etc/systemd/system/ollama.service \
  && echo COPIAS_OK
sudo systemctl start ollama
sha256sum /mnt/externo/ollama-*.tar.gz
```

Si no aparece `COPIAS_OK`, no hay copia: el `&&` corta la cadena y el fallo se ve en ese momento, no el día que haga falta. Las rutas son las del script oficial; una instalación por `apt` deja el binario en `/usr/bin/ollama`, así que se confirma antes con `systemctl show ollama -p ExecStart`.

Para restaurar en la misma máquina, en el mismo orden y con el servicio parado:

```bash
sudo systemctl stop ollama
sudo tar -xzf /mnt/externo/ollama-models-<fecha>.tar.gz -C /usr/share/ollama/.ollama
sudo tar -xzf /mnt/externo/ollama-bin-<fecha>.tar.gz -C /
sudo chown -R ollama:ollama /usr/share/ollama
sudo systemctl start ollama
ollama list
```

En una máquina nueva faltan dos cosas que la copia de los pesos no trae: el usuario del servicio y el registro de la unidad.

```bash
sudo useradd -r -s /usr/bin/false -m -d /usr/share/ollama ollama
sudo tar -xzf /mnt/externo/ollama-models-<fecha>.tar.gz -C /usr/share/ollama/.ollama
sudo tar -xzf /mnt/externo/ollama-bin-<fecha>.tar.gz -C /
sudo chown -R ollama:ollama /usr/share/ollama
sudo systemctl daemon-reload
sudo systemctl enable --now ollama
ollama list
```

El `chown` no sobra: al extraer como root, los ficheros quedan de `root` y el servicio, que corre como `ollama`, puede no leerlos. Después se comprueba con `ollama list` y con el `sha256` de la línea `FROM` (§3).

## 5. Ruta local del cliente

El cliente no necesita cambiar de aplicación: necesita un perfil que apunte a `ollama.lab.local:11434`. La configuración concreta está en [local-vs-cloud, §4](local-vs-cloud.md#configuración-del-flujo-local) y no se duplica aquí.

Ese perfil no se versiona: `opencode.json` está en `.gitignore`. Lo que queda en el repositorio es el fragmento documentado, y el fichero real hay que copiarlo al disco externo junto con el resto del inventario. Si se pierde, se reconstruye desde el fragmento, sin las claves.

Lo que hay que comprobar y todavía no está comprobado en este repositorio: **si el cliente arranca sin red**. Un cliente puede funcionar contra el modelo local y aun así consultar en el arranque un catálogo o una sesión de cuenta. Esa comprobación es parte del simulacro, no una suposición.

## 6. Qué se puede hacer con cada tamaño

Capacidad orientativa para el hardware que consta en la evidencia del §0: 4 GB de VRAM y 31 GB de RAM. No es una medición de rendimiento: dice lo que cabe, no lo que rinde. Del servidor no consta el hardware en el repositorio; si es otro, el simulacro lo fija antes de dar esta tabla por buena.

| Tamaño (Q4) | Dónde corre | Sirve para | No sirve para |
|---|---|---|---|
| 3B | Entero en VRAM | Autocompletado, renombrados, resúmenes cortos, dudas puntuales de sintaxis | Diseño, refactor amplio, razonamiento largo |
| 7B | Reparte GPU y CPU | Escribir y revisar código de un archivo, documentación, tests | Cambios que cruzan varios módulos |
| 14B | No cabe en VRAM; solo CPU | Borradores con criterio, explicaciones | Iterar sobre código |

La velocidad es una expectativa, no una medición: cuanto más reparte entre GPU y CPU, más espera por respuesta. Esa cifra la da el simulacro o no la da nadie.

Un modelo local no sustituye al remoto grande. La continuidad no devuelve la misma capacidad: devuelve la posibilidad de seguir trabajando con menos criterio externo y más tuyo. Decirlo es parte del plan; venderlo como «sigo igual» sería falso.

## 7. Simulacro (pendiente)

Lo que convierte esto en evidencia y no en intención. No ejecutado todavía.

1. Comprobar qué queda del montaje anterior: `ollama list`, `sha256` de la línea `FROM` (§3) y tamaños reales (§2). Si el servidor conserva los modelos, no hay que reinstalar nada; si no, hace falta una ventana con red para recuperar runtime y pesos. Ese dato es lo primero que el simulacro tiene que dejar claro.
2. Cortar solo la salida a Internet del equipo cliente, sin tocar la red de laboratorio ni SSH. Con `nftables`, y sustituyendo las redes de ejemplo por las del laboratorio:

   ```bash
   sudo nft add table inet drill
   sudo nft add chain inet drill out '{ type filter hook output priority 0; policy accept; }'
   sudo nft add rule inet drill out oifname "lo" accept
   sudo nft add rule inet drill out ip daddr 192.168.0.0/16 accept
   sudo nft add rule inet drill out ip6 daddr fe80::/10 accept
   sudo nft add rule inet drill out drop
   ```

   Para revertir, en un comando aparte y no en el mismo bloque, o se deshace nada más pegar:

   ```bash
   sudo nft delete table inet drill
   ```

   Si entras al cliente por SSH desde fuera de la subred aceptada, te quedas fuera al aplicarlo. Borrar la ruta por defecto (`ip route del default`) también aísla, pero corta SSH y DNS si el resolutor no está en la misma subred; por eso no es la primera opción.
3. En el servidor, `ollama run qwen2.5-coder:7b "explica en tres líneas qué hace este comando: tar -czf"`. En el cliente, `curl -s http://ollama.lab.local:11434/api/tags`. El corte se hace en el cliente: lo que se prueba es que el cliente llega al modelo sin Internet, no que el servidor esté aislado. Se anota en qué equipo va cada orden.
4. Abrir el cliente con el perfil local y pedir una tarea real, pequeña y verificable sobre este repositorio.
5. Registrar: qué arrancó, qué falló, cuánto tardó y qué tarea no se pudo hacer.

Criterio de paso: el modelo responde sin red y el cliente completa una tarea real. Todo lo demás se anota como límite, no como fallo del plan.

## 8. Lo que esto no resuelve

- **Actualizaciones del runtime.** Sin red no hay parches. Lo que se puede hacer antes es lo que ya dice el README: no exponer el puerto y mantener el firewall.
- **Conocimiento.** Los pesos no son documentación. Si el trabajo depende de consultar documentación externa, esa documentación también hay que tenerla, y este inventario no la cubre.
- **Licencias y modelos nuevos.** Un modelo descargado es el que hay. No se actualiza solo.
- **Capacidad.** Ver §6. Es degradación controlada, no equivalencia.

## 9. Inventario para rellenar

Se completa en el simulacro y se guarda junto a la evidencia, no aquí:

| Elemento | Ruta | Tamaño real | Digest o versión | Fecha |
|---|---|---|---|---|
| Runtime de Ollama | | | | |
| Modelo operativo | | | | |
| Modelo de reserva | | | | |
| Cliente | | | | |
| Copia externa | | | | |
