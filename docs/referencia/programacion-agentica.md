# Programación agéntica: dónde paga y cómo se controla

> **Estado:** Diseño (marco); la evidencia citada conserva el estado de su artefacto. **Fecha:** 2026-11-03. **Alcance:** criterio para decidir cuándo usar un agente y qué controles exigirle. No enseña a instalar la herramienta: eso está en las guías.

Un agente no es un chat más listo. Es un programa que lee el repositorio, decide un paso, lo ejecuta con herramientas y comprueba el resultado. La diferencia es la misma que entre dictarle una carta a alguien y darle las llaves del archivo, la fotocopiadora y el sello: gana autonomía y hay que decidir qué puede tocar. Esta página ordena cuándo compensa, qué riesgos añade y qué controles lo hacen defendible.

## 1. Qué es y qué no

Un agente de programación es un modelo al que se le añaden cuatro cosas:

| Pieza | Qué aporta |
|---|---|
| Instrucciones | Reglas del proyecto: arquitectura, estilo, verificación y límites |
| Herramientas | Leer, buscar, editar, ejecutar comandos, consultar la red |
| Permisos | Qué puede tocar y qué no, aplicado por la herramienta, no por el prompt |
| Estado | Archivos que sobreviven a la sesión: plan, diario, informes |

El modelo puede ser el mismo que el de un chat. Lo que cambia es el bucle: actúa, ve el resultado y vuelve a decidir. Por eso la unidad de diseño no es el prompt, sino **el permiso y la verificación**.

No es autocompletar: eso predice texto y no ejecuta. No es RPA: eso sigue reglas fijas y no juzga. No es un chatbot: eso responde y no deja el repositorio cambiado.

## 2. El bucle

1. **Contexto.** Lee las reglas del proyecto, los archivos implicados y el estado de la sesión anterior.
2. **Plan.** Divide el encargo y elige el siguiente paso.
3. **Acción.** Lee, edita, ejecuta o consulta.
4. **Verificación.** Pasa pruebas, validador, revisión o una comprobación determinista.
5. **Estado.** Deja escrito dónde se quedó para que la siguiente sesión no lo adivine.

El humano ocupa tres sitios: define el alcance, aprueba lo irreversible y revisa el resultado. El resto puede delegarse. Un paso sin verificación es una sugerencia, no un resultado.

## 3. Dónde paga

Paga cuando se cumplen cuatro condiciones:

- El «hecho» se puede escribir como una comprobación.
- El error se detecta antes de llegar a `main`.
- El daño de un fallo es pequeño o reversible.
- El contexto necesario está en archivos que el agente puede leer.

Ejemplos donde suelo usarlo: auditar la coherencia de un README con sus archivos, buscar enlaces y estados contradictorios, generar pruebas sobre una función acotada, repetir una migración mecánica y leer muchos archivos para resumir lo que cambió.

La prueba rápida: si no puedes escribir el «hecho cuando» como un comando que devuelve verde o rojo, todavía no está listo para un agente.

## 4. Dónde no

- Requisitos difusos o en discusión: el agente rellena el hueco con una suposición plausible.
- Diseño nuevo: puede proponer, pero la decisión necesita criterio y contexto que no están en el repositorio.
- Acciones irreversibles: desplegar, borrar, publicar o rotar credenciales.
- Decisiones de seguridad sin revisión: permisos, fronteras de datos, secretos.
- Tareas cuyo éxito no se puede comprobar: si no detectas el error, no delegas la decisión.

## 5. Ventajas

- **Constancia.** Aplica la misma lista cada vez; un script no se cansa ni se salta el paso 4.
- **Lectura rápida.** Recorre muchos archivos y cruza referencias que a una persona le costaría mantener en la cabeza.
- **Contexto explícito.** Las reglas viven en archivos, no en la memoria de quien estuvo en la reunión.
- **Exploración en paralelo.** Varios agentes de solo lectura pueden mirar partes distintas sin tocarse.
- **Coste visible.** Tokens, caché y tiempo quedan registrados y se pueden medir.

No promete código mejor ni criterio mejor. Promete ejecutar un criterio que ya existe, más veces y con menos fricción.

## 6. Riesgos

- **No determinismo.** El mismo encargo puede seguir dos caminos distintos; la comprobación tiene que ser estable aunque el camino no lo sea.
- **Exceso de permisos.** Un agente con shell y edición tiene el radio de daño de la cuenta que lo lanza.
- **Inyección desde el repositorio.** Un archivo, un issue o una página pueden contener instrucciones que el agente lea como órdenes.
- **Sesgo de automatización.** Un informe bien escrito se acepta sin comprobar; el formato no es evidencia.
- **Coste y contexto.** Releer archivos y arrastrar historial pesa más que la respuesta.
- **Mantenimiento de prompts.** Un comando es código: se duplica, se desincroniza y envejece.
- **Evidencia falsa.** Presentar un diseño o un runbook como si se hubiera ejecutado.
- **Fuga de datos.** El contexto que se envía a un proveedor remoto puede llevar más de lo que se cree.

