# Índice de documentación

Este directorio organiza el laboratorio en cuatro capas: **arquitectura** (decisiones y diseño), **guías** (procedimientos ejecutables), **referencia** (marcos de evaluación y bitácora) y **evidencias** (ejecuciones reales con artefactos o registros parciales que declaran lo que falta).

## Arquitectura (`arquitectura/`)

| Documento | Qué contiene |
|---|---|
| [`architecture.md`](arquitectura/architecture.md) | Visión general de componentes, límites de confianza y flujo previsto |

## Guías (`guias/`)

Procedimientos paso a paso para instalar, configurar y diagnosticar.

| Documento | Qué resuelve |
|---|---|
| [`server-deployment-ubuntu-ollama.md`](guias/server-deployment-ubuntu-ollama.md) | Despliegue bare-metal headless: Ubuntu Server, Netplan, OpenSSH, Ollama |
| [`continue-remote-ollama-setup.md`](guias/continue-remote-ollama-setup.md) | Sincronización de ventana de contexto 16K entre Continue y Ollama remoto |
| [`gpu-setup.md`](guias/gpu-setup.md) | Comprobación de drivers CUDA y visibilidad de GPU para Ollama |
| [`opencode-desde-cero.md`](guias/opencode-desde-cero.md) | Qué es OpenCode, por qué empezar con un modelo local y la primera sesión |
| [`agents-md-publico-privado.md`](guias/agents-md-publico-privado.md) | Cómo organizar las instrucciones de uno o varios repositorios y el filtro antes de publicarlas |
| [`opencode-session-continuity.md`](guias/opencode-session-continuity.md) | Patrón de continuidad entre sesiones con comandos y archivos de estado |
| [`local-vs-cloud.md`](guias/local-vs-cloud.md) | Criterios de decisión, flujo híbrido y configuración del modelo local |
| [`continuidad-ia-local.md`](guias/continuidad-ia-local.md) | Qué dejar en disco para seguir trabajando sin proveedor remoto; simulacro pendiente |
| [`troubleshooting.md`](guias/troubleshooting.md) | Diagnóstico conservador de problemas frecuentes |

## Referencia (`referencia/`)

Marcos de evaluación, decisiones y comparativas.

| Documento | Qué aporta |
|---|---|
| [`ai-security-evaluation.md`](referencia/ai-security-evaluation.md) | Marco de evaluación de calidad y seguridad de funciones con LLM (conjunto dorado, inyección, métricas, CI) |
| [`prompt-robustness-testing.md`](referencia/prompt-robustness-testing.md) | Diseño de la matriz de perturbación: canarios C0–C4, familias F1–F4, niveles N0–N3, métricas de evasión |
| [`bitacora-decisiones-aprendizaje.md`](referencia/bitacora-decisiones-aprendizaje.md) | Memoria técnica: decisiones, incidentes, causa raíz y ejes de aprendizaje |
| [`hoja-de-ruta-seguridad-asistentes.md`](referencia/hoja-de-ruta-seguridad-asistentes.md) | Frontera de datos, inyección desde el repositorio y permisos; fases y criterios de salida |
| [`coste-contexto-y-optimizacion.md`](referencia/coste-contexto-y-optimizacion.md) | Riesgo de consumo elevado de prompts, controles de optimización y prevención |
| [`opencode-vs-vscode-antigravity.md`](referencia/opencode-vs-vscode-antigravity.md) | Criterios de decisión: OpenCode frente a VS Code y Google Antigravity |
| [`programacion-agentica.md`](referencia/programacion-agentica.md) | Marco: qué es, dónde paga, qué riesgos añade y qué controles la hacen defendible; con la evidencia del laboratorio |

## Evidencias (`evidencias/`)

Ejecuciones reales con artefactos congelados (JSON, huella de entorno, resultados) o registros parciales declarados. Cada carpeta conserva sus artefactos originales; si se corrige un README, se anota la fecha y el motivo en lugar de reescribir la evidencia.

| Carpeta | Qué registra |
|---|---|
| [`2026-10-22-robustez-instrumento/`](evidencias/2026-10-22-robustez-instrumento/) | Validación del instrumento (selftest): determinismo, inversa, testigo y factor de expansión. **Sin modelo**. |
| [`2026-10-22-robustez-ejecucion-v1/`](evidencias/2026-10-22-robustez-ejecucion-v1/) | Primera ejecución con modelo (`qwen2.5:3b`, N0/N1). Obediencia 0,50 con el instrumento original. |
| [`2026-10-22-robustez-ejecucion-v2/`](evidencias/2026-10-22-robustez-ejecucion-v2/) | Línea base N0 con instrumento corregido (control negativo C0, 15 transformaciones). Obediencia 0,50 replicada. |
| [`2026-10-26-robustez-prompt-v2/`](evidencias/2026-10-26-robustez-prompt-v2/) | Prompt `v2` endurecido frente a `v1`, N0. La obediencia no cambia: las instrucciones no defienden a este modelo. |
| [`2026-10-30-inferencia-7b-continue/`](evidencias/2026-10-30-inferencia-7b-continue/) | Registro **Parcial**: integración 7B + Continue probada por el autor, sin artefacto reproducible. No es un PASS. |
| [`2026-10-30-opencode-uso-real/`](evidencias/2026-10-30-opencode-uso-real/) | **Validado** el uso de OpenCode v2.1.4 en esta máquina. No valida precios ni una instalación limpia. |
| [`2026-11-02-coste-contexto-sesiones/`](evidencias/2026-11-02-coste-contexto-sesiones/) | **Validado** el reparto de coste de 30 días: el 98% de la entrada es relectura de caché. **Pendiente** comparar variantes de razonamiento. |
| [`plantilla-evidencia.md`](evidencias/plantilla-evidencia.md) | Plantilla para registrar nuevas evidencias |

## Navegación rápida

- **Empezar aquí**: [`guias/server-deployment-ubuntu-ollama.md`](guias/server-deployment-ubuntu-ollama.md) (despliegue base)
- **Primeros pasos con OpenCode**: [`guias/opencode-desde-cero.md`](guias/opencode-desde-cero.md)
- **Contexto 16K**: [`guias/continue-remote-ollama-setup.md`](guias/continue-remote-ollama-setup.md)
- **Entender la matriz**: [`referencia/prompt-robustness-testing.md`](referencia/prompt-robustness-testing.md)
- **Seguridad de asistentes**: [`referencia/hoja-de-ruta-seguridad-asistentes.md`](referencia/hoja-de-ruta-seguridad-asistentes.md)
- **Ver resultados reales**: [`evidencias/2026-10-22-robustez-ejecucion-v2/`](evidencias/2026-10-22-robustez-ejecucion-v2/)
- **Índice de evidencias**: [`evidencias/`](evidencias/)
