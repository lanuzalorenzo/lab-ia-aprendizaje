# Coordinación de varias sesiones de agente sobre una cola de trabajo

**Qué probé:** si un reclamo que se toma creando un directorio impide que dos sesiones de agente cojan el mismo ítem y escriban el mismo fichero, y qué pasa con el tope de sesiones, el latido y una caída a mitad.

**Qué salió:** con un `mkdir` atómico, los seis casos y el control pasan y la pasada se repite igual. Con el `mkdir` que trae este equipo, dos procesos consiguieron crear el mismo directorio en 11 de 200 rondas, y el arnés se niega a empezar: la competición se rompe antes de llegar al diseño.

**Qué no está medido:** el latido real de un plugin durante llamadas a herramienta de un agente, el cierre bajo cerrojo con deltas, la prueba con agentes en lugar de procesos de shell y el tope y el ítem único con llegadas simultáneas.

> **Estado:** Parcial (2026-11-19). El mecanismo está ejecutado con sesiones simuladas y se repite; falta el latido real del plugin, el cierre bajo cerrojo, la prueba con agentes y las carreras de tope e ítem único con llegadas simultáneas.

Dos sesiones que trabajan a la vez sobre la misma cola se pisan igual que dos personas que escriben en la misma libreta sin mirar si la otra ya tiene el bolígrafo. No hace falta que se pongan de acuerdo en todo: basta con que ninguna empiece sin haber cogido su hoja. Esta página mide si ese gesto —coger la hoja— es suficiente para que no haya dos manos en el mismo renglón.

## 1. Metadatos

| Campo | Valor |
|---|---|
| **Fecha** | 2026-11-19 |
| **Tipo** | Ejecución de mecanismo de coordinación, sin modelo |
| **Sesiones** | Procesos de shell que simulan sesiones; no hay agente ni modelo |
| **Primitiva de reclamo** | `mkdir` sobre el sistema de archivos local; la pasada publicada usa GNU coreutils 9.7 |
| **Comando** | `MKDIR=/usr/bin/gnumkdir ./arnes.sh` |
| **Entorno** | Ubuntu, Linux 7.0.0-42-generic, 20 núcleos, 30 GB de RAM, bash 5.3.9, ext4 |
| **Artefactos** | [`arnes.sh`](arnes.sh), [`primitiva.sh`](primitiva.sh), [`resultados/`](resultados/) |
| **Estado** | Parcial |

## 2. Hipótesis

Si cada ítem de la cola se reclama creando un directorio antes de trabajar, y el reclamo guarda quién lo tiene, entonces:

1. dos sesiones que compiten por el mismo ítem no pueden ganarlo las dos;
2. el tope de tres sesiones se puede sostener sin cerrojo global;
3. una sesión no puede acumular dos ítems;
4. soltar y volver a coger el ítem deja rastro de quién lo abrió y quién lo cerró;
5. un latido viejo se puede señalar sin liberar el ítem por su cuenta;
6. una sesión que muere a mitad deja el ítem ocupado, no libre.

La hipótesis es del mecanismo, no del agente: no dice nada sobre la calidad del trabajo, solo sobre quién lo toca.

## 3. Montaje

El arnés reproduce el diseño con tres piezas y ningún cerrojo global.

| Pieza | Cómo se representa |
|---|---|
| **Reclamo** | Un directorio por ítem, `reclamos/<ítem>/`, creado con `mkdir`. Quien lo crea es el dueño. Dentro queda `reclamo` con sesión, ítem, repo, instante y rol. |
| **Rol** | Se fija al tomar el ítem: el primer reclamo de ese ítem es `principal`; los posteriores, `delta`. |
| **Latido** | Un fichero por sesión, `latidos/<sesión>`, refrescado con `touch` en cada acción. Su fecha de modificación (`mtime`) es la última señal. |
| **Caducidad de la señal** | A partir de 2700 segundos (45 minutos) sin latido, el ítem se muestra como «sin señal». No se libera solo: la decisión es de la persona. |
| **Tope** | Tres sesiones como máximo. Se cuenta cuántas sesiones distintas tienen reclamo antes de escribir el suyo. |
| **Un ítem por sesión** | Al reclamar se comprueba que la sesión no tenga ya otro ítem. Si lo tiene, el reclamo se retira y no se escribe. |

El orden importa: primero se crea el directorio, que es la puerta atómica; después se comprueban los invariantes de sesión y, si alguno falla, se retira el directorio. Así la exclusión por ítem no depende de un contador compartido, y el contador solo decide el tope.

Las sesiones son procesos de shell. Cada llamada a `reclamar`, `liberar` o `latir` hace de llamada a herramienta. No hay agente, no hay modelo y no hay tokens: lo que se prueba es el reparto del trabajo, no lo que se escribe dentro.

## 4. Casos y resultados

El arnés imprime siete comprobaciones: un control y seis casos. Todas están en [`resultados/01-arnes.txt`](resultados/01-arnes.txt).