## 7. Controles

1. **Mínimo privilegio.** Denegar por defecto y abrir solo lo necesario. Los agentes de revisión no editan ni ejecutan pruebas.
2. **Puertas humanas.** Commit, push, despliegue y publicación se aprueban; la revisión va antes de fusionar.
3. **Validadores deterministas.** Enlaces, esquema, umbrales y fechas los comprueba un script, no el modelo.
4. **Evidencia separada.** Ejecutado, diseñado y pendiente se distinguen; cada cifra lleva fecha y artefacto.
5. **Higiene de contexto.** Instrucciones compactas, estado en archivos, salida de herramientas acotada y compactación.
6. **Un dueño por regla.** Si dos archivos dicen lo mismo, uno manda y el otro enlaza; se sincroniza y se valida. Con varios repositorios, lo común sube a una sola capa y cada uno conserva lo suyo; cómo se reparte está en [`agents-md-publico-privado`](../guias/agents-md-publico-privado.md).
7. **Registro y auditoría.** Queda quién hizo qué y con qué permiso; los logs no llevan secretos.

La lista se puede resumir en una pregunta: **¿qué puede tocar el agente si se equivoca, y cómo me entero?**

## 8. Experimentos en este laboratorio

| Afirmación | Artefacto | Estado |
|---|---|---|
| El coste está en el contexto, no en la respuesta | [`2026-11-02-coste-contexto-sesiones`](../experimentos/2026-11-02-coste-contexto-sesiones/) | Validado (medición de 30 días) |
| OpenCode funciona en este equipo | [`2026-10-30-opencode-uso-real`](../experimentos/2026-10-30-opencode-uso-real/) | Validado (v2.1.4) |
| El instrumento de robustez mide de forma estable | [`2026-10-22-robustez-instrumento`](../experimentos/2026-10-22-robustez-instrumento/) | Validado (instrumento) |
| Endurecer el prompt no mejora la obediencia de este modelo | [`2026-10-26-robustez-prompt-v2`](../experimentos/2026-10-26-robustez-prompt-v2/) | Parcial (un modelo, nivel N0) |
| La continuidad se resuelve con estado en archivos | [`opencode-session-continuity`](../guias/opencode-session-continuity.md) | Patrón documentado |
| Las instrucciones públicas y privadas se separan | [`agents-md-publico-privado`](../guias/agents-md-publico-privado.md) | Patrón documentado |

Tres lecturas que sostienen el marco:

- **Coste.** En 162 sesiones de 30 días, el 98 % de los tokens de entrada fue relectura de caché y entrada más caché sumaron el 59 % del gasto. El coste por sesión del modelo de trabajo fue de 0,075 dólares. La consecuencia práctica: optimizar la respuesta sirve de poco; hay que optimizar lo que el agente relee.
- **Robustez.** El instrumento está validado, pero las ejecuciones son parciales: un modelo, un nivel y una obediencia de 0,50 que no se movió al endurecer el prompt. No demuestra que todos los modelos se comporten igual; sí demuestra que **la instrucción no es una barrera de seguridad**.
- **Uso real.** OpenCode está validado en esta máquina, con su versión y su registro. Eso no valida una instalación limpia ni un precio.

Lo que **no** está medido aquí: tasa de defectos detectados, productividad, adopción por un equipo y comportamiento en producción. No se afirma.

## 9. Límites

- Una máquina, un usuario y un modelo principal; la evidencia de coste cubre una ventana de 30 días.
- El laboratorio no es producción: no hay usuarios externos, turnos ni datos de terceros.
- La prueba de robustez es parcial y no se extrapola a otros modelos.
- El marco es un diseño; las cifras que cita conservan el estado de su artefacto.
- Los patrones se describen en genérico: no se citan repositorios, rutas ni comandos internos.

## 10. Mapa de lectura

| Si buscas | Lee |
|---|---|
| Qué es OpenCode y cómo empezar | [`opencode-desde-cero`](../guias/opencode-desde-cero.md) |
| Que la sesión no pierda el hilo | [`opencode-session-continuity`](../guias/opencode-session-continuity.md) |
| Separar instrucciones públicas y privadas | [`agents-md-publico-privado`](../guias/agents-md-publico-privado.md) |
| Frontera de datos, inyección y permisos | [`hoja-de-ruta-seguridad-asistentes`](hoja-de-ruta-seguridad-asistentes.md) |
| Coste de contexto y controles | [`coste-contexto-y-optimizacion`](coste-contexto-y-optimizacion.md) |
| Diseñar una prueba de robustez | [`prompt-robustness-testing`](prompt-robustness-testing.md) |
| Evaluar una función con LLM | [`ai-security-evaluation`](ai-security-evaluation.md) |
| Elegir cliente | [`opencode-vs-vscode-antigravity`](opencode-vs-vscode-antigravity.md) |

La siguiente medición no es «¿escribe mejor?», sino «¿cuántas tareas aceptadas por dólar y cuántos defectos detecta antes de que lleguen a `main`?».
