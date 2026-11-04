# Índice de documentación

El repositorio se lee de fuera hacia dentro: las **guías** resuelven un trabajo concreto, la **referencia** explica el criterio que hay detrás, los **experimentos** guardan lo que he probado con su resultado y sus límites, y **arquitectura** describe el montaje local. Un experimento no es un PASS: cada página abre con qué probé, qué salió y qué no está medido.

## Guías (`guias/`)

Procedimientos para volver a hacer lo mismo sin recordar los pasos.

| Trabajo | Documento | Qué resuelve |
|---|---|---|
| Montar el entorno | [`server-deployment-ubuntu-ollama.md`](guias/server-deployment-ubuntu-ollama.md) | Despliegue bare-metal headless: Ubuntu Server, Netplan, OpenSSH y Ollama |
| Montar el entorno | [`gpu-setup.md`](guias/gpu-setup.md) | Drivers CUDA y visibilidad de la GPU para Ollama |
| Montar el entorno | [`continue-remote-ollama-setup.md`](guias/continue-remote-ollama-setup.md) | Sincronizar la ventana de contexto de 16K entre Continue y Ollama remoto |
| Trabajar con el agente | [`opencode-desde-cero.md`](guias/opencode-desde-cero.md) | Qué es OpenCode, por qué empezar con un modelo local y la primera sesión |
| Trabajar con el agente | [`opencode-session-continuity.md`](guias/opencode-session-continuity.md) | Continuidad entre sesiones con comandos y archivos de estado |
| Trabajar con el agente | [`agents-md-publico-privado.md`](guias/agents-md-publico-privado.md) | Organizar las instrucciones de uno o varios repositorios y filtrarlas antes de publicar |
| Decidir qué sale de la red | [`local-vs-cloud.md`](guias/local-vs-cloud.md) | Criterios de decisión, flujo híbrido y configuración del modelo local |
| Decidir qué sale de la red | [`continuidad-ia-local.md`](guias/continuidad-ia-local.md) | Qué dejar en disco para seguir trabajando sin proveedor remoto |
| Cuando algo falla | [`troubleshooting.md`](guias/troubleshooting.md) | Diagnóstico conservador de problemas frecuentes |

## Referencia (`referencia/`)

Marcos de evaluación, decisiones y comparativas.

| Documento | Qué aporta |
|---|---|
| [`programacion-agentica.md`](referencia/programacion-agentica.md) | Marco: qué es, dónde paga, qué riesgos añade y qué controles la hacen defendible; con los experimentos del laboratorio |
| [`hoja-de-ruta-seguridad-asistentes.md`](referencia/hoja-de-ruta-seguridad-asistentes.md) | Frontera de datos, inyección desde el repositorio y permisos; fases y criterios de salida |
| [`ai-security-evaluation.md`](referencia/ai-security-evaluation.md) | Evaluación de calidad y seguridad de funciones con LLM: conjunto dorado, inyección, métricas y CI |
| [`prompt-robustness-testing.md`](referencia/prompt-robustness-testing.md) | Diseño de la matriz de perturbación: canarios C0–C4, familias F1–F4, niveles N0–N3 y métricas de evasión |
| [`coste-contexto-y-optimizacion.md`](referencia/coste-contexto-y-optimizacion.md) | Consumo elevado de prompts, controles de optimización y prevención |
| [`opencode-vs-vscode-antigravity.md`](referencia/opencode-vs-vscode-antigravity.md) | Criterios de decisión: OpenCode frente a VS Code y Google Antigravity |
| [`bitacora-decisiones-aprendizaje.md`](referencia/bitacora-decisiones-aprendizaje.md) | Memoria técnica: decisiones, incidentes, causa raíz y ejes de aprendizaje |

## Experimentos (`experimentos/`)

Cada carpeta conserva sus artefactos originales y declara lo que falta. Si se corrige una página, se anota la fecha y el motivo en lugar de reescribir el registro.

| Carpeta | Qué probé | Estado |
|---|---|---|
| [`2026-10-22-robustez-instrumento/`](experimentos/2026-10-22-robustez-instrumento/) | Que la prueba de robustez mide lo que dice: determinismo, inversa, testigo y factor de expansión. Sin modelo | Validado |
| [`2026-10-22-robustez-ejecucion-v1/`](experimentos/2026-10-22-robustez-ejecucion-v1/) | `qwen2.5:3b` en N0 y N1. La orden directa funciona; obediencia 0,50 | Parcial |
| [`2026-10-22-robustez-ejecucion-v2/`](experimentos/2026-10-22-robustez-ejecucion-v2/) | Línea base N0 con el instrumento corregido. La obediencia de 0,50 se replica | Parcial |
| [`2026-10-26-robustez-prompt-v2/`](experimentos/2026-10-26-robustez-prompt-v2/) | Prompt endurecido en N0. La obediencia no cambia: las instrucciones no defienden a este modelo | Parcial |
| [`2026-10-30-inferencia-7b-continue/`](experimentos/2026-10-30-inferencia-7b-continue/) | Integración de 7B con Continue, probada sin artefacto reproducible. No es un PASS | Parcial |
| [`2026-10-30-opencode-uso-real/`](experimentos/2026-10-30-opencode-uso-real/) | OpenCode v2.1.4 en esta máquina. No valida precios ni una instalación limpia | Validado |
| [`2026-11-02-coste-contexto-sesiones/`](experimentos/2026-11-02-coste-contexto-sesiones/) | Reparto de coste de 30 días: el 98% de la entrada es relectura de caché | Validado |
| [`plantilla-experimento.md`](experimentos/plantilla-experimento.md) | Plantilla para registrar un experimento nuevo | — |

## Arquitectura (`arquitectura/`)

| Documento | Qué contiene |
|---|---|
| [`architecture.md`](arquitectura/architecture.md) | El montaje local: componentes, límites de confianza y flujo previsto |

## Navegación rápida

- **Montar el entorno**: [`guias/server-deployment-ubuntu-ollama.md`](guias/server-deployment-ubuntu-ollama.md)
- **Primeros pasos con OpenCode**: [`guias/opencode-desde-cero.md`](guias/opencode-desde-cero.md)
- **Decidir entre local y cloud**: [`guias/local-vs-cloud.md`](guias/local-vs-cloud.md)
- **Entender la matriz**: [`referencia/prompt-robustness-testing.md`](referencia/prompt-robustness-testing.md)
- **Seguridad de asistentes**: [`referencia/hoja-de-ruta-seguridad-asistentes.md`](referencia/hoja-de-ruta-seguridad-asistentes.md)
- **Ver experimentos reales**: [`experimentos/2026-11-02-coste-contexto-sesiones/`](experimentos/2026-11-02-coste-contexto-sesiones/)
