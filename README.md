<img src="assets/iconos/ia-local.svg" width="64" alt="Icono del laboratorio de IA">

# Portfolio de aprendizaje en IA

Aprendo IA probando: uso cada herramienta en trabajo real y anoto qué sale. Empecé con un servidor propio y Ollama para no sacar datos de la red; hoy hay guías de agentes, experimentos y criterios sobre la frontera de datos. Nada de rankings sin medición.

> **Cómo se lee el estado.** Cada experimento declara el suyo en su ficha; las guías no llevan estado. **Validado** significa que se ejecutó y hay resultado observado. Un hallazgo no es un PASS.

## Guías

- **Montar el entorno:** [Ubuntu Server](docs/guias/server-deployment-ubuntu-ollama.md), [GPU y CUDA](docs/guias/gpu-setup.md) y [Continue con Ollama remoto](docs/guias/continue-remote-ollama-setup.md).
- **Trabajar con el agente:** [OpenCode desde cero](docs/guias/opencode-desde-cero.md), [continuidad entre sesiones](docs/guias/opencode-session-continuity.md) e [instrucciones públicas y privadas](docs/guias/agents-md-publico-privado.md).
- **Decidir qué sale de la red:** [local frente a cloud](docs/guias/local-vs-cloud.md) y [seguir sin proveedor remoto](docs/guias/continuidad-ia-local.md).
- **Cuando algo falla:** [diagnóstico](docs/guias/troubleshooting.md).

## Experimentos

- **Robustez:** `qwen2.5:3b` obedece la orden directa sin disfraz; el prompt endurecido no la mueve (0,50).
- **Contención:** red cerrada, disco de solo lectura y credencial fuera; el agente real, dentro, envía 24 KB antes de leer.
- **Autonomía:** un banco mide si un modelo local sube una rama sin tocar `main`: 0 veredictos en 14 ejecuciones.
- **Coste:** 98% de la entrada es relectura de caché.

Cada ficha dice qué probé, qué salió y qué falta medir. Índice: [`docs/README.md`](docs/README.md).

## Criterio

- **Hardware:** qué modelo cabe en cada memoria y cuándo compensa el equipo ([dimensionado](docs/referencia/dimensionado-hardware-ia-local.md)).
- **Autonomía:** cuatro niveles y cinco frenos para delegar sin persona delante ([autonomía](docs/referencia/autonomia-desatendida.md)).

## Antes de usarlo

- Ollama: firewall cerrado, `11434` sin abrir a Internet.
- Al agente que ejecuta: sin red y credencial fuera.
- La clave va en el entorno, no en `opencode.json`.
- Al proveedor remoto no le mandes secretos ni datos personales.

Criterios: [hoja de ruta de seguridad](docs/referencia/hoja-de-ruta-seguridad-asistentes.md). Licencia: MIT.
