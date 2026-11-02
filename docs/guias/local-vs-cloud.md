# Inferencia local frente a cloud: criterios y flujo del laboratorio

> **Estado:** Parcial — criterios documentados y experiencia de uso propia. No es un benchmark ni una comparación de rendimiento medida.
>
> **Propósito:** decidir dónde ejecutar cada carga de trabajo sin convertir la elección en una preferencia ideológica.

## 1. La pregunta correcta

No es «¿local o cloud?». Es:

> ¿Qué dato entra, quién lo ve, cuánto cuesta, cuánto tarda y qué capacidad necesita?

La respuesta puede ser distinta para cada flujo. En este laboratorio, el trabajo diario usa un proveedor remoto (OpenCode Go) y el local queda para datos que no pueden salir de la red.

## 2. Dimensiones

| Dimensión | Local | Cloud |
|---|---|---|
| Sensibilidad del dato | El dato no sale del equipo o de la red de laboratorio | Depende del contrato, la región y la retención |
| Coste | Hardware, electricidad y mantenimiento | Pago por uso; puede ser menor en picos |
| Latencia | Sin red; limitada por el hardware | Red y cola del proveedor |
| Capacidad | Limitada por VRAM y modelo | Modelos mayores y escalado elástico |
| Disponibilidad | Depende de tu equipo y tu red | Depende del proveedor |
| Mantenimiento | Tú actualizas runtime, drivers y modelos | El proveedor actualiza |
| Cumplimiento | Control directo, sin tercero | Requiere revisar región, retención y subencargados |
| Reproducibilidad | Alta si fijas versiones | Puede cambiar sin aviso |

## 3. Escenarios típicos

| Escenario | Decisión razonable | Motivo |
|---|---|---|
| Código o datos de un cliente | Local | El dato no debe salir sin contrato y autorización |
| Borradores y documentación pública | Cloud o híbrido | Capacidad y coste; el dato no es sensible |
| Clasificación de tickets con datos personales | Local o cloud con redacción previa | Minimizar el dato antes de enviarlo |
| Evaluación masiva de un conjunto dorado | Cloud acotado o local en lote | Depende del volumen y del presupuesto |
| Asistente de desarrollo diario | Remoto con buenos límites, si la política del proveedor es aceptable | Capacidad, disponibilidad y límites. El local exigió montaje y ajuste que consumían demasiado tiempo (experiencia propia, no medida) |
| Modelo grande para arquitectura | Cloud | El hardware local no lo soporta |

## 4. Flujo híbrido

El laboratorio usa dos flujos con el mismo cliente, OpenCode:

1. **Remoto para el trabajo diario:** OpenCode Go. Es el que uso a diario por sus límites y por la disponibilidad de modelos. Antes de enviarle código, hay que revisar su política de privacidad vigente.
2. **Local para lo que no puede salir de la red:** Ollama en un servidor dedicado, para código o datos que no deben salir de la red del laboratorio.

El flujo local dejó de ser la opción por defecto. Montarlo y ajustarlo consumía demasiado tiempo, y su capacidad no cubría el trabajo diario. Ahora solo se usa cuando el dato lo exige. Ver [bitácora, entrada 08](../referencia/bitacora-decisiones-aprendizaje.md#entrada-08-trabajo-diario-con-opencode-go-y-local-para-datos-restringidos).

La decisión no es permanente: se revisa cuando cambia el dato, el coste o la capacidad. Lo importante es que la configuración deje claro qué proveedor usa cada flujo y que no se mezclen datos sensibles con el flujo remoto.

### Configuración del flujo local

Se define en `opencode.json`. Sustituye `ollama.lab.local` por el nombre o la dirección de tu servidor:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "providers": {
    "ollama": {
      "package": "@opencode/ai/providers/openai-compatible",
      "settings": {
        "baseURL": "http://ollama.lab.local:11434/v1"
      },
      "models": {
        "qwen2.5-coder:7b": {
          "name": "Qwen 2.5 Coder 7B (local)"
        }
      }
    }
  }
}
```

El flujo remoto no necesita nada en el archivo: se conecta dentro de OpenCode con `/connect`. Las claves nunca van en `opencode.json` ni en el repositorio.

## 5. Errores frecuentes

- **«Local» significa privado.** Falso: depende de la configuración del cliente, del endpoint, de los logs y de si el modelo descarga recursos externos.
- **«Tengo GPU» significa que el modelo la usa.** Falso: hay que observarlo durante una inferencia.
- **«Cloud es más caro».** Depende del volumen y del coste de mantener hardware.
- **«El modelo local es igual de bueno».** Depende del modelo y de la tarea; no se asume.
- **«Ya funciona en mi máquina».** Sin versión fijada y sin evidencia, no es reproducible.

## 6. Cómo registrar la decisión

Para cada flujo, dejar escrito:

- qué dato entra y qué sensibilidad tiene;
- dónde se ejecuta el modelo y quién lo administra;
- qué coste se espera y con qué tope;
- qué latencia se necesita;
- qué se registra y durante cuánto tiempo;
- qué evidencia respalda que funciona;
- cuándo se revisa la decisión.

Una decisión sin fecha de revisión se convierte en deuda.

## 7. Lecciones del cambio de flujo

1. Separar flujos evita enviar código sensible a un proveedor por comodidad.
2. Los límites de uso pesan tanto como la privacidad: un flujo que se queda corto acaba sin usarse.
3. La seguridad depende de la red y de la gestión de claves, no solo de que el modelo corra en local.
4. La documentación debe distinguir configuración, ejecución y medición.

## 8. Límites

Este documento no compara modelos concretos ni publica latencias o costes medidos. Para eso hace falta ejecutar la misma carga en ambos entornos y conservar los resultados. Mientras no exista esa medición, las cifras son estimaciones o criterios, no evidencias.
