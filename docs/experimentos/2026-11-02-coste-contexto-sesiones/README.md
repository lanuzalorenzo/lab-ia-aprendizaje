# Coste real de las sesiones: el contexto pesa más que la respuesta

**Qué probé:** de qué se compone el coste de una sesión con agente, sobre 162 sesiones de 30 días.

**Qué salió:** el 98% de la entrada es relectura de caché; entrada y caché suman el 59% del coste y el razonamiento el 23%.

**Qué no está medido:** la comparación entre variantes de razonamiento: no hay sesiones con `low` ni con `high`.

> Resumen añadido el 2026-11-04; el registro original no cambia.

> **Estado:** Validado el reparto de coste de 30 días de sesiones en este equipo. **Pendiente** la comparación entre variantes de razonamiento: no hay todavía ninguna sesión con `low` ni con `high`.

Una sesión con un agente no se paga por lo que responde, sino por todo lo que tiene que releer antes de responder. Es como volver a fotocopiar el expediente entero en cada consulta: el gasto está en el papel, no en la respuesta. Esta evidencia mide ese reparto sobre 30 días de uso real en este equipo.

## 1. Metadatos

| Campo | Valor |
|---|---|
| **Fecha** | 2026-11-02 |
| **Tipo** | Medición sobre registros de uso |
| **Modelo** | `opencode-go/deepseek-v4.1-flash` (principal); `claude-haiku-5-5` como contraste |
| **Script** | `scripts/utilidades/coste_sesiones_opencode.py` |
| **Entorno** | Ubuntu 26.04.1 LTS; OpenCode `v2.1.4`; base local de sesiones |
| **Estado** | Validado (medición) · Pendiente (variantes) |

## 2. Qué se ha ejecutado

Se leyó en modo solo lectura la base de sesiones de OpenCode y se agregaron las 162 sesiones de los últimos 30 días:

```bash
./scripts/utilidades/coste_sesiones_opencode.py --days 30
./scripts/utilidades/coste_sesiones_opencode.py --days 30 --model deepseek --group variant
```

El coste lo registra OpenCode por sesión. Los tokens se agrupan por modelo y por variante.

## 3. Qué mide y qué no

| Pregunta | Estado |
|---|---|
| ¿Dónde se va el dinero en una sesión con agente? | Validado |
| ¿El razonamiento se factura como salida? | Validado por inferencia de precio |
| ¿Qué variante (`low`/`high`/`max`) conviene? | No medido: cero sesiones con `low` o `high` |
| ¿Los límites de contexto y salida del proveedor? | No medido aquí |
| ¿El coste se mantiene mes a mes? | No medido: una sola ventana |

## 4. Resultados

**Tamaño de la muestra.** 162 sesiones, $11,54 en 30 días. El modelo de trabajo concentra 128 sesiones y $9,62, con **$0,075 por sesión**.

**El 98,0% de los tokens de entrada es relectura de caché**: 1.060 millones de tokens de caché frente a 20,2 millones de entrada nueva. Por eso el precio que decide no es el de entrada, sino el de lectura de caché.

**Reparto del coste**, reconstruido con las tarifas de lista:

| Concepto | Peso |
|---|---:|
| Entrada sin caché | 29,0% |
| Lectura de caché | 30,4% |
| Salida visible | 17,7% |
| Razonamiento | 22,9% |

**El razonamiento se factura como salida.** En 117 sesiones se restó del coste la entrada y la caché y se dividió por los tokens restantes: el precio implícito es **$0,599/M** si se incluye el razonamiento, frente a **$1,32/M** si se excluye. La tarifa de salida es $0,60/M. El ajuste es directo.

**El tramo de contexto sí existe en otros modelos.** Una sesión con `claude-haiku-5-5` costó **$1,85** con 27,4 M de caché y 106 k de salida. Al pasar de 100 k de contexto, la tarifa sube: $0,05/M de caché y $2,50/M de salida. Con las tarifas de DeepSeek, la misma sesión habría costado entre **$0,14 y $0,19**.

## 5. Hallazgos y límites

- **H-1**: el ahorro real está en el contexto, no en acortar respuestas. Entrada y caché suman el 59% del gasto.
- **H-2**: elegir modelo por precio de entrada induce a error. Cuenta la caché y los tramos por tamaño de contexto.
- **H-3**: la variante de razonamiento mueve el 23% del coste. Es una palanca de segundo orden frente a la higiene de contexto.
- **H-4**: la reconstrucción con tarifas de lista supera el coste registrado en cerca de un 9%. Los porcentajes son la parte fiable; los importes absolutos, aproximados.

## 6. Qué no demuestra

- Que DeepSeek sea mejor modelo: solo mide coste, no calidad.
- Que `low` ahorre: sin datos, un turno extra puede consumir el ahorro.
- Que las tarifas sigan vigentes: cambian sin aviso.
- El gasto en modelos locales: la base solo registra el proveedor remoto.

## 7. Cómo reproducir

```bash
cd lab-ia-aprendizaje
./scripts/utilidades/coste_sesiones_opencode.py --days 30 --group model
./scripts/utilidades/coste_sesiones_opencode.py --days 30 --model deepseek --group variant
```

Hace falta una base de sesiones con actividad. El esquema no es una API pública y puede cambiar entre versiones de OpenCode.

## 8. Siguiente paso

Comparar `low`, `high` y el esfuerzo por defecto sobre seis tareas representativas, con la misma formulación y en sesiones nuevas. La métrica es **coste por tarea aceptada**, contando reintentos, no coste por token. Se registran también tokens de razonamiento, número de turnos y tiempo hasta la aceptación.
