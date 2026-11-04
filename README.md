<img src="assets/iconos/ia-local.svg" width="64" alt="Icono del laboratorio de IA">

# Portfolio de aprendizaje en IA

Aprendo IA probando: levanto una herramienta, la uso en trabajo real y anoto qué sale. Empecé con un servidor propio y Ollama para no sacar datos de la red; hoy hay guías de agentes, experimentos con resultado y criterios sobre qué dato cruza la frontera. Nada de rankings ni comparativas sin medición.

> **Estado (2026-11-04).** Cada guía y cada experimento declara el suyo en su ficha; este resumen no repite la lista. **Validado** significa que se ejecutó y hay resultado observado. Un hallazgo no es un PASS.

## Guías

- **Montar el entorno:** [Ubuntu Server](docs/guias/server-deployment-ubuntu-ollama.md), [GPU y CUDA](docs/guias/gpu-setup.md) y [Continue con Ollama remoto](docs/guias/continue-remote-ollama-setup.md).
- **Trabajar con el agente:** [OpenCode desde cero](docs/guias/opencode-desde-cero.md), [continuidad entre sesiones](docs/guias/opencode-session-continuity.md) e [instrucciones públicas y privadas](docs/guias/agents-md-publico-privado.md).
- **Decidir qué sale de la red:** [local frente a cloud](docs/guias/local-vs-cloud.md) y [seguir sin proveedor remoto](docs/guias/continuidad-ia-local.md).
- **Cuando algo falla:** [diagnóstico](docs/guias/troubleshooting.md).

## Experimentos

- **Robustez:** con `qwen2.5:3b`, una orden escondida se obedece sin disfraz; endurecer el prompt no baja la obediencia (0,50).
- **Coste:** el 98% de la entrada es relectura de caché.
- **OpenCode:** arranca, lee el repositorio y escribe.
- **7B con Continue:** funciona y va lento, sin artefacto reproducible.

Cada uno abre con qué probé, qué salió y qué no está medido. Índice: [`docs/README.md`](docs/README.md).

## Antes de usarlo

- Ollama no escucha en `0.0.0.0` sin firewall; el `11434` no se abre a Internet.
- La clave va en el entorno, no en `opencode.json`.
- Al proveedor remoto no le mandes secretos ni datos personales.

Criterios completos: [hoja de ruta de seguridad](docs/referencia/hoja-de-ruta-seguridad-asistentes.md). Licencia: MIT.