| Caso | Qué se hace | Observado | Resultado |
|---|---|---|---|
| **c0** | Control: dos procesos escriben el mismo fichero sin reclamar | Los dos salen con 0; sobrevive una sola línea y una sola marca | ok (control) |
| **c1** | 20 rondas de dos sesiones compitiendo por el mismo ítem | En las 20 gana exactamente una y queda un solo reclamo | Pasa |
| **c2** | Tres sesiones reclaman un ítem cada una; una cuarta lo intenta | La cuarta recibe `tope` y su ítem queda libre | Pasa |
| **c3** | Una sesión con un ítem intenta coger otro | Recibe `dos-items` y el segundo ítem queda libre | Pasa |
| **c4** | Una sesión suelta su ítem y otra lo coge | El primer rol es `principal` y el segundo, `delta` | Pasa |
| **c5** | El latido se retrasa 46 minutos y después se refresca | «sin señal»; tras el latido, `viva`; no se libera | Pasa |
| **c6** | La sesión muere con `SIGKILL` después de reclamar | Código 137, el reclamo sobrevive, la siguiente recibe `ocupado` y el estado es «sin señal» | Pasa |

El control importa tanto como los demás: sin reclamo, dos escritores trabajan a la vez sobre el mismo fichero y los dos creen haberlo hecho bien. Lo que muestra es una sobrescritura, no una escritura partida: el último reemplaza la línea del primero. La coordinación no hace más rápida la escritura; evita que una sesión pise lo de otra y que ninguna sepa que lo ha hecho.

## 5. La primitiva también se comprueba

El diseño descansa en que crear un directorio sea atómico: el núcleo crea el nombre o responde que ya existe, sin término medio. Eso no se hereda del nombre de la llamada; se mide.

`primitiva.sh` lanza dos procesos a crear el mismo camino y cuenta las rondas en las que los dos salen con éxito. Si el binario no crea ni un directorio, se detiene: un cero entonces no significa atomicidad. El arnés ejecuta esa medición antes de los casos y no corre si el resultado no es cero. En este equipo ([`resultados/00-primitiva.txt`](resultados/00-primitiva.txt)):

| Binario | Rondas | Rondas con dos creadores |
|---|---|---|
| `mkdir` de uutils 0.10.0 (el que resuelve `mkdir`) | 200 | 11 |
| `mkdir` de GNU coreutils 9.7 | 200 | 0 |

Con el primero, la pasada del arnés se detiene con código 2 antes de empezar ([`resultados/03-primitiva-no-atomica.txt`](resultados/03-primitiva-no-atomica.txt), que recoge también el `codigo=2`). La cifra cambia entre pasadas —11 en la medición de la tabla, 13 en la que provocó la negativa— porque la carrera no es determinista: por eso la guarda mira 200 rondas y no una. No es un detalle del arnés: es el primer modo de fallo del diseño, y ocurre antes de que ninguna sesión llegue a trabajar. La pasada publicada usa `MKDIR=/usr/bin/gnumkdir`, que es el binario atómico que trae el equipo.

## 6. Qué no demuestra

- **No hay agente.** Las sesiones son procesos de shell. No se mide si un agente respeta el reclamo cuando se le pide, ni cuánto tarda en pedirlo.
- **El latido no lo refresca un plugin.** El arnés usa `touch`; el umbral se prueba retrasando el `mtime` y el refresco, llamando a `latir`, no esperando 45 minutos con un plugin real. Que el plugin refresque en cada llamada a herramienta está diseñado, no ejecutado.
- **No hay cierre.** El cerrojo de cierre, el delta de las sesiones secundarias y el orden de aplicación no se tocan aquí.
- **No hay backlog.** La separación entre la cola de ítems y el backlog que ordena frentes no se prueba; el arnés solo tiene ítems.
- **El tope y el ítem único se prueban en serie.** Las dos comprobaciones se hacen con el directorio creado y antes de escribir el reclamo. No he medido dos sesiones cruzando el umbral de tres a la vez ni dos llamadas simultáneas de la misma sesión.
- **Un solo equipo y un solo sistema de archivos.** No hay NFS ni dos máquinas. La atomicidad de `mkdir` en red no está medida.
- **La cifra de uutils es de este equipo.** No afirma nada sobre otras versiones ni sobre otros sistemas; lo que sí muestra es que la primitiva se comprueba y que el arnés se niega a correr con una que no lo es.

## 7. Cómo reproducir

```bash
cd docs/experimentos/2026-11-coordinacion-sesiones
./primitiva.sh mkdir 200
./primitiva.sh /usr/bin/gnumkdir 200
MKDIR=/usr/bin/gnumkdir ./arnes.sh
```

El arnés termina con `FIN fallos=0` y código 0 si todo pasa, con `FIN fallos=N` y código 1 si algo falla, y con `ABORTA` y código 2 si la primitiva no es atómica. En un equipo donde `mkdir` sea GNU, `./arnes.sh` sin variable basta. Cada pasada usa un directorio temporal y lo borra al salir; no toca el repositorio.

[`resultados/02-repeticion.txt`](resultados/02-repeticion.txt) es la segunda pasada completa, con el mismo comando. Es idéntica a la primera, byte a byte: se comprueba con `cmp resultados/01-arnes.txt resultados/02-repeticion.txt`.

## 8. Siguiente paso

Ejecutar el mismo arnés con dos sesiones de agente reales y el plugin de latido activo: comprobar que el plugin refresca en cada llamada a herramienta, que el reclamo se pide antes de leer el ítem y que una sesión que muere deja el estado que el arnés ya describe. Eso es lo que separa este **Parcial** de un Validado.
